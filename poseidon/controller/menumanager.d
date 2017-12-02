module poseidon.controller.menumanager;

private import dwt.all;

private import poseidon.globals;
private import poseidon.model.project;
private import poseidon.controller.gui;
private import poseidon.controller.actionmanager;
private import poseidon.i18n.itranslatable;
private import poseidon.model.misc;


class MenuManager : ITranslatable
{
	private import poseidon.controller.edititem;
	private import poseidon.controller.editor;
	private import poseidon.util.registerutil;
	
	Menu 	menubar;
	Menu	extToolMenu;
	Menu	recentMenu;
	Menu	projectMenu;
	private Menu	documentMenu;

	public 	MenuItem	saveItem, saveasItem, saveallItem, closefileItem, closeprjItem, closeallprjItem,
						undoItem, redoItem,	cutItem, copyItem, pasteItem, selectallItem,
						togglecommentItem, streamcommentItem, boxcommentItem, nestcommentItem,
						findItem, findListItem, gotoItem, viewDebugItem, classBrowserItem,
						compileItem, runItem, buildItem, build_runItem, rebuildItem, BudItem, cleanItem,
						debugItem, debugbuildItem, debuginItem, debugrunItem, debugoverItem, debugreturnItem, debugstopItem, debugcleanbpsItem,
						encodeItem, registerItem, documentItem;
						
	// static properties
	private static MenuManager  pthis;

	public this()
	{
		pthis = this;
		initComponents();
		updateI18N();
	}

	private void initComponents()
	{
		menubar = new Menu(sShell, DWT.BAR);
		sShell.setMenuBar(menubar);

		// File Menu
		MenuItem barItem = new MenuItem(menubar, DWT.CASCADE);
		barItem.setData(LANG_ID, "menu.file");
		Menu menu = new Menu(barItem);
		barItem.setMenu(menu);

		/// file.newfile
		with(new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("newfile"));
			setData( LANG_ID, "file.newfile" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionNewFile(e);
			});
		}

		/// file.openfile
		with(new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("fldr"));
			setData( LANG_ID, "file.openfile" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionOpenFile(e);
			});
		}

		/// file.save
		with( saveItem = new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("save"));
			setData( LANG_ID, "file.save" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionSave(e);
			});
		}

		/// file.saveas
		with( saveasItem = new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("save_as"));
			setData( LANG_ID, "file.saveas" );
			setEnabled( false );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionSaveAs(e);
			});
		}

		/// file.saveall
		with(saveallItem = new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("save_all"));
			setData( LANG_ID, "file.saveall" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionSaveAll(e);
			});
		}
		
		/// file.closefile
		with( closefileItem = new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("close_view"));
			setData( LANG_ID, "file.closefile" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionCloseFile(e);
			});
		}


		new MenuItem(menu, DWT.SEPARATOR);
		
		/// file.newprj
		with(new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("newprj_wiz"));
			setData( LANG_ID, "file.newprj" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionNewProject(e);
			});
		}

		/// file.openprj
		with(new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("project_obj"));
			setData( LANG_ID, "file.openprj" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionOpenProject(e);
			});
		}

		/// file.closeprj
		with(closeprjItem = new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("uninstall_wiz"));
			setData( LANG_ID, "file.closeprj" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionCloseProject(e);
			});
		}

		/// file.closeallprj
		with(closeallprjItem = new MenuItem(menu, DWT.PUSH)){
			//setImage(Globals.getImage("uninstall_wiz"));
			setData( LANG_ID, "file.closeallprjs" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionCloseAllProject(e);
			});
		}
		
		new MenuItem(menu, DWT.SEPARATOR);
		
		/// file.mruprjs
		with(new MenuItem(menu, DWT.CASCADE)){
			setData( LANG_ID, "file.mruprjs" );
			setMenu(getRecentPrjMenu());
			handleEvent(null, DWT.Arm, delegate(Event e){
				(cast(MenuItem)e.widget).setMenu(pthis.getRecentPrjMenu());
			});
		}

		new MenuItem(menu, DWT.SEPARATOR);
		
		/// file.exit
		with(new MenuItem(menu, DWT.PUSH)){
			setData( LANG_ID, "file.exit" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionExit(e);
			});
		}
	
		// edit menu
		barItem = new MenuItem(menubar, DWT.CASCADE);
		barItem.setData(LANG_ID, "menu.edit");
		menu = new Menu(barItem);
		barItem.setMenu(menu);

		// edit.undo
		with( undoItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "undo" ) );
			setData( LANG_ID, "edit.undo" );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sActionMan.actionUndo( e );
			});
		}

		// edit.redo
		with( redoItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "redo" ) );
			setData( LANG_ID, "edit.redo" );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sActionMan.actionRedo( e );
			});
		}

		new MenuItem( menu, DWT.SEPARATOR );

		// edit.cut
		with( cutItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "cut" ) );
			setData( LANG_ID, "edit.cut" );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sActionMan.actionCut( e );
			});
		}

		// edit.copy
		with( copyItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "copy" ) );
			setData( LANG_ID, "edit.copy" );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sActionMan.actionCopy( e );
			});
		}			

		// edit.paste
		with( pasteItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "paste" ) );
			setData( LANG_ID, "edit.paste" );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sActionMan.actionPaste( e );
			});
		}
		
		// edit.selectall
		with( selectallItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setData( LANG_ID, "edit.selectall" );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sGUI.editor.direct2EditItemHSU( 3 );
			});
		}

		new MenuItem( menu, DWT.SEPARATOR );
		
		// edit.togglecomment
		with( togglecommentItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setData( LANG_ID, "edit.togglecomment" );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sGUI.editor.direct2EditItemHSU( 4 );
			});
		}
		
		// edit.streamcomment
		with( streamcommentItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setData( LANG_ID, "edit.streamcomment" );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sGUI.editor.direct2EditItemHSU( 5 );
			});
		}		

		// edit.boxcomment
		with( boxcommentItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setData( LANG_ID, "edit.boxcomment" );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sGUI.editor.direct2EditItemHSU( 6 );
			});
		}		


		// edit.nestcomment
		with( nestcommentItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setData( LANG_ID, "edit.nestcomment" );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sGUI.editor.direct2EditItemHSU( 9 );
			});
		}	

		// Search menu
		barItem = new MenuItem( menubar, DWT.CASCADE );
		barItem.setData(LANG_ID, "menu.search");
		menu = new Menu(barItem);
		barItem.setMenu(menu);

		/// search.properties
		with( findItem = new MenuItem(menu, DWT.PUSH))
		{
			setData( LANG_ID, "search.find" );
			setImage( Globals.getImage( "find" ) );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sGUI.editor.direct2EditItemHSU( 7 );
			});
		}

		/// search.properties
		with( findListItem = new MenuItem(menu, DWT.PUSH))
		{
			setData( LANG_ID, "search.searchinfile" );
			setImage( Globals.getImage( "search" ) );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sGUI.editor.showSearchDlg();
			});
		}
		new MenuItem( menu, DWT.SEPARATOR );

		/// Search.goto
		with( gotoItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setData( LANG_ID, "search.goto" );
			setImage( Globals.getImage( "goto" ) );
			handleEvent( this, DWT.Selection, delegate(Event e){
				sGUI.editor.direct2EditItemHSU( 8 );
			});
		}

		// view
		barItem = new MenuItem( menubar, DWT.CASCADE );
		barItem.setData( LANG_ID, "menu.view" );
		menu = new Menu( barItem );
		barItem.setMenu( menu );

		with( viewDebugItem = new MenuItem( menu, DWT.CHECK ) )
		{
			setImage( Globals.getImage( "debug_exc" ) );
			setData( LANG_ID, "view.debug" );
			handleEvent( this, DWT.Selection, delegate( Event e ){
				if( !sGUI.debugSash.getMaximizedControl() )
					sGUI.debugSash.setMaximizedControl( sGUI.mainSash );
				else
					sGUI.debugSash.setMaximizedControl( null );
			});
		}

		with( classBrowserItem = new MenuItem( menu, DWT.CHECK ) )
		{
			setImage( Globals.getImage( "package" ) );
			setData( LANG_ID, "view.class" );
			setSelection( true );
			handleEvent( this, DWT.Selection, delegate( Event e ){
				sGUI.editor.toggleMaximized();
			});
		}

		/+
		with( new MenuItem( menu, DWT.CHECK ) )
		{
			setText( "Bottom Panel" );
			/+
			handleEvent(this, DWT.Selection, delegate(Event e){
				sGUI.editor.direct2EditItemHSU( 7 );
			});
			+/
		}
		+/

		// project menu
		barItem = new MenuItem(menubar, DWT.CASCADE);
		barItem.setData(LANG_ID, "menu.project");
		menu = new Menu(barItem);
		barItem.setMenu(menu);
		projectMenu = menu;
		projectMenu.handleEvent(null, DWT.Show, delegate(Event e){
			boolean enabled = sGUI.packageExp.getProjectCount() > 0;
			Menu menu = cast(Menu)e.widget;
			foreach(MenuItem item; menu.getItems())
			{
				item.setEnabled(enabled);
			}
		});

		/// prj.properties
		with(new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("property"));
			setData( LANG_ID, "prj.properties" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionShowPrjProperty(e);
			});
		}

		/// prj.close
		with(new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("uninstall_wiz"));
			setData( LANG_ID, "prj.close" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionCloseProject(e);
			});
		}

		// prj.zip
		with(new MenuItem(menu, DWT.PUSH)){
			setImage(Globals.getImage("zip"));
			setData( LANG_ID, "prj.compress" );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionCompressProject(e);
			});
		}

		// compiler menu
		barItem = new MenuItem( menubar, DWT.CASCADE );
		barItem.setData( LANG_ID, "menu.build" );
		menu = new Menu( barItem );
		barItem.setMenu( menu );

		// compiler.compile
		with( compileItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage(Globals.getImage("compile"));
			setData( LANG_ID, "build.compile" );
			handleEvent(null, DWT.Selection, delegate( Event e ){
				sActionMan.actionDefaultCompile(e);
			});
		}

		// compiler.run
		with( runItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "run" ) );
			setData( LANG_ID, "build.run" );
			handleEvent(null, DWT.Selection, delegate( Event e ){
				sActionMan.actionDefaultRun(e);
			});
		}

		// compiler.build
		with( buildItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage(Globals.getImage("build"));
			setData( LANG_ID, "build.build" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDefaultBuildHSU(e);
			});
		}			

		// compiler.build & run
		with( build_runItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage(Globals.getImage("build_run"));
			setData( LANG_ID, "build.b_r" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDefaultBuild_RunHSU(e);
			});
		}

		// compiler.rebuild all
		with( rebuildItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage(Globals.getImage("rebuild"));
			setData( LANG_ID, "build.rebuild" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDefaultBuild(e);
			});
		}

		new MenuItem( menu, DWT.SEPARATOR );

		// compiler.Bud
		with( BudItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage(Globals.getImage( "Bud" ) );
			setData( LANG_ID, "build.bud" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionBud(e);
			});
		}
		/*
		new MenuItem( menu, DWT.SEPARATOR );

		with( debugItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage(Globals.getImage( "debug_exc" ) );
			setData( LANG_ID, "build.debug" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDebug( false );
			});
		}
		
		// compiler.debugbuild
		with( debugbuildItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage(Globals.getImage( "debug_exc" ) );
			setData( LANG_ID, "build.debugbuild" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDebug( true );
			});
		}
		*/
		new MenuItem( menu, DWT.SEPARATOR );

		with( cleanItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setData(LANG_ID, "build.clean");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionCleanSourceRunning( e );
			});
		}

		// debug menu
		barItem = new MenuItem( menubar, DWT.CASCADE );
		barItem.setData( LANG_ID, "menu.debug" );
		menu = new Menu( barItem );
		barItem.setMenu( menu );

		// debug.rundebug
		with( debugItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage(Globals.getImage( "debug_run" ) );
			setData( LANG_ID, "build.debug" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDebug( false );
			});
		}
		
		// debug.debugbuild
		with( debugbuildItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage(Globals.getImage( "debug_build" ) );
			setData( LANG_ID, "build.debugbuild" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDebug( true );
			});
		}

		new MenuItem( menu, DWT.SEPARATOR );
		
		// debug.resume
		with( debugrunItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "debug_resume" ) );
			setData( LANG_ID, "debug.tooltip_run" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDebugExec( e );
			});
		}
		
		// debug.in
		with( debuginItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "debug_stepinto" ) );
			setData( LANG_ID, "debug.tooltip_in" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDebugStepInto( e );
			});
		}

		// debug.over
		with( debugoverItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "debug_stepover" ) );
			setData( LANG_ID, "debug.tooltip_over" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDebugStepOver( e );
			});
		}
		
		// debug.return
		with( debugreturnItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "debug_stepreturn" ) );
			setData( LANG_ID, "debug.tooltip_ret" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDebugStepReturn( e );
			});
		}

		// debug.terimate
		with( debugstopItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "progress_stop" ) );
			setData( LANG_ID, "debug.tooltip_stop" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDebugStop( e );
			});
		}

		new MenuItem( menu, DWT.SEPARATOR );

		// debug.cleanbps
		with( debugcleanbpsItem = new MenuItem( menu, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "close_view" ) );
			setData( LANG_ID, "debug.cleanbps" );
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionCleanAllBreakPoints( e );
			});
		}		

		// tools menu
		barItem = new MenuItem(menubar, DWT.CASCADE);
		barItem.setData(LANG_ID, "menu.tools");
		menu = new Menu(barItem);
		barItem.setMenu(menu);

		/// tools.language
		MenuItem langItem;
		with(langItem = new MenuItem(menu, DWT.CASCADE)){
			// always set the "language" string to in English
			setData(LANG_ID,"tools.language");
			handleEvent(this, DWT.Selection, delegate(Event e){
			});
		}
		langItem.setMenu(getLanguageMenu(langItem));

		with( encodeItem = new MenuItem(menu, DWT.CASCADE)){
			// always set the "language" string to in English
			setData(LANG_ID,"tools.encode");
			setEnabled( false );
			handleEvent(this, DWT.Selection, delegate(Event e){
			});
		}
		encodeItem.setMenu(EncodeMenu(encodeItem));

		new MenuItem(menu, DWT.SEPARATOR);

		with( registerItem = new MenuItem(menu, DWT.CASCADE)){
			// always set the "language" string to in English
			setData(LANG_ID,"tools.associate");
			//setEnabled( false );
		}
		registerItem.setMenu(RegisterMenu(registerItem));
		
		new MenuItem(menu, DWT.SEPARATOR);
		/// tools.options
		with(new MenuItem(menu, DWT.PUSH)){
			setData(LANG_ID,"tools.options");
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionPreference(e);
			});
		}

		// help menu
		barItem = new MenuItem(menubar, DWT.CASCADE);
		barItem.setData(LANG_ID, "menu.help");
		menu = new Menu(barItem);
		barItem.setMenu(menu);

		/// help.document
		with( documentItem = new MenuItem(menu, DWT.CASCADE)){
			setData(LANG_ID,"gp.doc");
			setImage(Globals.getImage( "help_link" ) );
			handleEvent(this, DWT.Selection, delegate(Event e){
			});
		}
		documentMenu = DocumentMenu(documentItem);
		documentItem.setMenu(documentMenu);		

		new MenuItem(menu, DWT.SEPARATOR);

		/// help.about
		with(new MenuItem(menu, DWT.PUSH)){
			setData(LANG_ID,"help.about");
			setImage(Globals.getImage( "information" ) );
			handleEvent(this, DWT.Selection, delegate(Event e){
				sActionMan.actionAboutBox(e);
			});
		}
	}
	
	protected Menu getLanguageMenu(MenuItem item)
	{
		char[][] keys = Globals.languages.keys;
		Menu menu = new Menu(item);
		foreach(char[] name; keys){
			MenuItem mi = new MenuItem(menu, DWT.RADIO);
			mi.setText(name);
			mi.handleEvent(null, DWT.Selection, delegate(Event e){
				MenuItem mi = cast(MenuItem)e.widget;
				char[] text = mi.getText();
				if(text != Globals.curLang){
					Globals.curLang = text;
					Globals.loadI18N(text);
					sGUI.updateI18N();
				}
			});
			if(name == Globals.curLang)
				mi.setSelection(true);
		}
		return menu;
	}

	protected Menu EncodeMenu(MenuItem item)
	{
		char[][] keys = ["DEFAULT", "UTF8", "UTF8.BOM", "UTF16LE", "UTF16BE", "UTF32LE", "UTF32BE"];//Globals.languages.keys;
		Menu menu = new Menu(item);
		foreach(char[] name; keys)
		{
			MenuItem mi = new MenuItem(menu, DWT.PUSH);
			mi.setText(name);
			mi.handleEvent(null, DWT.Selection, delegate(Event e)
			{
				sActionMan.actionEncode( e );
			});
		}
		return menu;
	}

	protected Menu RegisterMenu(MenuItem item)
	{
		Menu menu = new Menu(item);

		MenuItem miRegister = new MenuItem(menu, DWT.PUSH);
		miRegister.setData( LANG_ID,"tools.register" );
		miRegister.handleEvent(null, DWT.Selection, delegate(Event e)
		{
			sActionMan.actionRegister( e );
		});		
		
		MenuItem miUnRegister = new MenuItem(menu, DWT.PUSH);
		miUnRegister.setData( LANG_ID,"tools.unregister" );
		miUnRegister.handleEvent(null, DWT.Selection, delegate(Event e)
		{
			sActionMan.actionUnRegister( e );
		});		

		return menu;
	}
	
	protected Menu DocumentMenu(MenuItem item)
	{
		Menu menu = new Menu(item);

		_ShortCut[] hotkeys = Globals.hotkeys;
		char[][5]	shortCutName;

		for( int i =0; i < hotkeys.length; ++ i )
		{
			if( hotkeys[i].name == "document0" )
				shortCutName[0] = hotkeys[i].keyname;
			else if( hotkeys[i].name == "document1" )
				shortCutName[1] = hotkeys[i].keyname;
			else if( hotkeys[i].name == "document2" )
				shortCutName[2] = hotkeys[i].keyname;
			else if( hotkeys[i].name == "document3" )
				shortCutName[3] = hotkeys[i].keyname;
			else if( hotkeys[i].name == "document4" )
				shortCutName[4] = hotkeys[i].keyname;
		}

		
		for( int i = 0; i < Globals.DDcoumentDir.length; ++ i )
		{
			if( !Globals.DDcoumentDir[i].length ) continue;
			MenuItem mi = new MenuItem(menu, DWT.PUSH);
			mi.setText( std.string.ljustify( "#" ~ std.string.toString(i) ~ " " ~ Globals.DDcoumentDir[i] , 50 ) ~ shortCutName[i] );
			
			mi.handleEvent(null, DWT.Selection, delegate(Event e)
			{
				MenuItem pItem = cast(MenuItem) e.widget;
				char[] text = pItem.getText();
				int posSpace = std.string.find( text, " " );
				int posNum = std.string.find( text, "#" );
				if( posSpace > posNum + 1 ) text = text[posNum+1..posSpace]; else text = "";
				if( text.length)
					sActionMan.actionDDocumentFile( std.string.atoi( text ) );
			});			
		}
		return menu;
	}		

	protected Menu getRecentPrjMenu() {
		if(recentMenu is null) {
			buildRecentPrjMenu();
		}	
		return recentMenu;
	}

	public Menu buildRecentPrjMenu() {
		if(recentMenu !is null) 
		{
			MenuItem[] items = recentMenu.getItems();
			foreach(MenuItem mi; items) {
				mi.dispose();
			}
		}
		recentMenu = new Menu(sShell, DWT.DROP_DOWN);
		// add the recent Prjs menu, reverse the sequency
		if(Globals.recentPrjs.length == 0) return recentMenu;
		for(int i = Globals.recentPrjs.length - 1; i>=0; --i)
		{
			PrjPair pp = Globals.recentPrjs[i];
			char[] title = pp.dir;
			if(pp.name.length)
				title ~= " - " ~ pp.name;
			with(new MenuItem(recentMenu, DWT.PUSH))
			{
				setText(title);
				setData(new StringObj(pp.dir));
				handleEvent(null, DWT.Selection, delegate(Event e){
					sActionMan.actionLoadRecentProject(e);
				});
			}
		}
		return recentMenu;
	}

	public static void updateMenuI18N(Menu menu)
		{
			MenuItem[] items = menu.getItems();
			foreach(MenuItem mi; items)
			{
				StringObj obj = cast(StringObj)mi.getData(LANG_ID);
				if(obj && obj.data){
					char[] txt = Globals.getTranslation(obj.data);
					mi.setText(txt);
				}
				Menu subMenu = mi.getMenu();
				if(subMenu)
					updateMenuI18N(subMenu);
			}
		}
		
	void updateI18N()
	{
		// nested method
		

		// code start here
		updateMenuI18N(menubar);	
		if(extToolMenu)
			updateMenuI18N(extToolMenu);

		addShortCutKeyName();
	}

	public Menu getExtToolMenu() {
		if(extToolMenu is null) {
			buildExtToolMenu();
		}	
		return extToolMenu;
	}

	public Menu buildExtToolMenu() {
		if(extToolMenu !is null) {
			MenuItem[] items = extToolMenu.getItems();
			foreach(MenuItem mi; items) {
				mi.dispose();
			}
		}
		extToolMenu = new Menu(sShell, DWT.CASCADE);
		// add the customized tool menu
		foreach(ToolEntry entry; Globals.toolEntries)
		{
			with(new MenuItem(extToolMenu, DWT.PUSH))
			{
				setText(entry.name);
				setData(entry);
				handleEvent(null, DWT.Selection, delegate(Event e){
					sActionMan.actionExtTool(e);
				});
			}
		}
		new MenuItem(extToolMenu, DWT.SEPARATOR);
		with(new MenuItem(extToolMenu, DWT.CASCADE)){
			setData(LANG_ID, "CUSTOMIZE");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionEditExtTool(e);
			});
		}

		updateMenuI18N(extToolMenu);
		
		return extToolMenu;
	}

	public void addShortCutKeyName()
	{
		_ShortCut[] hotkeys = Globals.hotkeys;

		for( int i = 0; i < hotkeys.length; ++ i )
		{
			switch( hotkeys[i].name )
			{
				// File
				case "save":
					saveItem.setText( std.string.ljustify( Globals.getTranslation( "file.save" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "save_allfiles":
					saveallItem.setText(  std.string.ljustify( Globals.getTranslation( "file.saveall" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "close_file":
					closefileItem.setText( std.string.ljustify( Globals.getTranslation( "file.closefile" ), 30 ) ~ hotkeys[i].keyname ); break;

				// Edit
				case "undo":
					undoItem.setText( std.string.ljustify( Globals.getTranslation( "edit.undo" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "redo":
					redoItem.setText( std.string.ljustify( Globals.getTranslation( "edit.redo" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "cut":
					cutItem.setText( std.string.ljustify( Globals.getTranslation( "edit.cut" ), 30 ) ~  hotkeys[i].keyname ); break;
				case "copy":
					copyItem.setText( std.string.ljustify( Globals.getTranslation( "edit.copy" ), 30 ) ~  hotkeys[i].keyname ); break;
				case "paste":
					pasteItem.setText( std.string.ljustify( Globals.getTranslation( "edit.paste" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "select_all":
					selectallItem.setText( std.string.ljustify( Globals.getTranslation( "edit.selectall" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "toggle_comment":
					togglecommentItem.setText( std.string.ljustify( Globals.getTranslation( "edit.togglecomment" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "stream_comment":
					streamcommentItem.setText( std.string.ljustify( Globals.getTranslation( "edit.streamcomment" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "box_comment":
					boxcommentItem.setText( std.string.ljustify( Globals.getTranslation( "edit.boxcomment" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "nest_comment":
					nestcommentItem.setText( std.string.ljustify( Globals.getTranslation( "edit.nestcomment" ), 30 ) ~ hotkeys[i].keyname ); break;

				// Search
				case "find":
					findItem.setText( std.string.ljustify( Globals.getTranslation( "search.find" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "search":
					findListItem.setText( std.string.ljustify( Globals.getTranslation( "search.searchinfile" ),30 ) ~ hotkeys[i].keyname ); break;
				case "goto_line":
					gotoItem.setText( std.string.ljustify( Globals.getTranslation( "search.goto" ), 30 ) ~ hotkeys[i].keyname ); break;

				// Build
				case "compile":
					compileItem.setText( std.string.ljustify( Globals.getTranslation( "build.compile" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "run_project":
					runItem.setText( std.string.ljustify( Globals.getTranslation( "build.run" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "build_project":
					buildItem.setText( std.string.ljustify( Globals.getTranslation( "build.build" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "build_run_project":
					build_runItem.setText( std.string.ljustify( Globals.getTranslation( "build.b_r" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "rebuild_project":
					rebuildItem.setText( std.string.ljustify( Globals.getTranslation( "build.rebuild" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "buildtool":
					BudItem.setText( std.string.ljustify( Globals.getTranslation( "build.bud" ), 30 ) ~ hotkeys[i].keyname ); break;

				// Debug
				case "debug_project":
					debugItem.setText( std.string.ljustify( Globals.getTranslation( "build.debug" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "debug_build_project":
					debugbuildItem.setText( std.string.ljustify( Globals.getTranslation( "build.debugbuild" ), 30 ) ~  hotkeys[i].keyname ); break;
				case "debug_run":
					debugrunItem.setText( std.string.ljustify( Globals.getTranslation( "debug.tooltip_run" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "debug_in":
					debuginItem.setText( std.string.ljustify( Globals.getTranslation( "debug.tooltip_in" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "debug_over":
					debugoverItem.setText(std.string.ljustify( Globals.getTranslation( "debug.tooltip_over" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "debug_return":
					debugreturnItem.setText( std.string.ljustify( Globals.getTranslation( "debug.tooltip_ret" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "debug_stop":
					debugstopItem.setText( std.string.ljustify( Globals.getTranslation( "debug.tooltip_stop" ), 30 ) ~ hotkeys[i].keyname ); break;
				case "debug_clean_bps":
					debugcleanbpsItem.setText( std.string.ljustify( Globals.getTranslation( "debug.cleanbps" ), 30 ) ~  hotkeys[i].keyname ); break;
				
				default:
			}
		}
	}

	void refreshDocumentHelp()
	{
		if( documentMenu !is null ) delete documentMenu;
		documentMenu = DocumentMenu(documentItem);
		documentItem.setMenu(documentMenu);
	}
}