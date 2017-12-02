module poseidon.controller.gui;

private
{
	import dwt.all;
	import poseidon.controller.bottompanel;
	import poseidon.controller.editor;
	import poseidon.controller.actionmanager;
	import poseidon.controller.menumanager;
	import poseidon.controller.outline;
	import poseidon.controller.packageexplorer;
	import poseidon.controller.statusbar;
	import poseidon.controller.toolbarmanager;
	import poseidon.globals;
	import poseidon.i18n.itranslatable;
	import poseidon.util.layoutshop;
	import poseidon.util.miscutil;
	import poseidon.model.project;
	import poseidon.intellisense.autocomplete;

	import poseidon.controller.filelist;
	import poseidon.controller.debugcontrol.debugger;
}


/**
 * global static members
 */
public static GUI 			sGUI;
public static Shell 		sShell;
public static Display 		sDisplay;
public static ActionManager sActionMan;
public static AutoComplete 	sAutoComplete;

 
class GUI : ITranslatable
{
	private import std.thread;
	private import std.c.windows.windows;
	
	public static bool	isClosing = false;
	
	Composite 		boxContainer;
	MenuManager 	menuMan;
	ToolBarManager 	toolMan;
	CTabFolder		siderTab;

	StatusBar 			statusBar;
	Editor 				editor;
	PackageExplorer 	packageExp;
	OutLine				outline;
	OutputPanel			outputPanel;
	SearchPanel			searchPanel;
	//DebugOutputPanel	debugOutputPanel;
	FileList			fileList;
	CDebugger		   	debuggerDMD;	


	SashForm 	mainSash, topSash, debugSash;

	public this(Display display, Shell mainShell, Shell splashShell)
	{
		sGUI = this;
		sDisplay = display;
		sShell = mainShell;
		sActionMan = new ActionManager();
		
		DWTResourceManager.registerResourceUser(mainShell);
		Globals.initIcons(mainShell);
		
		initComponents();

		// after all controls are created, sync the relationship between these controls
		syncControls();

		updateUserSettings();

		sAutoComplete = new AutoComplete;
		
		sShell.layout();

		if(splashShell){
			MiscUtil.sleep(1000);
			splashShell.dispose();
		}


		if( Globals.fileArgs.length > 1 )
		{
			char[] ext = std.string.tolower( std.path.getExt( Globals.fileArgs[1] ) );
			if( ext == "d" || ext == "di" )
			{
				sGUI.packageExp.openFile( Globals.fileArgs[1], 1 );
			}
			else if( ext == "poseidon" )
			{
				sGUI.packageExp.loadProject( std.path.getDirName( Globals.fileArgs[1] ) );
				toolMan.updateToolBar();
			}			
		}		
	}

	private void syncControls() 
	{
		editor.addEditorListener(outline);
		editor.addEditorListener(packageExp);
		editor.addEditorListener(toolMan);
		editor.addEditorListener(statusBar);
		editor.addEditorListener(fileList);
	}

	private void initComponents()
	{
		sShell.setLayout(LayoutShop.createGridLayout(1, 0, 0, 0, 0, false));
		sShell.setText("Poseidon");
		sShell.setImage(Globals.getImage("d-icon"));
		sShell.handleEvent(null, DWT.Close, delegate(Event e){
			sGUI.onClose(e);
		});

		menuMan = new MenuManager();
		toolMan = new ToolBarManager();

		/** Container for all boxes (Favorites, TabFolder and Newstext) */
		boxContainer = new Composite(sShell, DWT.NONE);
		boxContainer.setLayout(LayoutShop.createGridLayout(1, 2, 2, 2, 2));
		boxContainer.setLayoutData(new GridData(DWT.FILL, DWT.FILL, true, true));

		debugSash = new SashForm( boxContainer, DWT.VERTICAL | DWT.SMOOTH );
		debugSash.setLayoutData(new GridData (GridData.GRAB_VERTICAL | GridData.GRAB_HORIZONTAL | GridData.HORIZONTAL_ALIGN_FILL | GridData.VERTICAL_ALIGN_FILL));

		/+
		
		SashForm watchSash = new SashForm( debugSash, DWT.HORIZONTAL | DWT.SMOOTH);

		TopPanel topPanel = new TopPanel( watchSash );
		//_debugPanel = topPanel.debugItem;

		WatchPanel topRightPanel = new WatchPanel( watchSash );
		//varPanel = topRightPanel.varPanel;
		+/

		debuggerDMD = new CDebugger( debugSash );


		mainSash = new SashForm( debugSash, DWT.VERTICAL | DWT.SMOOTH );
		mainSash.setLayoutData(new GridData (GridData.GRAB_VERTICAL | GridData.GRAB_HORIZONTAL | GridData.HORIZONTAL_ALIGN_FILL | GridData.VERTICAL_ALIGN_FILL));
		topSash = new SashForm(mainSash, DWT.HORIZONTAL | DWT.SMOOTH);
		SashForm topSash2 = new SashForm(topSash, DWT.VERTICAL | DWT.SMOOTH);
		
		siderTab = new CTabFolder( topSash2, DWT.BOTTOM | DWT.H_SCROLL | DWT.BORDER );
		/+


		siderTab.handleEvent(siderTab, DWT.MouseDoubleClick, delegate(Event e)
		{
			CTabFolder st = (cast(CTabFolder)e.cData);
			SashForm sash = cast(SashForm) st.getParent();

			if(e.button == 1){
				//MessageBox.showMessage( "ddd" );
				if(sash.getMaximizedControl())
					sash.setMaximizedControl(null);
				else
					sash.setMaximizedControl(st);
			}
		});
		+/
		debugSash.setMaximizedControl(mainSash);

		fileList = new FileList( topSash2,DWT.NONE );
		
		editor = new Editor(topSash);

		// Below code is from Veronika Irvine http://dev.eclipse.org/newslists/news.eclipse.platform.swt/msg04442.html
		Listener listener = new class Listener
		{
			bool drag = false;
			bool exitDrag = false;
			EditItem dragItem;
			
			public void handleEvent( Event e )
			{
				Point p = new Point( e.x, e.y );
				if( e.type == DWT.DragDetect )
				{
					p = editor.toControl( sDisplay.getCursorLocation() ); //see bug 43251
				}
			
				switch( e.type )
				{
					case DWT.DragDetect:
						EditItem item = cast(EditItem) editor.getItem(p);
						if( item is null ) return;
						drag = true;
						exitDrag = false;
						dragItem = item;
						auto hand = sDisplay.getCurrent().getSystemCursor( DWT.CURSOR_HAND );
						sShell.getShell().setCursor( hand );
						break;

					case DWT.MouseEnter:
						if( exitDrag )
						{
							exitDrag = false;
							drag = e.button != 0;
						}
						break;

					case DWT.MouseExit:
						if( drag )
						{
							editor.setInsertMark( null, false );
							exitDrag = true;
							drag = false;
						}
						break;
						
					case DWT.MouseUp:
						if( !drag ) return;
						editor.setInsertMark( null, false );
						CTabItem item = editor.getItem( new Point( p.x, p.y ) );
						if( item !is null )
						{
							Rectangle rect = item.getBounds();
							boolean after = p.x > rect.x + rect.width / 2;
							int index = editor.indexOf( item );
							index = after ? index + 1 : index; // index -1;
							index = Math.max( 0, index );

							EditItem _editItem = dragItem;

							EditItem newItem = new EditItem( editor, _editItem.iteminfo, _editItem.getFileName, _editItem.scintilla, _editItem.fileParser, _editItem.filetime, index );
							newItem.setText( dragItem.getText() );
							newItem.setToolTipText( dragItem.getFileName() );
							Control c = dragItem.getControl();
							dragItem.setControl( null );
							newItem.setControl( c );
							dragItem.dispose();
							editor.setSelectionAndNotify( newItem );
						}
						drag = false;
						exitDrag = false;
						dragItem = null;
						sShell.getShell().setCursor( null );
						break;

					case DWT.MouseMove:
						if( !drag ) return;
						CTabItem item = editor.getItem( new Point( p.x, p.y ) );
						if( item is null )
						{
							auto no = sDisplay.getCurrent().getSystemCursor( DWT.CURSOR_NO );
							sShell.getShell().setCursor( no );							
							editor.setInsertMark( null, false );
							return;
						}
						Rectangle rect = item.getBounds();
						boolean after = p.x > rect.x + rect.width/2;
						editor.setInsertMark( item, after );
						auto hand = sDisplay.getCurrent().getSystemCursor( DWT.CURSOR_HAND );
						sShell.getShell().setCursor( hand );
						break;
				}
			}
		};

		editor.addListener(DWT.DragDetect, listener);
		editor.addListener(DWT.MouseUp, listener);
		editor.addListener(DWT.MouseMove, listener);
		editor.addListener(DWT.MouseExit, listener);
		editor.addListener(DWT.MouseEnter, listener);
		
		
		int[] arWeight = new int[2];
		arWeight[0] = 25;
		arWeight[1] = 75;
		topSash.setWeights(arWeight);
		debugSash.setWeights( [20, 80] );		

		// Package Explorer
		packageExp = new PackageExplorer(siderTab, editor);
		// OutLine
		outline = new OutLine(siderTab, DWT.NONE);
		siderTab.setSelection(0);
		
		// the bottom ctabfolder
		BottomPanel bottomPanel = new BottomPanel(mainSash);
		
		outputPanel = bottomPanel.outputPanel;
		searchPanel = bottomPanel.searchPanel;
		//debugOutputPanel = bottomPanel.debugOutputPanel;

		// do this after all controls added, and the array length same to control count
		mainSash.setWeights(arWeight.reverse);

		statusBar = new StatusBar(boxContainer);
		boxContainer.forceFocus();

		if( Globals.ExplorerWeight[0] > 0 )
			topSash.setWeights( Globals.ExplorerWeight );
			
		if( Globals.BottomPanelWeight[0] > 0 )
			mainSash.setWeights( Globals.BottomPanelWeight );
		else
		{
			if( Globals.BottomPanelLastWeight[0] > 0 )
			{
				bottomPanel.lastSashWeights = new int[2];
				bottomPanel.lastSashWeights[0..2] = Globals.BottomPanelLastWeight[0..2];
				bottomPanel.setMinimized(true);
			}
		}
	}

	package void onClose(Event e)
	{
		// collect opened file names before editor close all
		char[][] openedFiles = editor.getFileNames();
		
		if(!editor.closeAll())
			e.doit = false;
		else{
			// save work space here
			saveWorkSpace(openedFiles);
			sGUI.packageExp.closeAllProject();
			Globals.shellBounds = sShell.getBounds();
			Globals.isShellMaximized = sShell.getMaximized();
			Globals.saveConfig();
			isClosing = true;
		}
	}

	
	

	/** Runs the event loop for RSSOwl */
	private void runEventLoop() {

		/**
		 * This is not very good style, but I will catch any exception, to log and display the message!
		 */
		try {
			while (!sShell.isDisposed()) {
				if (!sDisplay.readAndDispatch()) {
					
					if( Display.copyData.length )
					{
						char[] ext = std.string.tolower( std.path.getExt( Display.copyData ) );
						if( ext == "d" || ext == "di" ) 
							sGUI.packageExp.openFile( Display.copyData, 1 );
						else if( ext == "poseidon" )
						{
							sGUI.packageExp.loadProject( std.path.getDirName( Display.copyData ) );
							toolMan.updateToolBar();
						}
							
						//MessageBox.showMessage( Display.copyData );
						Display.copyData = null;
					}

					sDisplay.sleep();
				}
			}
		} catch (Exception e) {

			/** Log and sDisplay Message */
			// logger.log("runEventLoop (Unforseen Exception)", e);
			// logger.logCritical("runEventLoop (Unforseen Exception)", e);

			/** Ask the user if he wants to send the report */
			// int result = MessageBox.showMessage(Globals.getTranslation("ERROR_UNEXPECTED")
				// , i18n.getTranslation("MESSAGE_BOX_TITLE_ERROR")
				// , sShell
				// , DWT.YES | DWT.NO | DWT.ICON_ERROR);

			/** Call the mail application if the user wants to send the error report */
			// if (result == DWT.YES)
				// BrowserShop.openLink(URLShop.createErrorReport());
		}

		// run debuggerDMD destructor 
		if( debuggerDMD !is null )
			if( debuggerDMD.isPipeCreate() ) delete debuggerDMD;
			
		/** Dispose sDisplay */
		sDisplay.dispose();
	}

	private void loadWorkSpace()
	{
		// nested class 
		class __Thread : Thread {
			char[][] prjs;
			char[][] files;
			int delegate(char[][] prjs, char[][] files) _dg;
			// override the base class method
			int run()
			{
				if(_dg)
					return _dg(prjs, files);
				return -1;
			}
		}
		
		
		// code start here
		char[][] openedPrjs;
		char[][] openedFiles;

		if(Globals.loadWorkSpace(openedPrjs, openedFiles)){
			
			__Thread thread = new __Thread();
			thread.prjs = openedPrjs;
			thread.files = openedFiles;
			thread._dg = &loadWorkSpaceThreadRoutine;
			thread.run();
		}
	}

	private int loadWorkSpaceThreadRoutine(char[][] openedPrjs, char[][] openedFiles) {
		
		foreach(char[] prjName; openedPrjs) {
			sDisplay.asyncExec(new StringObj(prjName), delegate(Object args){
				StringObj obj = cast(StringObj)args;
				if(!sGUI.packageExp.isDisposed()){
					sGUI.packageExp.loadProject(obj.data);
					// another background thread is started to parse the project
					MiscUtil.sleep(50);
				}
			});
		}

		foreach(char[] fileName; openedFiles) {
			sDisplay.asyncExec(new StringObj(fileName), delegate(Object args){
				StringObj obj = cast(StringObj)args;
				if(!sGUI.packageExp.isDisposed()){
					sGUI.packageExp.openFile(obj.data, -1, false);
					// another background thread is started to parse the file and build the syntax tree
					// give more time
					MiscUtil.sleep(50);
				}
			});
		}
		
		return 0;
	}

	private void saveWorkSpace(char[][] openedFiles)
	{
		char[][] openedPrjs;
		foreach(Project prj; packageExp.getProjects()){
			openedPrjs ~= prj.projectDir;
		}

		Globals.saveWorkSpace(openedPrjs, openedFiles);
	}

	public void showGui(){
		sShell.open();

		if(Globals.loadWorkSpaceAtStart){
			loadWorkSpace();
		}

		if( Globals.useDefaultParser )
			if( sAutoComplete !is null )
				foreach( char[] dir; Globals.defaultParserPaths ) sAutoComplete.loadDefaultParser( Globals.appDir ~ "\\ana\\" ~ dir );		

		if( sAutoComplete !is null ) 
			if( !sAutoComplete.loadRuntimeParser() ) MessageBox.showMessage( "Load D Runtime Parser Error!" );
		
		/** Start the event loop to read and dispatch events */
		runEventLoop();
	}

	public void toggleBottomTabState() {
		assert(mainSash);
		assert(topSash);
		
		if(mainSash.getMaximizedControl())
			mainSash.setMaximizedControl(null);
		else
			mainSash.setMaximizedControl(topSash);
	}
	
	public void toggleSiderTabState() {
		editor.toggleMaximized();
	}

	public void updateI18N()
	{
		menuMan.updateI18N();
		toolMan.updateI18N();
		
		// ...
		packageExp.updateI18N();
		outline.updateI18N();
		editor.updateI18N();
		outputPanel.updateI18N();
		searchPanel.updateI18N();
		//debugOutputPanel.updateI18N();
	}

	private void updateUserSettings()
	{
		/** Shell Properties */
		boolean isMaximized = Globals.isShellMaximized;
		Rectangle bounds = Globals.shellBounds;
		int monitorCount = sDisplay.getMonitors().length;
	
		/** Shell setup for one monitor */
		if (monitorCount <= 1) {

		/** Maximized State */
		  if (isMaximized)
			sShell.setMaximized(isMaximized);
	
		  /** Bounds */
		  if (bounds !is null && !isMaximized)
			sShell.setBounds(bounds);
		}
	
		/** Shell setup for two or more monitors */
		else {
	
		  /** Bounds */
		  if (bounds !is null)
			sShell.setBounds(bounds);
	
		  /** Maximized State */
		  if (isMaximized)
			sShell.setMaximized(isMaximized);
		}

		toolMan.updateToolBar();
		statusBar.updateStatusBar();
	}
	
}