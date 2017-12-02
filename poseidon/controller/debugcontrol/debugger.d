module poseidon.controller.debugcontrol.debugger;

class CDebugger
{
private:
	import dwt.all;
	import poseidon.controller.debugcontrol.debugPanel;
	import poseidon.controller.debugcontrol.watch;
	import poseidon.controller.debugcontrol.pipe;

	import poseidon.model.executer;
	import poseidon.model.misc;
	import poseidon.controller.gui;
	import poseidon.controller.edititem;
	import poseidon.controller.debugcontrol.debugparser;

	import poseidon.controller.dialog.generaldialog;

	SashForm					_parent;
	SashForm 					_brother;
	SashForm 					debugSash;
	
	CDebugItem					debugItem;
	CDebugOutoupItem			outputItem;
	CVariableItem				varItem;
	CBreakPointItem				bpItem;
	CRegisterItem				regItem;
	CStackItem					stackItem;
	CDllItem					dllItem;
	CDisassemblyItem			disassemblyItem;
	
	CPipe						pipe;

	bool						bStarted;

	void updateRegisters( char[][] regs ){ regItem.updateItems( regs );	}

	void updateStack( char[][] stacks )
	{
		stackItem.clean( false );
		foreach( char[] s; stacks )
			if( s.length > 2 ) stackItem.add( s );
	}

	void listDll( char[][] dlls )
	{
		dllItem.clean( false );
		foreach( char[] s; dlls )
		{
			char[][] baseAndName = std.string.split( s, " " );
			if( baseAndName.length > 1 ) 
				if( baseAndName[0] != "Name" && baseAndName[0] != "Base" ) dllItem.add( baseAndName );
		}
	}

	//void updateVariables(){	varItem.updateVariables(); }


public:
	static bool		bShowOutPut = true;
	static bool 	bLiveUpdateVar;
	static bool		bLiveUpdateDisassembly;
	
	
	CWatchPanel 	topRightPanel;

	static char[]	projectDir;
	
	this( SashForm parent )
	{
		debugSash = new SashForm( parent, DWT.HORIZONTAL | DWT.SMOOTH);

		TopPanel topLeftPanel = new TopPanel( debugSash );
		debugItem = topLeftPanel.debugItem;
		outputItem = topLeftPanel.outputItem;

		topRightPanel 	= new CWatchPanel( debugSash );
		varItem 		= topRightPanel.varItem;
		bpItem 			= topRightPanel.bpItem;
		regItem		 	= topRightPanel.regItem;
		stackItem 		= topRightPanel.stackItem;
		dllItem			= topRightPanel.dllItem;
		disassemblyItem = topRightPanel.disassemblyItem;
		
		debugSash.setWeights( [40, 60] );
	}

	~this()
	{
		if( pipe !is null ) delete pipe;

		bStarted = false;
		projectDir = "";
	}

	// GUI Function
	void hide( bool bTrue )
	{
		if( bTrue )
			debugSash.setMaximizedControl( _brother );
		//else
			//debugSash.setMaximizedControl( this );
	}

	void setBrotherSashForm( SashForm broSash ){ _brother = broSash; }

	void clear(){ outputItem.content.setText( "" ); }
	
	void setString( char[] str ){ if( bShowOutPut ) outputItem.content.setText( str ); }

	void appendString( char[] str ){ if( bShowOutPut ) outputItem.content.append( str ); }

	void appendLine( char[] str ){ if( bShowOutPut ) outputItem.content.append( str ~ "\n" ); }
	
	// Debug Function-------------------------------------------------------------------
	bool execDebugger( ToolEntry entry, char[] _projectDir )
	{
		if( pipe is null )
		{
			if( sGUI.debugSash.getMaximizedControl() )
			{
				sGUI.debugSash.setMaximizedControl( null );
				sGUI.menuMan.viewDebugItem.setSelection( true );
			}

			outputItem.content.setText( "" );
			pipe = new CPipe( entry );
			if( pipe !is null )
			{
				if( pipe.isError() )
				{
					outputItem.content.setText( "Debugger is Terminated!!\n" );
					bStarted = false;
					
					delete pipe;
					return false;
				}
				else
					resetToolBar();
			}
			else
				return false;
		}

		// We have Debug Items
		foreach( TableItem ti; bpItem.getAllItems() )
		{
			if( ti.getChecked() )
			{
				char[] fileName = std.string.strip( ti.getText( 3 ) );
				if( std.path.isabs( fileName ) ) fileName = std.string.replace( fileName, _projectDir ~ "\\", "" );
				
				pipe.sendCommand( "bp " ~ fileName ~ ":" ~ std.string.strip( ti.getText( 2 ) ) ~ "\n" );
				
			}
		}

		projectDir = _projectDir;
		debugItem.setFirstTreeItem( entry.args );
		return true;
	}

	char[] write( char[] command, bool bShow = true )
	{
		if( pipe !is null ) return pipe.sendCommand( command, bShow );
		return null;
	}

	void read(){ if( pipe !is null ) pipe.readConsole(); }
	
	bool isPipeCreate(){ if( pipe is null ) return false;else return true; }

	void resume() 
	{
		if( isPipeCreate() ) 
		{
			write( "r\n" );
			bStarted = true;
			resetToolBar();
			dumpStackFrame( false );
			if( bLiveUpdateVar ) sGUI.debuggerDMD.dumpVariables( false );
			if( bLiveUpdateDisassembly ) sGUI.debuggerDMD.dumpDisassembly();
		}
	}
	
	void stop()
	{ 
		if( pipe !is null )
		{
			delete pipe;
			EditItem[] eis = cast(EditItem[]) sGUI.editor.getItems();
			// 刪掉所有的執行MARK
			foreach( EditItem ei; eis )
				ei.deleteAllDebugRunMarker();

			outputItem.txtCommandLine.setText( "" );
			
			debugItem.clean();

			varItem.clean();
			regItem.clean();
			stackItem.clean();
			dllItem.clean();
			disassemblyItem.clean();

			outputItem.content.setText( "Debugger is Terminated!!\n" );

			bStarted = false;
		}
	}

	void consoleCommand()
	{
		if( !isPipeCreate()) return;
		
		char[] result = std.string.strip( outputItem.txtCommandLine.getText() );

		if( result.length )
		{
			bool bTemp = bShowOutPut;
			bool bRefreshVar;
			
			bShowOutPut = true;
			if( result == "q" )
			{
				sActionMan.actionDebugStop( null );
				return;
			}
			else
			{
				char[][] commands = std.string.split( result );

				switch( commands[0] )
				{
					case "r"		: if( commands.length == 1 ) resume();			break;
					case "in"		: if( commands.length == 1 ) step( 0, true ); 	break;
					case "ov"		: if( commands.length == 1 ) step( 1, true ); 	break;
					case "out"		: if( commands.length == 1 ) step( 2, true ); 	break;

					case "bp":
						if( commands.length > 1 )
						{
							char[][] splitColon = std.string.split( commands[1], ":" );

							if( splitColon.length == 2 ) // file:linenum
							{
								if( commands.length == 2 )
									addBP_editor( splitColon[0], std.string.atoi( splitColon[1] ), projectDir ); // bp file:linenum
								else if( commands.length == 3 )
									addBP_editor( splitColon[0], std.string.atoi( splitColon[1] ), std.string.atoi( commands[2] ), projectDir );
							}
						}
						break;
						
					case "dbp":
						if( commands.length == 2 )
						{
							if( commands[1] == "*" ) // del all
							{
								bpItem.cleanAllBps();
							}
							else
							{
								char[][] splitColon = std.string.split( commands[1], ":" );
								if( splitColon.length == 1 ) // dbp index
								{
									delBP_editor( splitColon[0] );
								}
								else
								{
									delBP_editor( splitColon[0], std.string.atoi( splitColon[1] ) );
								}
							}
						}
						break;
						
					case "ed", "el":
						bRefreshVar = true;
					default:
						write( result ~ "\n" );
				}
			}

			bShowOutPut = bTemp;
			outputItem.txtCommandLine.selectAll();
			if( bRefreshVar ) dumpVariables( false, true );
		}
	}
		
	void addBP_editor( char[] fullPath, int lineNum, char[] _projectDir = null )
	{
		char[] moduleName;
		if( std.path.isabs( fullPath ) )
			moduleName = std.string.replace( fullPath, _projectDir ~ "\\", "" );
		else
			moduleName = fullPath;			

		if( isPipeCreate )
		{
			char[] result = write( "bp " ~ moduleName ~ ":" ~ std.string.toString( lineNum ) ~ "\n" );

			int setPos = std.string.find( result, "Breakpoint set: " );
			if( setPos > -1 )
			{
				setPos += 16;
				int namePos = std.string.rfind( result, ":" );
				if( namePos > -1 ) fullPath = result[setPos..namePos]; else return;
			}
			else
				return;
		}

		bpItem.add( fullPath, moduleName, lineNum );
	}

	void addBP_editor( char[] fullPath, int lineNum, int id, char[] _projectDir = null )
	{
		char[] moduleName;
		if( std.path.isabs( fullPath ) )
			moduleName = std.string.replace( fullPath, _projectDir ~ "\\", "" );
		else
			moduleName = fullPath;	
		
		if( isPipeCreate )
		{
			char[] result = write( "bp " ~ moduleName ~ ":" ~ std.string.toString( lineNum ) ~ " " ~ std.string.toString( id ) ~ "\n" );
			
			int setPos = std.string.find( result, "Breakpoint set: " );
			if( setPos > -1 )
			{
				setPos += 16;
				int namePos = std.string.rfind( result, ":" );
				if( namePos > -1 ) fullPath = result[setPos..namePos]; else return;
			}
			else
				return;
		}

		bpItem.add( fullPath, moduleName, lineNum, id );
	}	

	void delBP_editor( char[] id )
	{
		write( "dbp " ~ id ~ "\n" );
		bpItem.del( std.string.atoi( id ) );
	}
	
	void delBP_editor( char[] fullPath, int lineNum )
	{
		write( "dbp " ~ fullPath ~ ":" ~ std.string.toString( lineNum ) ~ "\n" );
		bpItem.del( fullPath, lineNum );
	}

	void resetToolBar()
	{
		debugItem.updateToolBar();
		outputItem.updateToolBar();
		regItem.updateToolBar();
		stackItem.updateToolBar();
		varItem.updateToolBar();
		dllItem.updateToolBar();
		disassemblyItem.updateToolBar();
	}

	void step( int flag, bool bShow = true )
	{
		if( !isPipeCreate() || !bStarted ) return;
		
		char[] result;
		
		switch( flag )
		{
			case 0: // step into
				result = write( "in\n", bShow );
				break;

			case 1: // step over
				result = write( "ov\n", bShow );
				break;

			case 2: // step return
				result = write( "out\n", bShow );
				break;

			default:
				return;
		}

		dumpStackFrame( false );
		if( bLiveUpdateDisassembly ) disassemblyItem.disassemblyLine( null );
		CDebugParser.step( result );
	}

	void dumpRegister( bool bShow = true )
	{
		if( !isPipeCreate() || !bStarted ) return;
		
		char[] result = write( "dr\n", bShow );
		updateRegisters( CDebugParser.dumpRegister( result ) );
	}

	void dumpStack( bool bShow = true )
	{
		if( !isPipeCreate() || !bStarted ) return;
		
		char[] result = write( "ds\n", bShow );
		updateStack( CDebugParser.dumpStack( result ) );
	}

	void dumpDll( bool bShow = true )
	{
		if( !isPipeCreate() || !bStarted ) return;
		
		char[] result = write( "ldll\n", bShow );
		listDll( CDebugParser.listDlls( result ) );
	}

	void dumpVariables( bool bShow = true, bool bForceRefresh = false )
	{
		if( !isPipeCreate() || !bStarted ) return;
		
		char[] result = sGUI.debuggerDMD.write( "lsv\n", bShow );
		varItem.parseLSV( result, bForceRefresh );
		//updateVariables();
	}

	void dumpStackFrame( bool bShow = true )
	{
		if( !isPipeCreate() || !bStarted ) return;
		
		char[] result = sGUI.debuggerDMD.write( "us\n", bShow );
		char[][] treedata = CDebugParser.listStackFrame( result );
		if( treedata.length ) debugItem.updateStackFrame( treedata );else debugItem.setNoTreeItem();
	}

	char[][] dumpThread( bool bShow = true )
	{
		if( !isPipeCreate() || !bStarted ) return null;
		
		char[] result = sGUI.debuggerDMD.write( "lt\n", bShow );
		return CDebugParser.listThreads( result );
	}

	void selectThread( char[] id, bool bShow = true )
	{
		if( !isPipeCreate() || !bStarted ) return null;
		
		char[] result = sGUI.debuggerDMD.write( "st " ~ id ~ "\n", bShow );
	}

	void selectFrame( char[] number, bool bShow = true )
	{
		if( !isPipeCreate() || !bStarted ) return null;
		
		char[] result = sGUI.debuggerDMD.write( "f " ~ number ~ "\n", bShow );
	}

	void dumpDisassembly()
	{
		if( !isPipeCreate() || !bStarted ) return null;

		disassemblyItem.disassemblyLine( null );
	}
	
	bool isRunning(){ return bStarted; }
}
