module poseidon.intellisense.autocomplete;

private
{
	import CodeAnalyzer.syntax.core;
	import poseidon.intellisense.search;
	import std.string;
	import poseidon.controller.gui;
	import poseidon.controller.packageexplorer;
	import poseidon.globals;
}

/*
interface IComplete
{
	char[][] rootSearch( char[] root );
}
*/

// KeywordComplete
class KeywordComplete//:IComplete
{
private:
	import poseidon.util.xmlutil, ak.xml.coreXML, std.stdio;
	
	char[][] keywords_d = [ /*"Pascal", "Windows",*/ "abstract", "alias", "align", "asm", "assert", "auto", "body", "bool", "break", "byte",
					    	  "case", "cast", "catch", "cdouble", "cent", "cfloat", "char", "class", "const", "continue",
							  "creal", "dchar", "debug", "default", "delegate", "delete", "deprecated", "do", "double", 
							  "else", "enum", "export", "extern", "false", "final", "finally", "float", "for", "foreach", "function",
							  "goto", "idouble", "if", "ifloat", "import", "inout", "int", "interface", "invariant",
							  "ireal", "is", "lazy", "long", "mixin", "module", "new", "null",/*
							  "opAddAssign", "opAndAssign", "opApply", "opCall", "opCast", "opCatAssign", "opDivAssign",
							  "opIndex", "opIndexAssign", "opMulAssign", "opModAssign", "opOrAssign", "opPostInc",
							  "opPostDec", "opSubAssign", "opXorAssign", "opSlice", "opShlAssign", "opShrAssign", "opUShrAssign",*/
							  "out", "override", "package", "pragma", "private", "protected", "public",
							  "real", "ref", "return", "scope", "short", "static", "struct", "super", "switch", "synchronized",
							  "template", "this", "throw", "true", "try", "typedef", "typeid", "typeof",
							  "ubyte", "ucent", "uint", "ulong", "union", "unittest", "ushort",
							  "version", "void", "volatile", "wchar", "while", "with" ];	

	this()
	{
		char[] filename = std.path.join(Globals.lexerDir, "SCLEX_D.xml");
		XML xml = new XML();
		if(xml.Open(filename) < 0 )
		{
			delete xml;
			return; // failed
		}

		keywords_d = null;
	
		XMLnode root = xml.m_root.getChildEx("config", null);
		XMLnode node = root.getChild("lexer");
		if( node )
		{
			XMLnode nodeKeyWord = node.getChild("keywords");
			if(nodeKeyWord){
				int count = nodeKeyWord.getChildCount();
				for(int i=0; i<count; ++i)
				{
					char[] value = XMLUtil.getAttrib(nodeKeyWord.getChild(i), "value", null);
					keywords_d ~= std.string.split( value, " " );
				}
			}
		}
		keywords_d.sort;
	}

	char[][] rootSearch( char[] root )
	{
		char[][] results;
		if( root.length  ) char_rootSearchR( 0, keywords_d.length - 1, ( Globals.parserCaseSensitive ? root : std.string.tolower( root ) ), keywords_d, results  );

		return results;
	}
}

/*
// MRUComplete
class MRUComplete : IComplete
{
	private char[][] items;

	void addItem( char[] i )
	{ 
		i = i.strip();
		if ( ! TArray!(char[]).array_contains( items, i ) ) items ~= i; // make sure its unique
	} 

	char[][] rootSearch( char[] root )
	{
		char[][] results;
		if( root.length  ) char_rootSearchR( 0, items.length - 1, std.string.tolower( root ) , items, results );

		return results;
	}
}
*/



// ImportComplete
class ImportComplete
{
private:
	char[][] baseDirs;

	char[][] getfiltered( char[][] results )
	{
		char[][] uniques;
		
		foreach( char[] s; results )
		{
		    if( std.path.getExt( s ) == "d" )
				uniques ~= s[0 .. $-2]; // 如果附屬檔名為d,取得名稱
			else
				if( s.find(".") == -1 ) uniques ~= s;
		}

		return uniques.sort;
	}

public:

	this( char[][] defaultImportPath ){	baseDirs = defaultImportPath; }

	void createBaseDirs( char[][] defaultImportPath ){ baseDirs = defaultImportPath; }

	char[][] initialImports()
	{
		char[][] results;

		foreach( char[] dir; baseDirs )
			results ~= std.file.listdir( dir );

		return getfiltered( results );
	}

	char[][] perform( char[] word )
	{
		char[] s = std.string.replace( word, ".", "\\" );

		foreach( char[] path; baseDirs )
		{
			char[] fullPath = std.path.join( path, s );
			if( std.file.exists( fullPath ) )
			{
				try
				{
					if( std.file.isdir( fullPath ) ) return getfiltered( std.file.listdir( fullPath ) );
				}
				catch
				{
				}
			}
		}

		return null;
	}
}

// AutoComplete
class AutoComplete
{
	private import poseidon.util.fileutil;
	private import poseidon.util.miscutil;
	private import dwt.all;
	private import std.stream;

	class CAutoCompleteList
	{
		private:
		struct ListUnit
		{
			char[] identifier, typeIdentifier, imageIndex;//, from;
		}

		static ListUnit[] 	container;
		static int 			MaxIdentLength;


		static char[] getImageIndex( CAnalyzerTreeNode node, inout ListUnit unit )
		{
			int m, v;

			switch( node.DType )
			{
				case D_FUNCTION: 	m = 0; break;
				case D_VARIABLE: 	m = 1; break;
				case D_CLASS: 		m = 2; break;
				case D_STRUCT: 		m = 3; break;
				case D_INTERFACE:	m = 4; break;
				case D_UNION:		m = 5; break;
				case D_ENUM:		m = 6; break;
				case D_PARAMETER:
					return "?24";
				
				case D_ENUMMEMBER:
					return "?25";
				
				case D_TEMPLATE:
					if( node.baseClass == "i" )
					{
						if( node.getLeaf( 0 ).DType & D_FUNCTION ) return "?30";
					}
					else if( node.baseClass == "c" )
					{
						switch( node.getLeaf(0).DType )
						{
							case D_CLASS: 		return "?31";
							case D_STRUCT: 		return "?32";
							case D_UNION:		return "?33";
							case D_INTERFACE: 	return "?34";
							default:
						}
					}
							
					return "?26";

				case D_IMPORT:
					if( node.typeIdentifier.length )
					{
						unit.identifier = node.typeIdentifier;
						return "?22";
					}

					int dotPos = std.string.find( node.identifier, "." );
					if( dotPos < 0 ) dotPos = node.identifier.length;

					unit.identifier = node.identifier[0..dotPos];
					return "?22";

				case D_ALIAS:
				case D_TYPEDEF:
					return "?27";

				case D_MIXIN:
					if( node.typeIdentifier.length ) unit.identifier = node.typeIdentifier;
					return "?28";

				case D_FUNLITERALS:
					return "?29";

				default:
					return "?23";
			}

			if( node.prot & D_Private ) 
				v = 0;
			else if( node.prot & D_Protected ) 
				v = 1;
			else
				v = 2;

			return "?" ~ std.string.toString( m * 3 + v );
		}

		public:
		static void add( char[] word, char[] imageindex )
		{
			ListUnit unit;
			unit.identifier = word;
			if( word.length > MaxIdentLength ) MaxIdentLength = word.length;
			unit.imageIndex = imageindex;

			container ~= unit;
		}

		static void add( char[][] words, char[] imageindex )
		{
			foreach( char[] s; words )
				add( s, imageindex );
		}		

		static void add( CAnalyzerTreeNode node )
		{
			ListUnit unit;

			unit.identifier = node.identifier;
			if( node.identifier.length > MaxIdentLength ) MaxIdentLength = node.identifier.length;
			
			unit.typeIdentifier = node.typeIdentifier;
			unit.imageIndex = getImageIndex( node, unit );

			/*
			char[] moduleName, fullPath;
			sAutoComplete.getModuleNames( node, moduleName, fullPath );
			unit.from = moduleName;
			*/

			container ~= unit;
		}

		static void add( CAnalyzerTreeNode[] nodes )
		{
			foreach( CAnalyzerTreeNode t; nodes )
				add( t );
		}

		static void clean()
		{
			MaxIdentLength = 0;
			container.length = 0;
		}

		static char[] getResult()
		{
			if( !container.length ) return null;
			
			char[] result;
			MaxIdentLength += 2;
			
			scope sortTool = new CIdentSort!(ListUnit)( container ) ;

			foreach( ListUnit l; sortTool.scintillaPop() )//pop() )
			{
				result ~= ( ( l.typeIdentifier.length && Globals.showType ? std.string.ljustify( l.identifier, MaxIdentLength ) ~ "::" ~ l.typeIdentifier : l.identifier ) ~ l.imageIndex ~ "^" );
			}

			result = result[0..length-1];

			clean();

			return result;
		}
	}

	
	CAnalyzerTreeNode[char[]][char[]]			projectParsers;
	private CAnalyzerTreeNode[char[]][char[]]	defaultParsers;
	
	CAnalyzerTreeNode	 						fileParser;
	CAnalyzerTreeNode 							runtimeObjectParser;
	//private char[]							fileParserPath;

	KeywordComplete 							keywordParser;
	//MRUComplete 								mruParser;

	ImportComplete[char[]]						projectImportParsers;
  
	this()
	{
		keywordParser = new KeywordComplete;
		//mruParser = new MRUComplete;
		//importParser = new ImportComplete;
	}

	void setFileParser( CAnalyzerTreeNode f ){ fileParser = f; }
	
	//void setFileParserPath( char[] path ){ fileParserPath = path; }

	//char[] getFileParserPath(){ return fileParserPath;}

	private void _message( Object args )
	{
		StringObj s = cast(StringObj) args;
		sGUI.outputPanel.appendString( s.data );
	}

	bool saveNCB( char[] projectPath, char[] projectName, char[][] path )
	{
		char[] fileText;

		if( !projectParsers.length ) return false;

		if( projectName in projectParsers )
		{
			foreach( char[] s; path )
			{
				if( s in projectParsers[projectName] )
				{
					if( projectParsers[projectName][s] !is null )
						fileText ~= ( CodeAnalyzer.syntax.nodeHsu.savenalyzerNode( null, projectParsers[projectName][s] ) ~ "<End_Of_File>\n" );
				}
			}

			if( fileText.length )
			{
				poseidon.util.fileutil.FileSaver.save( projectPath ~ "\\" ~ projectName ~ ".ncb", fileText );
				return true;
			}
		}

		return false;
	}


	private CAnalyzerTreeNode[] loadNCB( char[] ncbFilePath, char[][] projectFiles )
	{
		// nested function
		bool _isProjectFile( char[] fileName )
		{
			foreach( char[] s; projectFiles )
			{
				if( fileName == s ) return true;
			}
			return false;
		}

		
		scope file = new File( ncbFilePath, FileMode.In );

		CAnalyzerTreeNode 	activeNode;
		CAnalyzerTreeNode[]	pasers;

		Display display = Display.getDefault();

		bool 				bReleaseFlag;
		CAnalyzerTreeNode 	root;

		char[] firstLine = file.readLine();
		if( firstLine.length > 8 )
		{
			// skip UTF-8 BOM EF BB BF
			if( firstLine[length-9..length] == "536870912" )
			{
				root = new CAnalyzerTreeNode;
				root.DType = D_MAINROOT;		
				activeNode = root;
			}
			else
			{
				throw new Exception( ".ncb file: " ~ ncbFilePath ~ " head error!" );
			}
		}
		else
			throw new Exception( ".ncb file: " ~ ncbFilePath ~ " head error!" );


		void _addNode()
		{
			char[] lineText = file.readLine();

			if( lineText.length )
			{
				if( lineText[0] == '/' ) 
				{
					activeNode = activeNode.getRoot();
				}
				else
				{
					char[][] splitTexts = std.string.split( lineText, "#" );
					if( splitTexts.length == 7 )
					{
						activeNode = activeNode.addLeaf( std.conv.toInt( splitTexts[1] ),
									std.conv.toInt( splitTexts[0] ), splitTexts[2], splitTexts[3],
										std.conv.toInt( splitTexts[4] ), splitTexts[5], splitTexts[6] );

						if( activeNode.DType & D_MODULE )
						{
							if( _isProjectFile( activeNode.typeIdentifier ) )
							{
								if( Globals.backLoadParser )
									display.asyncExec( new StringObj( "NCB File[ "~ activeNode.typeIdentifier ~ " ] Parsed.\n" ) , &_message );
								else
									sGUI.outputPanel.appendString( "NCB File[ "~ activeNode.typeIdentifier ~ " ] Parsed.\n" );
							}
							else
							{
								bReleaseFlag = true;
							}
						}
						
					}
					else if( splitTexts.length == 1 )
					{
						if( lineText == "<End_Of_File>" )
						{
							if( bReleaseFlag )
							{
								if( root !is null ) delete root;
								bReleaseFlag = false;
							}
							else
								pasers ~= root;
						}
						else if( lineText == "536870912" )
						{
							root = new CAnalyzerTreeNode;
							root.DType = D_MAINROOT;		
							activeNode = root;
						}
						else
						{
							delete pasers;
							throw new Exception( ".ncb file: " ~ ncbFilePath ~ " error!" );
						}
					}
					else
					{
						delete pasers;
						throw new Exception( ".ncb file: " ~ ncbFilePath ~ " error!" );
					}
				}
			}
		}

		while( !file.eof )
		{
			_addNode();
		}
				
		file.close();

		return pasers;
	}

	
	CAnalyzerTreeNode getParserFromProjectParser( char[] fileName )
	{
		if( !projectParsers.length ) return null;

		char[] projectName = sGUI.packageExp.getActiveProjectName();

		if( projectName in projectParsers )
		{
			if( fileName in projectParsers[projectName] )
				return projectParsers[projectName][fileName];
			else
				return null;
		}
		else
			return null;
	}

	CAnalyzerTreeNode getParserFromProjectParserByModuleName( char[] moduleName )
	{
		if( !projectParsers.length ) return null;

		char[] projectName = sGUI.packageExp.getActiveProjectName();

		foreach( CAnalyzerTreeNode t; projectParsers[projectName] )
		{
			char[] mName, fName;
			getModuleNames( t, mName, fName );
			if( mName == moduleName ) return t;
		}

		return null;
	}


	void addProjectParser( char[][] paths )
	{
		char[] projectName 	= sGUI.packageExp.getActiveProjectName();
		char[] projectDir	= sGUI.packageExp.getActiveProjectDir();

		char[] ncbFullPath = projectDir ~ "\\" ~ projectName ~ ".ncb";

		if( std.file.exists( ncbFullPath ) )
		{
			try
			{
				foreach( CAnalyzerTreeNode t; loadNCB( ncbFullPath, paths ) )
				{
					char[] mName, fName;
					getModuleNames( t, mName, fName );
					projectParsers[projectName][fName] = t;
				}
			}
			catch( Exception e )
			{
				MessageBox.showMessage( e.toString );
			}
		}

		Display display = Display.getDefault();

		foreach( char[] s; paths )
		{
			if( !std.string.icmp( std.path.getExt( s ), "d" ) || !std.string.icmp( std.path.getExt( s ), "di" )  )
			{
				try
				{
					bool bLoadParse = true;
					
					if( projectName in projectParsers )
						if( s in projectParsers[projectName] ) bLoadParse = false;

					if( bLoadParse )
					{
						projectParsers[projectName][s] = CodeAnalyzer.syntax.core.parseFileHSU( s );
						if( Globals.backLoadParser )
							display.asyncExec( new StringObj( "File[ "~ s ~ " ] Parsed.\n" ) , &_message );
						else
							sGUI.outputPanel.appendString( "File[ "~ s ~ " ] Parsed.\n" );
					}
				}
				catch( Exception e )
				{
					if( Globals.backLoadParser )
						display.asyncExec( new StringObj( "      File[ "~ s ~ " ] Parsed Error.\n" ) , &_message );
					else
					{
						sGUI.outputPanel.setForeColor( 0, 0, 0 );
						sGUI.outputPanel.appendString( "      File[ "~ s ~ " ] Parsed Error.\n" );
					}
				}
			}
		}

		if( ( Globals.parseAllModule || Globals.parseImported ) && paths.length ) setAdditionImportModules();
	}

	void refreshFileParser( char[][] paths )
	{
		char[] projectName = sGUI.packageExp.getActiveProjectName();

		if( projectName in projectParsers )
		{
			foreach( char[] key; projectParsers[projectName].keys )
				if( !MiscUtil.inArray( key, paths ) ) removeSingleFileParser( key, projectName );

			foreach( char[] fileName; paths )
				if( !( fileName in projectParsers[projectName] ) ) addSingleFileParser( fileName, projectName );
		}
		else
			addProjectParser( paths );
	}
	

	void updateProjectParser( CAnalyzerTreeNode analyzer, char[] fileName )
	{
		char[] projectName = sGUI.packageExp.getActiveProjectName();

		if( projectName in projectParsers )
		{
			if( fileName in projectParsers[projectName] )
			{
				bool BReverseFileParse;
				
				CAnalyzerTreeNode parser = projectParsers[projectName][fileName];
				delete parser;

				if( analyzer !is null )
				{
					projectParsers[projectName][fileName] = analyzer;
					sGUI.outputPanel.setForeColor( 0, 0, 0 );
					sGUI.outputPanel.appendString( "Project[ " ~ projectName ~ " ][ "~ fileName ~ " ] Parser Updated.\n" );
				}
				else
				{
					projectParsers[projectName].remove( fileName );
				}
			}
			else
			{
				if( analyzer !is null )
				{
					projectParsers[projectName][fileName] = analyzer;
					sGUI.outputPanel.setForeColor( 0, 0, 0 );
					sGUI.outputPanel.appendString( "Project[ " ~ projectName ~ " ][ "~ fileName ~ " ] Parser Added.\n" );
				}
			}
		}
		else
		{
			if( analyzer )
			{
				projectParsers[projectName][fileName] = analyzer;
				sGUI.outputPanel.setForeColor( 0, 0, 0 );
				sGUI.outputPanel.appendString( "Project[ " ~ projectName ~ " ][ "~ fileName ~ " ] Parser Added.\n" );
			}
		}
	}

	bool addSingleFileParser( char[] fileName, char[] projectName )
	{
		if( projectName in projectParsers )
		{
			if( fileName in projectParsers[projectName] )
			{
				CAnalyzerTreeNode t = projectParsers[projectName][fileName];
				if( t !is null ) delete t;
			}

			try
			{
				projectParsers[projectName][fileName] = CodeAnalyzer.syntax.core.parseFileHSU( fileName );
				sGUI.outputPanel.setForeColor( 0, 0, 0 );

				/*if( Globals.backLoadParser )
				{
					Display display = Display.getDefault();
					display.asyncExec( new StringObj( "Project[ " ~ projectName ~ " ][ "~ fileName ~ " ] Parser Added.\n" ) , &_message );
				}
				else*/
					sGUI.outputPanel.appendString( "Project[ " ~ projectName ~ " ][ "~ fileName ~ " ] Parser Added.\n" );
					
				return true;
			}
			catch( Exception e )
			{
				if( fileName in projectParsers[projectName] ) projectParsers[projectName].remove( fileName );
				return false;
			}
		}
		
		return false;
	}
	

	bool removeSingleFileParser( char[] fileName, char[] projectName )
	{
		if( projectName in projectParsers )
		{
			if( fileName in projectParsers[projectName] )
			{
				CAnalyzerTreeNode t = projectParsers[projectName][fileName];
				if( t !is null ) delete t;
				projectParsers[projectName].remove( fileName );

				/*if( Globals.backLoadParser )
				{
					Display display = Display.getDefault();
					display.asyncExec( new StringObj( "Removed [ " ~ projectName ~ " ][ "~ fileName ~ " ] Parser.\n" ) , &_message );
				}
				else
				{*/
					sGUI.outputPanel.setForeColor( 0, 0, 0 );
					sGUI.outputPanel.appendString( "Removed [ " ~ projectName ~ " ][ " ~ fileName ~ " ] Parser.\n" );
				/*}*/
				
				return true;
			}
		}
		return false;
	}

	bool renSingleFileParser( char[] fileName, char[] newFileName, char[] projectName )
	{
		if( projectName in projectParsers )
		{
			if( fileName in projectParsers[projectName] )
			{
				projectParsers[projectName][newFileName] = projectParsers[projectName][fileName].dup();
				CAnalyzerTreeNode t = projectParsers[projectName][fileName];
				if( t !is null ) delete t;				
				projectParsers[projectName].remove( fileName );

				sGUI.outputPanel.appendString( "Rename File[ " ~ fileName ~ " ] To [ " ~ newFileName ~ " ].\n" );
				return true;
			}
		}
		return false;
	}

	
	void deleteProjectParser( char[] projectName )
	{
		if( projectName in projectParsers )
		{
			foreach( CAnalyzerTreeNode t; projectParsers[projectName] )
				if( t ) delete t;

			projectParsers.remove( projectName );
			sGUI.outputPanel.setForeColor( 0, 0, 0 );
			sGUI.outputPanel.appendString( "Removed project[ " ~ projectName ~ " ].\n" );
		}
	}

	void deleteImportParser( char[] projectDir )
	{
		if( projectDir in projectImportParsers )
		{
			ImportComplete i = projectImportParsers[projectDir];
			delete i;
			projectImportParsers.remove( projectDir );
		}	
	}


	void loadDefaultParser( char[] dir )
	{
		try
		{
			scope stdFiles = new CFindAllFile( dir, "*.ana" );

			char[][] 	files = stdFiles.getFiles();
			char[]		defaultParserName = std.string.tolower( std.path.getBaseName( dir ) );

			sGUI.outputPanel.appendLine( "Default Paser[ " ~ defaultParserName ~ " ] Loading......" );
			sGUI.outputPanel.setForeColor( 0, 160, 0 );

			foreach( char[] s; files )
			{
				CAnalyzerTreeNode tempAnalyzer = CodeAnalyzer.syntax.nodeHsu.loadAnalyzerNode( s );
				if( tempAnalyzer )
				{
					char[] moduleName = tempAnalyzer.getLeaf( 0 ).identifier;

					defaultParsers[defaultParserName][moduleName] = tempAnalyzer;
					sGUI.outputPanel.appendLine( "[ " ~ moduleName ~ " ] " ~ "Loaded." );
				}
				else
				{
					sGUI.outputPanel.appendLine( "   The .ana File[ " ~ s ~ " ] may be broken" );
				}
			}
			sGUI.outputPanel.appendLine( "......Load Finish.\n" );
		}
		catch( Exception e )
		{
			char[]	defaultParserName = std.string.tolower( std.path.getBaseName( dir ) );
			sGUI.outputPanel.appendLine( "   Default Parser [ " ~  defaultParserName ~ " ] Load Error. ( Wrong Parser Path )" );
			MessageBox.showMessage( e.toString );
			// throw new Exception( "Load Default Parser Error!" );
		}
	}

	bool loadRuntimeParser()
	{
		try
		{
			runtimeObjectParser = CodeAnalyzer.syntax.nodeHsu.loadAnalyzerNode( "object.ana" );
		}
		catch
		{
			return false;
		}

		return true;
	}

	CAnalyzerTreeNode checkRuntimeParser( char[] ident )
	{
		if( runtimeObjectParser !is null )
		{
			CAnalyzerTreeNode[] dummyClass;
			return getMemberAnalyzerTreeNode( ident, D_ALL, runtimeObjectParser, dummyClass );
		}
		return null;
	}
	
	char[] forceComplete( char[] word )
	{
		/*
		char[][] words;

		words = mruParser.rootSearch( word );
		words ~= keywordParser.rootSearch( word );
     
		// 列出所有的 CAnalyzerTreeNode
		CAnalyzerTreeNode[] treeNodes = search( word, D_ALL );

		foreach( CAnalyzerTreeNode t; treeNodes )
			word ~= t.identifier;

		// 排列所有的words
		TArray!(char[]).sort( words, &icharCompare );
		char[][] uniques = TArray!(char[]).array_unique( words );
		char[] ret = std.string.join( uniques, " " );
			
		return ret;
		*/return null;
	}

	/+
	char[][] setMemberImage( CAnalyzerTreeNode[] nodes, char[][] mixinWords = null )
	{
		if( !nodes.length && !mixinWords.length ) return null;
		
		char[][] words;
		
		foreach( CAnalyzerTreeNode t; nodes )
		{
			int m, v;

			switch( t.DType )
			{
				case D_FUNCTION: 	m = 0; break;
				case D_VARIABLE: 	m = 1; break;
				case D_CLASS: 		m = 2; break;
				case D_STRUCT: 		m = 3; break;
				case D_INTERFACE:	m = 4; break;
				case D_UNION:		m = 5; break;
				case D_ENUM:		m = 6; break;
				case D_PARAMETER:
					words ~= ( t.identifier ~ ( Globals.showType ? "::" ~ t.typeIdentifier : null ) ~ "?24" );
					continue;
					break;
				/+
				case D_ENUMMEMBER:
					words ~= ( t.identifier ~ "?25" );
					continue;
					break;
				+/
				case D_TEMPLATE:
					words ~= ( t.identifier ~ "?26" );
					continue;
					break;

				case D_IMPORT:
					if( t.typeIdentifier.length )
						words ~= ( t.typeIdentifier ~ "?22" );
					else
					{
						int dotPos = std.string.find( t.identifier, "." );
						if( dotPos < 0 ) dotPos = t.identifier.length;
							
						words ~= ( t.identifier[0..dotPos] ~ "?22" );
					}
					continue;
					break;

				default:
					words ~= ( t.identifier ~ "?23" );
					continue;
					break;
			}

			if( t.prot & D_Private ) 
				v = 0;
			else if( t.prot & D_Protected ) 
				v = 1;
			else
				v = 2;

			if( m < 2 )
				words ~= ( t.identifier ~ ( Globals.showType ? "::" ~ t.typeIdentifier : null ) ~ "?" ~ std.string.toString( m * 3 + v ) );
			else
				words ~= ( t.identifier ~ "?" ~ std.string.toString( m * 3 + v ) );
		}

		if( mixinWords.length ) words ~= mixinWords;

		if( !words.length ) return null;

		scope sortList = new CCharsSort!( char[] )( words );
		words = sortList.scintillaPop();

		return words;
	}
	+/


	void autoCSearch( char[] word, CAnalyzerTreeNode headNode )
	{
		//char[][] 	words;
		//char[] 		ret;

		/*
		words = mruParser.rootSearch( word );
		words ~= keywordParser.rootSearch( word );

		if( words.length )
		{
			TArray!(char[]).sort( words, &icharCompare );
			char[][] uniques = TArray!(char[]).array_unique( words );
			ret = std.string.join( uniques, "?21 " ) ~ "?21";
		}
		*/
		foreach( char[] s; keywordParser.rootSearch( word ) )
			CAutoCompleteList.add( s, "?21" );

		if( fileParser )
		{
			if( headNode !is null )
			{
				char[] mName, fName;
				getModuleNames( headNode, mName, fName );

				if( word.length <= mName.length )
				{
					if( Globals.parserCaseSensitive )
					{
						if( word == mName[0..word.length] ) CAutoCompleteList.add( mName, "?22" );
					}
					else
					{
						if( std.string.tolower( word ) == std.string.tolower( mName[0..word.length] ) )
							CAutoCompleteList.add( mName, "?22" );
					}
				}				
			}
			
			char[][] 	treeWords;
			int			DType = D_ALL - D_MODULE - D_MAINROOT - D_BLOCK - D_CTOR - D_DTOR;
			int			noFunctionScopeDType = DType - D_FUNCTION;
			
			CAnalyzerTreeNode[] treeNodesSum;
				
			if( !headNode )
				treeNodesSum = getAnalyzerAllNode( fileParser, DType );
			else
			{
				treeNodesSum = getAnalyzerAllNodeR( headNode, DType );
				treeNodesSum ~= getAnalyzerAllNode( runtimeObjectParser, DType );

				// If under class, get base class
				CAnalyzerTreeNode nowNode = headNode;

				while( !( nowNode.DType & D_MAINROOT ) )
				{
					if( nowNode.DType & ( D_CLASS | D_INTERFACE ) )
					{
						if( nowNode.baseClass.length )
						{
							foreach( CAnalyzerTreeNode t; getBaseClassNode( nowNode ) )
							{
								if( headNode.DType & ( D_CLASS | D_INTERFACE ) )
									treeNodesSum ~= getMembers( noFunctionScopeDType, t );
								else
									treeNodesSum ~= getMembers( DType, t );
							}
						}
					}

					nowNode = nowNode.getRoot();
				}
				
				CAnalyzerTreeNode[] 		importModules;		

				getImport( "dummy", D_ALL, headNode, importModules, true );
				int moduleDType = D_UDTS | D_FUNCTION | D_ALIAS | D_TYPEDEF | D_VARIABLE | D_IMPORT;
				foreach( CAnalyzerTreeNode a; importModules )
				{
					foreach( CAnalyzerTreeNode t; getMembers( moduleDType, a ) )
						if( !( t.prot & ( D_Private | D_Protected ) ) ) treeNodesSum ~= t;
				}
			}

			if( treeNodesSum.length )
			{
				//CAnalyzerTreeNode[] treeNodes = rootSearch( word, treeNodesSum );
				foreach( CAnalyzerTreeNode t; rootSearch( word, treeNodesSum ) )
				{
					if( Globals.showAllMember )
						CAutoCompleteList.add( t );
					else
					{
						if( isSameRoot( t, headNode ) )
							CAutoCompleteList.add( t );
						else
							if( !( t.prot & D_Private ) ) CAutoCompleteList.add( t );
					}
				}
				//CAutoCompleteList.add( treeNodes );
			}
		}
	}	


	// 找出特定種類的 CAnalyzerTreeNode ( CAnalyzerTreeNode.name = ... )
	CAnalyzerTreeNode[] search( char[] word, int DType = D_ALL, bool bPassFilePaser = false )
	{
		CAnalyzerTreeNode[] treeNodes;

		if( !fileParser ) return null;

		if( word.length )
		{
			if( !bPassFilePaser )
				if( !treeNodes.length ) treeNodes ~= lookAnalyzerTree( word, DType, fileParser ); 
			
			if( !treeNodes.length ) // 再找專案的Parser
			{
				char[] projectName = sGUI.packageExp.getActiveProjectName();
				foreach ( CAnalyzerTreeNode p; projectParsers[projectName] )
					if( p != fileParser ) treeNodes ~= lookAnalyzerTree( word, DType, p );
			}
			
		}

		return treeNodes;
	}		
		

	// 從根節點->子節點方向找尋及傳回所有適合的 CAnalyzerTreeNode
	CAnalyzerTreeNode[] lookAnalyzerTree( char[] ident, int DType = D_ALL, CAnalyzerTreeNode activeTreeNode = null )
	{
		if( !ident.length ) return null;
		if( !activeTreeNode ) return null;

		CAnalyzerTreeNode[] results;
		foreach( CAnalyzerTreeNode t; getAnalyzerAllNode( activeTreeNode, DType ) )
		{
			if( t.identifier == ident ) results ~= t;
		}

		return results;		
		/*
		if( !ident.length ) return null;
		if( !activeTreeNode ) return null;

		CAnalyzerTreeNode[] analyzerTreeNodes;

		// Nested Function
		void _lookingFormHead( CAnalyzerTreeNode treeNode )
		{
			if( treeNode.DType & DType  )
				if( treeNode.identifier == ident ) analyzerTreeNodes ~= treeNode;
			
			foreach( CAnalyzerTreeNode t; treeNode.getAllLeaf() )
				_lookingFormHead( t );
		}

		_lookingFormHead( activeTreeNode );

		return analyzerTreeNodes;
		*/
	}


	// 反向找尋及傳回第一個適合的 CAnalyzerTreeNode
	CAnalyzerTreeNode getAnalyzerTreeNode( char[] ident, int DType = D_ALL, CAnalyzerTreeNode treeNode = null,
					  bool bBottomLook = false )
	{
		if( !ident.length ) return null;
		if( !treeNode ) return null;

		int Deprecated = checkDeprecated();

		if( bBottomLook ) // 找尋此節點的葉節點
		{
			foreach( CAnalyzerTreeNode t; getMembers( DType, treeNode ) )
				if( t.identifier == ident )	return t;
		}

		CAnalyzerTreeNode node = treeNode.getRoot();

		while( node )
		{
			for( int i = 0; i < node.getLeafCount(); ++i )
			{
				if( node[i].DType & ( D_VERSION | D_DEBUG ) )
				{
					if( !( node.DType & ( D_VERSION | D_DEBUG ) ) )
					{
						CAnalyzerTreeNode[] dummyClasses;
						CAnalyzerTreeNode resultNode = getMemberAnalyzerTreeNode( ident, DType, node[i], dummyClasses );
						if( resultNode ) return resultNode;
					}
				}
				else
				{
					if( node[i].DType & DType )
						if( !( node[i].prot & Deprecated ) )
							if( node[i].identifier == ident ) return node[i];
				}
			}
			node = node.getRoot;
		}

		return null;
	}
	

	// 找出繼承的類別們
	CAnalyzerTreeNode[] getBaseClassNode( CAnalyzerTreeNode treeNode  )
	{
		CAnalyzerTreeNode[] baseClassNodes;
		
		void _getNode( CAnalyzerTreeNode node )
		{
			if( !node.baseClass.length ) return;

			char[][] 			className = std.string.split( node.baseClass, "," );
			CAnalyzerTreeNode[] gotClasses;


			foreach( char[] s; className )
			{
				int			DType = D_CLASS | D_INTERFACE;
				char[][] 	templateClassName = std.string.split( s, "!" );

				s = templateClassName[0];
				if( templateClassName.length > 1 ) DType = DType | D_TEMPLATE;

				
				// 先找原class所在Parser
				CAnalyzerTreeNode activeTreeNode = getAnalyzerTreeNode( s, DType, node, true );

				if( !activeTreeNode )
				{
					CAnalyzerTreeNode[] dummyAnalyzers;
					activeTreeNode = getImport( s, DType, node, dummyAnalyzers );

					if( activeTreeNode ) 
					{
						if( DType & D_TEMPLATE )
						{
							foreach( CAnalyzerTreeNode t; activeTreeNode.getAllLeaf() )
							{
								if( t.DType == D_CLASS || t.DType == D_INTERFACE )
									if( t.identifier == s )	
										activeTreeNode = t;
							}
						}

						if( !MiscUtil.inArray( activeTreeNode, baseClassNodes ) ) 
						{
							baseClassNodes ~= activeTreeNode;
							gotClasses ~= activeTreeNode;
						}
					}
				}else
				{
					if( DType & D_TEMPLATE )
					{
						foreach( CAnalyzerTreeNode t; activeTreeNode.getAllLeaf() )
						{
							if( t.DType == D_CLASS || t.DType == D_INTERFACE )
								if( t.identifier == s )	
									activeTreeNode = t;
						}
					}

					if( !MiscUtil.inArray( activeTreeNode, baseClassNodes ) ) 
					{					
						baseClassNodes ~= activeTreeNode;
						gotClasses ~= activeTreeNode;
					}
				}
			}

			foreach( CAnalyzerTreeNode t; gotClasses )
			{
				_getNode( t );
			}
				
		}

		_getNode( treeNode );

		return baseClassNodes;
	}


	CAnalyzerTreeNode[] getMembers( int DType = D_ALL, CAnalyzerTreeNode node = null )
	{
		if( !node ) return null;

		char[][]	projectVersions = sGUI.packageExp.activeProject.getVersionCondition();
		char[][]	projectDebugs	= sGUI.packageExp.activeProject.getDebugCondition();
		
		if( node.DType & ( D_VERSION | D_DEBUG ) )
			if( !checkCondition( node, node.prev, projectVersions, projectDebugs ) ) return null;

		int Deprecated = checkDeprecated();
		CAnalyzerTreeNode[] results;

		for( int i = 0; i < node.getLeafCount; ++ i )
		{
			if( node[i].DType & ( D_VERSION | D_DEBUG ) )
			{			
				results ~= getMembers( DType, node[i] );
				continue;
			}
			else if( node[i].DType & D_MIXIN )
			{
				if( !( node.DType & ( D_VERSION | D_DEBUG ) ) )
				{
					results ~= getTemplateNodes( node[i] );
				}

				/*
				CAnalyzerTreeNode mixinNode = getAnalyzerTreeNode( node[i].identifier, D_TEMPLATE, node[i], false );
				if( mixinNode is null )
				{
					CAnalyzerTreeNode[] dummyAnalyzers;
					mixinNode = getImport( node[i].identifier, D_TEMPLATE, node[i], dummyAnalyzers );
				}

				if( mixinNode !is null )
				{
					results ~= getMembers( D_VARIABLE | D_UDTS | D_FUNCTION, mixinNode );
					//bNotFriendClass = true;
				}
				*/

				continue;
			}

			if( node[i].DType & DType )
				if( !( node[i].prot & Deprecated ) ) results ~= node[i];
		}

		return results;
	}
	
	
	// 取得
	CAnalyzerTreeNode getMemberAnalyzerTreeNode( char[] ident, int DType = D_ALL, CAnalyzerTreeNode node = null, inout CAnalyzerTreeNode[] baseClasses = null )
	{
		if( !ident.length ) return null;
		if( !node ) return null;

		char[][]	projectVersions = sGUI.packageExp.activeProject.getVersionCondition();
		char[][]	projectDebugs	= sGUI.packageExp.activeProject.getDebugCondition();

		int Deprecated = checkDeprecated();
		
		for( int i = 0; i < node.getLeafCount; ++ i )
		{
			if( node[i].DType & ( D_VERSION | D_DEBUG ) )
			{
				if( checkCondition( node[i], ( i > 0 ? node[i-1] : null ), projectVersions, projectDebugs ) )
				{
					CAnalyzerTreeNode conditionNodeResult = getMemberAnalyzerTreeNode( ident, DType, node[i], baseClasses );
					if( conditionNodeResult !is null ) return conditionNodeResult;
				}

				continue;
			}
			else if( node[i].DType & D_MIXIN )
			{
				CAnalyzerTreeNode mixinNode = getAnalyzerTreeNode( node[i].identifier, D_TEMPLATE, node[i], false );
				if( mixinNode is null )
				{
					CAnalyzerTreeNode[] dummyAnalyzers;
					mixinNode = getImport( node[i].identifier, D_TEMPLATE, node[i], dummyAnalyzers );
				}

				if( mixinNode !is null )
				{
					mixinNode = getMemberAnalyzerTreeNode( ident, DType, mixinNode, baseClasses );
					if( mixinNode !is null ) return mixinNode;
				}

				continue;
			}			

			if( node[i].DType & DType )
				if( !( node[i].prot & Deprecated ) )
					if( node[i].identifier == ident ) return node[i];
		}

		// 找不到時找繼承父類別的成員
		if( node.baseClass.length )
		{
			baseClasses = getBaseClassNode( node );
			
			foreach( CAnalyzerTreeNode t; baseClasses )
			{
				foreach( CAnalyzerTreeNode tt; t.getAllLeaf() )
				{
					if( tt.DType & DType )
						if( !( tt.prot & Deprecated ) )
							if( tt.identifier == ident ) return tt;
				}
			}
		}

		return null;
	}


	// 取得
	CAnalyzerTreeNode getMixinIdentifierNode( char[] ident, CAnalyzerTreeNode node = null )
	{
		if( !ident.length ) return null;
		if( !node ) return null;

		char[][]	projectVersions = sGUI.packageExp.activeProject.getVersionCondition();
		char[][]	projectDebugs	= sGUI.packageExp.activeProject.getDebugCondition();

		int Deprecated = checkDeprecated();
		
		for( int i = 0; i < node.getLeafCount; ++ i )
		{
			if( node[i].DType & ( D_VERSION | D_DEBUG ) )
			{
				if( checkCondition( node[i], ( i > 0 ? node[i-1] : null ), projectVersions, projectDebugs ) )
				{
					CAnalyzerTreeNode subNode = getMixinIdentifierNode( ident, node[i] );
					if( subNode !is null ) return subNode;
				}

				continue;
			}
			else if( node[i].DType & D_MIXIN )
			{
				
				if( ident == node[i].typeIdentifier )
				{
					/*
					CAnalyzerTreeNode mixinNode = getAnalyzerTreeNode( node[i].identifier, D_TEMPLATE, node[i], false );
					CAnalyzerTreeNode[] dummyAnalyzers;
					
					if( mixinNode is null )	
						mixinNode = getImport( node[i].identifier, D_TEMPLATE, node[i], dummyAnalyzers );
					*/

					return node[i];
				}
			}			
		}

		return null;
	}

	
	CAnalyzerTreeNode[] getAnalyzerAllNode( CAnalyzerTreeNode node, int DType = D_ALL )
	{
		CAnalyzerTreeNode[] results;

		void _getLeaf( CAnalyzerTreeNode _node )
		{
			if( _node.DType & DType ) results ~= _node;
			
			if( _node.DType & ( D_VERSION | D_DEBUG ) )
			{
				results ~= getMembers( DType, _node );
			}
			else
			{
				foreach( CAnalyzerTreeNode t; _node.getAllLeaf() )
					_getLeaf( t );
			}
		}

		foreach( CAnalyzerTreeNode t; node.getAllLeaf() )
			_getLeaf( t );

		return results;
	}

	CAnalyzerTreeNode[] getTemplateNodes( CAnalyzerTreeNode node )
	{
		CAnalyzerTreeNode[] results;
		bool bGo;
		
		// only on scope
		if( node.DType & D_MIXIN ) // guick test!
		{
			CAnalyzerTreeNode mixinNode = getAnalyzerTreeNode( node.identifier, D_TEMPLATE, node, false );
			if( mixinNode is null )
			{
				CAnalyzerTreeNode[] dummyAnalyzers;
				mixinNode = getImport( node.identifier, D_TEMPLATE, node.getRoot, dummyAnalyzers );
			}

			if( mixinNode !is null ) results ~= getMembers( D_VARIABLE | D_UDTS | D_FUNCTION, mixinNode );
		}

		return results;

	}

	CAnalyzerTreeNode[] getAnalyzerAllNodeR( CAnalyzerTreeNode node, int DType = D_ALL, bool bSkipScopeMixin = false )
	{
		if( !node ) return null;

		CAnalyzerTreeNode[] results;

		bool bhadScopeMixin = bSkipScopeMixin;

		while( node )
		{
			for( int i = 0; i < node.getLeafCount(); ++i )
			{
				if( node[i].DType & ( D_VERSION | D_DEBUG ) )
				{
					if( !( node.DType & ( D_VERSION | D_DEBUG ) ) )
						results ~= getMembers( DType, node[i] );
				}
				else if( node[i].DType & D_MIXIN )
				{
					if( !( node.DType & ( D_VERSION | D_DEBUG ) ) )
					{
						if( !bhadScopeMixin ) results ~= getTemplateNodes( node[i] );
					}

					if( node[i].DType & DType ) results ~= node[i];
				}
				else
				{
					if( node[i].DType & DType ) results ~= node[i];
				}
			}
			node = node.getRoot;
			bhadScopeMixin = true;
		}

		return results;
	}
	

	// 取得目前專案中額外引含的模組
	void setAdditionImportModules( CAnalyzerTreeNode singleModule = null )
	{
		int[char[]] 	importedModuleNameArray;
		bool 			bFirstImport = true, bGotNew;

		if( !Globals.parseAllModule && !Globals.parseImported ) return;
		
		char[] projectName = sGUI.packageExp.getActiveProjectName();

		Display display = Display.getDefault();

		if( singleModule is null )
		{
			if( Globals.backLoadParser )
				display.asyncExec( new StringObj( "\nAddition Parser Load......\n" ) , &_message );
			else
				sGUI.outputPanel.appendString( "\nAddition Parser Load......\n" );
		}
		else
		{
			if( Globals.backLoadParser )
				display.asyncExec( new StringObj( "" ) , &_message );
			else
				sGUI.outputPanel.appendLine( "" );
		}

		void _addParser( CAnalyzerTreeNode[] parsers )
		{
			if( !parsers.length ) return;
			
			CAnalyzerTreeNode[] addAnalyzers;
			char[][]			addImportNames;
			
			foreach( CAnalyzerTreeNode parser; parsers )
			{
				CAnalyzerTreeNode[] analyzerTreeNodes;
				
				foreach( CAnalyzerTreeNode t; getAnalyzerAllNode( parser ) )
					if( t.DType & D_IMPORT ) 
					{
						if( bFirstImport )
							analyzerTreeNodes ~= t;
						else
						{
							if( Globals.parseAllModule )
							{
								analyzerTreeNodes ~= t;
							}
							else
							{
								if( t.prot & D_Public ) analyzerTreeNodes ~= t;
							}
						}
					}

				foreach( CAnalyzerTreeNode t; analyzerTreeNodes )
				{
					if( !( t.identifier in importedModuleNameArray ) )
					{
						addImportNames ~= t.identifier;
						importedModuleNameArray[t.identifier] = 1;
					}
				}
			}

			int countAddImportModule = addImportNames.length;
			if( countAddImportModule == 0 ) return;
			int count;

			foreach( char[] moduleName; addImportNames )
			{
				bool 		bGetDefaultparser;
				char[][] 	splitModuleName = std.string.split( moduleName, "." );
				char[] 		anaModuleName, defaultParserName, defaultParserFileName;
				
				if( splitModuleName.length > 1 )
				{
					defaultParserName = Globals.appDir ~ "\\ana\\" ~ splitModuleName[0];
					
					if( std.file.exists( defaultParserName ) )
					{
						defaultParserFileName = defaultParserName ~ "\\" ~ std.string.replace( moduleName, ".", "-" ) ~ ".ana";
						/*
						for( int i = 1; i < splitModuleName.length; ++ i )
							anaModuleName ~= ( "-" ~ splitModuleName[i] );

						anaModuleName = anaModuleName[1..length];
						defaultParserFileName = defaultParserName ~ "\\" ~ anaModuleName ~ ".ana";

						if( !std.file.exists( defaultParserFileName ) )
							defaultParserFileName = defaultParserName ~ "\\" ~ splitModuleName[0] ~ "-" ~ anaModuleName ~ ".ana";
						*/
						
						if( std.file.exists( defaultParserFileName ) )
						{
							bGotNew = true;
							
							try
							{
								CAnalyzerTreeNode defaultParserNode = loadAnalyzerNode( defaultParserFileName );
								char[] mName, fName;
								getModuleNames( defaultParserNode, mName, fName );
								projectParsers[projectName][fName] = defaultParserNode;
								addAnalyzers ~= defaultParserNode;

								if( Globals.backLoadParser )
									display.asyncExec( new StringObj( "Module[ "~ moduleName ~ " ] Loaded And Parsed.\n" ) , &_message );
								else
									sGUI.outputPanel.appendString( "Module[ "~ moduleName ~ " ] Loaded And Parsed.\n" );
									
								bGetDefaultparser = true;
								count ++;
								if( count >= countAddImportModule ) break;
							}
							catch( Exception e )
							{
								if( Globals.backLoadParser )
									display.asyncExec( new StringObj( "      Module[ "~ moduleName ~ " ] Parsed Error.\n" ) , &_message );
								else
									sGUI.outputPanel.appendString( "      Module[ "~ moduleName ~ " ] Parsed Error.\n" );
							}
						}
					}
				}

				if( !bGetDefaultparser )
				{
					foreach( char[] path; sGUI.packageExp.activeProject().projectIncludePaths ~ sGUI.packageExp.activeProject().scINIImportPath )
					{
						char[] name = std.string.replace( moduleName, ".", "\\" );
						name = std.path.join( path, name );// ~".d";
					
						try
						{
							CAnalyzerTreeNode extraParser = CodeAnalyzer.syntax.core.parseFileHSU( name ~ ".di" );
							projectParsers[projectName][name ~ ".di"] = extraParser;
							addAnalyzers ~= extraParser;

							if( Globals.backLoadParser )
								display.asyncExec( new StringObj( "File[ "~ name ~ ".di ] Loaded And Parsed.\n" ) , &_message );
							else
								sGUI.outputPanel.appendString( "File[ "~ name ~ ".di ] Loaded And Parsed.\n" );
								
							count ++;
							bGotNew = true;
							if( count >= countAddImportModule ) break;
						}
						catch( Exception e )
						{
							try
							{
								CAnalyzerTreeNode extraParser = CodeAnalyzer.syntax.core.parseFileHSU( name ~ ".d" );
								projectParsers[projectName][name ~ ".d"] = extraParser;
								addAnalyzers ~= extraParser;

								if( Globals.backLoadParser )
									display.asyncExec( new StringObj( "File[ "~ name ~ ".d ] Loaded And Parsed.\n" ) , &_message );
								else
									sGUI.outputPanel.appendString( "File[ "~ name ~ ".d ] Loaded And Parsed.\n" );
									
								count ++;
								bGotNew = true;
								if( count >= countAddImportModule ) break;
							}
							catch( Exception e )
							{
								if( e.toString != "NoExist" )
								{
									if( Globals.backLoadParser )
										display.asyncExec( new StringObj( "      File[ "~ name ~ " ] Parsed Error.\n" ) , &_message );
									else
										sGUI.outputPanel.appendString( "      File[ "~ name ~ " ] Parsed Error.\n" );

									bGotNew = true;
								}
							}
						}
					}
					
					if( count >= countAddImportModule ) break;
				}
			}

			bFirstImport = false;
			_addParser( addAnalyzers );
		}
		

		CAnalyzerTreeNode[] parserGroup;
		
		foreach( CAnalyzerTreeNode t; projectParsers[projectName] )
		{
			if( t !is null )
			{
				char[] mName, mFullPath;
				getModuleNames( t, mName, mFullPath );			
				importedModuleNameArray[mName] = 1;
				if( singleModule is null ) parserGroup ~= t;
			}
		}

		if( singleModule !is null ) parserGroup ~= singleModule;
		
		_addParser( parserGroup );

		if( singleModule is null )
		{
			if( Globals.backLoadParser )
				display.asyncExec( new StringObj( "All Done.\n" ) , &_message );
			else
				sGUI.outputPanel.appendString( "All Done.\n" );
		}
		else
		{
			if( Globals.backLoadParser && bGotNew )
				display.asyncExec( new StringObj( "\nAddition Parser Load done.\n" ) , &_message );
		}
	}	


	public CAnalyzerTreeNode getModuleNames( CAnalyzerTreeNode node, inout char[] _moduleName, inout char[] _moduleFullPath )
	{
		while( !( node.DType & D_MAINROOT ) )
			node = node.getRoot();

		
		foreach( CAnalyzerTreeNode t; node.getAllLeaf() )
		{
			if( t.DType & D_MODULE )
			{
				_moduleName = t.identifier;
				_moduleFullPath = t.typeIdentifier;
				return node;
			}
		}
		return null;
	}
	

	CAnalyzerTreeNode getImport( char[] word, int DType, CAnalyzerTreeNode activeTreeNode, out CAnalyzerTreeNode[] importedModules, bool bGetModules = false )
	{
		bool 				bInRootModule = true;
		int[char[]]			importedModuleNameArray;
		CAnalyzerTreeNode[]	importModules;
		//char[][] 			modulesName;
		CAnalyzerTreeNode	ret;
		CAnalyzerTreeNode	activeParser;


		char[] projectName = sGUI.packageExp.getActiveProjectName();


		char[] mName, mFullPath;

		if( activeTreeNode ) 
			activeParser = getModuleNames( activeTreeNode, mName, mFullPath );
		else
			activeParser = fileParser;
		
		if( !activeParser || !word.length ) return null;

		importedModuleNameArray[mName] = 1;

		// Nested Function
		bool _inProjectParser( char[] m )
		{
			foreach( CAnalyzerTreeNode[char[]] t; defaultParsers )
				if( m in t ) return true;
			
			foreach( CAnalyzerTreeNode t; projectParsers[projectName] )
			{
				if( t !is null )
				{
					char[] name, fullPath;

					getModuleNames( t, name, fullPath );
					if( name == m ) return true;
				}
			}

			return false;
		}

		CAnalyzerTreeNode _getProjectParserByModuleName( char[] m )
		{
			foreach( CAnalyzerTreeNode[char[]] t; defaultParsers )
				if( m in t ) return t[m];			
			//if( m in defaultParsers["std"] ) return defaultParsers["std"][m];

			foreach( CAnalyzerTreeNode t; projectParsers[projectName] )
			{
				if( t !is null )
				{
					char[] name, fullPath;

					getModuleNames( t, name, fullPath );
					if( name == m ) return projectParsers[projectName][fullPath];
				}
			}

			return null;
		}

		
		// Nested Function
		void _lookingFormHead( CAnalyzerTreeNode treeNode )
		{
			if( ret ) return;

			while( !( treeNode.DType & D_MAINROOT ) ) treeNode = treeNode.getRoot();

			foreach( CAnalyzerTreeNode t; getMembers( DType, treeNode ) )
			{
				if( !( t.prot & ( D_Private | D_Protected ) ) )
				{
					if( t.identifier == word ) 
					{
						ret = t;
						return;
					}
				}
			}
			/*
			foreach( CAnalyzerTreeNode t; treeNode.getAllLeaf() )
			{
				if( !( t.prot & ( D_Private | D_Protected ) ) )
				{
					if( t.DType & DType  )
					{
						if( t.identifier == word ) 
						{
							ret = t;
							return;
						}
					}
				}
			}
			*/
		}
		
		void _findImport( CAnalyzerTreeNode analyzer )
		{
			char[][] insidemodulesName;

			if( analyzer )
			{
				if( bInRootModule ) // 第一次找尋import
				{
					CAnalyzerTreeNode[] importFirst = getAnalyzerAllNodeR( activeTreeNode, D_IMPORT, true );
					
					foreach( CAnalyzerTreeNode t; importFirst )
					{
						if( !( t.identifier in importedModuleNameArray ) )
						{
							if( _inProjectParser( t.identifier ) )
							{
								insidemodulesName ~= t.identifier;
								importedModuleNameArray[t.identifier] = 1;
							}
						}
					}						
				}
				else
				{
					foreach( CAnalyzerTreeNode t; getMembers( D_IMPORT, analyzer ) )//analyzer.getAllLeaf() )
					{
						if( !( t.identifier in importedModuleNameArray ) )
						{
							if( t.prot & D_Public )
							{
								if( _inProjectParser( t.identifier ) )
								{									
									insidemodulesName ~= t.identifier;
									importedModuleNameArray[t.identifier] = 1;
								}
							}
						}
					}					
				}
			}else
				return;

			bInRootModule = false;
			if( insidemodulesName.length )
			{
				//modulesName.length = 0;
				//modulesName ~= insidemodulesName;
				foreach( char[]	s; insidemodulesName )
				{
					CAnalyzerTreeNode a = _getProjectParserByModuleName( s );
					if( a ) 
					{
						importModules ~= a;
						_findImport( a );
					}
				}
			}
		}
	
		_findImport( activeParser );

		if( bGetModules )
		{
			importedModules = importModules;
			return null;
		}

		importedModules = importModules;

		foreach( CAnalyzerTreeNode a; importModules )
		{
			/*
			char[] name, fullPath;
			getModuleNames( a, name, fullPath );	
			sGUI.outputPanel.appendString( "modules.name = " ~ name ~ "\n" );
			*/
			_lookingFormHead( a );
			if( ret ) break;
		}

		return ret;
	}

	public int checkDeprecated()
	{ 
		if( sGUI.packageExp.activeProject.getDeprecated() )	return 0;

		return D_Deprecated;
	}

	public bool checkCondition( CAnalyzerTreeNode node, CAnalyzerTreeNode prevNode, char[][] prjVersions, char[][] prjDebugs )
	{
		if( node is null ) return false;

		if( !prjVersions.length )
			prjVersions = sGUI.packageExp.activeProject.getVersionCondition();
		
		if( !prjDebugs.length )
			prjDebugs = sGUI.packageExp.activeProject.getDebugCondition();


		bool _checkExist( CAnalyzerTreeNode _node, CAnalyzerTreeNode _prevNode )
		{
			if( _node.DType & D_VERSION )
			{
				bool		bMatch, bElseVersion;
				char[]		versionName;

				if( _node.identifier == "-else-" )
				{
					if( _prevNode is null ) return false;
					
					versionName = _prevNode.identifier;
					bElseVersion = true;
				}
				else
					versionName = _node.identifier;

				bMatch = MiscUtil.inArray( versionName, prjVersions );

				if( !bElseVersion && bMatch )
				{
					return true;
				}
				else if( bElseVersion && !bMatch )
				{
					return true;
				}
			}
			else if( _node.DType & D_DEBUG )
			{
				bool		bMatch, bElseDebug;
				char[]		debugName;

				if( _node.identifier == "-else-" )
				{
					if( _prevNode is null ) return false;
					
					debugName = _prevNode.identifier;
					bElseDebug = true;
				}
				else
					debugName = _node.identifier;

				bMatch = MiscUtil.inArray( debugName, prjDebugs );
				
				if( !bMatch )
				{
					if( debugName == "-anonymous-" )
					{
						foreach( char[] s; prjDebugs )
						{
							if( s.length == 1 )  // judge if prjDebugs incluse -debug=0
								if( s[0] == 48 )
								{
									bMatch = true;
									break;
								}
								
							if( std.string.atoi( s ) > 0 ) // can't not judge -debug=0
							{
								bMatch = true;
								break;
							}
						}
					}
					else
					{
						int debugNameLevel = std.string.atoi( debugName );
						if( debugNameLevel == 0 ) debugNameLevel = -2147483640;
						
						if( debugName.length == 1 )
							if( debugName[0] == 48 )
								debugNameLevel = 0;
						
						
						if( debugNameLevel >= 0 ) // debugName is debug=level
						{
							foreach( char[] s; prjDebugs )
							{
								// judge if prjDebug is debug = level
								int projectLevel = std.string.atoi( s );
								if( projectLevel == 0 ) projectLevel = -2147483640;
								
								if( s.length == 1 )
									if( s[0] == 48 ) projectLevel = 0;
									
								
								if( debugNameLevel <= projectLevel )
								{
									bMatch = true;
									break;
								}
							}
						}
					}

					/+
					// HEAVY slow down the speed( maybe try~catch ), I have no idea how to increase it!!
						just only use above code
					
					try
					{
						int debugNameLevel = std.conv.toInt( debugName );
						foreach( char[] s; prjDebugs )
						{
							try
							{
								int projectLevel = std.conv.toInt( s );
								if( debugNameLevel <= projectLevel )
								{
									bMatch = true;
									break;
								}
							}
							catch
							{ // s is not debug=level
							}
						}
					}
					catch
					{ 
						// debugName is not debug=level
						// maybe debugName = -anonymous-
						if( debugName == "-anonymous-" )
						{
							foreach( char[] s; prjDebugs )
							{
								try
								{
									std.conv.toInt( s ); // if no exception occur, prjDebugs include debug=level
									bMatch = true;
									break;
								}
								catch
								{ // s is not debug=level
								}
							}
						}
					}
					+/
				}
					
				if( !bElseDebug && bMatch )
				{
					return true;
				}
				else if( bElseDebug && !bMatch )
				{
					return true;
				}
			}

			return false;
		}

		void _updateConditionalSpec( CAnalyzerTreeNode _node )
		{
			// find D_CONDITIONSPEC
			for( int i = 0; i < _node.getLeafCount; ++ i )
			{
				if( _node[i].DType & D_CONDITIONSPEC )
				{
					if( _node[i].typeIdentifier == "version" )
						prjVersions ~= _node[i].identifier;
					else
						prjDebugs ~= _node[i].identifier;
				}
				else if( _node[i].DType & ( D_VERSION | D_DEBUG ) )
				{
					if( _checkExist( _node[i], ( i > 0 ? _node[i-1] : null ) ) )
					{
						_updateConditionalSpec( _node[i] );
					}
				}
			}
		}

		// get D_MAINROOT
		CAnalyzerTreeNode head = node;
		
		while( !( head.DType & D_MAINROOT ) )
			head = head.getRoot();


		_updateConditionalSpec( head );
		return _checkExist( node, prevNode );
	}

    public CAnalyzerTreeNode[] rootSearch( char[] root, CAnalyzerTreeNode[] allListings, int DType = D_ALL )
	{
		bool dcharSliceMatch( char[] one, char[] two )
		{
			dchar[] dOne = std.utf.toUTF32( one );
			dchar[] dTwo;

			if( Globals.parserCaseSensitive )
				dTwo = std.utf.toUTF32( two );
			else
				dTwo = std.utf.toUTF32( std.string.tolower( two ) );

			if( dOne  == dTwo[0..dOne.length] )  return true;

			return false;
		}

		
		CAnalyzerTreeNode[] matches;
		if( !Globals.parserCaseSensitive ) root = std.string.tolower( root );
			
		//DType = DType - D_IMPORT;
		foreach( CAnalyzerTreeNode t; allListings )
		{
			
			if( t.DType & ( D_IMPORT | D_MIXIN ) )
			{
				if( t.typeIdentifier.length )
				{
					if( t.typeIdentifier.length >= root.length )
					{
						if( dcharSliceMatch( root, t.typeIdentifier ) ) matches ~= t;
						/*
						if( Globals.parserCaseSensitive )
						{
							if( root == t.typeIdentifier[0..root.length] ) matches ~= t;
						}
						else
						{
							if( root == std.string.tolower( t.typeIdentifier[0..root.length] ) ) matches ~= t;
						}
						*/
					}

					continue;
				}
			}
			else if( t.DType & D_ENUM )
			{
				if( t.identifier == "-anonymous-" )
				{
					matches ~= rootSearch( root, t.getAllLeaf, D_ENUMMEMBER );
					continue;
				}
			}
			

			if( t.DType & DType )
				if( t.identifier.length )
					if( t.identifier.length >= root.length )
					{
						if( dcharSliceMatch( root, t.identifier ) ) matches ~= t;
						/*
						if( Globals.parserCaseSensitive )
						{
							if( root == t.identifier[0..root.length] ) matches ~= t;
						}
						else
						{
							if( root == std.string.tolower( t.identifier[0..root.length] ) ) matches ~= t;
						}
						*/
					}
		}

		return matches;
    }

	bool isSameRoot( CAnalyzerTreeNode a, CAnalyzerTreeNode b )
	{
		while( !( a.DType & D_MAINROOT ) )
			a = a.getRoot();

		while( !( b.DType & D_MAINROOT ) )
			b = b.getRoot();

		if( a == b ) return true;


		return false;
	}	
}