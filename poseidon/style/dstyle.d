module poseidon.style.dstyle;

private import poseidon.style.stylekeeper;

class DStyle : AbstractStyleKeeper
{
	private import std.utf;
	private import poseidon.globals;
	private import dwt.extra.scintilla;
	private import poseidon.controller.scintillaex;
	private import poseidon.controller.gui;
	private import CodeAnalyzer.syntax.nodeHsu;
	private import poseidon.intellisense.search;
	private import poseidon.util.miscutil;
	private import std.string, std.thread;
	private import poseidon.controller.ddoc.ddocparser;
	private import CodeAnalyzer.utilCA.nodeUtil;
	/+
	enum
	{
		SCE_D_DEFAULT = 0,
		SCE_D_COMMENT = 1,
		SCE_D_COMMENTLINE = 2,
		SCE_D_COMMENTDOC = 3,
		SCE_D_COMMENTNESTED = 4,
		SCE_D_NUMBER = 5,
		SCE_D_WORD = 6,
		SCE_D_WORD2 = 7,
		SCE_D_WORD3 = 8,
		SCE_D_TYPEDEF = 9,
		SCE_D_STRING = 10,
		SCE_D_STRINGEOL = 11,
		SCE_D_CHARACTER = 12,
		SCE_D_OPERATOR = 13,
		SCE_D_IDENTIFIER = 14,
		SCE_D_COMMENTLINEDOC = 15,
		SCE_D_COMMENTDOCKEYWORD = 16,
		SCE_D_COMMENTDOCKEYWORDERROR = 17,
	}
	+/
	enum 
	{
		SCE_D_DEFAULT = 0
		,SCE_D_COMMENT = 1
		,SCE_D_COMMENTLINE = 2
		,SCE_D_COMMENTDOC = 3
		,SCE_D_NUMBER = 4
		,SCE_D_WORD = 5
		,SCE_D_STRING = 6
		,SCE_D_CHARACTER = 7
		,SCE_D_UUID = 8
		,SCE_D_PREPROCESSOR = 9
		,SCE_D_OPERATOR = 10
		,SCE_D_IDENTIFIER = 11
		,SCE_D_STRINGEOL = 12
		,SCE_D_VERBATIM = 13
		,SCE_D_REGEX = 14
		,SCE_D_COMMENTLINEDOC = 15
		,SCE_D_WORD2 = 16
		,SCE_D_VERBATIMTICK = 17
		,SCE_D_COMMENTDOCKEYWORDERROR = 18
		,SCE_D_GLOBALCLASS = 19
		,SCE_D_WORD3 = 20
		,SCE_D_WORD4 = 21
		,SCE_D_WORD5 = 22
		,SCE_D_WORD6 = 23
		,SCE_D_WORD7 = 24
		,SCE_D_WORD8 = 25
		,SCE_D_WORD9 = 26
		,SCE_D_NESTCOMMENT = 27
		,SCE_D_NESTCOMMENT1 = 28
		,SCE_D_NESTCOMMENT2 = 29
		,SCE_D_NESTCOMMENT3 = 30
		,SCE_D_NESTCOMMENT4 = 31
	}

	const int SCLEX_D = 76;
	//const int SCLEX_D = 79;
	
	// the default key words
	const static char[][] sKeyWords = 
	["void bit byte ubyte short ushort int uint long ulong cent ucent float double real ifloat idouble ireal cfloat cdouble creal char wchar dchar body asm bool true false function delegate"
	, "public private protected with extern"
	, "final abstract override const debug version pragma public private deprecated protected volatile"
	, "class struct interface enum new this mixin null delete invariant super union"
	, "if for foreach while do assert return unittest try catch else throw switch case break continue default finally goto synchronized"
	, "is import module alias typedef with cast package typeof typeid"
	, "in out const static inout ref lazy extern export auto align scope"
	];

	private const char[][] IntegralList = [ "alignof", "init", "max", "min", "sizeof" ];
	private const char[][] FloatList = [ "alignof", "dig", "epsilon", "infinity", "init", "min", "min_10_exp", "min_exp", "mant_dig", "max", "max_10_exp", "max_exp", "nan", "sizeof" ];
	private const char[][] ArrayList = [ "dup", "length", "ptr", "reverse", "sizeof", "sort" ];

	private CAnalyzerTreeNode originalFunctionNode;

	private char[][char[]] 		templateParams;

	const char[] LEXER_NAME = "SCLEX_D";
	char[] getLexerName() { return LEXER_NAME;}
	int getLexerID() { return SCLEX_D; }
	
	char[][] getKeyWords()
	{
		if(keyWords is null)
			keyWords = sKeyWords.dup;
		return keyWords; 
	}

	void applySettings(ScintillaEx sc) 
	{
		// check whether keywords and styles loaded successfully,
		// make sure styles is not null
		getStyles();
		getKeyWords();
		
		super.applySettings(sc);
		
		// do extra d settings here

		// !!! notify handle should only install once
		Object obj = sc.getData("Handler-set");
		if(obj is null) 
		{
			sc.setData("handler-set", "true");
			sc.handleNotify(sc, Scintilla.SCN_UPDATEUI, &onUpdateUI);
			sc.handleNotify(sc, Scintilla.SCN_AUTOCSELECTION, &onAutoCSelection);
			sc.handleNotify(sc, Scintilla.SCN_CHARADDED, &onCharAdded);
			//sc.handleNotify( sc, Scintilla.SCN_MODIFIED, &onModified );
			
		}
	}

	void resetKeyWords()
	{
		keyWords = sKeyWords.dup;
	}

	void onModified( SCNotifyEvent e ) 
	{
		if( !Globals.useCodeCompletion || !sAutoComplete.fileParser ) return;
		
		ScintillaEx sc = cast(ScintillaEx) e.cData;

		if( sc.canUndo() ) // When First open the file, the e.linesAdded is line number of the file
		{
			if( e.linesAdded > 0 )
			{
				int currentLine = sc.lineFromPosition( e.position ) + 1;
				fixLineNumber( sAutoComplete.fileParser, currentLine, e.linesAdded );
				// sGUI.outputPanel.appendLine( "Add = " ~ std.string.toString( e.linesAdded ) ~ "\nCurrentLine = " ~ std.string.toString( currentLine ) );
			}
		}
		
		if( e.linesAdded < 0 )
		{
			int currentLine = sc.lineFromPosition( e.position ) + 1;
			fixLineNumber( sAutoComplete.fileParser, currentLine, e.linesAdded );
			// sGUI.outputPanel.appendLine( "Add = " ~ std.string.toString( e.linesAdded ) ~ "\nCurrentLine = " ~ std.string.toString( currentLine ) );
		}
	}
	
	void onUpdateUI( SCNotifyEvent event )
	{
		Scintilla sc = cast(Scintilla) event.cData;
		
		if ( sc.getStyleAt( sc.getCurrentPos() ) == SCE_D_STRING || sc.getStyleAt( sc.getCurrentPos() ) == SCE_D_STRINGEOL )
		{} 
		else performWordHover( sc );
	}

	// 加入mruParser
	private void onAutoCSelection( SCNotifyEvent e )
	{
		if( Globals.showType )
		{
			ScintillaEx sc = cast(ScintillaEx) e.cData;

			if( sc )
			{
				sc.autoCCancel();
				int posColon = std.string.rfind( e.text, "::" );
				if( posColon > 0 ) e.text = std.string.strip( e.text[0..posColon] );

				sc.setAnchor( e.lParam );
				sc.replaceSel( e.text );
			}
		}
		
		
		/*
		Scintilla sc = cast(Scintilla) e.cData;

		CAnalyzerTreeNode[] treeNodes = sAutoComplete.search( e.text );
		
		if( treeNodes.length ) 
		{
			foreach( CAnalyzerTreeNode t; treeNodes )
			{
				if( t.identifier == e.text )
				{
					sAutoComplete.mruParser.addItem( e.text.dup );
					break;
				}
			}
		}*/
	}

	// 鍵入字的時候
	private void onCharAdded( SCNotifyEvent e ) 
	{
		if( !Globals.useCodeCompletion || !Globals.showAutomatically || !sAutoComplete.fileParser ) return;
		
		ScintillaEx sc = cast(ScintillaEx) e.cData;
		int ch = e.ch;

		try
		{
			if( ch == '.' ) 
			{
				sc.autoCCancel();
				//performDotCompletionAndFunctionToolTip( sc, false );
			}
			else if( ch == '(' )
			{
				performDotCompletionAndFunctionToolTip( sc, true );
			}
			else if( ch == ' ')
			{
				char[] word = readCurrentWord( sc, true );
				if( word == "import" ) performImportStart( sc );

				return;
			}
			else
			{
				if( Globals.updateParseLiveFull )
				{
					if( ch != 13 && ch !='\n' ) addAnalyzerNodeLive( sc );
				}
				else if( Globals.updateParseLive )
				{
					addAnalyzerNodeLive( sc );
				}
			}

			if( sc.autoCActive() ) return;
			performDotCompletionAndFunctionToolTip( sc, false );
			//performAutoComplete( sc );
		}
		catch( Exception e )
		{
			if( !sc ) 
				MessageBox.showMessage( "ScintillaEx Error!!" );
			else
				MessageBox.showMessage( e.toString );
		}
	}


	public void forceComplete( ScintillaEx sc )
	{
		if( sc is null ) return;

		int 	pos = sc.getCurrentPos() - 1;
		int 	ch = sc.getCharAt( pos );

		try
		{
			if( ch == '.' ) 
			{
				sc.autoCCancel();
				//performDotCompletionAndFunctionToolTip( sc, false );
			}
			else if( ch == '(' )
			{
				performDotCompletionAndFunctionToolTip( sc, true, true );
			}
			else if( ch == ' ')
			{
				char[] word = readCurrentWord( sc, true );
				if( word == "import" ) performImportStart( sc );

				return;
			}
			else
			{
				if( Globals.updateParseLiveFull )
				{
					if( ch != 13 && ch !='\n' ) addAnalyzerNodeLive( sc );
				}
				else if( Globals.updateParseLive )
				{
					addAnalyzerNodeLive( sc );
				}
			}

			if( sc.autoCActive() ) return;
			performDotCompletionAndFunctionToolTip( sc, false, true );
			//performAutoComplete( sc );
		}
		catch( Exception e )
		{
			if( !sc ) 
				MessageBox.showMessage( "forceComplete Error!!" );
			else
				MessageBox.showMessage( e.toString );
		}
	}


	private char[] getWithName( CAnalyzerTreeNode functionHeadNode )
	{
		if( functionHeadNode !is null )
			if( functionHeadNode.DType & D_BLOCK )
				if( functionHeadNode.baseClass == "with" )
				{
					if( functionHeadNode.typeIdentifier.length )
						return functionHeadNode.typeIdentifier;
					else
						return functionHeadNode.identifier;
				}

		return null;
	}
	

	private void performDotCompletionAndFunctionToolTip( Scintilla sc, bool bFunctionToolTip, bool bForce = false )
	{
		bool 				bDotEnd, bModuleScope;
		char[]				typedWord, withName, listToolTip;
		char[][] 			currentWords = readCurrentWholeWord( sc, bFunctionToolTip, bDotEnd );
		CAnalyzerTreeNode 	functionHeadNode;

		if( !currentWords.length ) return;

		originalFunctionNode = null;

		if( !currentWords[0].length )
		{
			// use module scope
			bModuleScope = true;
			if( currentWords.length > 1 )
				currentWords = currentWords[1..length];
			else
				return;
		}

		
		if( !bFunctionToolTip )
		{
			if( !bDotEnd )
			{
				if( currentWords.length == 1 )
				{
					// maybe "with"
					if ( currentWords[0].length >= Globals.lanchLetterCount || bForce )
					{
						functionHeadNode = searchFunctionHead( sc );
						if( bModuleScope )
						{
							while( !( functionHeadNode.DType & D_MAINROOT ) )
								functionHeadNode = functionHeadNode.getRoot();
						}
						
						sAutoComplete.autoCSearch( currentWords[0], functionHeadNode );
					}

					withName = getWithName( functionHeadNode );
					if( !withName.length )
					{
						char[] list = sAutoComplete.CAutoCompleteList.getResult();
						if( list.length ) sc.autoCShow( currentWords[0].length, list );
						return;
					}
					else
					{
						typedWord = currentWords[0];
						currentWords.length = 0;
					}
				}
				else
				{
					typedWord = currentWords[length-1];
					currentWords.length = currentWords.length - 1;
				}
			}
		}

		bool	bIsImport = haveImportKeyWord( sc );

		if( !bIsImport )
		{
			if( functionHeadNode is null )
			{
				functionHeadNode = searchFunctionHead( sc );
				if( bModuleScope )
				{
					while( !( functionHeadNode.DType & D_MAINROOT ) )
						functionHeadNode = functionHeadNode.getRoot();
				}
			}

			withName = getWithName( functionHeadNode );
			if( withName.length ) currentWords = withName ~ currentWords;

			originalFunctionNode = functionHeadNode;
		
			performAnalyzer( currentWords, typedWord, functionHeadNode, listToolTip, bFunctionToolTip );

			// Remove Template Parameters Associative arrays
			if( templateParams.length )
				foreach( char[] s; templateParams.keys ) templateParams.remove( s );
		}

		if( bFunctionToolTip )
		{
			CDDocParser.showTip( sc, -1, listToolTip, 0x777777, 0xffffff );
		}
		else
		{
			if( bIsImport )
			{
				char[] 	word = std.string.join( currentWords, "." );
				char[][] lists = sAutoComplete.projectImportParsers[sGUI.packageExp.getActiveProjectDir].perform( word );
				sAutoComplete.CAutoCompleteList.add( lists, "?22" );
			}

			char[] list = sAutoComplete.CAutoCompleteList.getResult();
			if( list.length ) sc.autoCShow( typedWord.length, list );
			if( typedWord.length ) sc.autoCSelect( typedWord );
		}
		
	}

	
	private CAnalyzerTreeNode performAnalyzer( char[][] currentWords, char[] typedWord, CAnalyzerTreeNode functionHeadNode, 
												inout char[] listToolTip, bool bFunctionToolTip, bool bJumpToDefintion =false )
	{
		bool 				bIsArray, bIsFunction, bIsCallTemplateFun, bUseFunTip, bShowList;
		char[]				word, originalWord;
		CAnalyzerTreeNode 	activeTreeNode;
		CAnalyzerTreeNode[] baseClasses;
		
		
		if( !sAutoComplete.fileParser ) return null;
		if( !currentWords.length ) return null;

		// Nested Function
		char[] _checkArrayOrFunction( char[] str )
		{
			if( !str.length ) return null;


			char[][] splitedWords = std.string.split( str, "!" );
			if( splitedWords.length > 1 )
			{
				bIsArray = false;
				bIsFunction = false;
				bIsCallTemplateFun = true;
			}
			else
			{
				splitedWords = std.string.split( str, "(" );
				if( splitedWords.length > 1 )
				{
					bIsArray = false;
					bIsFunction = true;
					bIsCallTemplateFun = false;
				}
				else
				{
					splitedWords = std.string.split( str, "[" );
					if( splitedWords.length > 1 )
					{
						bIsArray = true;
						bIsFunction = false;
						bIsCallTemplateFun = false;
					}
				}
			}

			return splitedWords[0];
		}

		CAnalyzerTreeNode _checkAlias( inout char[] aWord, CAnalyzerTreeNode node )
		{
			bool[char[]] bAliaed;
			
			CAnalyzerTreeNode _look( char[] ident, CAnalyzerTreeNode fromNode )
			{
				CAnalyzerTreeNode typeAlias = sAutoComplete.getAnalyzerTreeNode( ident, D_ALIAS | D_TYPEDEF, fromNode );
				if( !typeAlias )
				{
					CAnalyzerTreeNode[] dummyAnalyzers;
					typeAlias = sAutoComplete.getImport( ident, D_ALIAS | D_TYPEDEF, fromNode, dummyAnalyzers );
				}

				if( typeAlias )
				{
					if( ident in bAliaed ) return fromNode;

					bAliaed[ident] = true;
					//char[][] splitType = std.string.split( typeAlias.typeIdentifier );
					aWord = typeAlias.typeIdentifier;//splitType[0];
					return _look( typeAlias.typeIdentifier, typeAlias );
				}

				return fromNode;
			}

			return _look( aWord, node );
		}
		
		CAnalyzerTreeNode _getType( CAnalyzerTreeNode treeNode )
		{
			if( treeNode )
			{
				if( treeNode.DType & D_FUNCTION )
				{
					if( bUseFunTip )
					{
						CAnalyzerTreeNode father = treeNode.getRoot();
						char[] oriIdentifier = treeNode.identifier;
						if( father )
						{	// maybe function overload
							foreach( CAnalyzerTreeNode t; father.getAllLeaf() )
							{
								if( t.identifier == oriIdentifier )
									listToolTip ~= ( t.typeIdentifier ~ " " ~ t.identifier ~ "(" ~ t.parameterString ~ ")\n" );
							}
						}
						else
							listToolTip ~= ( treeNode.typeIdentifier ~ " " ~ treeNode.identifier ~ "(" ~ treeNode.parameterString ~ ")\n" );

						if( bJumpToDefintion ) return treeNode;
					}
					else
					{
						treeNode = getOverloadFunction( treeNode );

						char[] lookup = treeNode.typeIdentifier;

						if( lookup.length ) lookup = std.string.removechars( lookup, "*" );

						lookup = getConstTypeD2( lookup );
						
						if( lookup != "void" )
						{
							if( !isBuiltInType( lookup ) )
							{						
								// char[][] splitTypeIdents = std.string.split( lookup, "." );
								char[][] splitTypeIdents = splitBySign( lookup, '.' );
								
								// check if builtin type
								if( splitTypeIdents.length == 1 )
								{
									sAutoComplete.CAutoCompleteList.clean();
									if( splitTypeIdents[0] in templateParams )
									{
										if( isBuiltInType( templateParams[splitTypeIdents[0]] ) )
										{
											return null;
										}
										else
										{
											sAutoComplete.CAutoCompleteList.clean();
											splitTypeIdents[0] = templateParams[splitTypeIdents[0]];

											if( splitTypeIdents[0][length-1] == ']' )
												if( !bIsArray )
												{
													isBuiltInType( "char[]" );
													return null;
												}
										}
									}
									else
									{
										if( splitTypeIdents[0][length-1] == ']' )
											if( !bIsArray )
											{
												isBuiltInType( "char[]" );
												return null;
											}
									}
								}
								
								return performAnalyzer( splitTypeIdents, typedWord, treeNode, listToolTip, ( bFunctionToolTip ), bJumpToDefintion );
							}
							else
							{
								char[][] tempLookup = std.string.split( lookup, "[" );
								if( tempLookup.length > 1 ) // 變數TYPE含有[]
								{
									if( bIsArray )
									{
										sAutoComplete.CAutoCompleteList.clean();
										isBuiltInType( tempLookup[0] );
									}
								}
							}
						}

						return null;
					}
				}
				else if( treeNode.DType & D_UDTS )
				{
					if( treeNode.DType & D_TEMPLATE )
					{
						// Nest function, to find counts of ()
						int _checkParen( char[] text )
						{
							int countParen, totalCount;
							
							if( text[length-1] == ')' )
							{
								countParen = 1;
								totalCount = 0;
								for( int i = text.length - 2; i > -1; -- i )
								{
									if( text[i] == '(' )
									{
										countParen --;
										if( countParen == 0 ) totalCount ++;
									}
									else if( text[i] == ')' )
									{
										countParen ++;
									}
								}
							}

							if( countParen == 0 ) return totalCount;else return -1;
						}

						// Nest function, to find the parameters of ()
						char[][] _getTemplateParams( char[] text )
						{
							if( !text.length ) return null;
							
							// get first (
							char[][] 	result;
							int 		countParen, firstOpenParen = std.string.find( text, '(' );
							char[]		paramString;

							if( firstOpenParen > 0 )
							{
								for( int i = firstOpenParen + 1; i < text.length; ++ i )
								{
									if( text[i] == ',' )
									{
										if( countParen == 0 )
										{
											result ~= paramString;
											paramString = "";
											continue;
										}
									}
									else if( text[i] == '(' )
										countParen ++;
									else if( text[i] == ')' )
									{
										countParen --;
										if( countParen < 0 )
										{
											result ~= paramString;
											break;
										}
									}

									paramString ~= text[i];
								}
							}
							else
							{
								if( compilerVersion > 1 )
								{
									int afterNot = std.string.find( text, '!' );
									if( afterNot > 0 ) result ~= text[afterNot+1..length];
								}
							}

							return result;
						}

						void _setTemplateParameterAssociativeArrays( char[] _word, char[] _paramString )
						{
							// To Do: Alias Parameters, Tuple Parameters.......
							char[][] params = _getTemplateParams( _word );
							char[][] paramsT = splitBySign( _paramString, ',', true );
							char[]	 defaultParam;

							if( paramsT.length >= params.length )
								for( int i = 0; i < paramsT.length; ++ i )
								{
									// Template Value Parameters
									char[][] splitValueParameters = splitBySpace( paramsT[i], false );
									
									if( splitValueParameters.length > 1 )
									{
										if( splitValueParameters[1].length )
										{
											int posColon = std.string.find( splitValueParameters[1], ":" );
											if( posColon > 0 ) splitValueParameters[1] = splitValueParameters[1][0..posColon];
											
											templateParams[splitValueParameters[1]] = splitValueParameters[0];
										}
										continue;
									}
									
									int pos = std.string.find( paramsT[i], ":" );
									if( pos < 0 )
									{
										// Trailing template parameters can be given default values
										pos = std.string.find( paramsT[i], "=" );
										if( i >= params.length )
										{
											if( pos > 0 ) defaultParam = getConstTypeD2( paramsT[i][pos+1..length] );
										}
									}
									else
									{
										// Template Type Parameters
										// Argument Deduction
										/*
										1.
										從一個特例化進行的推演可以為多個參數提供值
										Deduction from a specialization can provide values for more than one parameter:

										template Foo(T: T[U], U)
										{
											...
										}

										Foo!(int[long])  // instantiates Foo with T set to int, U set to long

										2.
										template TBar(T : T[]) { }
										alias TBar!(char[]) Foo3; // (2) T 被推導為 char										
										*/										
										char[] 		argumentDeduction0 = paramsT[i][0..pos];
										char[]		argumentDeduction1 = paramsT[i][pos+1..length];
										char[][] 	argumentDeduction2 = getIdentAndParams( argumentDeduction1 );

										if( argumentDeduction2.length )
											if( argumentDeduction2.length > 1 )
											{
												if( argumentDeduction2[1][length-1] == ']' )
												{
													char[][] p = getIdentAndParams( params[i] );
													if( p.length )
														if( p.length > 1 )
														{
															if( p[1][length-1] == ']' )
															{
																char[] pp = getConstTypeD2( p[0] );
																if( argumentDeduction0 != argumentDeduction2[0] )
																{
																	if( pp[length-1] != ']' ) pp ~= "[]";
																	templateParams[argumentDeduction0] = pp;
																}

																pp = getConstTypeD2( p[0] );
																if( !isBuiltInType( pp ) )
																	templateParams[argumentDeduction2[0]] = pp;
																else
																	sAutoComplete.CAutoCompleteList.clean();

																if( argumentDeduction2[1].length > 2 )
																{ 
																	argumentDeduction2[1] = argumentDeduction2[1][1..length-1];
																	if( p[1].length > 2 )
																	{
																		p[1] = p[1][1..length-1];
																		templateParams[argumentDeduction2[1]] = getConstTypeD2( p[1] );
																	}
																}
																continue;
															}
														}
												}
											}
											else  // argumentDeduction2 -> getIdentAndParams return no parameters
											{
												char[][] p = getIdentAndParams( params[i] );
												if( p.length ) templateParams[std.string.removechars( argumentDeduction2[0], "*" )] = getConstTypeD2( p[0] );
											}
									}
									
									if( pos < 0 ) pos = paramsT[i].length;
									if( pos > 0 )
									{
										if( i < params.length )
											templateParams[paramsT[i][0..pos]] = getConstTypeD2( params[i] );
										else
										{
											// Trailing template parameters can be given default values
											if( defaultParam in templateParams )
												templateParams[paramsT[i][0..pos]] = templateParams[defaultParam];
											else
											{
												if( defaultParam.length ) templateParams[paramsT[i][0..pos]] = defaultParam;
											}

											break;
										}
										// sGUI.outputPanel.appendLine( "paramsT = " ~ paramsT[i][0..pos] ~ " = " ~ params[i] );
									}
								}
						}

						
						if( !bIsCallTemplateFun )  // no "!"
						{
							if( treeNode.baseClass == "i" ) // template function
							{
								// Implicit Template
								int countParens = _checkParen( originalWord );

								if( countParens == 0 )
								{
									if( bUseFunTip ) return _getType( treeNode.getLeaf( 0 ) ); // Square(
								}
								else if( countParens == 1 )
								{
									if( !bUseFunTip ) return _getType( treeNode.getLeaf( 0 ) ); // Square(3).
								}
								
								return null;	
							}
							else
								return null;
						}
						else
						{
							if( treeNode.baseClass == "c" ) // template class
							{
								//MessageBox.showMessage( dTypeToChars( treeNode.DType ) ~ " " ~ treeNode.identifier ~ "\n" ~ std.string.join( currentWords, "." ) ~ "\n" ~ word ~ "\n" ~ originalWord );
								
								if( !bUseFunTip )
								{
									//return _getType( treeNode.getLeaf( 0 ) );

									int countParens = _checkParen( originalWord );

									// Set Type of template Parameters
									_setTemplateParameterAssociativeArrays( originalWord, treeNode.parameterString );

									if( countParens == 2 || countParens == 1 ) // CLASS!()().
										treeNode = treeNode.getLeaf( 0 );
									else
									{
										if( compilerVersion > 1 )
										{
											if( countParens == 0 ) treeNode = treeNode.getLeaf( 0 );else return null;
										}
										else
											return null;
									}
								}
								else
								{
									
									int countParens = _checkParen( originalWord );

									//MessageBox.showMessage( "countParens = " ~ std.string.toString( countParens ) );

									if( countParens == 1 ) // CTOR
										treeNode = treeNode.getLeaf( 0 );
									else if( countParens > 1 )
									{
										return null;
									}
								}
							}
							else if( treeNode.baseClass == "i" ) // template function
							{
								if( !bUseFunTip )
								{
									if( _checkParen( originalWord ) == 2 ) // Square!()()
									{
										int countParens = _checkParen( originalWord );

										// Set Type of template Parameters
										_setTemplateParameterAssociativeArrays( originalWord, treeNode.parameterString );

										return _getType( treeNode.getLeaf( 0 ) );
									}
									else
										return null; // if not Square!()(), don't show codecompletion
								}
								else
								{
									int countParens = _checkParen( originalWord );

									if( countParens == 1 ) // Square!()(
										return _getType( treeNode.getLeaf( 0 ) );
									else if( countParens != 0 ) //Square!(
										return null;
								}
							}
							else
							{	
								if( bUseFunTip )
								{
									if( currentWords[length-1][length-1] == ')' ) return null;
								}
								else
								{
									// Set Type of template Parameters
									_setTemplateParameterAssociativeArrays( originalWord, treeNode.parameterString );
								}
							}
						}

						if( treeNode.baseClass.length ) baseClasses = sAutoComplete.getBaseClassNode( treeNode );
					}
					else
					{
						if( treeNode.baseClass.length ) baseClasses = sAutoComplete.getBaseClassNode( treeNode );
					}

					if( bUseFunTip )
					{
						if( treeNode )
						{
							if( treeNode.DType & D_CLASS )
							{
								foreach( CAnalyzerTreeNode t; treeNode.getAllLeaf() )
								{
									if( t.DType & D_CTOR )
										listToolTip ~= ( t.identifier ~ "(" ~ t.parameterString ~ ")\n" );
								}
								//return null;
							}
							else if( treeNode.DType & D_STRUCT )
							{
								foreach( CAnalyzerTreeNode t; treeNode.getAllLeaf() )
								{
									if( t.DType & D_FUNCTION )
										if( t.identifier == "opCall" )
											listToolTip ~= ( t.identifier ~ "(" ~ t.parameterString ~ ")\n" );
								}
							}
							else if( treeNode.DType & D_TEMPLATE )
							{
								listToolTip ~= ( treeNode.identifier ~ "(" ~ treeNode.parameterString ~ ")\n" );
							}
						}
					}
					else
					{
						if( bShowList ) symbolsToAutoCShow( typedWord, treeNode, baseClasses );
					}
					
					return treeNode;
					
				}
				else if( treeNode.DType & ( D_VARIABLE | D_PARAMETER | D_ALIAS | D_TYPEDEF ) )
				{
					char[] 	lookup = treeNode.typeIdentifier;
					int 	DType = D_CLASS | D_INTERFACE | D_STRUCT | D_UNION;

					//if( bIsFunction ) return null;
					//char[] lookup0 = treeNode.typeIdentifier;

					if( lookup.length > 1 )
						if( lookup[0] == '.' )
						{
							// module scope variables typeidentifier
							// now treeNode should be one member of D_MAINROOT, so move to D_MAINROOT
							lookup = lookup[1..length];
							while( !( treeNode.DType & D_MAINROOT ) )
								treeNode = treeNode.getRoot();								
						}					

					//找尋D_ALIAS
					treeNode = _checkAlias( lookup, treeNode );

					if( treeNode )
						if( treeNode.DType & ( D_ALIAS | D_TYPEDEF ) )
						{
							int posDelegate = std.string.find( lookup, " delegate" );
							int posFunction = std.string.find( lookup, " function" );

							if( posDelegate > -1 || posFunction > -1 )
							{
								char[] typeIdent, params;
								
								if( posDelegate > -1 ) typeIdent = lookup[0..posDelegate];
								if( posFunction > -1 ) typeIdent = lookup[0..posFunction];

								if( !bUseFunTip )
								{
									lookup = typeIdent;
								}
								else
								{
									int posOpenParen = std.string.find( lookup, "(" );
									int posCloseParen = std.string.rfind( lookup, ")" );
									if( posCloseParen > posOpenParen && posOpenParen > -1 && posCloseParen > 0 ) 
										params = lookup[posOpenParen+1..posCloseParen];

									listToolTip ~= ( typeIdent ~ " " ~ treeNode.identifier ~ "(" ~ params ~ ")\n" );
								}
							}
						}

					if( lookup.length ) lookup = std.string.removechars( lookup, "*" );
					lookup = getConstTypeD2( lookup );
					
					if( lookup != "void" )
					{
						if( !isBuiltInType( lookup ) )
						{
							if( lookup[length-1] == ']' )
							{
								if( bIsArray )
								{
									//char[] arrayName = getArrayName( lookup );
									//if( arrayName.length ) lookup = arrayName;
								}
								else
								{
									isBuiltInType( "char[]" );
									return null;
								}
							}

							char[][] splitTypeIdents = splitBySign( lookup, '.' );

							// check if builtin type
							if( splitTypeIdents.length == 1 )
								if( splitTypeIdents[0] in templateParams )
								{
									sAutoComplete.CAutoCompleteList.clean();
									if( isBuiltInType( templateParams[splitTypeIdents[0]] ) )
										return null;
									else
									{
										sAutoComplete.CAutoCompleteList.clean();
										splitTypeIdents[0] = templateParams[splitTypeIdents[0]];
									}
								}
								
							if( bJumpToDefintion && bUseFunTip )
								if( !Globals.jumpTop && treeNode.identifier == word ) return treeNode;
								
							return performAnalyzer( splitTypeIdents, typedWord, treeNode, listToolTip, ( bFunctionToolTip), bJumpToDefintion );
						}
						else
						{
							if( lookup[length-1] == ']' ) // 變數TYPE含有[]
							{
								if( bIsArray )
								{
									sAutoComplete.CAutoCompleteList.clean();//list = null;
									isBuiltInType( getArrayName( lookup ) );
									/*
									char[][] splitIdentAndParams = getIdentAndParams( lookup, true );
									if( splitIdentAndParams.length ) isBuiltInType( splitIdentAndParams[0] );
									*/
								}
							}
						}
					}
				}
				else if( treeNode.DType & D_MIXIN )
				{
					CAnalyzerTreeNode mixinNode = sAutoComplete.getAnalyzerTreeNode( treeNode.identifier, D_TEMPLATE, treeNode );
					CAnalyzerTreeNode[] dummyAnalyzers;
					
					if( mixinNode is null )	
						mixinNode = sAutoComplete.getImport( treeNode.identifier, D_TEMPLATE, treeNode, dummyAnalyzers );

					if( mixinNode !is null )
					{
						if( bShowList && !bUseFunTip ) symbolsToAutoCShow( typedWord, mixinNode, baseClasses );
					}

					return mixinNode;
				}
				else if( treeNode.DType & D_FUNLITERALS )
				{
					if( bUseFunTip )
					{
						listToolTip ~= ( treeNode.typeIdentifier ~ " " ~ treeNode.identifier ~ "(" ~ treeNode.parameterString ~ ")\n" );
					}
					else
					{
						char[][] splitTypeIdents = std.string.split( treeNode.typeIdentifier, "." );
						return performAnalyzer( splitTypeIdents, typedWord, treeNode, listToolTip, ( bFunctionToolTip ), bJumpToDefintion );
						//return _getReturnType();
					}
				}
				else if( treeNode.DType & D_ALIAS )
				{
					char[][] splitTypeIdent = std.string.split( treeNode.typeIdentifier, "." );
					
					if( bIsCallTemplateFun )
						splitTypeIdent[length-1] ~= "!";
					else if( bIsArray )
						splitTypeIdent[length-1] ~= "[";
					else if( bIsFunction )
						splitTypeIdent[length-1] ~= "(";

					if( bJumpToDefintion && bUseFunTip )
						if( !Globals.jumpTop && treeNode.identifier == word ) return treeNode;
						
					return performAnalyzer( splitTypeIdent, typedWord, treeNode, listToolTip, ( bFunctionToolTip ), bJumpToDefintion );
				}
			}

			if( bJumpToDefintion ) return treeNode;else return null;
		}

		CAnalyzerTreeNode _lookBLOCK( CAnalyzerTreeNode treeNode )
		{
			if( !treeNode ) return activeTreeNode;
			if( activeTreeNode ) return activeTreeNode;

			foreach( CAnalyzerTreeNode t; treeNode.getAllLeaf() )
			{
				if( t.DType == D_BLOCK )
				{
					activeTreeNode = sAutoComplete.getMemberAnalyzerTreeNode( word, D_ALL - D_BLOCK, t, baseClasses );
					baseClasses.length = 0;
					
					if( activeTreeNode )
						return activeTreeNode;
					else
						_lookBLOCK( t );
				}
				if( activeTreeNode ) break;;
			}

			return activeTreeNode;
		}


		CAnalyzerTreeNode[] importModules;
		bool				bModuleImportCall;

		CAnalyzerTreeNode _judgeModule( int index, out bool bContinue )
		{
			char[][] 			words;
			bool[char[]]		bAlreadyImported;

			foreach( CAnalyzerTreeNode t; importModules )
			{
				if( t.getLeafCount() )
				{
					char[] moduleName = t.getLeaf( 0 ).identifier;

					foreach( CAnalyzerTreeNode tt; sAutoComplete.getAnalyzerAllNodeR( functionHeadNode, D_IMPORT ) )
					{
						if( tt.identifier == moduleName )
							if( tt.typeIdentifier.length )
							{
								moduleName = tt.typeIdentifier;
								break;
							}
					}

					char[][] splitedModuleName = std.string.split( moduleName, "." );

					
					if( splitedModuleName.length == 1 )
					{
						if( word == moduleName )
						{
							bModuleImportCall = true;
							if( currentWords.length == 1 )
							{
								moduleToAutoCShow( t );
								return null;
							}
							
							//list ~= moduleToAutoCShow( t );
						}
					}

					if( currentWords.length < splitedModuleName.length )
					{
						int j;
						for( j = 0; j < currentWords.length; ++ j )
						{
							if( currentWords[j] != splitedModuleName[j] ) break;
						}

						if( j == currentWords.length )
						{
							if( !( splitedModuleName[j] in bAlreadyImported ) )
							{
								words ~= splitedModuleName[j];
								bAlreadyImported[splitedModuleName[j]] = true;
							}	
						}
					}
					else
					{
						int j;
						for( j = 0; j < splitedModuleName.length; ++ j )
						{
							if( currentWords[j] != splitedModuleName[j] ) break;
						}

						//words.length = 0;
						if( currentWords.length == splitedModuleName.length )
						{
							if( j == splitedModuleName.length )
							{
								moduleToAutoCShow( t );
								//list ~= moduleToAutoCShow( t );
								return null;
							}
						}
						else if( currentWords.length > splitedModuleName.length )
						{
							if( index < splitedModuleName.length )
							{
								bContinue = true;
								continue;
							}
											
							if( j == splitedModuleName.length )
							{
								bModuleImportCall = false;
								CAnalyzerTreeNode[] _dummyClasses;
								CAnalyzerTreeNode treeNode = sAutoComplete.getMemberAnalyzerTreeNode( word, D_VARIABLE | D_UDTS | D_FUNCTION, t, _dummyClasses );
								return _getType( treeNode );
							}
						}
					}
				}
			}
		
			/+
			foreach( CAnalyzerTreeNode t; sAutoComplete.getAnalyzerAllNodeR( functionHeadNode, D_IMPORT ) )
			{
				CAnalyzerTreeNode	activeimportModule;
				char[] 				moduleName = t.identifier;

				foreach( CAnalyzerTreeNode tt; importModules )
				{
					if( tt.getLeafCount() )
					{
						if( tt[0].identifier == moduleName )
						{
							activeimportModule = tt;
							break;
						}
					}
				}

				if( t.typeIdentifier.length ) moduleName = t.typeIdentifier;

				char[][] splitedModuleName = std.string.split( moduleName, "." );

				if( splitedModuleName.length == 1 )
				{
					if( word == moduleName )
					{
						bModuleImportCall = true;

						if( activeimportModule !is null )
						{
							if( currentWords.length == 1 )
							{
								moduleToAutoCShow( activeimportModule );
								return null;
							}
						}
					}
				}

				if( currentWords.length < splitedModuleName.length )
				{
					int j;
					for( j = 0; j < currentWords.length; ++ j )
					{
						if( currentWords[j] != splitedModuleName[j] ) break;
					}

					if( j == currentWords.length )
					{
						if( !( splitedModuleName[j] in bAlreadyImported ) )
						{
							if( typedWord.length )
							{
								if( std.string.find( splitedModuleName[j], typedWord ) > -1 ) words ~= splitedModuleName[j];
							}
							else
								words ~= splitedModuleName[j];
								
							bAlreadyImported[splitedModuleName[j]] = true;
						}	
					}
				}
				else
				{
					int j;
					for( j = 0; j < splitedModuleName.length; ++ j )
					{
						if( currentWords[j] != splitedModuleName[j] ) break;
					}

					//words.length = 0;
					if( currentWords.length == splitedModuleName.length )
					{
						if( j == splitedModuleName.length )
						{
							if( activeimportModule !is null ) moduleToAutoCShow( activeimportModule );
							return null;
						}
					}
					else if( currentWords.length > splitedModuleName.length )
					{
						if( index < splitedModuleName.length )
						{
							bContinue = true;
							continue;
						}
											
						if( j == splitedModuleName.length )
						{
							CAnalyzerTreeNode[] 	_dummyClasses;
							CAnalyzerTreeNode 		treeNode;

							bModuleImportCall = false;

							if( activeimportModule !is null ) treeNode = sAutoComplete.getMemberAnalyzerTreeNode( word, D_VARIABLE | D_UDTS | D_FUNCTION, activeimportModule, _dummyClasses );
							bNotFriendClass = true;
							return _getType( treeNode );
						}
					}				
				}
			}
			+/

			if( words.length ) sAutoComplete.CAutoCompleteList.add( words, "?22" );

			return null;
		}


		CAnalyzerTreeNode _getHeadModule()
		{
			if( functionHeadNode !is null )
			{
				CAnalyzerTreeNode head = functionHeadNode;
				
				char[] mName, fName;
				sAutoComplete.getModuleNames( head, mName, fName );
				
				if( word == mName )
				{
					while( !( head.DType & D_MAINROOT ) )
						head = head.getRoot();
				}
				else
					return null;

				return head;
			}

			return null;
		}
		

		if( functionHeadNode )
		{
			for( int i = 0; i < currentWords.length; ++ i )
			{
				word = _checkArrayOrFunction( currentWords[i] );
				originalWord = currentWords[i]; // originalWord include params
				if( !word.length ) return null;
				
				int DType;
				//if( bIsFunction ) DType = D_FUNCTION;else 
				DType = D_ALL - D_IMPORT - D_MAINROOT - D_MODULE - D_UNITTEST -D_UNKNOWN - D_BLOCK - //D_FUNLITERALS -
						D_CONDITIONSPEC - D_ANONYMOUSBLOCK;// - D_MIXIN;

				baseClasses.length = 0;

				if( i == currentWords.length - 1 )
					if( bFunctionToolTip ) bUseFunTip = true;else bShowList = true;

				if( i == 0 )
				{
					activeTreeNode = sAutoComplete.getMixinIdentifierNode( word, functionHeadNode );
					
					// 先找fileParser
					if( activeTreeNode is null )
						activeTreeNode = sAutoComplete.getAnalyzerTreeNode( word, DType, functionHeadNode, true );

					if( activeTreeNode && ( word == "this" || word == "super" ) ) activeTreeNode = null; // for class/interface pointer or ctor
					
					// 找繼承的BaseClass
					if( !activeTreeNode )
					{
						CAnalyzerTreeNode rootNode = functionHeadNode.getRoot();
						CAnalyzerTreeNode fatherNode;
						
						while( rootNode )
						{
							if( rootNode.DType & ( D_CLASS | D_INTERFACE ) )
							{
								if( word == "this" )
								{
									activeTreeNode = rootNode;
									break;
								}
								else if( rootNode.baseClass.length )
								{
									fatherNode = rootNode;
									break;
								}
							}
							
							rootNode = rootNode.getRoot();
						}

						if( fatherNode )
						{
							baseClasses = sAutoComplete.getBaseClassNode( fatherNode );

							if( baseClasses.length && word == "super" )
							{
								activeTreeNode = baseClasses[0];
							}
							else
							{
								CAnalyzerTreeNode[] dummyClasses;
								
								foreach( CAnalyzerTreeNode t; baseClasses )
								{
									activeTreeNode = sAutoComplete.getMemberAnalyzerTreeNode( word, DType, t, dummyClasses );
									if( activeTreeNode )
									{
										//if( sAutoComplete.getAnalyzerTreeNode( t.identifier, D_CLASS | D_INTERFACE, functionHeadNode, true ) is null ) bNotFriendClass = true;
										break;
									}
								}
							}

							baseClasses.length = 0;
						}
					}
					
					// 找import的模組
					if( !activeTreeNode )
					{
						CAnalyzerTreeNode[] dummyAnalyzers;
						activeTreeNode = sAutoComplete.getImport( word, DType, functionHeadNode, dummyAnalyzers );
					}

					// 找import的模組
					if( !activeTreeNode )
					{
						bool bContinue;
						activeTreeNode = sAutoComplete.getImport( word, DType, functionHeadNode, importModules, true );

						_judgeModule( i, bContinue );

						if( bContinue )
						{
							bModuleImportCall = true;
							continue;
						}
					}

					if( !activeTreeNode ) activeTreeNode = sAutoComplete.checkRuntimeParser( word );
					
					if( activeTreeNode )
					{
						activeTreeNode = _getType( activeTreeNode );
					}
					else
					{
						activeTreeNode = _getHeadModule();
						if( activeTreeNode !is null )
						{
							if( bShowList && !bUseFunTip ) symbolsToAutoCShow( typedWord, activeTreeNode, null );
						}
						else
							break;
					}
				}
				else // i > 0
				{
					sAutoComplete.CAutoCompleteList.clean();
					listToolTip.length = 0;
					activeTreeNode = sAutoComplete.getMemberAnalyzerTreeNode( word, DType, activeTreeNode, baseClasses );
					baseClasses.length = 0;
					activeTreeNode = _getType( activeTreeNode );

					if( !activeTreeNode )
					{
						if( bModuleImportCall )
						{
							bool bContinue;
							activeTreeNode = _judgeModule( i, bContinue );

							if( bContinue ) continue;
							if( !activeTreeNode ) break;
						}
						else
							break;
							//continue;
					}
				}
			}

			return activeTreeNode;
		}
	}


	static char[] readHoverWord( Scintilla sc )
	{
		if ( sc.getLineCount() <= 2 ) return null;
		int pos =  sc.getCurrentPos();
		int endLine = sc.getLineCount();
		int endPos = sc.positionFromLine( endLine );
		char[] wordForward, wordBackward, word;
	
		char ch = sc.getCharAt( pos++ );
		wordForward ~= ch;

		while( !isWordBreak( ch ) )
		{
			ch = sc.getCharAt(pos++);
			wordForward ~= ch;
			if( pos >= endPos ) break;
		}
	
		pos = sc.getCurrentPos();
		ch 	= sc.getCharAt( --pos );
	
		while( !isWordBreak( ch ) )
		{
			ch = sc.getCharAt(pos--);
			wordBackward ~= ch;
			if( pos <= 0 ) break;
		}
		
		wordBackward.reverse;
	
		word = wordBackward ~ wordForward;
	
		if( isWordBreak( word[word.length - 1] ) ) word = word[0..word.length - 1];

		if( isWordBreak( word[0] ) ) word = word[1..word.length];
	
		return std.string.strip( word );
	}

	
	static char[] readHoverWord( Scintilla sc, int pos )
	{
		char[]		text;
		dchar[] 	word, oWord;
		dchar 		ch;
		int			startPos = pos;

		// move to head
		while( pos > -1 )
		{
			ch = sc.getCharAt( pos );

			if( ch != '.' )
				if( isWordBreak( ch ) ) break;			

			-- pos;
			oWord ~= ch;
		}

		/+
		try
		{
			oWord.reverse;
			text = std.utf.toUTF8( oWord );
			std.utf.validate( text ); 		// 檢查是否為有效的 UTF8

			//MessageBox.showMessage( text );
		}
		catch
		{
		}
		+/


		// look back
		pos ++;
		int arraySignCount;
		
		do 
		{
			ch = sc.getCharAt( pos );

			if( ch == '[' )
				arraySignCount ++;
			else if( ch == ']' )
				arraySignCount --;
			else if( ch == ' ' )
			{
				if( arraySignCount == 0 ) break;
			}
			else if( ch == '.' )
			{
				if( pos > startPos ) break;
			}
			else
			{
				if( isWordBreak( ch ) )	break;
			}

			word ~= ch;
			++ pos;
		}
		while( ch != '\0' )
		

		if( !word.length ) return null;

		try
		{
			text = std.utf.toUTF8( word );
			std.utf.validate( text ); 		// 檢查是否為有效的 UTF8

			return std.string.strip( text );
		}
		catch
		{
		}

		return null;
	}

	void performImportStart(Scintilla sc)
	{
		char[] fileName = sGUI.editor.getSelectedFileName();
		if( fileName.length )
		{
			if( sGUI.packageExp.isFileInProjects( fileName ) )
			{
				char[][] lists = sAutoComplete.projectImportParsers[sGUI.packageExp.getActiveProjectDir].initialImports();
				sAutoComplete.CAutoCompleteList.add( lists, "?22" );
				char[] list = sAutoComplete.CAutoCompleteList.getResult();
				if( list.length ) sc.autoCShow( 0, list );
			}
		}
	}

	bool haveImportKeyWord( Scintilla sc )
	{
		char[]		word;
		dchar[] 	dword;
		dchar 		ch;
		int			pos = sc.getCurrentPos() - 2;

		// move to head
		while( pos > -1 )
		{
			ch = sc.getCharAt( pos );

			if( ch == ';' || ch == ':' || ch == '{' || ch == '}' ) break;

			dword ~= ch;
			-- pos;
		}

		if( dword.length ) dword.reverse;else return false;


		try
		{
			word = std.utf.toUTF8( dword );
			std.utf.validate( word ); 		// 檢查是否為有效的 UTF8
		}
		catch
		{
			return false;
		}

		int posImport = std.string.find( word, "import" );
		if( posImport > -1 )
		{
			ch = sc.getCharAt( pos + posImport + 7 );
			//sGUI.outputPanel.appendLine( "pos + posImport =>" ~ cast(char) ch ~ "<" );
			if( ch < 33 || ch > 126 ) return true;
		}
		return false;
		
		/*
		if( std.string.find( word, "import " ) > -1 ) return true;

		return false;
		*/
	}
	
	

	// functions from scintillautil
	void skipWhiteSpace( Scintilla sc, inout int pos , int direction = 0 /* 0 for backward, 1 for forward */ )
	{
		if( direction )
		{	
			while( sc.getCharAt( pos ) == ' ' || sc.getCharAt( pos ) == '\t' )
			{
				pos ++;
			}
			pos--;
		}
		else 
		{
			while( sc.getCharAt( pos ) == ' ' || sc.getCharAt( pos ) == '\t' )
			{
				pos --;
			}
			pos++;
		}
	}

	/*	Split text by dot, fix empty space
		Ex: sc.getCharAt( text.length ) -> sc & getCharAt(text.length)
	*/
	private char[][] splitBySign( char[] word, char sign = '.', bool bReserveSpace = false )
	{
		char[][]	result;
		char[] 		ident, skipSign;
		int			countArraySign, countFunctionSign;

		if( !bReserveSpace )
		{
			word = std.string.removechars( word, " " );
			word = std.string.removechars( word, "\t" );
			word = std.string.removechars( word, "\r" );
			word = std.string.removechars( word, "\n" );
		}

		for( int i = 0; i < word.length; ++ i )
		{
			if( skipSign == "" )
			{
				if( word[i] == '(' )
					skipSign = "(";
				else if( word[i] == '[' )
					skipSign = "[";
				
				if( word[i] == sign )
				{
					result ~= std.string.strip( ident );
					ident = "";
				}
				else
				{
					if( bReserveSpace )
						if( word[i] == ' ' || word[i] == '\n' || word[i] == '\t' || word[i] == '\r' )
							if( ident.length )
								if( ident[length-1] != ' ' )
								{
									ident ~= ' ';
									continue;
								}

					ident ~= word[i];
				}
				
				// if( word[i] == '=' ) ident = "";else ident ~= word[i];
			}
			else
			{
				if( skipSign == "[" )
				{
					if( word[i] == ']' )
					{
						if( countArraySign == 0 )
						{
							//ident ~= ']';
							skipSign = "";
						}
						else
						{
							countArraySign --;
						}
					}
					else if( word[i] == '[' )
					{
						countArraySign ++;
					}
				}
				else if( skipSign == "(" )
				{
					if( word[i] == ')' )
					{
						if( countFunctionSign == 0 )
							skipSign = "";
						else
							countFunctionSign --;
					}
					else if( word[i] == '(' )
					{
						countFunctionSign ++;
					}
				}

				if( bReserveSpace )
					if( word[i] == ' ' || word[i] == '\n' || word[i] == '\t' || word[i] == '\r' )
						if( ident.length )
							if( ident[length-1] != ' ' )
							{
								ident ~= ' ';
								continue;
							}

				ident ~= word[i];
			}
		}

		result ~= std.string.strip( ident );

		return result;
	}


	private char[][] getIdentAndParams( char[] text, bool bOnlyIdent = false )
	{
		if( !text.length ) return null;

		int			countSign;
		char[]		ident;
		char[]		param;
		char[][]	ret;
		bool		bInParamMode;

		foreach( char c; text )
		{
			if( c == '(' || c == '[' )
			{
				if( bOnlyIdent ) break;
				if( !bInParamMode )	bInParamMode = true;
				countSign ++;
			}
			else if( c == ')' || c == ']' )
			{
				countSign --;
			}

			if( !bInParamMode )
				ident ~= c;
			else
				param ~= c;
		}

		ret ~= ident;
		if( param.length ) ret ~= param;

		return ret;
	}


	private char[] getArrayName( char[] text )
	{
		if( !text.length ) return null;

		if( text[length-1] == ']' )
		{
			int		countFunctionSign;
			char[] 	ret;

			foreach( char c; text )
			{
				if( c == '(' )
					countFunctionSign ++;
				else if( c == ')' )
					countFunctionSign --;
				else if( c == '[' )
				{
					if( countFunctionSign == 0 ) return ret;
				}

				ret ~= c;
			}
		}

		return null;
	}

	private char[][] readCurrentWholeWord( Scintilla sc, bool bFunctionToolTip, inout bool bDotEnd, int _pos = -1 )
	{
		char[] 	word;
		int		originalPos = sc.getCurrentPos();
		int 	pos = _pos < 0 ? originalPos - 2 : _pos;//= sc.getCurrentPos() - 2;

		// CodeCompletion won't work at comment (自動完成功能在註解中不動作)
		if( isComment( sc, pos ) ) return null;
		
		if( !bFunctionToolTip )
		{
			if( sc.getCharAt( pos + 1 ) != '.' )
			{
				pos ++;
				bDotEnd = false;
			}
			else
				bDotEnd = true;
		}
		
		dchar 	ch  = sc.getCharAt( pos );
		int		tailPos = pos;
		int		countParen;

		bool _wordBreak()
		{
			switch( sc.getCharAt( pos ) )
			{
				case ';':
				case '{':
				case '}':
				case '>':
				case ':':
				case '<':
				case '=':
				case '\'':
				case '+':
				case '-':
				case '*':
				case '/':
				case '%':
				case '|':
				case '&':
				case '^':
				case '?':
				case '~':
					if( countParen == 0 ) return true;else return false;
					break;

				case '[':
				case '(':
					countParen --;
					if( countParen < 0 ) return true;
					return false;
					break;
					
				case ']':
				case ')':
					countParen ++;
					return false;
					break;

				case ',':
					if( countParen == 0 ) return true;
					return false;
					break;
			
				default:
					return false;
					break;
			}
		}

		if( ch == '.' ) return null;

		// bool 	bGetChar;  // Make things easy...
		while( !_wordBreak() )
		{
			if( !isComment( sc, pos ) )
			{
				ch = sc.getCharAt( pos );

				if( countParen == 0 )
					if( ch == ' ' ||  ch == '\t' ) break;

				/* make things easy....
				if( countParen == 0 )
				{
					if( ch == ' ' ||  ch == '\t' )
					{
						if( bGetChar ) break;
					}
					else if( ch == '.' || ch == '(' || ch == '[' )
					{
						bGetChar = false;
					}
					else
					{
						bGetChar = true;
					}
					
					{
						try
						{
							char[] w = std.utf.toUTF8( dword );
							std.utf.validate( w ); 		// 檢查是否為有效的 UTF8
							if( std.string.strip( w ).length ) break;
						}
						catch
						{
							return null;
						}
					}
				}
				else
					bGetChar = true;
				*/
				
				if( --pos < 0 ) break;
			}
			else
			{
				if( --pos < 0 )	break;
				if( countParen == 0 ) break;
			}
		}

		// Get Words
		TextRange t = TextRange( pos + 1, tailPos + 1 );
		sc.getTextRange( &t );
		word = t.text;
				
		try
		{
			std.utf.validate( word ); 		// check if valid UTF8 or not (檢查是否為有效的UTF8)
		}
		catch
		{
			return null;
		}

		//sGUI.outputPanel.appendLine( std.string.join( splitBySign( word, '.' ), "." ) );
		return splitBySign( word, '.' );
	}


	void addAnalyzerNodeLive( Scintilla sc )
	{
		if( Globals.updateParseLiveFull )
		{
			try
			{
				CAnalyzerTreeNode headNode = searchFunctionHead( sc );
				
				
				//sGUI.editor.getSelectedEditItemHSU.updateFileParser2();
			}
			catch
			{
			}

			return;
		}
		else
		{
			if( !sAutoComplete.fileParser ) return;
			
			CAnalyzerTreeNode headNode = searchFunctionHead( sc );//findFunctionHead( sc );

			if( !headNode ) return;

			char[]		text, oText;
			dchar[] 	word, oWord;
			int 		pos =  sc.getCurrentPos();
			int			oPos = pos - 1;
			dchar 		ch;

			// look back
			if( sc.getCharAt( pos ) == ';' )
			{
			}
			else if( sc.getCharAt( pos - 1 ) == ';' )
			{
				pos -= 1;
			}
			else
			{
				do 
				{
					ch = sc.getCharAt( pos );
					if( ch == ';' || ch == '}' || ch == '{' || ch == ':' || ch == '\n' ) break;
					++ pos;
				}
				while( ch != '\0' )
			}

			// look front
			bool bFrontSign;
			
			while( pos > 0 )
			{
				ch = sc.getCharAt( pos );

				if( ch == ';' || ch == '}' || ch == '{' || ch == ':' )
				{
					if( bFrontSign ) break;else bFrontSign = true;
				}

				if( ch != '\n' )
				{
					if( ch == '\t' && sc.getCharAt( pos - 1 ) == '\n' )
					{
					}
					else
					{
						word ~= ch;
						if( pos != oPos ) oWord ~= ch;
					}
				}

				-- pos;
			}

			if( !word.length ) return;
			if( word == oWord ) return;


			// 取得原來文字的node
			CAnalyzerTreeNode oAnalyzerNode;
			try
			{
				if( oWord.length )
				{
					oWord.reverse;
					oText = std.utf.toUTF8( oWord );
					std.utf.validate( oText ); 		// 檢查是否為有效的 UTF8

					oText = std.string.strip( oText );

					oAnalyzerNode = CodeAnalyzer.syntax.core.parseTextHSU( oText, null, false );
					if( oAnalyzerNode )
						if( oAnalyzerNode.getLeafCount() < 1 ) delete oAnalyzerNode;
				}
			}
			catch
			{
				if( oAnalyzerNode ) delete oAnalyzerNode;
			}


			CAnalyzerTreeNode liveAnalyzernNode;
			try
			{
				// 目前文字的node
				word.reverse;
				text = std.utf.toUTF8( word );
				std.utf.validate( text ); 		// 檢查是否為有效的 UTF8

				text = std.string.strip( text );

				liveAnalyzernNode = CodeAnalyzer.syntax.core.parseTextHSU( text, null, false );

				if( liveAnalyzernNode )
				{
					if( liveAnalyzernNode.getLeafCount() < 1 )
					{
						delete liveAnalyzernNode;
						return;
					}
				}
			
				
				CAnalyzerTreeNode activeTreeNode = headNode;

				// Nested Function
				int _checkExist( CAnalyzerTreeNode node )
				{
					for( int i = 0; i < activeTreeNode.getLeafCount(); ++ i )
					{
						if( activeTreeNode.getLeaf( i ).DType & D_VARIABLE )
						{
							if( activeTreeNode.getLeaf( i ).identifier == node.identifier && 
								activeTreeNode.getLeaf( i ).DType == node.DType ) 
								return i;
						}
					}

					return -1;
				}

				// Nested Function
				void _dupTreeNode( CAnalyzerTreeNode treeNode )
				{
					foreach( CAnalyzerTreeNode t; treeNode.getAllLeaf() )
					{
						if( t.DType & D_VARIABLE )
						{
							if( validateVariable( t.identifier ) )
							{
								activeTreeNode.addLeaf( t.prot, t.DType, t.identifier, t.typeIdentifier, sc.lineFromPosition( sc.getCurrentPos() ),
														t.parameterString, t.baseClass );
							}
							
							//activeTreeNode = activeTreeNode.getLeaf( activeTreeNode.getLeafCount() - 1 );
							//_dupTreeNode( t );
							//activeTreeNode= activeTreeNode.getRoot();
						}
						else if( t.DType & D_IMPORT )
						{
							foreach( CAnalyzerTreeNode tt; sAutoComplete.getAnalyzerAllNodeR( activeTreeNode, D_IMPORT ) )
							{
								if( t.identifier == tt.identifier ) return;
							}
							
							activeTreeNode.addLeaf( t.prot, t.DType, t.identifier, t.typeIdentifier, sc.lineFromPosition( sc.getCurrentPos() ),
													t.parameterString, t.baseClass );

							if( Globals.parseAllModule || Globals.parseImported )
							{
								if( Globals.backLoadParser )
								{
									int _addMoudule()
									{
										sAutoComplete.setAdditionImportModules( sAutoComplete.fileParser );
										return 0;
									}
									
									Thread th = new Thread( &_addMoudule );
									th.start();
								}
								else
									sAutoComplete.setAdditionImportModules( sAutoComplete.fileParser );
							}
						}
					}
				}


				// 有原來文字的Node刪除之
				if( oAnalyzerNode )
				{
					foreach( CAnalyzerTreeNode t; oAnalyzerNode.getAllLeaf() )
					{
						if( t.DType & D_VARIABLE )
						{
							int oldIndex =_checkExist( t );

							if( oldIndex >= 0 )
							{
								CAnalyzerTreeNode[] 	tempChildren;
								CAnalyzerTreeNode       delChild;

								for( int i = 0; i < activeTreeNode.getLeafCount(); ++ i )
								{
									if( i != oldIndex )	tempChildren ~= activeTreeNode.getLeaf( i );
								}

								CAnalyzerTreeNode delNode = activeTreeNode.getLeaf( oldIndex );
								delete delNode;

								activeTreeNode.passChildren( tempChildren );
							}
						}
					}
				}

				// 加入目前文字的Node
				_dupTreeNode( liveAnalyzernNode );		
			}
			catch
			{
				if( liveAnalyzernNode ) delete liveAnalyzernNode;
				// liveAnalyzernNode parse error!!
			}

			if( oAnalyzerNode ) delete oAnalyzerNode;
			if( liveAnalyzernNode ) delete liveAnalyzernNode;
		}
	}

	

	static char[] readCurrentWord( Scintilla sc, bool skipOverWordBreaks = false, int shift = -1 )
	{
		dchar[] word;
		int 	pos = sc.getCurrentPos() + shift;
		dchar 	ch = sc.getCharAt( pos );

		if( skipOverWordBreaks )
		{
			while( isWordBreak( ch ) ) 
				ch = sc.getCharAt( pos-- );

			pos++;
		}

		while( !isWordBreak( ch ) )
		{
			ch = sc.getCharAt( pos-- );
			word ~= ch;
			if( pos < 0 ) break;
		}

		if( word.length > 1 )
			word.reverse;
		else
			return null;
	
		if( isWordBreak( word[word.length - 1] ) ) word = word[0..word.length - 1 ];
		if( isWordBreak( word[0] ) ) word = word[1..word.length ];

		char[] ret;
  
		try
		{
			ret = std.utf.toUTF8( word );
			std.utf.validate( ret ); 		// 檢查是否為有效的 UTF8
		}
		catch
		{
			ret = null;
		}

		return ret;
	}

	// 檢查型別 type
	private bool isBuiltInType( char[] type )
	{
		if( !type.length ) return true;
		
		// Nested Function
		int getList( char[] types )
		{
			if( types == "int" ) 
				return 0;
			else if ( types == "uint" )
				return 0;
			else if ( types == "bool" )
				return 0;
			else if( types == "byte" )
				return 0;
			else if( types == "ubyte" )
				return 0;
			else if( types == "short" )
				return 0;
			else if( types == "ushort" )
				return 0;
			else if ( types == "long" )
				return 0;
			else if ( types == "ulong" )
				return 0;
			else if ( types == "char" )
				return 0;
			else if( types == "wchar" )
				return 0;
			else if( types == "dchar" )
				return 0;
			else if ( types == "cent" )
				return 1;
			else if ( types == "ucent" )
				return 1;
			else if ( types == "float" )
				return 1;
			else if( types == "double" )
				return 1;
			else if( types == "real" )
				return 1;
			else if( types == "ifloat" )
				return 1;
			else if( types == "idouble" )
				return 1;
			else if( types == "ireal" )
				return 1;
			else if( types == "cfloat" )
				return 1;
			else if( types == "cdouble" )
				return 1;
			else if( types == "creal" )
				return 1;
			else
				return -1;
		}

		bool bWithArray;

		if( type[length-1] == ']' )
		{
			bWithArray = true;
			int posOpenbracket = std.string.find( type, '[' );
			if( posOpenbracket > 0 ) type = type[0..posOpenbracket];
		}

		if( bWithArray )
		{
			int ret = getList( type );
			if( ret >= 0 )
			{
				sAutoComplete.CAutoCompleteList.add( ArrayList, "?21" );
				return true;
			}
		}
		else
		{
			int ret = getList( type );
			if( ret == 0 )
			{
				sAutoComplete.CAutoCompleteList.add( IntegralList, "?21" );
				return true;
			}
			else if( ret == 1 )
			{
				sAutoComplete.CAutoCompleteList.add( FloatList, "?21" );
				return true;
			}
		}

		return false;
	}

	private char[] getConstTypeD2( char[] word )
	{
		if( !word.length ) return null;
		if( Globals.parserDMDversion < 2 ) return word;

		int posClose 		= std.string.find( word, ")" );
		int posArrayOpen 	= std.string.find( word, "[" );
		int posArrayClose 	= std.string.find( word, "]" );

		bool bArray;
		if( posArrayClose > posArrayOpen && posArrayOpen > posClose ) bArray = true;
		

		int pos = std.string.find( word, "const(" );
		if( pos == 0 )
			if( posClose > 6 ) return word[6..posClose] ~ ( bArray ? "[]" : null );

		pos = std.string.find( word, "invariant(" );
		if( pos == 0 )
			if( posClose > 10 ) return word[10..posClose] ~ ( bArray ? "[]" : null );

		pos = std.string.find( word, "immutable(" );
		if( pos == 0 )
			if( posClose > 10 ) return word[10..posClose] ~ ( bArray ? "[]" : null );
	
		return word;
	}
	
	static bool isWordBreak( char ch )
	{
		if ( ch == '.' || ch == ' ' || ch == '\t' || ch == ')' || ch == '('
			|| ch == '*' || ch == '+' || ch == '-' || ch == '/' || ch == '&'
			|| ch == ']' || ch == '[' || ch == '}' || ch == '\r' || ch == '\n'
			|| ch == ',' || ch == '=' || ch == ';' || ch == '!' ) return true;

		return false;
	}

	void performWordHover(Scintilla sc)
	{
	  // need to display this somewhere else besides callTips -- maybe a new control

	//   try {

	// 	  char [] word = readHoverWord(sc);
	// 	  if ( word.length )
	// 		{
	// 		  word.strip();
	// 		  SymbolListing [] listings = sAutoComplete.search(word);
	// 		  //MessageBox.showMsg(word);
	// 		  // TODO : make this smarter, instead of just choosing the first match
	// 		  if ( listings.length )
	// 		{
	// 		  SymbolListing l = listings[0];
			  
	// 		  char []  display = SymbolToChars(l.sym);
			  
	// 		  sc.callTipShow(sc.getCurrentPos(),display );

	// 		}
	// 		  //else sc.callTipCancel();
			  
			  
	// 		}
	//   }
	//   catch ( Exception e ) { 		  /* MessageBox.showMsg(e.toString() );*/ } 
	  
	}


	char[] readImportWord( Scintilla sc )
	{
		int 	pos = sc.getCurrentPos();
		char[] 	word;

		char ch = sc.getCharAt( --pos );

		while( ch != ' ' && ch != '\n' && ch != '\r' )
		{
			ch = sc.getCharAt( pos-- );
			word ~= ch;
			if ( pos < 0 ) break;
		}
		
		if( word.length > 1 ) word.reverse;
		
		if( word[$ - 1] == '.' ) word = word[0..$ - 1];

		return strip( word );
	}


	private void symbolsToAutoCShow( char[] typedWord, CAnalyzerTreeNode treeNode, CAnalyzerTreeNode[] baseClasses  ) 
	{
		if( treeNode is null ) return;

		CAnalyzerTreeNode[] nodes;

		CAnalyzerTreeNode[] memberNodes;

		if( treeNode.DType & D_ENUM )
		{
			memberNodes = sAutoComplete.getMembers( D_ENUMMEMBER, treeNode );

			if( treeNode.identifier != "-anonymous-" )
			{
				char[][] enumWords;

				if( typedWord.length )
				{			
					foreach( char[] s; [ "min", "max", "sizeof" ] )
					{

						if( typedWord.length <= s.length )
						{
							if( Globals.parserCaseSensitive )
							{
								if( typedWord == s[0..typedWord.length] ) enumWords ~= s;
							}
							else
							{
								if( std.string.tolower( typedWord ) == s[0..typedWord.length] ) enumWords ~= s;
							}
						}
					}
				}
				else
					enumWords = [ "min", "max", "sizeof" ];

				sAutoComplete.CAutoCompleteList.add( enumWords, "?21" );
			}
		}
		else
		{
			memberNodes = sAutoComplete.getMembers( D_VARIABLE | D_UDTS | D_FUNCTION, treeNode );

			foreach( CAnalyzerTreeNode t; baseClasses )
				memberNodes ~=  sAutoComplete.getMembers( D_VARIABLE | D_UDTS | D_FUNCTION, t );			
		}


		foreach( CAnalyzerTreeNode t; memberNodes )
		{
			if( t.DType & D_ENUM && t.identifier == "-anonymous-" )
			{
				symbolsToAutoCShow( typedWord, t, baseClasses );
				continue;
			}
			
			if( Globals.showAllMember )
				nodes ~= t;
			else
			{
				if( !sAutoComplete.isSameRoot( originalFunctionNode, t ) )
				{
					if( !( t.prot & ( D_Private | D_Protected ) ) ) nodes ~= t;
				}
				else
					nodes ~= t;

				/*
				if( !bNotFriendClass )
					nodes ~= t;
				else
					if( !( t.prot & ( D_Private | D_Protected ) ) ) nodes ~= t;
				*/
			}
		}

		if( typedWord.length )
			nodes = sAutoComplete.rootSearch( typedWord, nodes );
		
		sAutoComplete.CAutoCompleteList.add( nodes );
	}	


	private void moduleToAutoCShow( CAnalyzerTreeNode treeNode ) 
	{
		CAnalyzerTreeNode[] nodes;

		foreach( CAnalyzerTreeNode t; sAutoComplete.getMembers( D_VARIABLE | D_UDTS | D_FUNCTION, treeNode ) )
		{
			if( !( t.prot & ( D_Private | D_Protected ) ) ) nodes ~= t;
		}
		
		sAutoComplete.CAutoCompleteList.add( nodes );
	}


	private CAnalyzerTreeNode searchFunctionHead( Scintilla sc, int pos = -1 )
	{
		if( !sAutoComplete.fileParser ) return null;
		
		bool 				bMatch;
		int					originAnchorPos = sc.getCurrentPos();
		int					originPos = pos < 0 ? originAnchorPos : pos;

		pos = originPos - 1;
		
		char 				ch 	= sc.getCharAt( pos );
		char[]				word, finalWord, paramWord;

		int[]				lineBlocks;

		CAnalyzerTreeNode 	result;


		bool _isOperatorOverload( char[] s )
		{
			if( s == "opCall" || s == "opSlice" || s == "opSliceAssign" || s == "opAssign" ) 
				return true;
			else
				return false;
		}

		CAnalyzerTreeNode _getParam( int posLeftParen, int posRightParen, CAnalyzerTreeNode[] treeNodes )
		{
			if( !treeNodes.length ) return null;
			// If function overload......
			char[] paramWord;

			if( posLeftParen + 1 == posRightParen )
				paramWord = "";
			else
			{
				for( int i = posLeftParen + 1; i < posRightParen; ++ i )
					paramWord ~= sc.getCharAt( i );

				paramWord = std.string.removechars( paramWord, " " );
				paramWord = std.string.removechars( paramWord, "\t" );
				paramWord = std.string.removechars( paramWord, "\r" );
				paramWord = std.string.removechars( paramWord, "\n" );

				char[] temp;
				bool   bPass = true;
				foreach( char c; paramWord )
				{
					if( bPass )
						if( c == '=' ) bPass = false;else temp ~= c;
					else
					{
						if( c == ',' )
						{
							bPass = true;
							temp~= ',';
						}
					}
				}
				paramWord = temp;
			}

			foreach( CAnalyzerTreeNode t; treeNodes )
			{
				char[] nodeParamStr = std.string.removechars( t.parameterString, " " );
				if( paramWord == nodeParamStr )	return t;
			}

			return null;
		}
		

		CAnalyzerTreeNode _findAnalyzerNode( int posLeftParen, int posRightParen, int types = 0 )
		{
			int 	semiPos = posLeftParen - 1;
			char 	semiChar = sc.getCharAt( semiPos );
			char[] 	semiWord;
					
			while( semiChar != ';' &&  semiChar != '}' && semiChar != '{' )
			{
				if( !isComment( sc, semiPos ) )
				{
					if( types != 0 )  
						if( semiChar == ':' ) break;
					
					if( semiChar != '\n' && semiChar !='\t' &&  semiChar != '\r' ) 
						if( semiChar < 128 ) semiWord ~= semiChar;
					else
						semiWord ~= " ";
							
					semiPos --;
					if( semiPos < 0 ) break;
					semiChar = sc.getCharAt( semiPos );
				}
				else
					if( --semiPos < 0 ) break;
			}

			char[][] splitSemiWord = splitBySpace( semiWord );
			if( splitSemiWord.length )
			{
				switch( types )
				{
					case 0: // find UDT head
						char[] parenWord = splitSemiWord[length - 1 ];
						if( parenWord[length - 1] == ')' ) return null;
						/+
						foreach( char[] ss; splitSemiWord )
						{
							sGUI.outputPanel.appendLine( ss );
						}
						+/
						for( int i = 0; i < splitSemiWord.length; ++ i )
						{
							char[] s = splitSemiWord[i];
							if( s == "class" || s == "interface" ||	s == "struct" || s == "union" || s == "enum" )
							{
								char[] udtName;
								
								if( i < splitSemiWord.length - 1 )
								{
									// 去掉繼承的字
									char[][] inheritWords = std.string.split( splitSemiWord[i + 1], ":" );
									udtName = inheritWords[0];
								}
								else
									return null;

								CAnalyzerTreeNode[] treeNodes = sAutoComplete.lookAnalyzerTree( udtName, D_UDTS, sAutoComplete.fileParser );
								if( treeNodes.length ) return treeNodes[0];else return null;
							}
							else if( s == "else" || s == "try" || s == "catch" || s == "finally" || s == "debug" ||
									 s == "do" || s == "synchronized" ) //|| s == "asm" )
							{
								lineBlocks ~= sc.lineFromPosition( posLeftParen ) + 1;
							}
						}

						break;
						
					case 1:
						char[] finalWord = splitSemiWord[length - 1];
						if( finalWord != "if" && finalWord != "while" && finalWord != "for" && finalWord != "foreach"
								&& finalWord != "else" && finalWord != "version" && finalWord != "debug" 
								&& finalWord != "catch" && finalWord != "switch" && finalWord != "with" 
								&& finalWord != "synchronized" )
						{
							// 過載運算子及建構子
							if( finalWord == "this" || finalWord == "~this" || _isOperatorOverload( finalWord ) )
							{
								// 繼續找
								CAnalyzerTreeNode thisResultNode;
								int methodPos = semiPos;
	
								while( semiPos >= 0 )
								{
									char c = sc.getCharAt( semiPos );
									if( c == '{' )
									{
										int matchBracePos = sc.braceMatch( semiPos );

										if( matchBracePos > 0 )
											if( matchBracePos > methodPos )
											{
												thisResultNode = _findAnalyzerNode( semiPos, 0, 0 );
												if( thisResultNode !is null ) break;
											}
									}
									semiPos --;
								}

								if( thisResultNode )
								{
									CAnalyzerTreeNode[] treeNodes ;
									if( _isOperatorOverload( finalWord ) )
										treeNodes = sAutoComplete.lookAnalyzerTree( finalWord, D_FUNCTION, thisResultNode );
									else 
										treeNodes = sAutoComplete.lookAnalyzerTree( finalWord, D_CTOR | D_DTOR, thisResultNode );
										
									return _getParam( posLeftParen, posRightParen, treeNodes );
								}
							}
							
							//sGUI.outputPanel.appendString( "Function word = >" ~ finalWord ~ "<\n" );
							CAnalyzerTreeNode[] treeNodes = sAutoComplete.lookAnalyzerTree( finalWord, D_FUNCTION | D_CTOR | D_DTOR, sAutoComplete.fileParser );
							if( treeNodes.length ) 
							{
								if( treeNodes.length == 1 )
									return treeNodes[0];
								else
								{
									// If function overload......
									CAnalyzerTreeNode t = _getParam( posLeftParen, posRightParen, treeNodes );
									if( t ) return t;
								}
							}
							else
							{
								// maybe D_FUNLITERALS
								lineBlocks ~= sc.lineFromPosition( posLeftParen ) + 1;
							}
						}
						else
						{
							lineBlocks ~= sc.lineFromPosition( posLeftParen ) + 1;
						}

						break;

					case 2:
						char[] finalWord = splitSemiWord[0];
						if( finalWord == "case" || finalWord == "default" )
						{
							/+
							int switchPos = posLeftParen;

							dchar[] 	dword;
							
							while( switchPos > 5 )
							{
								dword ~= sc.getCharAt( switchPos - 6 );
								dword ~= sc.getCharAt( switchPos - 5 );
								dword ~= sc.getCharAt( switchPos - 4 );
								dword ~= sc.getCharAt( switchPos - 3 );
								dword ~= sc.getCharAt( switchPos - 2 );
								dword ~= sc.getCharAt( -- switchPos );

								if( dword == "switch" ) break;
							}

							if( dword == "switch" )
							{
								sGUI.outputPanel.appendLine( "get" );
								char 	c;
								bool	bGetOpencurly;
								
								while( switchPos < posLeftParen )
								{
									c = sc.getCharAt( switchPos );
									if( c == '{' )
									{
										bGetOpencurly = true;
										break;
									}
									switchPos ++;
								}
								
								if( bGetOpencurly )
								{
									int closecurlyPos = sc.braceMatch( switchPos );

									if( closecurlyPos > 0 )
									{
										if( closecurlyPos > posLeftParen ) 
										{
											int endPos = closecurlyPos;
											int nextCasePos = posLeftParen;

											while( nextCasePos < closecurlyPos-4 )
											{
												dword ~= sc.getCharAt( ++ nextCasePos );
												dword ~= sc.getCharAt( nextCasePos + 1 );
												dword ~= sc.getCharAt( nextCasePos + 2 );
												dword ~= sc.getCharAt( nextCasePos + 3 );
												if( dword == "case" )
												{
													endPos = nextCasePos;
													break;
												}
											}

											int defaultPos = posLeftParen;
											while( defaultPos < closecurlyPos-6)
											{
												dword ~= sc.getCharAt( ++ defaultPos );
												dword ~= sc.getCharAt( defaultPos + 1 );
												dword ~= sc.getCharAt( defaultPos + 2 );
												dword ~= sc.getCharAt( defaultPos + 3 );
												dword ~= sc.getCharAt( defaultPos + 4 );
												dword ~= sc.getCharAt( defaultPos + 5 );
												dword ~= sc.getCharAt( defaultPos + 6 );
												if( dword == "default" )
												{
													endPos = defaultPos;
													break;
												}
											}

											if( originPos > posLeftParen && originPos < endPos ) 
												lineBlocks ~= sc.lineFromPosition( posLeftParen ) + 1;
										}
									}
								}								
							}
							
							+/
							
							sc.setAnchor( posLeftParen );
							sc.searchAnchor();
							sc.hideSelection( true );
							int switchPos = sc.searchPrev( ScintillaEx.SCFIND_MATCHCASE, "switch" );
							
							if( switchPos > -1 )
							{
								if( switchPos > posLeftParen ) return null;
								
								char 	c;
								bool	bGetOpencurly;
								while( switchPos < posLeftParen )
								{
									c = sc.getCharAt( switchPos );
									if( c == '{' )
									{
										bGetOpencurly = true;
										break;
									}
									switchPos ++;
								}

								if( bGetOpencurly )
								{
									int closecurlyPos = sc.braceMatch( switchPos );

									if( closecurlyPos > 0 )
									{
										if( closecurlyPos > posLeftParen ) 
										{
											int endPos = closecurlyPos;
											int nextCasePos = sc.searchNext( ScintillaEx.SCFIND_MATCHCASE, "case" );
											if( nextCasePos > posLeftParen && nextCasePos < endPos ) endPos = nextCasePos;

											int defaultPos = sc.searchNext( ScintillaEx.SCFIND_MATCHCASE, "default" );
											if( defaultPos > posLeftParen && defaultPos < endPos ) endPos = defaultPos;

											if( originPos > posLeftParen && originPos < endPos ) 
												lineBlocks ~= sc.lineFromPosition( posLeftParen ) + 1;
										}
									}
								}
							}

							sc.setAnchor( originAnchorPos );
							sc.setCurrentPos( originAnchorPos );
							//sc.gotoPos( originPos );
							sc.hideSelection( false );
							
						}
						break;
					
					default:
						return null;
				}
			}
			else
			{
				if( types == 0 ) lineBlocks ~= sc.lineFromPosition( posLeftParen ) + 1;
			}
			
			return null;
		}

		CAnalyzerTreeNode _findBlock( CAnalyzerTreeNode node, int lineNum )
		{
			foreach( CAnalyzerTreeNode t; node.getAllLeaf() )
			{
				if( t.DType & ( D_BLOCK | D_FUNLITERALS | D_ANONYMOUSBLOCK ) )
					if( t.lineNumber == lineNum ) return t;
			}

			return null;
		}
		

		while( !bMatch )
		{
			switch( ch )
			{
				case '{':
					int matchBracePos = sc.braceMatch( pos );

					if( matchBracePos >= 0 ) 
					{
						if( matchBracePos < originPos ) // Nested Function
						{
							word = null;
							break;
						}
					}

					CAnalyzerTreeNode t = _findAnalyzerNode( pos, 0, 0 );
					if( t )
						return t;
					else
					{
						if( !word.length ) word = "{";else word = null;
					}
					break;

				case ')':
					if( word == "{" )
					{
						word = "){";
						int matchPos = sc.braceMatch( pos );
						if( matchPos >= 0 && matchPos < pos )
						{
							CAnalyzerTreeNode t = _findAnalyzerNode( matchPos, pos, 1 );
							if( t )
							{
								if( lineBlocks.length )
								{
									CAnalyzerTreeNode tt = t;
									for( int i = lineBlocks.length - 1; i >= 0; --i )
									{
										CAnalyzerTreeNode ttt = _findBlock( tt, lineBlocks[i] );
										if( ttt !is null ) tt = ttt;else break;
									}

									return  tt;
								}

								return t;
							}
							else
							{
								pos = matchPos;
								word = null;
							}
						}
					}
					break;

				case ':':
					_findAnalyzerNode( pos, pos, 2 );
					break;

				case ' ':
				case '\t':
				case '\n':
				case '\r':
					break;

				case ';':
				case '!':
					word = null;
					break;

				default:
					break;
			}

			pos --;

			if( pos < 0 ) return sAutoComplete.fileParser;

			ch = sc.getCharAt( pos );
		}

		return null;


		/*
		if( result ) 
			sGUI.outputPanel.appendString( "Function Head = >" ~ result.typeIdentifier ~ " " ~ result.identifier ~ "<\n" );
		else
			sGUI.outputPanel.appendString( "Function Head not MATCH!!!!!!!\n" );
		*/
	}


	static private char[][] splitBySpace( in char[] s, bool isReverseWord = true )
	{
		if( !s.length ) return null;
		
		char[][] results;
		char[] tempWord;
		int skipSpace;

		
		if( !isReverseWord ) s.reverse;
		
		s = std.string.strip( s );
		s.reverse;
		s = std.string.strip( s ) ~ " "; 

		foreach( char c; s )
		{
			if( c != ' ' && c != '\n' && c != '\t' && c != '\r' )
			{
				tempWord ~= c;
				if( c == '[' )
					skipSpace ++;
				else if( c == ']' )
					skipSpace --;
			}
			else
			{
				if( tempWord.length )
				{
					if( !skipSpace )
					{
						if( results.length )
						{
							char[] ss = results[length-1];
							if( ss[length-1] == ']' )
							{
								if( tempWord[0] == '[' )
								{
									tempWord = ss ~ tempWord;
									results.length = results.length - 1;
								}
							}
						}
								
						results ~= tempWord;
						tempWord = "";
					}
				}
				else
					tempWord = "";
			}
		}
		return results;
	}

	private bool validateVariable( char[] var )
	{
		foreach( char c; var )
		{
			if( c < 64 || c > 122 ) return false;
			if( c > 90 && c < 97 )
				if( c != 95 ) return false;
		}

		return true;
	}

	private CAnalyzerTreeNode getOverloadFunction( CAnalyzerTreeNode oneFunctionNode )
	{
		if( oneFunctionNode is null ) return null;
		
		// check if function overload
		CAnalyzerTreeNode aboveNode = oneFunctionNode.getRoot;
		if( aboveNode !is null )
		{
			CAnalyzerTreeNode[] overloadFunctionNodes;
			//bool 				bAllSame = true;
			
			foreach( CAnalyzerTreeNode t; sAutoComplete.getMembers( D_FUNCTION, aboveNode ) )
			{
				if( t.identifier == oneFunctionNode.identifier )
				{
					if( t != oneFunctionNode )
						if( t.typeIdentifier != "void" ) 
						{
							//if( overloadFunctionNodes.length )
								//if( overloadFunctionNodes[length-1].typeIdentifier != t.typeIdentifier ) bAllSame = false;

							overloadFunctionNodes ~= t;
						}
				}
			}

			if( !overloadFunctionNodes.length )
				return oneFunctionNode;
			else if( overloadFunctionNodes.length == 1 )
				return overloadFunctionNodes[0];
			else
			{
				/+
				// compare parameters.....
				// Not Yet......
				if( !bAllSame )
				{
					int 	countParams, pos, matchBracePos, endPos = sc.getCurrentPos() - 2;
					char 	c = sc.getCharAt( endPos );

					if( c == ')' )
					{
						matchBracePos = sc.braceMatch( endPos );
						pos = matchBracePos + 1;
						
						if( matchBracePos > -1 )
						{
							while( pos < endPos )
							{
								c = sc.getCharAt( pos );
								if( c == '(' || c == '[' || c == '{' )
								{
									pos = sc.braceMatch( pos ) + 1;
									if( pos == 0 || pos >= endPos ) break;
									c = sc.getCharAt( pos );
								}

								if( c == ',' ) countParams ++;

								pos ++;
							}
						}

						int 	countNodeParams;//, countNodeInitParams = std.string.count( t.parameterString, "=" );
						foreach( CAnalyzerTreeNode t; overloadFunctionNodes )
						{
							char[][] nodeParamVars = std.string.split( t.parameterString );
							if( nodeParamVars.length % 2 == 0 ) countNodeParams = nodeParamVars.length / 2;

							countNodeParams -= std.string.count( t.parameterString, "=" );

							if( countParams == countNodeParams )
							{

							}
							// NG!! need type analysis......
							
						}
					}
				}
				+/
				
				return overloadFunctionNodes[0];

			}
		}

		return oneFunctionNode;
	}

	private bool isComment( Scintilla sc, int pos )
	{
		int style = sc.getStyleAt( pos );
		if( style > 0 && style < 4 )
			return true;
		else if( style > 26 && style < 32 )
			return true;

		return false;
	}

	public void performJumpToDefintion( Scintilla sc, int pos, inout char[] fileFullPath, inout char[] moduleName, inout int lineNum, out CAnalyzerTreeNode resultNode )
	{
		// special version
		char[] _readHoverWord( Scintilla sc )
		{
			if ( sc.getLineCount() <= 2 ) return null;

			int _pos = pos < 0 ? sc.getCurrentPos() : pos;


			int endLine = sc.getLineCount();
			int endPos = sc.positionFromLine( endLine );
			char[] wordForward, wordBackward, word;
		
			char ch = sc.getCharAt( _pos++ );
			wordForward ~= ch;

			while( !isWordBreak( ch ) )
			{
				ch = sc.getCharAt( _pos++ );
				wordForward ~= ch;
				if( _pos >= endPos ) break;
			}

			_pos = pos < 0 ? sc.getCurrentPos() : pos;
			
			ch 	= sc.getCharAt( --_pos );
		
			while( !isWordBreak( ch ) )
			{
				ch = sc.getCharAt( _pos-- );
				wordBackward ~= ch;
				if( _pos <= 0 ) break;
			}
			
			wordBackward.reverse;
		
			word = wordBackward ~ wordForward;
		
			if( isWordBreak( word[word.length - 1] ) ) 
				if( word[length-1] != '!' ) word = word[0..word.length - 1];

			if( isWordBreak( word[0] ) ) word = word[1..word.length];
		
			return std.string.strip( word );
		}

		
		bool 				bDotEnd, bModuleScope, bFunctionToolTip = true;
		char[]				typedWord, withName, listToolTip;
		char[][] 			currentWords = readCurrentWholeWord( sc, bFunctionToolTip, bDotEnd, pos );
		CAnalyzerTreeNode 	functionHeadNode;

		fileFullPath = moduleName = "";
		lineNum = -1;
		resultNode = originalFunctionNode = null;

		if( !currentWords.length ) return;
		char[] tail = _readHoverWord( sc );
		currentWords[length-1] = tail;

		if( currentWords[0].length )
			if( currentWords[0][0] == '!' ) currentWords[0] = currentWords[0][1..length];

		if( !currentWords[0].length )
		{
			// use module scope
			bModuleScope = true;
			if( currentWords.length > 1 )
				currentWords = currentWords[1..length];
			else
				return;
		}

		//sGUI.outputPanel.appendLine( "Fixed currentWords = " ~ std.string.join( currentWords, "~" ) );


		bool	bIsImport = haveImportKeyWord( sc );

		if( !bIsImport )
		{
			if( functionHeadNode is null )
			{
				functionHeadNode = searchFunctionHead( sc, pos );
				if( bModuleScope )
				{
					while( !( functionHeadNode.DType & D_MAINROOT ) )
						functionHeadNode = functionHeadNode.getRoot();
				}
			}

			withName = getWithName( functionHeadNode );
			if( withName.length ) currentWords = withName ~ currentWords;

			originalFunctionNode = functionHeadNode;

			if( tail == currentWords[0] ) // currentWords.length == 1 )
			{
				CAnalyzerTreeNode easyNode = sAutoComplete.getAnalyzerTreeNode( currentWords[0], D_ALL - D_MAINROOT - D_BLOCK - D_MODULE, functionHeadNode, true );
				if( easyNode !is null )
				{
					resultNode = easyNode;
					lineNum = easyNode.lineNumber;
					while( !( easyNode.DType & D_MAINROOT ) )
						easyNode = easyNode.getRoot;

					if( easyNode.getLeafCount )
						if( easyNode.getLeaf( 0 ).DType & D_MODULE )
						{
							fileFullPath =  easyNode.getLeaf( 0 ).typeIdentifier;
							moduleName = easyNode.getLeaf( 0 ).identifier;
							return;
						}
				}
			}
			
		
			CAnalyzerTreeNode easyNode = performAnalyzer( currentWords, typedWord, functionHeadNode, listToolTip, bFunctionToolTip, true );
			if( easyNode !is null )
			{
				resultNode = easyNode;
				lineNum = easyNode.lineNumber;
				while( !( easyNode.DType & D_MAINROOT ) )
					easyNode = easyNode.getRoot;

				if( easyNode.getLeafCount )
					if( easyNode.getLeaf( 0 ).DType & D_MODULE )
					{
						fileFullPath =  easyNode.getLeaf( 0 ).typeIdentifier;
						moduleName = easyNode.getLeaf( 0 ).identifier;
					}
			}
		}
		else
		{
			char[]		word;
			dchar[] 	dword;

			pos = pos < 0 ? sc.getCurrentPos() : pos;
			
			//int			pos = sc.getCurrentPos();
			dchar 		ch = sc.getCharAt( pos - 1 );

			if( ch != ' ' && ch != ';' && ch != ',' )
			{
				// move to head
				while( pos > -1 )
				{
					ch = sc.getCharAt( -- pos );
					if( ch == '\t' || ch == ' ' || ch == ';' ||ch == ',' ) break;
				}

				ch = sc.getCharAt( ++ pos );
			}

			ch = sc.getCharAt( pos );

			// look back
			while( ch != '\0' )
			{
				if( ch == ';' || ch == ',' ) break;
				dword ~= ch;
				ch = sc.getCharAt( ++ pos );
			}
			
			try
			{
				word = std.utf.toUTF8( dword );
				std.utf.validate( word ); 		// 檢查是否為有效的 UTF8
			}
			catch
			{
				return;
			}

			word = std.string.strip( word );
			if( word.length )
			{
				CAnalyzerTreeNode easyNode = sAutoComplete.getParserFromProjectParserByModuleName( word );
				if( easyNode !is null )
				{
					resultNode = easyNode;
					if( easyNode.getLeafCount )
						if( easyNode.getLeaf( 0 ).DType & D_MODULE )
						{
							fileFullPath =  easyNode.getLeaf( 0 ).typeIdentifier;
							lineNum = easyNode.getLeaf( 0 ).lineNumber;
							moduleName = easyNode.getLeaf( 0 ).identifier;
						}
				}
			}
		}
	}	
} // end of class DStyle
