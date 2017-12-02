/*
These are modified by Kuan Hsu, just for Poseidon use!!
Thank for hasan's wonderful code analysis!!

In this version, I cancel D_GLOBALVAR, D_METHOD, D_MEMBER, D_PRAGMA, 

*/
module CodeAnalyzer.syntax.nodeHsu;

private
{
	import std.stream;
	import poseidon.util.fileutil;
	import std.conv;
}

const int D_CLASS = 2;				//*
const int D_STRUCT = 4;				//*
const int D_ENUM = 8;				//*
const int D_ENUMMEMBER = 16;		//*
const int D_ALIAS = 32;				//*
const int D_TYPEDEF = 64;			//*
const int D_CONDITIONSPEC = 128;	//*
const int D_FUNLITERALS = 256;		//*
const int D_UNITTEST = 512;
const int D_VARIABLE = 1024;		//*
const int D_ANONYMOUSBLOCK = 2048;	//*
const int D_UNION = 4096;			//*
const int D_INTERFACE = 8192;		//*
const int D_INVARIANT = 16384;
const int D_VERSION = 32768;		//*
const int D_DEBUG = 65536;			//*
const int D_PARAMETER = 131072;		//*
const int D_PRAGMA = 262144;
const int D_CTOR = 524288;			//*
const int D_DTOR = 1048576;			//*
const int D_STATICCTOR = 2097152;
const int D_STATICDTOR = 4194304;
const int D_FUNCTION = 8388608;		//*
const int D_TEMPLATE = 16777216;	//*
const int D_IMPORT = 33554432;		//*
const int D_MIXIN = 67108864;		//*    
const int D_UNKNOWN = 134217728;	//*
const int D_MODULE = 268435456;		//*
const int D_MAINROOT = 536870912;	//*
const int D_BLOCK	 = 1073741824;	//* 2^30


const int D_Public 		= 2;		//*
const int D_Private 	= 4;		//*
const int D_Protected 	= 8;		//*
const int D_Export 		= 16;		//*
const int D_Package 	= 32;		//*
const int D_Deprecated 	= 64;		//*
const int D_Override 	= 128;		//*
const int D_Abstract 	= 256;
const int D_Const 		= 512;		//*
const int D_Auto 		= 1024;		//*
const int D_Static		= 2048;		//*
const int D_Final 		= 4096;		//*
const int D_Align 		= 8192;
const int D_Extern 		= 16384;	//*
const int D_Pragma 		= 32768;	//*
const int D_Scope		= 65536;	//*
const int D_Invariant	= 131072;	//*
const int D_Pure		= 262144;	//*
const int D_Nothrow		= 524288;	//*
const int D_Ref			= 1048576;	//*
const int D_Immutable	= 2097152;	//*
const int D_Gshared		= 4194304;	//*
const int D_Shared		= 8388608;	//*


const int D_ALL = 0  | D_CLASS | D_STRUCT | D_ENUM | D_ENUMMEMBER | D_ALIAS | D_TYPEDEF | D_CONDITIONSPEC | D_FUNLITERALS | 
		  D_UNITTEST | D_VARIABLE | D_ANONYMOUSBLOCK | D_UNION | D_INTERFACE | D_INVARIANT | D_VERSION | D_DEBUG |
		  D_PARAMETER | D_PRAGMA | D_CTOR | D_DTOR | D_STATICCTOR | D_STATICDTOR | D_FUNCTION | D_TEMPLATE |
		  D_IMPORT | D_MIXIN | D_UNKNOWN | D_MODULE | D_MAINROOT | D_BLOCK;
const int D_UDTS = D_CLASS | D_STRUCT | D_ENUM | D_INTERFACE | D_UNION | D_TEMPLATE ;

const int D_Attribute = D_Public | D_Private | D_Protected | D_Export | D_Package | D_Deprecated | D_Override |
		  D_Abstract | D_Const | D_Auto | D_Static | D_Final | D_Align | D_Extern | D_Pragma;
const int D_Prot = D_Public | D_Private | D_Protected | D_Export | D_Package;
const int D_Storage = D_Deprecated | D_Override | D_Abstract | D_Const | D_Auto | D_Static | D_Final | D_Scope | D_Shared | D_Gshared | D_Extern | D_Pure | D_Nothrow | D_Invariant;

char[] dTypeToChars( int t )
{
	switch ( t )
	{
		case D_CLASS : return "D_CLASS";
		case D_STRUCT : return "D_STRUCT";
		case D_ENUM : return "D_ENUM";
		case D_ENUMMEMBER : return "D_ENUMMEMBER";
		case D_ALIAS : return "D_ALIAS";
		case D_TYPEDEF : return "D_TYPEDEF";
		case D_CONDITIONSPEC : return "D_CONDITIONSPEC";
		case D_FUNLITERALS : return "D_FUNLITERALS";
		case D_UNITTEST : return "D_UNITTEST";
		case D_VARIABLE : return "D_VARIABLE";
		case D_ANONYMOUSBLOCK : return "D_ANONYMOUSBLOCK";
		case D_UNION : return "D_UNION";
		case D_INTERFACE : return "D_INTERFACE";
		case D_INVARIANT : return "D_INVARIANT";
		case D_VERSION : return "D_VERSION";
		case D_DEBUG : return "D_DEBUG";
		case D_PARAMETER : return "D_PARAMETER";
		case D_PRAGMA : return "D_PRAGMA";
		case D_CTOR : return "D_CTOR";
		case D_DTOR : return "D_DTOR";
		case D_STATICCTOR : return "D_STATICCTOR";
		case D_STATICDTOR : return "D_STATICDTOR";
		case D_FUNCTION : return "D_FUNCTION";
		case D_TEMPLATE : return "D_TEMPLATE";
		case D_IMPORT : return "D_IMPORT";
		case D_MIXIN : return "D_MIXIN";
		case D_UNKNOWN : return "D_UNKNOWN";
		case D_MODULE : return "D_MODULE";		
		case D_MAINROOT : return "D_MAINROOT";
		case D_BLOCK : return "D_BLOCK";
		default: return "ERROR";
		
	}
	
	return "not found"; 
}


char[] dAttributeToChars( int t )
{
	char[] result;
	
	if( t & D_Public )		result ~= "public ";
	if( t & D_Private )		result ~= "private ";
	if( t & D_Protected )	result ~= "protected ";
	if( t & D_Export )	result ~= "export ";
	if( t & D_Package )	result ~= "package ";
	if( t & D_Deprecated )	result ~= "deprecated ";
	if( t & D_Override )	result ~= "override ";
	if( t & D_Abstract )	result ~= "abstract ";
	if( t & D_Const )	result ~= "const ";
	if( t & D_Auto )	result ~= "auto ";
	if( t & D_Scope )	result ~= "scope ";

	if( t & D_Static )	result ~= "static ";
	if( t & D_Final )	result ~= "final ";
	if( t & D_Align )	result ~= "align ";
	if( t & D_Extern )	result ~= "extern ";
	if( t & D_Pragma )	result ~= "pragma ";

	return result;
}


// global variables
CAnalyzerTreeNode 	DMainSymbolNode, activeNode;
char[]				tokenText, globalIdentifier, globalTypeIdentifier, globalParams, globalBaseClass;
int					globalDType, globalProt;
bool				bAttributeDeclarationColon, bTemplateParameterList, bFunctionTemplate;
int					compilerVersion = 1;

class CAnalyzerTreeNode
{
private:
	CAnalyzerTreeNode 	father;
	CAnalyzerTreeNode[] children;

public:	
	//char[]	attribute;
	int			prot;
	int			DType;
    char[] 		identifier;
    char[] 		typeIdentifier;
    char[] 		parameterString;
	char[]		baseClass;

    int 		lineNumber;


	CAnalyzerTreeNode opIndex( int i ){ if( i < children.length && i > -1 ) return children[i]; }

	this( int Prot = 0, int D_type = D_UNKNOWN, char[] Identifier = null, 
		char[] TypeIdentifier = null, uint LineNumber = 0, char[] ParameterString = null, char[] BaseClass = null )
	{
		prot				= Prot;
		DType				= D_type;
		identifier			= Identifier;
		typeIdentifier		= TypeIdentifier;
		parameterString		= ParameterString;
		lineNumber			= LineNumber;
		baseClass			= BaseClass;
	}

	~this()
	{ 
		if( children.length > 0 )
		{
			for( int i = 0; i < children.length; ++ i )
				delete children[i];
		}
	
		children.length = 0;
	}

	CAnalyzerTreeNode addLeaf( int Prot = 0, int D_type = D_UNKNOWN, char[] Identifier = null, 
							   char[] TypeIdentifier = null, uint LineNumber = 0, 
							   char[] ParameterString = null, char[] BaseClass = null )
	{
		CAnalyzerTreeNode leaf 	= new CAnalyzerTreeNode;
		leaf.father				= this;
		//leaf.attribute		= attribute;
		leaf.prot				= Prot;
		leaf.DType				= D_type;
		leaf.identifier			= Identifier;
		leaf.typeIdentifier		= TypeIdentifier;
		leaf.parameterString	= ParameterString;
		leaf.lineNumber			= LineNumber;
		leaf.baseClass			= BaseClass;

		children ~= leaf;
		
		return leaf;
	}

	void insertLeaf( CAnalyzerTreeNode node, int index )
	{
		int lengthLeafs = children.length;
		
		if( lengthLeafs == 0 || index >= lengthLeafs ) 
		{
			children ~= node;
			return;
		}
		
		CAnalyzerTreeNode[] tempChildren;

		if( index < 0 ) index = 0;
		if( index > 0 ) tempChildren ~= children[0..index];
			
		tempChildren ~= node;
		tempChildren ~= children[index..length];

		children = tempChildren;
	}


	CAnalyzerTreeNode getLeaf( int index )
	{
		if( !children.length ) return null;
		if( index >= children.length || index < 0 ) return null;
		return children[index];
	}


	CAnalyzerTreeNode dup()
	{
		CAnalyzerTreeNode ret = new CAnalyzerTreeNode( prot, DType, identifier, typeIdentifier, lineNumber, 
								parameterString, baseClass );

		ret.father = this.father;
		

		CAnalyzerTreeNode activeTreeNode = ret;

		void _dupTreeNode( CAnalyzerTreeNode treeNode )
		{
			foreach( CAnalyzerTreeNode t; treeNode.getAllLeaf() )
			{
				activeTreeNode.addLeaf( t.prot, t.DType, t.identifier, t.typeIdentifier, t.lineNumber,
										t.parameterString, t.baseClass );

				activeTreeNode = activeTreeNode.getLeaf( activeTreeNode.children.length - 1 );
				_dupTreeNode( t );
				activeTreeNode = activeTreeNode.father;
			}
		}
		
		_dupTreeNode( this );

		return ret;
	}

	
	uint getLeafCount(){ return children.length; }
	
	CAnalyzerTreeNode getRoot(){ return father; }
	
	CAnalyzerTreeNode[] getAllLeaf(){ return children; }

	void passChildren( CAnalyzerTreeNode[] leafs ){ children = leafs; }

	/*
	int indexOf()
	{
		CAnalyzerTreeNode root = this.getRoot();
		if( root !is null )
		{
			for( int i = 0; i < root.getLeafCount(); ++ i )
			{
				if( root[i] == this ) return i;
			}
		}

		return -1;
	}
	*/

	CAnalyzerTreeNode prev( int index = 1 )
	{
		CAnalyzerTreeNode root = this.getRoot();
		if( root !is null )
		{
			bool bFound;
			int i;
			for( i = 0; i < root.getLeafCount(); ++ i )
			{
				if( root.getLeaf( i ) == this )
				{
					bFound = true;
					break;
				}
			}

			if( bFound ) return root.getLeaf( i-index );
		}

		return null;
	}

	/+
	CAnalyzerTreeNode next( int index = 1 )
	{
		CAnalyzerTreeNode root = this.getRoot();
		if( root !is null )
		{
			bool bFound;
			int i;
			for( i = 0; i < root.getLeafCount(); ++ i )
			{
				if( root[i] == this )
				{
					bFound = true;
					break;
				}
			}

			if( bFound ) return root[i+index];
		}

		return null;
	}
	+/
}


char[] savenalyzerNode( char[] dirName, CAnalyzerTreeNode headNode, char[] oriFilePath = null )
{
	//auto file = new BufferedFile( std.path.getName( fileName ) ~ ".ana", FileMode.OutNew );

	char[] 	fileText;
	char[]	saveFileName;
	int 	D_skip;

	if( dirName.length )
		D_skip = D_FUNCTION | D_STATICCTOR | D_STATICDTOR | D_CTOR | D_DTOR | D_DEBUG | D_UNITTEST;
	else
		D_skip = D_UNITTEST;

	void _addNode( CAnalyzerTreeNode node )
	{
		if( !( node.DType & D_skip ) )
		{
			foreach( CAnalyzerTreeNode t; node.getAllLeaf() )
			{
				if( !( t.DType & D_UNITTEST ) )
				{
					if( t.DType & D_MODULE )
					{
						if( dirName.length )
						{
							fileText ~= ( std.string.toString( t.DType ) ~ "#" ~ std.string.toString( t.prot ) ~ "#" ~ t.identifier ~ "#" ~
										"<ana>" ~ ( oriFilePath.length ? oriFilePath : t.identifier )
										~ "#" ~ std.string.toString( t.lineNumber ) ~ "#" ~ t.parameterString ~ "#" ~
										t.baseClass ~ "\n" );
							saveFileName = dirName ~ "\\" ~ std.string.replace( t.identifier, ".", "-" ) ~ ".ana";
						}
						else
							fileText ~= ( std.string.toString( t.DType ) ~ "#" ~ std.string.toString( t.prot ) ~ "#" ~ t.identifier ~ "#" ~
										t.typeIdentifier ~ "#" ~ std.string.toString( t.lineNumber ) ~ "#" ~ t.parameterString ~ "#" ~
										t.baseClass ~ "\n" );
					}
					else
					{
						fileText ~= ( std.string.toString( t.DType ) ~ "#" ~ std.string.toString( t.prot ) ~ "#" ~ t.identifier ~ "#" ~
										t.typeIdentifier ~ "#" ~ std.string.toString( t.lineNumber ) ~ "#" ~ t.parameterString ~ "#" ~
										t.baseClass ~ "\n" );
					}
					/+
					file.writef( "%s", std.string.toString( t.DType ) ~ "#" );
					file.writef( "%s", std.string.toString( t.prot ) ~ "#" );
					file.writef( "%s", t.identifier ~ "#" );
					file.writef( "%s", t.typeIdentifier ~ "#" );
					file.writef( "%s", std.string.toString( t.lineNumber ) ~ "#" );
					file.writef( "%s", t.parameterString ~ "#" );
					file.writefln( "%s", t.baseClass );
					+/
					_addNode( t );
					fileText ~= "/\n";
					//file.writefln( "/" );
				}
			}
		}
	}

	fileText ~= ( std.string.toString( D_MAINROOT ) ~ "\n" );
	//file.writefln( std.string.toString( D_MAINROOT ) );

	_addNode( headNode );

	fileText ~= ("/\n" );

	if( dirName.length )
	{
		try
		{
			FileSaver.save( saveFileName, fileText );
		}
		catch( Exception e )
		{
			throw ( e );
		}
	}

	return fileText;
	
	//file.writefln( "/" );
	//file.close();
}


CAnalyzerTreeNode loadAnalyzerNode( char[] fileName )
{
	scope file = new File( std.path.getName( fileName ) ~ ".ana", FileMode.In );
	file.readLine();

	CAnalyzerTreeNode root = new CAnalyzerTreeNode;
	root.DType = D_MAINROOT;		
	CAnalyzerTreeNode activeNode = root;

	void _addNode()
	{
		char[] lineText = file.readLine();

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
			}
			else
			{
				throw new Exception( lineText );
			}
		}
	}

	while( !file.eof )
	{
		_addNode();
	}
			
	file.close();

	return root;
}

void clean()
{
	tokenText = globalIdentifier = globalTypeIdentifier = globalParams = globalBaseClass = null;
	globalDType = globalProt = 0;
	bAttributeDeclarationColon = bTemplateParameterList = bFunctionTemplate = false;
}