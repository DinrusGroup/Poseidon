module poseidon.controller.toolbarmanager;

private import dwt.all;
private import poseidon.globals;
private import poseidon.controller.gui;
private import poseidon.controller.actionmanager;
private import poseidon.i18n.itranslatable;
private import poseidon.model.misc;
private import poseidon.controller.editor;
private import poseidon.controller.packageexplorer;

private import poseidon.model.project;

class ToolBarManager : ITranslatable, EditorListener
{
	private import std.string;
	
	ToolBar toolbar;
	ToolItem tiClosePrj, tiSave, tiSaveAll, tiBack, tiForward, tiClearCache;
	ToolItem tiMarkToggle, tiMarkPrev, tiMarkNext, tiMarkClear, tiBuild, tiExtTools;

	private ToolItem tiUndo, tiRedo, tiCut, tiCopy, tiPaste, tiCompile, tiRun, tiBuild_Run, tiRebuild, tiBud;//, tiDebug;

	//Text txtFunctionHead;

	//ImageCombo cobBuildTool;

	// static properties
	private static ToolBarManager  pthis;
	// make sure the editor/pkgexpler is created when you reference them
	private Editor editor() { return sGUI.editor; }
	private PackageExplorer packageExp() { return sGUI.packageExp; }

	public this()
	{
		pthis = this;		
		initComponents();
		updateNavState();
		updateI18N();

		sActionMan.navCache.addListener(new class Listener{
			public void handleEvent(Event e) {
				pthis.updateNavState();
			}
		});
	}

	private void initComponents()
	{
		toolbar = new ToolBar(sShell, DWT.FLAT);

		with(new ToolItem(toolbar,DWT.PUSH))
		{
			setImage(Globals.getImage("newprj_wiz"));
			setData(LANG_ID, "tb.newprj");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionNewProject(e);
			});
		}
		with(new ToolItem(toolbar,DWT.PUSH))
		{
			setImage(Globals.getImage("project_obj"));
			setData(LANG_ID, "tb.openprj");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionOpenProject(e);
			});
		}
		with(tiClosePrj = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("uninstall_wiz"));
			setDisabledImage(Globals.getImage("uninstall_wiz_dis"));
			setData(LANG_ID, "tb.closeprj");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionCloseProject(e);
			});
		}
		new ToolItem(toolbar, DWT.SEPARATOR);
		with(tiSave = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("save"));
			setDisabledImage(Globals.getImage("save_dis"));
			setData(LANG_ID, "tb.save");
			handleEvent(null, DWT.Selection, delegate(Event e) {
				sActionMan.actionSave(e);
			});
		}
		with(tiSaveAll = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("save_all"));
			setDisabledImage(Globals.getImage("save_all_dis"));
			setData(LANG_ID, "tb.saveall");
			handleEvent(null, DWT.Selection, delegate(Event e) {
				sActionMan.actionSaveAll(e);
			});
		}


		new ToolItem( toolbar, DWT.SEPARATOR );
		with( tiUndo = new ToolItem( toolbar, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "undo" ) );
			setDisabledImage( Globals.getImage( "undo_dis" ) );
			setData( LANG_ID, "tb.undo" );
			handleEvent( null, DWT.Selection, delegate( Event e ) {	sActionMan.actionUndo( e );	} );
		}
			
		with( tiRedo = new ToolItem( toolbar, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "redo" ) );
			setDisabledImage( Globals.getImage( "redo_dis" ) );
			setData( LANG_ID, "tb.redo" );
			handleEvent( null, DWT.Selection, delegate( Event e ) {	sActionMan.actionRedo( e );	} );
		}

		new ToolItem( toolbar, DWT.SEPARATOR );
		with( tiCut = new ToolItem( toolbar, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "cut" ) );
			setDisabledImage(Globals.getImage("cut_dis"));
			setData(LANG_ID, "tb.cut");
			handleEvent( null, DWT.Selection, delegate( Event e ) {	sActionMan.actionCut( e );	} );
		}
			
		with( tiCopy = new ToolItem( toolbar, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "copy" ) );
			setDisabledImage(Globals.getImage("copy_dis"));
			setData(LANG_ID, "tb.copy");
			handleEvent( null, DWT.Selection, delegate( Event e ) {	sActionMan.actionCopy( e );	} );
		}

		with( tiPaste = new ToolItem( toolbar, DWT.PUSH ) )
		{
			setImage( Globals.getImage( "paste" ) );
			setDisabledImage( Globals.getImage( "paste_dis" ) );
			setData(LANG_ID, "tb.paste");
			handleEvent( null, DWT.Selection, delegate( Event e ) {	sActionMan.actionPaste( e );	} );
		}
			
		

		// navigation
		new ToolItem(toolbar, DWT.SEPARATOR);
		with(tiBack = new ToolItem(toolbar, DWT.PUSH)) {			
			setImage(Globals.getImage("e_back"));
			setDisabledImage(Globals.getImage("e_back_dis"));
			setData(LANG_ID, "tb.navprev");
			handleEvent(new Integer(0), DWT.Selection, &sActionMan.actionNavigate);
		}
		with(tiForward = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("e_forward"));
			setDisabledImage(Globals.getImage("e_forward_dis"));
			setData(LANG_ID, "tb.navnext");
			handleEvent(new Integer(1), DWT.Selection, &sActionMan.actionNavigate);
		}
		with(tiClearCache = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("clear"));
			setDisabledImage(Globals.getImage("clear_dis"));
			setData(LANG_ID, "tb.navclr");
			handleEvent(null, DWT.Selection, &sActionMan.actionClearNavCache);
		}

		// book mark
		new ToolItem(toolbar, DWT.SEPARATOR);
		with(tiMarkToggle = new ToolItem(toolbar, DWT.PUSH)) {			
			setImage(Globals.getImage("mark_toggle"));
			setDisabledImage(Globals.getImage("mark_toggle_dis"));
			setData(LANG_ID, "tb.marktoggle");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionMarkerCmd(e);
			});
		}
		with(tiMarkPrev = new ToolItem(toolbar, DWT.PUSH)) {			
			setImage(Globals.getImage("mark_prev"));
			setDisabledImage(Globals.getImage("mark_prev_dis"));
			setData(LANG_ID, "tb.markprev");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionMarkerCmd(e);
			});
		}
		with(tiMarkNext = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("mark_next"));
			setDisabledImage(Globals.getImage("mark_next_dis"));
			setData(LANG_ID, "tb.marknext");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionMarkerCmd(e);
			});
		}
		with(tiMarkClear = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("mark_clear"));
			setDisabledImage(Globals.getImage("mark_clear_dis"));
			setData(LANG_ID, "tb.markclr");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionMarkerCmd(e);
			});
		}

		// Compile build
		new ToolItem(toolbar, DWT.SEPARATOR);
		with(tiCompile = new ToolItem(toolbar, DWT.PUSH))
		{
			setImage(Globals.getImage("compile"));
			setDisabledImage(Globals.getImage("compile_dis"));
			setData(LANG_ID, "tb.compile");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDefaultCompile(e);
			});
		}
		with(tiRun = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("run"));
			setDisabledImage(Globals.getImage("run_dis"));
			setData(LANG_ID, "tb.run");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDefaultRun(e);
			});
		}
		with(tiBuild = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("build"));
			setDisabledImage(Globals.getImage("build_dis"));
			setData(LANG_ID, "tb.build");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDefaultBuildHSU(e);
			});
		}
		with(tiBuild_Run = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("build_run"));
			setDisabledImage(Globals.getImage("build_run_dis"));
			setData(LANG_ID, "tb.b_r");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDefaultBuild_RunHSU(e);
			});
		}
		with(tiRebuild = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("rebuild"));
			setDisabledImage(Globals.getImage("rebuild_dis"));
			setData(LANG_ID, "tb.rebuild");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDefaultBuild(e);
			});
		}

		new ToolItem(toolbar, DWT.SEPARATOR);
		with( tiBud = new ToolItem(toolbar, DWT.PUSH)){
			setImage( Globals.getImage( "Bud" ) );
			setDisabledImage( Globals.getImage("Bud_dis") );
			setData(LANG_ID, "tb.bud");
			
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionBud(e);
			});
		}
		/*
		new ToolItem(toolbar, DWT.SEPARATOR);
		with( tiDebug = new ToolItem(toolbar, DWT.PUSH)){
			setImage(Globals.getImage("debug_exc"));
			setDisabledImage(Globals.getImage("debug_exc_dis"));
			setData(LANG_ID, "tb.debug");
			
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionDebug( true );
			});
		}
		*/

		// external tools
		new ToolItem(toolbar, DWT.SEPARATOR);
		with(tiExtTools = new ToolItem(toolbar, DWT.DROP_DOWN)){
			setImage(Globals.getImage("external_tools"));
			setData(LANG_ID, "tb.exttool");
			handleEvent(null, DWT.Selection, delegate(Event e){
				sActionMan.actionTbarExtTools(e);
			});
		}
		/+
		new ToolItem(toolbar, DWT.SEPARATOR);
		ToolItem mother = new ToolItem(toolbar, DWT.SEPARATOR);

		with( txtFunctionHead = new Text( toolbar, DWT.BORDER ) )
		{
			mother.setWidth( 200 );
			mother.setControl( txtFunctionHead );


		}+/
		/+
		new ToolItem(toolbar, DWT.SEPARATOR);
		ToolItem mother = new ToolItem(toolbar, DWT.SEPARATOR);
		
	
		with( cobBuildTool = new ImageCombo( toolbar, DWT.READ_ONLY ) )
		{
			
			add( "DMD", Globals.getImage("external_tools") );
			add( "BUD", Globals.getImage("external_tools") );
			Font font = new Font( display, "Verdana", 9, DWT.NORMAL );
			setFont( font );
			select(0);
			pack();
			//handleEvent( null, DWT.Modify, &onCobBuildToolHSU );
		}
		mother.setWidth( 85 );
		mother.setControl( cobBuildTool );
		+/
		
	}

	public void onActiveEditItemChanged(EditorEvent e) 
	{
		updateToolBar();
	}
	public void onAllEditItemClosed(EditorEvent e){
		updateToolBar();
	}
	public void onEditItemSaveStateChanged(EditorEvent e){
		updateToolBar();
	}
	public void onEditItemDisposed(EditorEvent e){}

	public void updateNavState() 
	{
		tiBack.setEnabled(sActionMan.navCache.canBack());
		tiForward.setEnabled(sActionMan.navCache.canForward());
		tiClearCache.setEnabled(sActionMan.navCache.hasCache());
	}


	/**
	 * do disable/enable toolitem check 
	 */
	public void updateToolBar() 
	{
		if(tiSave.isDisposed() || editor is null)
			return;

		boolean havePrj = packageExp.getProjectCount() > 0;
		boolean haveDoc = editor.getItemCount()> 0;
		
		tiSave.setEnabled(editor.modified());
		tiSaveAll.setEnabled( haveDoc );
 
		char[] selectEditItemName = sGUI.editor.getSelectedFileName();
		if( selectEditItemName.length )
		{
			if( sGUI.packageExp.isFileInProjects( selectEditItemName ) )
			{
				tiCompile.setEnabled( havePrj );
				tiRun.setEnabled( havePrj );
				tiBuild_Run.setEnabled( havePrj );
				tiBuild.setEnabled( havePrj );
				tiRebuild.setEnabled( havePrj );
				tiBud.setEnabled( havePrj );
			}
			else
			{
				tiCompile.setEnabled( false );
				tiRun.setEnabled( false );
				tiBuild.setEnabled( false );
				tiRebuild.setEnabled( false );
				tiBud.setEnabled( false );
				tiBuild_Run.setEnabled( true );
			}
		}
		else
		{
			tiCompile.setEnabled( havePrj );
			tiRun.setEnabled( havePrj );
			tiBuild_Run.setEnabled( havePrj );
			tiBuild.setEnabled( havePrj );
			tiRebuild.setEnabled( havePrj );
			tiBud.setEnabled( havePrj );
		}

		bool bDebugs;
		if( sGUI !is null )
		{
			//if( sGUI.debuggerDMD.isPipeCreate() ) tiDebug.setEnabled( false );else tiDebug.setEnabled( true );
			//if( !packageExp.getProjectCount() )  tiDebug.setEnabled( false );
			if( !sGUI.debuggerDMD.isPipeCreate() ) bDebugs = true;
			if( !packageExp.getProjectCount() )  bDebugs = false;
		}
				
		tiUndo.setEnabled( editor.direct2EditItemHSU( 0 ) );
		tiRedo.setEnabled( editor.direct2EditItemHSU( 1 ) );
		tiPaste.setEnabled( editor.direct2EditItemHSU( 2 ) );
		tiPaste.setEnabled( haveDoc );
		tiCut.setEnabled( haveDoc );
		tiCopy.setEnabled( haveDoc );

		tiMarkToggle.setEnabled(haveDoc);
		tiMarkNext.setEnabled(haveDoc);
		tiMarkPrev.setEnabled(haveDoc);
		tiMarkClear.setEnabled(haveDoc);
		tiClosePrj.setEnabled(packageExp.getProjectCount() > 0);

		if( sGUI.menuMan )
		{
			// file menu
			sGUI.menuMan.saveItem.setEnabled( tiSave.getEnabled() );
			sGUI.menuMan.saveasItem.setEnabled( haveDoc );
			sGUI.menuMan.saveallItem.setEnabled( tiSaveAll.getEnabled() );
			sGUI.menuMan.closefileItem.setEnabled( haveDoc );

			sGUI.menuMan.closeprjItem.setEnabled( havePrj );
			sGUI.menuMan.closeallprjItem.setEnabled( havePrj );

			// edit menu
			sGUI.menuMan.undoItem.setEnabled( tiUndo.getEnabled() );
			sGUI.menuMan.redoItem.setEnabled( tiRedo.getEnabled() );
			sGUI.menuMan.cutItem.setEnabled( haveDoc );
			sGUI.menuMan.copyItem.setEnabled( haveDoc );
			sGUI.menuMan.pasteItem.setEnabled( haveDoc );
			sGUI.menuMan.selectallItem.setEnabled( haveDoc );
			sGUI.menuMan.togglecommentItem.setEnabled( haveDoc );
			sGUI.menuMan.streamcommentItem.setEnabled( haveDoc );
			sGUI.menuMan.boxcommentItem.setEnabled( haveDoc );
			sGUI.menuMan.nestcommentItem.setEnabled( haveDoc );
			
			// search menu
			sGUI.menuMan.findItem.setEnabled( haveDoc );
			sGUI.menuMan.findListItem.setEnabled( havePrj );
			sGUI.menuMan.gotoItem.setEnabled( haveDoc );
			
			// compiler menu
			sGUI.menuMan.compileItem.setEnabled( tiCompile.getEnabled() );
			sGUI.menuMan.runItem.setEnabled( tiRun.getEnabled() );
			sGUI.menuMan.buildItem.setEnabled( tiBuild.getEnabled() );
			sGUI.menuMan.build_runItem.setEnabled( tiBuild_Run.getEnabled() );
			sGUI.menuMan.rebuildItem.setEnabled( tiRebuild.getEnabled() );
			sGUI.menuMan.BudItem.setEnabled( tiRebuild.getEnabled() );
			sGUI.menuMan.cleanItem.setEnabled( tiCompile.getEnabled() );

			// Debug
			sGUI.menuMan.debugItem.setEnabled( bDebugs/*tiDebug.getEnabled()*/ );
			sGUI.menuMan.debugbuildItem.setEnabled( bDebugs/*tiDebug.getEnabled()*/ );
			sGUI.menuMan.debugcleanbpsItem.setEnabled( haveDoc );

			if( sGUI.debuggerDMD.isPipeCreate() )
			{
				sGUI.menuMan.debugrunItem.setEnabled( true );
				sGUI.menuMan.debugstopItem.setEnabled( true );
				if( sGUI.debuggerDMD.isRunning() )
				{
					sGUI.menuMan.debuginItem.setEnabled( true );
					sGUI.menuMan.debugoverItem.setEnabled( true );
					sGUI.menuMan.debugreturnItem.setEnabled( true );
					
				}
				else
				{
					sGUI.menuMan.debuginItem.setEnabled( false );
					sGUI.menuMan.debugoverItem.setEnabled( false );
					sGUI.menuMan.debugreturnItem.setEnabled( false );
				}
			}
			else
			{
				sGUI.menuMan.debuginItem.setEnabled( false );
				sGUI.menuMan.debugrunItem.setEnabled( false );
				sGUI.menuMan.debugoverItem.setEnabled( false );
				sGUI.menuMan.debugreturnItem.setEnabled( false );
				sGUI.menuMan.debugstopItem.setEnabled( false );
			}
			
			sGUI.menuMan.encodeItem.setEnabled( haveDoc );
		}	
	}
	
	public void updateExtToolInfo()
	{
		if(ToolEntry.lastTool)
		{
			tiExtTools.setToolTipText(ToolEntry.lastTool.name);
		}
	}

	public void updateI18N()
	{
		ToolItem[] items = toolbar.getItems();
		foreach(ToolItem ti; items){
			StringObj obj = cast(StringObj)ti.getData(LANG_ID);
			if(obj && obj.data){
				ti.setToolTipText(Globals.getTranslation(obj.data));
			}			
		}
		
		updateExtToolInfo();
	}

	/*
	private void onCobBuildToolHSU( Event e )
	{
		int result = cobBuildTool.getSelectionIndex();

		if( result == 0 )
			Globals.useBUILD = false;
		else if( result == 1 )
			Globals.useBUILD = true;

		if( sGUI.packageExp )
		{
			Globals.explorerType = !Globals.useBUILD;
			sGUI.packageExp.setPackageName();
			sGUI.packageExp.refreshAllProject();
			//sGUI.packageExp.refreshProject();
		}
	}
	*/
}