module poseidon.controller.debugcontrol.debugPanel;


private import dwt.all;

private import poseidon.controller.editor;
private import poseidon.controller.gui;
private import poseidon.globals;
private import poseidon.i18n.itranslatable;
private import poseidon.controller.debugcontrol.watch;

class TopPanel : CTabFolder
{
	int[]		TopPanelLastWeight, lastSashWeights;
	SashForm	_parent;
	const int	TAB_HEIGHT = 24;
	Composite	tbContainer;	// tool bar container
	
	CDebugItem			debugItem;
	CDebugOutoupItem 	outputItem;
	StackLayout			stackLayout;

	void onTabFolderSelection( Event e ) 
	{
		TopPanel pthis = cast(TopPanel) e.widget;
		CWatchItem item = cast(CWatchItem)e.item;
		pthis.stackLayout.topControl = item.getTbBar(null);
		pthis.tbContainer.layout();		
	}
	
	this( SashForm parent )
	{
		super( parent, DWT.TOP | DWT.BORDER );
		_parent = parent;
		
		initGUI();

		this.handleEvent( null, DWT.Selection, &onTabFolderSelection );
	}
	
	private void initGUI()
	{
		//setMinimizeVisible(true);
		Color[3] 	colorsActive = [DWTResourceManager.getColor(0, 100, 255), DWTResourceManager.getColor(113, 166, 244), null ];
		this.setSelectionBackground( colorsActive, [60, 100], true);
		this.setTabHeight(24);
		this.setSimple(false);
		this.setSelectionForeground(DWTResourceManager.getColor(255,255,255));

		debugItem = new CDebugItem(this);
		outputItem = new CDebugOutoupItem( this );
		this.setSelection(0);
		tbContainer = new Composite(this, DWT.NONE);
		stackLayout = new StackLayout();
		tbContainer.setLayout(stackLayout);
		
		Control top = debugItem.getTbBar(tbContainer);
		outputItem.getTbBar(tbContainer);
		
		stackLayout.topControl = top;
		tbContainer.layout();
		setTopRight(tbContainer);
	}
}


class CDebugItem : CWatchItem
{
private:
	import 		poseidon.controller.debugcontrol.debugger;
	import 		poseidon.model.project;

	ToolItem	tiResume, tiTerminate, tiIn, tiOver, tiReturn;//, tiSuspend;
	Tree		tree;

	char[]		currentStackFrameLocation, currentThreadID;

	void initGUI( Composite parent )
	{
		setImage( Globals.getImage( "debug_exc" ) );
		
		tree = new Tree( parent, DWT.NONE );
		scope font = new Font( getDisplay, "Courier New", 8, DWT.NONE );
		tree.setFont( font );
		this.setControl( tree );

		tree.handleEvent( null, DWT.DefaultSelection, &onTreeDefaultSelection );
	}

	void onTreeDefaultSelection( Event e )
	{
		TreeItem item = cast(TreeItem) e.item;

		char[] data = item.getText();
		int atIndex = std.string.rfind( data, " @ " );
		if( atIndex > -1 )
		{
			if( data[0..7] == "Thread[" )
			{
				// Select Thread Not complete!!!
				int indexID = std.string.find( data, "]" );
				if( indexID > -1 )
				{
					char[] id = data[7..indexID+1];
					if( id == currentThreadID ) return;

					//sGUI.debuggerDMD.selectThread( id, false );
					

				}

			}
			else
			{
				char[] moduleName = data[0..atIndex];
				char[] fileAndLine = data[atIndex+3..length];
				//currentStackFrameLocation = fileAndLine;
				
				int colonIndex = std.string.rfind( fileAndLine, ":" );
				if( colonIndex > 0 )
				{
					currentStackFrameLocation = fileAndLine;
					
					char[] 	filePath = fileAndLine[0..colonIndex];
					char[]	fullPath;
					int 	line = std.string.atoi( fileAndLine[colonIndex+1..length] ) - 1;

					bool bGot;

					if( !std.file.exists( filePath ) )
					{
						if( !std.path.isabs( filePath ) )
						{
							fullPath = std.path.join( CDebugger.projectDir, filePath );

							if( !std.file.exists( fullPath ) )
							{
								foreach( char[] path; Globals.debuggerSearchPath )
								{
									fullPath = std.path.join( path, filePath );
									if( std.file.exists( fullPath ) )
									{
										filePath = fullPath;
										bGot = true;
										break;
									}
								}
							}
							else
							{
								filePath = fullPath;
								bGot = true;
							}
						}
					}
					else
					{
						if( !std.path.isabs( filePath ) )
							if( std.file.exists( std.path.join( CDebugger.projectDir, filePath ) ) ) 
								filePath = std.path.join( CDebugger.projectDir, filePath );

						bGot = true;
					}

					if( !bGot )
					{
						char[] path;
						char[] baseName = std.path.getName( std.path.getBaseName( filePath ) );

						foreach( char[] dir; Globals.debuggerSearchPath )
						{
							fullPath = std.path.join( dir, baseName );
							if( std.file.exists( fullPath ) )
							{
								filePath = fullPath;
								bGot = true;
								break;
							}
						}

						if( !bGot )
						{
							foreach( char[] s; std.string.split( moduleName, "." ) )
							{
								if( s != baseName )
									path = s ~ "\\";
								else
									break;
							}

							path = path ~ std.path.getBaseName( filePath );

							if( sGUI.packageExp.activeProject !is null )
							{
								foreach( char[] dir; sGUI.packageExp.activeProject().projectIncludePaths ~ sGUI.packageExp.activeProject().scINIImportPath )
								{
									fullPath = std.path.join( dir, path );
									if( std.file.exists( filePath ) )
									{
										filePath = fullPath;
										bGot = true;
										break;
									}
								}
							}
						}
					}
					

					if( sGUI.editor.openFile( filePath, null, line, true ) )
					{
						int index;
						scope normalFont = new Font( getDisplay, "Courier New", 8, DWT.NONE );
						scope selectedFont = new Font( getDisplay, "Verdana", 8, DWT.BOLD | DWT.ITALIC  );
						
						foreach( TreeItem ti; item.getParentItem().getItems() )
						{
							if( index > -1 )
							{
								if( ti == item )
								{
									sGUI.debuggerDMD.selectFrame( std.string.toString( index ), false );
									ti.setFont( selectedFont );
									index = -99;
								}
								else
								{
									ti.setFont( normalFont );
									++ index;
								}
							}
							else
								ti.setFont( normalFont );
						}

						if( CDebugger.bLiveUpdateVar ) sGUI.debuggerDMD.dumpVariables( true );
						if( CDebugger.bLiveUpdateDisassembly ) sGUI.debuggerDMD.dumpDisassembly();
					}
				}
			}
		}
	}

public:
	this( CTabFolder parent )
	{
		super( parent );
		initGUI( parent );
		updateI18N();

		//content.handleEvent( content, DWT.MouseDoubleClick, &onDBClick );
	}

	Control getTbBar( Composite container )
	{
		if( tbBar is null)
		{
			tbBar = new Composite( container, DWT.NONE );
			GridLayout gl = new GridLayout();
			tbBar.setLayout(gl);
			with( gl )
			{
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar( tbBar, DWT.FLAT | DWT.HORIZONTAL  );
			toolbar.setLayoutData( new GridData( GridData.HORIZONTAL_ALIGN_END ) );

			with( new ToolItem( toolbar, DWT.SEPARATOR ) )
			{
				setWidth( 50 );
			}

			with( tiResume = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage( Globals.getImage( "debug_resume" ) );
				setDisabledImage( Globals.getImage( "debug_resume_dis" ) );
				setToolTipText( Globals.getTranslation( "debug.tooltip_run" ) );
				setEnabled( false );
				handleEvent( this, DWT.Selection, delegate( Event e ){
					sActionMan.actionDebugExec(e);
				});
			}
		
			with( tiTerminate = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage( Globals.getImage( "progress_stop" ) );
				setDisabledImage( Globals.getImage( "progress_stop_dis" ) );
				setToolTipText( Globals.getTranslation( "debug.tooltip_stop" ) );
				setEnabled( false );
				handleEvent( this, DWT.Selection, delegate( Event e ){
					sActionMan.actionDebugStop(e);
				});
			}

			new ToolItem( toolbar, DWT.SEPARATOR );

			with( tiIn = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage( Globals.getImage( "debug_stepinto" ) );
				setDisabledImage( Globals.getImage( "debug_stepinto_dis" ) );
				setToolTipText( Globals.getTranslation( "debug.tooltip_in" ) );
				setEnabled( false );
				handleEvent( this, DWT.Selection, delegate( Event e ){
					sGUI.debuggerDMD.step( 0 );
					//sActionMan.actionDebugStepInto(e);
				});
			}

			with( tiOver = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage( Globals.getImage( "debug_stepover" ) );
				setDisabledImage( Globals.getImage( "debug_stepover_dis" ) );
				setToolTipText( Globals.getTranslation( "debug.tooltip_over" ) );
				setEnabled( false );
				handleEvent( this, DWT.Selection, delegate( Event e ){
					sGUI.debuggerDMD.step( 1 );
					//sActionMan.actionDebugStepOver(e);
				});
			}

			with( tiReturn = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage( Globals.getImage( "debug_stepreturn" ) );
				setDisabledImage( Globals.getImage( "debug_stepreturn_dis" ) );
				setToolTipText( Globals.getTranslation( "debug.tooltip_ret" ) );
				setEnabled( false );
				handleEvent( this, DWT.Selection, delegate( Event e ){
					sGUI.debuggerDMD.step( 2 );
					//sActionMan.actionDebugStepReturn(e);
				});
			}

			new ToolItem( toolbar, DWT.SEPARATOR );

			with( tiStop = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage(Globals.getImage( "refresh" ) );
				setDisabledImage( Globals.getImage( "refresh_dis" ) );
				setToolTipText( Globals.getTranslation( "pop.refresh" ) );
				setEnabled( false );
				handleEvent(this, DWT.Selection, delegate(Event e)
				{
					//sActionMan.actionListDlls( e );
				});
			}
			updateToolBar();
		}
		
		return tbBar;
	}
	
	//void setBusy( bool busy){ tiTerminate.setEnabled( busy ); }

	void updateI18N(){ this.setText( Globals.getTranslation( "debug.debug" ) );	}

	void updateStackFrame( char[][] data )
	{
		tree.removeAll();

		Project prj = sGUI.packageExp.activeProject();

		if( prj is null ) return;

		char[] exePath;

		if( !prj.projectTargetName.length )
			exePath = prj.projectDir ~ "\\" ~ prj.projectName ~ ".exe";
		else
			exePath = prj.projectDir ~ "\\" ~ prj.projectTargetName ~ ".exe";

	
		TreeItem ti_0 = new TreeItem( tree, DWT.NONE );
		ti_0.setText( std.path.getBaseName( exePath ) );
		ti_0.setImage( Globals.getImage( "debug_misc" ) );

		TreeItem ti_1 = new TreeItem( ti_0, DWT.NONE );
		ti_1.setText( exePath );
		ti_1.setImage( Globals.getImage( "debug_debugthreads" ) );
		
		char[][] threads = sGUI.debuggerDMD.dumpThread( false );

		foreach( char[] s; threads )
		{
			char[][] threadData = std.string.split( s, "><" );

			TreeItem ti_2 = new TreeItem( ti_1, DWT.NONE );
			ti_2.setText( "Thread[" ~ threadData[1] ~ "] @ " ~ threadData[2] );
			ti_2.setImage( Globals.getImage( "debug_threads" ) );
			
			if( threadData[0] == ">" )
			{
				currentThreadID = threadData[1];
				scope selectedFont = new Font( getDisplay, "Verdana", 8, DWT.BOLD | DWT.ITALIC  );
				ti_2.setFont( selectedFont );

				bool 		bBoldStackFrame;
				TreeItem[] 	ttis;
				
				for( int i = 0; i < data.length; ++ i )
				{
					auto _tti = new TreeItem( ti_2, DWT.NONE );
					ttis ~= _tti;

					//if( i == 0 ) tti.setFont( selectedFont );

					_tti.setText( data[i] );

					int atIndex = std.string.rfind( data[i], " @ " );
					if( atIndex > -1 )
					{
						if( currentStackFrameLocation == data[i][atIndex+3..length] )
						{
							_tti.setFont( selectedFont );
							sGUI.debuggerDMD.selectFrame( std.string.toString( i ), false );
							bBoldStackFrame = true;
						}
					}
					
					_tti.setImage( Globals.getImage( "debug_stackframe" ) );
				}

				if( !bBoldStackFrame )
				{
					ttis[0].setFont( selectedFont );
					if( currentStackFrameLocation.length ) sGUI.debuggerDMD.selectFrame( "0", false );
					currentStackFrameLocation = "";
				}
			}

			ti_2.setExpanded( true );
		}

		ti_1.setExpanded( true );
		ti_0.setExpanded( true );		
	}

	void setFirstTreeItem( char[] exePath )
	{
		TreeItem ti = new TreeItem( tree, DWT.NONE );
		ti.setText( std.path.getBaseName( exePath ) );
		ti.setImage( Globals.getImage( "debug_misc" ) );
	}

	void setNoTreeItem()
	{
		if( tree !is null ) tree.removeAll();
		
		TreeItem ti = new TreeItem( tree, DWT.NONE );
		ti.setText( "No StackFrame Information( Process terminated? )" );
		ti.setImage( Globals.getImage( "unknown" ) );
	}
	
	void updateToolBar() 
	{
		if( sGUI.debuggerDMD is null ) return;

		if( !sGUI.debuggerDMD.isPipeCreate() )
		{
			tiResume.setEnabled( false );
			tiTerminate.setEnabled( false );
			tiIn.setEnabled( false );
			tiOver.setEnabled( false );
			tiReturn.setEnabled( false );
		}
		else
		{
			tiResume.setEnabled( true );
			tiTerminate.setEnabled( true );

			if( sGUI.debuggerDMD.isRunning )
			{
				tiIn.setEnabled( true );
				tiOver.setEnabled( true );
				tiReturn.setEnabled( true );
				
			}
			else
			{
				//tiSuspend.setEnabled( false );
				tiIn.setEnabled( false );
				tiOver.setEnabled( false );
				tiReturn.setEnabled( false );
			}
		}
	}

	void clean()
	{
		if( tree !is null ) tree.removeAll();

		currentStackFrameLocation = currentThreadID = "";
	}
}


class CDebugOutoupItem : CWatchItem
{
private:
	ToolItem	tiCommand;

	void initGUI( Composite parent )
	{
		setImage(Globals.getImage("console_view"));

		content = new Text( parent, DWT.MULTI | DWT.WRAP | DWT.V_SCROLL );
		scope font = new Font( display, Editor.settings._setting.outputStyle.font, Editor.settings._setting.outputStyle.size, DWT.NORMAL );
		content.setFont( font );
		this.setControl( content );
	}

public:
	Text		content;
	Text		txtCommandLine;
	
	this( CTabFolder parent )
	{
		super( parent );
		initGUI( parent );
		updateI18N();
		//content.handleEvent( content, DWT.MouseDoubleClick, &onDBClick );
	}

	Control getTbBar( Composite container )
	{
		if( tbBar is null)
		{
			tbBar = new Composite( container, DWT.NONE );
			GridLayout gl = new GridLayout();
			tbBar.setLayout(gl);
			with( gl )
			{
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar( tbBar, DWT.FLAT | DWT.HORIZONTAL  );
			toolbar.setLayoutData( new GridData( GridData.HORIZONTAL_ALIGN_END ) );

			new ToolItem( toolbar, DWT.SEPARATOR );
			ToolItem mother = new ToolItem(toolbar, DWT.SEPARATOR);

			with( txtCommandLine = new Text( toolbar, DWT.BORDER ) )
			{
				mother.setWidth( 120 );
				mother.setControl( txtCommandLine );
				setEnabled( false );
				scope font = new Font( display, "Arial", 8, DWT.NORMAL );
				setFont( font );
				
				handleEvent( this, DWT.KeyDown, delegate( Event e )
				{
					if( e.keyCode == DWT.CR || e.keyCode == DWT.KEYPAD_CR  )
					{
						sGUI.debuggerDMD.consoleCommand();
						//sActionMan.actionDebugCommand(e);
					}
				});
			}			

			with( tiCommand = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage( Globals.getImage( "debug_command" ) );
				setDisabledImage( Globals.getImage( "debug_command_dis" ) );
				setToolTipText( Globals.getTranslation( "debug.tooltip_send" ) );
				setEnabled( false );
				handleEvent( this, DWT.Selection, delegate( Event e )
				{
					sGUI.debuggerDMD.consoleCommand();
					//sActionMan.actionDebugCommand(e);
				});
			}
			
			new ToolItem( toolbar, DWT.SEPARATOR );

			with( new ToolItem( toolbar, DWT.CHECK ) )
			{
				setImage( Globals.getImage( "synced" ) );
				setToolTipText( Globals.getTranslation( "debug.tooltip_cons" ) );
				setSelection( sGUI.debuggerDMD.bShowOutPut );
				handleEvent( this, DWT.Selection, delegate( Event e )
				{
					sGUI.debuggerDMD.bShowOutPut = !sGUI.debuggerDMD.bShowOutPut;
					setSelection( sGUI.debuggerDMD.bShowOutPut );
					if( !sGUI.debuggerDMD.bShowOutPut ) content.setText( "" );
				});				
			}

			with( new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage(Globals.getImage("close_view"));
				setToolTipText( Globals.getTranslation( "debug.tooltip_cleancons" ) );
				handleEvent(this, DWT.Selection, delegate(Event e) {
					CDebugOutoupItem pthis = cast(CDebugOutoupItem) e.cData;
					pthis.content.setText( "" );
				});
			}	

			updateToolBar();
		}
		
		return tbBar;
	}
	
	//void setBusy( bool busy){ tiTerminate.setEnabled( busy ); }

	void updateI18N(){ this.setText(Globals.getTranslation("outputpanel.title")); }

	void updateToolBar() 
	{
		if( sGUI.debuggerDMD is null ) return;

		if( !sGUI.debuggerDMD.isPipeCreate() )
		{
			tiCommand.setEnabled( false );
			txtCommandLine.setEnabled( false );
		}
		else
		{
			tiCommand.setEnabled( true );
			txtCommandLine.setEnabled( true );
		}
	}
}