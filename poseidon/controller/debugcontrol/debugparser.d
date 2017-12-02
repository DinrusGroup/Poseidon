module poseidon.controller.debugcontrol.debugparser;

class CDebugParser
{
public:
	import std.string;
	import dwt.all;
	import poseidon.controller.gui;
	import poseidon.controller.edititem;
	import poseidon.controller.debugcontrol.debugger;
	import poseidon.globals;


	static bool findFileNameAndLineNum( char[] input, inout char[] fileName, inout int lineNum )
	{
		fileName = "";
		lineNum = -1;
		
		if( input.length )
		{
			// 找第一行
			int findIndex = std.string.find( input, "\n" );
			if( findIndex > 0 )
			{
				int spaceIndex = std.string.find( input[0..findIndex], " 0x" );
				if( spaceIndex > 0 )
				{
					int lnIndex = std.string.rfind( input[0..spaceIndex], ":" );
					if( lnIndex > 0 )
					{
						// BreakPoint Hit!!!
						int hitIndex = std.string.find( input[0..spaceIndex], " hit at " );
						if( hitIndex == -1 ) hitIndex = -8;

						fileName = input[hitIndex + 8..lnIndex];
						lineNum = std.string.atoi( input[lnIndex + 1..spaceIndex] );

						char[] fullPath;

						if( !std.file.exists( fileName ) )
						{
							if( !std.path.isabs( fileName ) )
							{
								fullPath = std.path.join( CDebugger.projectDir, fileName );

								if( !std.file.exists( fullPath ) )
								{
									foreach( char[] path; Globals.debuggerSearchPath )
									{
										fullPath = std.path.join( path, fileName );
										if( std.file.exists( fullPath ) )
										{
											fileName = fullPath;
											return true;
										}
									}
								}
								else
								{
									fileName = fullPath;
									return true;
								}
							}
						}
						else
						{
							if( !std.path.isabs( fileName ) ) 
								if( std.file.exists( std.path.join( CDebugger.projectDir, fileName ) ) )
									fileName = std.path.join( CDebugger.projectDir, fileName );

							return true;
						}

						if( !std.file.exists( fileName ) )
						{
							char[] result = sGUI.debuggerDMD.write( "us\n", false );
							int posLine = std.string.find( result, "\n" );
							if( posLine > 3 )
							{
								result = result[0..posLine];
								if( result[0..3] == "#0 " )
								{
									result = std.string.strip( result[3..length] );

									int openparenPos = std.string.find( result, "(" );
									if( openparenPos > 0 )
									{
										char[][] splitModuleName = std.string.split( std.string.strip( result[0..openparenPos] ) );

										if( splitModuleName.length )
										{
											result = splitModuleName[length-1];
											
											char[] path;
											char[] baseName = std.path.getName( std.path.getBaseName( fileName ) );
											foreach( char[] s; std.string.split( result, "." ) )
											{
												if( s != baseName )
													path = s ~ "\\";
												else
													break;
											}

											path = path ~ std.path.getBaseName( fileName );

											foreach( char[] dir; Globals.debuggerSearchPath )
											{
												baseName = std.path.join( dir, path );
												if( std.file.exists( baseName ) )
												{
													fileName = baseName;
													return true;
												}
											}

											if( sGUI.packageExp.activeProject !is null )
											{
												foreach( char[] dir; sGUI.packageExp.activeProject().projectIncludePaths ~ sGUI.packageExp.activeProject().scINIImportPath )
												{
													baseName = std.path.join( dir, path );

													if( std.file.exists( baseName ) )
													{
														fileName = baseName;
														return true;
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}

		return false;
	}

	static void gotoMarkLine( char[] fileName, int lineNum )
	{
		sGUI.packageExp.openFile( fileName, lineNum - 1, true );
		EditItem ei = sGUI.editor.findEditItem( fileName );
		if( ei !is null ) ei.toggleDebugRunMarker( lineNum - 1 );
	}

	static char[][] dumpRegister( char[] input )
	{
		char[][] registers;
		
		char[][] lines = std.string.split( input, "\n" );

		foreach( char[] s; lines )
		{
			if( s.length >= 14 ) registers ~= s[6..14];
			if( s.length >= 29 ) registers ~= s[21..29];
			if( s.length >= 44 ) registers ~= s[36..44];
			if( s.length >= 59 ) registers ~= s[51..59];
		}

		return registers;
	}

	static char[][] dumpStack( char[] input )
	{ 
		return std.string.split( input, "\n" );
	}

	static char[][] listDlls( char[] input )
	{
		return std.string.split( input, "\n" );
	}

	static char[] getType( char[] varName )
	{
		char[] result = sGUI.debuggerDMD.write( "t " ~ varName ~ "\n", false );
		char[][] spltiResult = std.string.split( result, "\n" );

		if( spltiResult.length == 3 )
		{
			if( spltiResult[0].length > 20 )
				if( spltiResult[0][0..20] == "Parser: Parser error" ) return null;

			return spltiResult[1]; // include "->"
		}

		return null;
	}

	static char[] getValue( char[] varName, char[] type, bool bCast = true, bool bReturnFull = false )
	{
		char[] result;

		if( bCast )
			result = sGUI.debuggerDMD.write( "= cast(" ~ type ~ ")" ~ varName ~ "\n", false );
		else
			result = sGUI.debuggerDMD.write( "= " ~ varName ~ "\n", false );
			
		char[][] spltiResult = std.string.split( result, "\n" );

		if( result.length )
		{
			if( !bReturnFull )
				return spltiResult[0];
			else
				return result;
		}

		return null;
	}

	static char[] getExpress( char[] varName )
	{
		char[] result = sGUI.debuggerDMD.write( "= " ~ varName ~ "\n", false );
		if( result.length > 3 )
			if( result[length-3..length] == "\n->" ) result = result[0..length-3];		

		return result;
	}	

	static int hexString2Decimal( char[] text )
	{
		uint	result;

		text = std.string.tolower( text );

		int powIndex = -4;
		if( std.string.count( text, "0x" ) )
		{
			for( int i = text.length - 1; i > 1; -- i )
			{
				int j = cast(int) text[i];
				if( j >= 97 ) j = j - 87;else j = j- 48;

				if( powIndex == -4 ) result += j;else result +=  j * 16 << powIndex;

				powIndex +=4;
			}
		}
		else
			result = std.string.atoi( text );

		return result;
	}

	/+
	static CVariableNode listVariables( char[] input )
	{
		//char[] _scope;
		
		void _parserVar( CVariableNode node, char[] data, char[] _scope )
		{
			int countCaret;
			
			char[][] lines = std.string.split( data, "\n" );

			for( int i = 0; i < lines.length; ++ i )
			{
				char[][] variableAndValue = std.string.split( std.string.strip( lines[i] ), " = " );

				if( variableAndValue.length == 1 )
				{
					if( variableAndValue[0].length > 6 )
					{
						if( variableAndValue[0][0..6] == "Scope:" )
						{
							node = node.add( variableAndValue[0][6..length] );
							/*
							int spacePos = std.string.rfind( variableAndValue[0], " " );
							if( spacePos > -1 )
								node = node.add( variableAndValue[0][spacePos..length] );
							else
								node = node.add( variableAndValue[0][6..length] );
							*/
						}
					}
					else if( variableAndValue[0] == "{" )
					{
						countCaret ++;
					}
					else if( variableAndValue[0] == "}" )
					{
						countCaret --;
						if( _scope.length )
						{
							int dotPos = std.string.rfind( _scope[0..length-1], "." );
							if( dotPos < 0 )
								_scope = "";
							else
								_scope = _scope[0..dotPos+1];
						}						
					}
				}
				else
				{
					char[]	name 	= variableAndValue[0];
					char[]	value 	= variableAndValue[1];
					char[] 	hex;
					char[]	ext;
					bool	bHaveSon;

					if( countCaret != 0 )
						if( value.length > 1 )
							if( value[length - 1] == ',' ) value = value[0..length - 1];

					if( std.string.count( value, "0x" ) )
					{
						hex = value;
						value = std.string.toString( hexString2Decimal( hex ) );
					}
					else if( value == "..." )
					{
						bHaveSon = true;
					}
					else
					{
						if( !std.string.count( value, "." ) )
							hex = "0x" ~ std.string.toString( cast(long) std.string.atoi( value ), cast(uint) 16 );							
					}


					// add _scope name( maybe scope.name or scope[name] )
					char[] varName = _scope ~ name ;
					if( _scope.length && name.length )
					{
						if( _scope[length-1] == '.' && name[0] == '[' )
							varName = _scope[0..length-1] ~ name;
					}

					
					char[] type = getType( varName );
					/+
					if( type == "ulong" )
					{
						char[] valueResult = getValue( _scope ~ name, "char[]" );
						if( valueResult != "null" )	
						{
							ext = "(" ~ valueResult ~ ")";
						}
						else
						{
							value = valueResult;
						}
					}
					else +/if( type == "ubyte[]" )
					{
						char[] valueResult = getValue( _scope ~ name, "char[]" );
						if( valueResult != "null" )	
						{
							ext = "(" ~ valueResult ~ ")";
						}
						else
						{
							value = valueResult;
						}
					}
					else if( type == "ubyte" ) // if( type == "char" )
					{
						int dec = hexString2Decimal( hex ) ;
						value 	= std.string.toString( dec );

						if( dec > 31 && dec < 127 )ext = "('" ~ ( cast(char) hexString2Decimal( hex ) ) ~ "')";
					}

					if( bHaveSon )
					{
						node = node.add( _scope, name, type, value, hex, ext );

						_parserVar( node, getExpress( varName ), varName ~ "." );
						node = node.getRoot();
					}
					else
						node.add( _scope, name, type, value, hex, ext );
				}
			}
		}

		if( sGUI.debuggerDMD.variableBaseRoot !is null ) delete sGUI.debuggerDMD.variableBaseRoot;

		sGUI.debuggerDMD.variableBaseRoot = new CVariableNode( null, null, null );
		
		CVariableNode _activeNode = sGUI.debuggerDMD.variableBaseRoot;

		_parserVar( _activeNode, input, null );

		return _activeNode;
	}
	+/
	
	static char[][] listStackFrame( char[] input )
	{
		char[][] txtFrame;

		if( input.length > 2 ) input = input[0..length-2]; // erase ->
		
		foreach( char[] s; std.string.split( input, "#" ) )
		{
			if( s.length )
			{
				char[] moduleName, args, lineNum;

				// moduleName
				int inPos = std.string.find( s, " in " );
				if( inPos > -1 )
				{
					int openparenPos = std.string.find( s[inPos+4..length], "(" );
					if( openparenPos > -1 )
					{
						char[][] splitModuleName = std.string.split( std.string.strip( s[inPos+4..inPos+4+openparenPos] ) );
						moduleName = splitModuleName[length-1];
					}
					else
						continue;
				}
				else
				{
					// Top stackframe?
					if( s[0] == '0' )
					{
						int openparenPos = std.string.find( s, "(" );
						if( openparenPos > -1 )
						{
							char[][] splitModuleName = std.string.split( std.string.strip( s[1..openparenPos] ) );
							moduleName = splitModuleName[length-1];
						}
					}
					else
						continue;
				}

				// lineNum
				int atPos = std.string.rfind( s, " at " );
				if( atPos > -1 )
				{
					lineNum = s[atPos+4..length];
				}
				else
				{
					// from?
					int fromPos = std.string.rfind( s, " from " );
					if( fromPos > -1 ) lineNum = s[fromPos+6..length];
				}

				// args
				int countCRLF = std.string.count( s, "\n" );
				if( countCRLF == 1 )
				{
					args = "()";
				}
				else if( countCRLF > 1 )
				{
					char[][] splitCRLF = std.string.splitlines( s );
					args = "( args = { ";
					for( int i = 1; i < splitCRLF.length - 1; ++ i )
						args ~= ( std.string.strip( splitCRLF[i] ) ~ " " );

					args ~= "} ) ";
				}
				else
					continue;

				txtFrame ~= ( moduleName ~ args ~ " @ " ~ lineNum );
			}
		}

		return txtFrame;
	}

	static char[][] listThreads( char[] input )
	{
		char[][] threads;
		
		foreach( char[] s; std.string.splitlines( input ) )
		{
			if( s.length > 70 )
				if( s[1] == '*' )
				{
					char[][] locations = std.string.split( s[70..length] );
					if( locations.length > 1 ) threads ~= ( s[0] ~ "><" ~ std.string.strip( s[2..9] ) ~ "><" ~ locations[0] );
				}
		}

		return threads;
	}

	static void step( char[] input )
	{
		char[] 	fileName;
		int 	lineNum;
		
		if( findFileNameAndLineNum( input, fileName, lineNum ) ) gotoMarkLine( fileName, lineNum );

		if( CDebugger.bLiveUpdateVar ) sGUI.debuggerDMD.dumpVariables( true );

		switch( sGUI.debuggerDMD.topRightPanel.getSelectionIndex() )
		{
			case 2:
				sGUI.debuggerDMD.write( "dr\n" );
				break;
			case 3:
				sGUI.debuggerDMD.write( "ds\n" );
				break;
			default:
				break;
		}
	}
}