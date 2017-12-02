module poseidon.controller.editor;

private import dwt.all;
private import dwt.extra.all;
private import dwt.internal.converter;

public import poseidon.controller.edititem;
private import poseidon.controller.bottompanel;
private import poseidon.controller.dialog.askreloaddlg;
private import poseidon.controller.dialog.finddlg;
private import poseidon.controller.dialog.generaldialog;
private import poseidon.controller.dialog.searchdlg;
private import poseidon.controller.gui;
private import poseidon.controller.packageexplorer;
private import poseidon.controller.scintillaex;
private import poseidon.globals;
private import poseidon.i18n.itranslatable;
private import poseidon.model.misc;
private import poseidon.model.navcache;
private import poseidon.model.project;
private import poseidon.util.fileutil;
private import poseidon.util.waitcursor;
private import poseidon.controller.menumanager;
private import poseidon.model.editorsettings;
private import poseidon.util.miscutil;
private import std.path;
private import std.stream;


struct _EditorEvent {
	int type;
	Object cData;
	EditItem item;

	static _EditorEvent opCall(int type, EditItem item)
	{
		_EditorEvent e;
		e.type = type;
		e.item = item;
		return e;

	}
}

alias _EditorEvent* EditorEvent;

interface EditorListener
{
	void onActiveEditItemChanged(EditorEvent e);
	void onAllEditItemClosed(EditorEvent e);
	void onEditItemSaveStateChanged(EditorEvent e);
	void onEditItemDisposed(EditorEvent e);
}

// auto set/reset modifyChecking of Editor
auto class AutoModifyProtect {
	private Editor editor;
	this(Editor editor){
		this.editor = editor;
		editor.modifyChecking = true;
	}
	~this(){
		editor.modifyChecking = false;
	}
}

class Editor : CTabFolder, ITranslatable {
	
	private import dwt.internal.converter;
	private import poseidon.style.xpm;

	// editor event type
	enum{
		EEV_ACTIVE_CHANGE,
		EEV_ALL_CLOSED,
		EEV_SAVE_STATE,
		EEV_ITEM_DISPOSE,
	}
	
	const int MARK_SYMBOLE 			= 2;
	const int MARK_DEBUGSYMBOLE 	= 1;
	const int MARK_DEBUGRUNSYMBOLE 	= 3;
	const int MARK_DEBUGRUNLINE 	= 4;
	
	public static EditorSettings settings;
	
	private class SearchObj{
		char[][] 	filelist;
		FindOption 	fop;		
		Integer		count;		
		Integer		fileCnt;
		int			action;		
		boolean 	_continue = true;	// user can stop search by set it to false
		
		this(char[][] filelist, FindOption fop, Integer count, Integer fileCnt, int action){
			this.filelist = filelist;
			this.fop = fop;
			this.count = count;
			this.fileCnt = fileCnt;
			this.action = action;			
		} 
	}
	
	/**
	 * declared as static so the nested function can access it freely
	 */
	private static SearchObj	searchObj;
	private static ScintillaEx	invisibleSC;
	private static Editor		pthis;
	
	private EditorListener[] eventListeners;
	
	private Menu	contextMenu;
	
	private static Color[3] colorsActive; 
	private static int[2] percentArray = [60, 100];	
	
	private boolean 	modifyChecking = false;
	public FindDlg 		findDlg;
	
	this(SashForm parent)
	{ 		
		super(parent, DWT.TOP | DWT.CLOSE | DWT.H_SCROLL | DWT.BORDER); 
		pthis = this;
		colorsActive[0] = DWTResourceManager.getColor(0, 100, 255);
		colorsActive[1] = DWTResourceManager.getColor(113, 166, 244);
		colorsActive[2] = null;
		
		this.setSelectionBackground(colorsActive, percentArray, true);
		this.setTabHeight(24);
		this.setSimple(false);
		this.setSelectionForeground(DWTResourceManager.getColor(255,255,255));
		
		this.handleCTabFolderEvent(this, CTabFolder.CLOSE, &onTabFolderItemClose);
		this.handleEvent(null, DWT.MouseUp, &onTabFolderMouseUp);
		this.handleEvent(null, DWT.Selection, &onTabFolderSelection);
		this.handleEvent(null, DWT.Dispose, &onDispose);
		this.handleEvent(this, DWT.MouseDoubleClick, delegate(Event e){
			if(e.button == 1){
				(cast(Editor)e.cData).toggleMaximized();
			}
		});
		
		findDlg = new FindDlg(getShell(), this);
		findDlg.setImage( Globals.getImage( "find" ) ); // Set Icon
		// create the invisible scintilla for search and replace
		invisibleSC = new ScintillaEx(sShell, DWT.NONE);
		// don't collect undo actions
		invisibleSC.setUndoCollection(false);
		
		GridData gdata = new GridData();
		gdata.exclude = true;
		invisibleSC.setLayoutData(gdata);
		invisibleSC.setVisible(false);
		
		updateI18N();

		// install the Shell's event handler to check ExternModify
		sShell.handleEvent(null, DWT.Activate, delegate(Event e) {
			pthis.checkExternModify();
		});


		private_method_xpm 			= getXpm( "images\\obj16\\xpm\\function_private_obj.xpm");
		protected_method_xpm 		= getXpm( "images\\obj16\\xpm\\function_protected_obj.xpm" );
		public_method_xpm 			= getXpm( "images\\obj16\\xpm\\function_obj.xpm" );
		private_variable_xpm 		= getXpm( "images\\obj16\\xpm\\variable_private_obj.xpm" );
		protected_variable_xpm 		= getXpm( "images\\obj16\\xpm\\variable_protected_obj.xpm" );
		public_variable_xpm 		= getXpm( "images\\obj16\\xpm\\variable_obj.xpm" );
		class_private_obj_xpm 		= getXpm( "images\\obj16\\xpm\\class_private_obj.xpm" );
		class_protected_obj_xpm		= getXpm( "images\\obj16\\xpm\\class_protected_obj.xpm" );
		class_obj_xpm 				= getXpm( "images\\obj16\\xpm\\class_obj.xpm" );
		struct_private_obj_xpm 		= getXpm( "images\\obj16\\xpm\\struct_private_obj.xpm" );
		struct_protected_obj_xpm 	= getXpm( "images\\obj16\\xpm\\struct_protected_obj.xpm" );
		struct_obj_xpm 				= getXpm( "images\\obj16\\xpm\\struct_obj.xpm" );
		interface_private_obj_xpm 	= getXpm( "images\\obj16\\xpm\\interface_private_obj.xpm" );
		interface_protected_obj_xpm = getXpm( "images\\obj16\\xpm\\interface_protected_obj.xpm" );
		interface_obj_xpm 			= getXpm( "images\\obj16\\xpm\\interface_obj.xpm" );
		union_private_obj_xpm 		= getXpm( "images\\obj16\\xpm\\union_private_obj.xpm" );
		union_protected_obj_xpm 	= getXpm( "images\\obj16\\xpm\\union_protected_obj.xpm" );
		union_obj_xpm 				= getXpm( "images\\obj16\\xpm\\union_obj.xpm" );
		enum_private_obj_xpm 		= getXpm( "images\\obj16\\xpm\\enum_private_obj.xpm" );
		enum_protected_obj_xpm 		= getXpm( "images\\obj16\\xpm\\enum_protected_obj.xpm" );
		enum_obj_xpm 				= getXpm( "images\\obj16\\xpm\\enum_obj.xpm" );
		
		normal_xpm 					= getXpm( "images\\obj16\\xpm\\normal.xpm" );
		import_xpm 					= getXpm( "images\\obj16\\xpm\\import.xpm" );
		autoWord_xpm 				= getXpm( "images\\obj16\\xpm\\autoword.xpm" );

		parameter_xpm				= getXpm( "images\\obj16\\xpm\\parameter_obj.xpm" );
		enum_member_obj_xpm			= getXpm( "images\\obj16\\xpm\\enum_member_obj.xpm" );
		template_obj_xpm			= getXpm( "images\\obj16\\xpm\\template_obj.xpm" );

		alias_obj_xpm				= getXpm( "images\\obj16\\xpm\\alias_obj.xpm" );
		mixin_template_obj_xpm		= getXpm( "images\\obj16\\xpm\\mixin_template_obj.xpm" );
		functionpointer_obj_xpm		= getXpm( "images\\obj16\\xpm\\functionpointer_obj.xpm" );
		
		template_function_obj_xpm	= getXpm( "images\\obj16\\xpm\\template_function_obj.xpm" );
		template_class_obj_xpm		= getXpm( "images\\obj16\\xpm\\template_class_obj.xpm" );
		template_struct_obj_xpm		= getXpm( "images\\obj16\\xpm\\template_struct_obj.xpm" );
		template_union_obj_xpm		= getXpm( "images\\obj16\\xpm\\template_union_obj.xpm" );
		template_interface_obj_xpm	= getXpm( "images\\obj16\\xpm\\template_interface_obj.xpm" );
	}

	public void addEditorListener(EditorListener listener)
	{
		if(listener)
			eventListeners ~= listener;
	}

	public void removeEditorListener(EditorListener listener)
	{
		if(listener)
			TVector!(EditorListener).remove(eventListeners, listener);
	}

	public void fireEditorEvent(int type, EditItem item)
	{
		foreach(EditorListener listener; eventListeners)
		{
			_EditorEvent e = _EditorEvent(type, item);
			if(type == EEV_ACTIVE_CHANGE)
				listener.onActiveEditItemChanged(&e);
			else if(type == EEV_ALL_CLOSED)
				listener.onAllEditItemClosed(&e);
			else if(type == EEV_SAVE_STATE)
				listener.onEditItemSaveStateChanged(&e);
			else if(type == EEV_ITEM_DISPOSE)
				listener.onEditItemDisposed(&e);
		}
	}

	/**
	 * check whether any opened files modified externally
	 */
	public void checkExternModify() {
		
		/**
		 * Since every time the main shell gains focus, a checkExterModify event occurs,
		 * this will happen serveral times during checkExternModify() because we popup dialogs
		 * for users to make choice. And this will cause endless loop. The fix is set a flag,
		 * when a checking is progress, the subsequent checking ignored.
		 */
		if(modifyChecking) return;
		
		// auto set/reset modifyChecking flag
		scope amp = new AutoModifyProtect(this); 
		 
		EditItem[] eisNeedUpdate;
		EditItem[] eisDeleted;
		EditItem[] items = cast(EditItem[])getItems();
		foreach(EditItem ei; items) {
			assert(ei);
			int state = ei.getExternalModify();
			if(state == 1) 
				eisNeedUpdate ~= ei;
			else if(state == -1)
				eisDeleted ~= ei;
			
		}
		if(eisDeleted.length > 0) {
			
			char[] query = Globals.getTranslation("mb.extmodify");
			foreach(EditItem item; eisDeleted) {
				char[] title = item.getFileName() ~ " " ~ query;
				if(DWT.YES == MessageBox.showMessage(title, 
					Globals.getTranslation("mb.filechange"), getShell(), DWT.ICON_QUESTION | DWT.YES | DWT.NO)) 
				{
					item.setTitleModified(true);
				}else{
					// DWT.NO
					// don't prompt to save
					item.close(false);
				}
			}
		}
	
		if(eisNeedUpdate.length > 0) {
			// Yes No All None
			// 0, 1, 2, 3
			int flag = -1;
			foreach(EditItem item; eisNeedUpdate) 
			{
				if(flag != 2 && flag != 3){
					AskReloadDlg dlg = new AskReloadDlg(getShell(), item.getFileName());
					flag = dlg.open();
				}
				if(flag == 3) {
					item.updateFileTime();
				}
				if(flag == 0 || flag == 2){
					int line = item.scintilla.getCurrentLineNumber();
					item.loadFile(item.getFileName());
					item.scintilla.gotoLine(line);
				}else if(flag == 1){
					item.updateFileTime();
				}
				
			}
		}
		
	}
	
	/**
	 * check whether any opened files unsaved when app exit
	 */
	public boolean checkUnsaved() {
		return closeAll();
	}
	
	/**
	 * when prompt to save, user chooses cancel, return false;
	 * otherwise return true;
	 * 
	 */
	public boolean closeAll() {
		EditItem[] items = cast(EditItem[])getItems();
		foreach(EditItem ei; items) {
			if(!ei.close())
				return false;
		}
		return true;
	}
	
	// when prompt to save, user chooses cancel, return false;
	// otherwise return true;
	public boolean closeOthers(CTabItem item) {
		if(item is null)
			item = this.getSelection();
		EditItem[] items = cast(EditItem[])getItems();
		foreach(EditItem ei; items) {
			if(ei !is item){
				if(!ei.close()) 
					return false;
			}
		}
		return true;
	}
	
	public boolean closeFile(char[] fullpathname) {
		EditItem item = findEditItem(fullpathname);
		if(item)
			return item.close();
		return true;
	}
	
	/** 
	 * close all opened files which  belongs to the project
	 */
	public boolean closeProject(Project prj) {
		EditItem[] children = cast(EditItem[])getItems();
		foreach(EditItem doc; children) {
			if(doc.iteminfo && doc.iteminfo.project is prj) {
				if(!doc.close())
					return false;
			}
		}

		prj.save();

		if( Globals.useCodeCompletion || Globals.showOnlyClassBrowser )
			sAutoComplete.saveNCB( prj.projectDir, prj.projectName, prj.projectFiles ~ prj.projectInterfaces );
			
		return true;
	}

	private void doSearch(FindOption fop, int action)
	{
		char[] strScope, strAction;
		char[] strReplace = "";
		switch(action){
			case SearchDlg.FIND_ALL:
				strAction = "Find \"" ~ fop.strFind ~ "\" in ";
				break;
			case SearchDlg.REPLACE_ALL:
				strAction = "Replace \"" ~ fop.strFind ~ "\" to \"" ~ fop.strReplace ~ "\" in ";
				strReplace = "/ Replaced ";
				break;
			case SearchDlg.MARK_ALL:
				strAction = "Mark \"" ~ fop.strFind ~ "\" in ";
				break;
			case SearchDlg.COUNT_ALL:
				strAction = "Count \"" ~ fop.strFind ~ "\" in ";
				break;
			default : break;
		}
		
		switch(fop._scope) {
		case SS_CURFILE:
			strScope = "current file";
			break;
		case SS_OPENEDFILES:
			strScope = "all opened files.";
			break;
		case SS_CURPROJECT:
			strScope = "current project.";
			break;
		case SS_ALLPROJECTS:
			strScope = "all projects.";
			break;
		default:assert(0);
		}
		sGUI.searchPanel.setString(strAction ~ strScope ~ "\n\n");
		sGUI.searchPanel.bringToFront();
		sGUI.searchPanel.setBusy(true);
		
		if(fop._scope == SS_CURFILE){
			EditItem ei = cast(EditItem)getSelection();
			assert(ei);
			int count = processAll(fop, action, ei.scintilla, false);
			sGUI.searchPanel.appendLine("\nTotally found " ~ strReplace  ~ std.string.toString(count));			
			sGUI.searchPanel.setBusy(false);
		}
		else if(fop._scope == SS_OPENEDFILES){
			EditItem[] eis = cast(EditItem[])getItems();
			int count = 0;
			foreach(EditItem ei; eis)
				count += processAll(fop, action, ei.scintilla, false);
			sGUI.searchPanel.appendLine("\nTotally found " ~ strReplace ~ std.string.toString(count)
				 ~ ", \tFile scaned " ~ std.string.toString(eis.length));
			sGUI.searchPanel.setBusy(false);
		}
		else if(fop._scope == SS_CURPROJECT){
			// any documents opened already must be processed in GUI thread
			// because they may be unsaved
			EditItem[] 	eis = prepareItemsToSearch(sGUI.packageExp.activeProject);
			char[][]	redundance;
			int count = 0;
			foreach(EditItem ei; eis){
				count += processAll(fop, action, ei.scintilla, false);
				redundance ~= ei.getFileName();
			}
			// prpare the file list to process
			char[][] filelist = sGUI.packageExp.getProjectFiles(sGUI.packageExp.activeProject);
			filelist = removeRedundance(filelist, redundance); 
			// do other search in the background thread
			// Currently background thread not implemented yet
			Editor.searchObj = new SearchObj(filelist, fop, new Integer(count), new Integer(eis.length), action);
			
			Thread thread = new Thread(&_doSearchThread);
			thread.run();
		}
		else if(fop._scope == SS_ALLPROJECTS){
			// any documents opened already must be processed in GUI thread,
			// because they may be unsaved
			EditItem[] 	eis = prepareItemsToSearch(null);
			char[][]	redundance;
			int count = 0;
			foreach(EditItem ei; eis){
				count += processAll(fop, action, ei.scintilla, false);
				redundance ~= ei.getFileName();
			}
			// prpare the file list to process 
			char[][] filelist = sGUI.packageExp.getProjectsFiles();
			filelist = removeRedundance(filelist, redundance);
			// do other search in the background thread
			Editor.searchObj = new SearchObj(filelist, fop, new Integer(count), new Integer(eis.length), action);
			
			Thread thread = new Thread(&_doSearchThread);
			thread.run();
		}
	}
	
	/*
	 * All codes in this method is executed in background thread, don't access any GUI resource directly,
	 * use Display.asyncExec() or Display.syncExec() instead  
	 */
	private int _doSearchThread(){
		// nested functions
		void _loadFile(Object args){
			if(!searchObj._continue || invisibleSC.isDisposed()) 
				return;
			
			char[] filename = (cast(StringObj)args).data;
			// don't use ScintillaEx.loadFile() directly, because it do much extra works
			// load file myself to promote performance
			Editor.invisibleSC.clearAll();
			Editor.invisibleSC.setFileName(filename);
			
			char[] buffer;
			int ibom;
			try{
				FileReader.read(filename, buffer, ibom);
			}catch(Exception e){
				return;
			}
			// add text to scintilla
			Editor.invisibleSC.addText(buffer);
			Editor.invisibleSC.ibom = ibom;	// used in replace operation when save the file
			delete buffer;
		}
		
		void _doit(Object args){
			if(!searchObj._continue || invisibleSC.isDisposed()) 
				return;
			
			int times = processAll(searchObj.fop, searchObj.action, Editor.invisibleSC, true);
			searchObj.count.value += times;
			searchObj.fileCnt.value += 1;
		}

		void _end(Object args){
			if(invisibleSC.isDisposed() || sGUI.searchPanel.isDisposed()) 
				return;
				
			Editor.invisibleSC.clearAll();
			if(!searchObj._continue){
				sGUI.searchPanel.appendLine("\nCanced by user."); 
			}
			char[] strReplace = "";
			if(searchObj.action == SearchDlg.REPLACE_ALL) strReplace = "/ Replaced ";
			sGUI.searchPanel.appendLine("\nTotally found " ~ strReplace ~ std.string.toString(searchObj.count.value)
				 ~ ", \tFile scaned " ~ std.string.toString(searchObj.fileCnt.value));
			
			sGUI.searchPanel.setBusy(false);
			Editor.searchObj = null;
		}				
		
		// code begin here
		Display display = Display.getCurrent();
		
		foreach(char[] file; searchObj.filelist){		
			StringObj args = new StringObj(file);
			display.asyncExec(args, &_loadFile);
			MiscUtil.sleep(10);
			display.asyncExec(null, &_doit);
			MiscUtil.sleep(10);
		}
		display.asyncExec(null, &_end);
		
		return 0;
	}	
		
	EditItem findEditItem(CTabItem item) {
		if(item is null )	
			return null;
		return cast(EditItem)item;
	}
	
	EditItem findEditItem(char[] fullpathname) {
		assert(fullpathname);
		CTabItem[] items = this.getItems();
		foreach(CTabItem item; items) {
			EditItem ei = cast(EditItem)item;
			// Util.trace(ei.getFileName());
			// Util.trace(fullpathname);
			// windows platform is case insensitive
			version(Windows){
			if(std.string.icmp(ei.getFileName(), fullpathname) == 0 ) 
				return ei;
			}else{
			if(ei.getFileName() == fullpathname ) 
				return ei;
			}
		}
		return null;
	}
	
	/**
	 *
	 */
	public void findInSelection(FindOption fop) {
	}
	
	public Scintilla findScintilla(char[] filename) {
		EditItem ei = findEditItem(filename);
		if(ei)	
			return ei.scintilla;
		return null;
	}
	
	private Menu getContextMenu() {
		if(contextMenu is null) {
			contextMenu = new Menu(this);
			with(new MenuItem(contextMenu, DWT.PUSH))
			{
				setData(LANG_ID, "tb.save");
				handleEvent(null, DWT.Selection, delegate(Event e){
					pthis.save();
				});
			}
			with(new MenuItem(contextMenu, DWT.PUSH))
			{
				setData(LANG_ID, "tb.saveall");
				handleEvent(null, DWT.Selection, delegate(Event e){
					pthis.saveAll();
				});
			}
			new MenuItem(contextMenu, DWT.SEPARATOR);
			with(new MenuItem(contextMenu, DWT.PUSH))
			{
				setData(LANG_ID, "CLOSE");
				handleEvent(null, DWT.Selection, delegate(Event e){
					(cast(EditItem)pthis.getSelection()).close();
				});
			}
			with(new MenuItem(contextMenu, DWT.PUSH)){
				setData(LANG_ID, "CLOSE_OTHERS");
				handleEvent(null, DWT.Selection, delegate(Event e){
					pthis.closeOthers(pthis.getSelection());
				});
			}
			with(new MenuItem(contextMenu, DWT.PUSH)) {
				setData(LANG_ID, "CLOSE_ALL");
				handleEvent(null, DWT.Selection, delegate(Event e){
					pthis.closeAll();
				});
			}

			MenuManager.updateMenuI18N(contextMenu);
		} 
		return contextMenu;
	}	
	
	/**
	 * return a temp array of the current opened file names
	 */
	public char[][] getFileNames() {
		EditItem[] items = cast(EditItem[])getItems();
		char[][] names;
		foreach(EditItem item; items) {
			names ~= item.getFileName();
		}
		return names;
	}
	
	char[] getSelectedFileName() {
		EditItem ei = cast(EditItem)getSelection();
		if(ei){
			return ei.getFileName();
		}
		return null;
	}

	bool selectedIsProjectFile()
	{
		EditItem ei = cast(EditItem)getSelection();
		if( ei )
			return sGUI.packageExp.isFileInProjects( ei.getFileName() );

		return false;
	}
	
	public char[] getSelText(){
		EditItem ei = cast(EditItem)getSelection();
		if(ei){
			return ei.scintilla.getSelText();
		}
		return null;
	}
	
	/++
	 + return 4 int value 
	 + [0] current line or -1 when no scintilla editor opened
	 + [1] current col or -1 when no scintilla editor opened 
	 + [2] 0/1 for insert/overwrite, -1 when no scintilla editor opened 
	 + [3] file encoding, -1 for ANSI/MBCS, BOM.UTF8/UTF16LE...
	 +/
	public int[] getLineInfo() {
		int[] result = new int[4];
		EditItem ei = cast(EditItem)getSelection();
		if(ei){
			int nPos = ei.scintilla.getCurrentPos();
  			result[0] = ei.scintilla.lineFromPosition(nPos);
  			result[1] = ei.scintilla.getColumn(nPos);
  			result[2] = ei.scintilla.getOvertype();
			result[3] = ei.scintilla.ibom;
		}else{
			result[0] = -1;
			result[1] = -1; 
			result[2] = -1; 
			result[3] = -1;
		}
		return result;
	}
	
	public CTabFolder getTabFolder() {
		return this;
	}

	/+
	public void handleEditorEvent(Object customData, int eventType, void delegate(EditorEvent) func) {
		EvtHandler hand;
		hand.type = eventType;
		hand.cData = customData;
		hand.func = func;
		eventHandlers ~= hand;
	}+/
	
	public boolean isFileOpened(char[] fullpathname) {
		assert(fullpathname);
		EditItem ei = findEditItem(fullpathname);
		return (ei !is null);
	}
	
	public static boolean isSearchBusy(){
		return (Editor.searchObj !is null);
	}
	
	public boolean modified() {
		 EditItem ei = cast(EditItem)getSelection();
		 if(ei) 
		 	return ei.modified(); 
		 return false;		 
	}


	/**
	 * the CTabFolder dispose as well as this Editor
	 */
	private void onDispose(Event e){
		if(contextMenu)	
			contextMenu.dispose();
		if(findDlg)
			findDlg.dispose();
		if(invisibleSC)
			invisibleSC.dispose();
	}
	
	private void onTabFolderItemClose(CTabFolderEvent e) {
		EditItem ei = cast(EditItem)e.item;
		if(ei is null)
			return;
		if(!ei.close())
			e.doit = false;

		/*
		set the sAutoComplete.setFileParser to null,
		then onTabFolderSelection() will set the new sAutoComplete.setFileParser if TabItem is exist....
		*/
		sAutoComplete.setFileParser( null );
	}
		
	private void onTabFolderSelection( Event e ) 
	{
		EditItem ei = cast(EditItem) e.item;
		ei.reportErrors();
		/*
		sAutoComplete.setFileParser( sAutoComplete.getParserFromProjectParser( ei.getFileName() ) );
		if( ei.fileParser is null ) ei.fileParser = sAutoComplete.fileParser;
		*/
		sAutoComplete.setFileParser( ei.fileParser );

		fireEditorEvent(EEV_ACTIVE_CHANGE, ei);
		ei.scintilla.forceFocus();
	}
	
	private void onTabFolderMouseUp(Event e) {
		if(e.button == 3)
		{
			CTabItem item = this.getItem(new Point(e.x, e.y));
			if(item)
			{
				// the right button to track popup menu
				Menu menu = getContextMenu();
				menu.setLocation(this.toDisplay(e.x, e.y));
				menu.setVisible(true);
			}
		}
		else if(e.button == 2)
		{
			EditItem ei = cast(EditItem)this.getItem(new Point(e.x, e.y));
			if( ei !is null ) closeFile( ei.getFileName );
		}
	} 

	public boolean openFile(char[] fullpathname, ItemInfo iteminfo, int line = -1, bool focus = false )
	{
		assert(fullpathname);
		// Util.trace(fullpathname);

		char[] ext = std.string.tolower( std.path.getExt( fullpathname ) );

		if( !ext.length )
		{
			if( fullpathname.length >= 9 )
			{
				if( fullpathname[0..8] == "Untitled" ) 
				{
					EditItem ei = findEditItem( fullpathname );
					if( ei is null )
					{
						ei = new EditItem( this, iteminfo, fullpathname );
						if( line == -1 ) line = 0;
						//ei.updateFileParser(fullpathname);
					}
					
					// fix : 20060126 shawn liu
					// fire CTabFolder.Selection event, DWT will not fire this event when you call 
					// CTabFolder.setSelection(int) or CTabFolder.setSelection(CTabItem)
					setSelectionAndNotify(ei);

					ei.scintilla.forceFocus();

					if( line >= 0 )
					{
						ei.scintilla.call( ei.scintilla.SCI_ENSUREVISIBLEENFORCEPOLICY, line );
						ei.setSelection( line );
					}
					
					return true;
				}
			}
		}

		if( !sGUI.packageExp.isInExplorerOthers( fullpathname ) )
		{
			if( focus )
			{
				scope p = new Program;
				p.launch( fullpathname );
			}
			return true;
		}		
		
		if( !std.file.exists( fullpathname ) )
		{
			MessageBox.showMessage(Globals.getTranslation("mb.file_not_exists") ~ "\n\""~fullpathname ~ "\"", Globals.getTranslation("ERROR"), getShell());
			return false;
		}
		if( !std.file.isfile( fullpathname ) )
		{
			MessageBox.showMessage(Globals.getTranslation("mb.invalid_file") ~ "\n\"" ~ fullpathname ~ "\"", Globals.getTranslation("ERROR"), getShell());
			return false;
		}
		
		// don't open those relative path file
		if( !std.path.isabs( fullpathname ) ) return false;
		
		version( Windows )
		{
			// windows is case insensitive	
			// TODO: there seems a bug in Phobos, tolower() convert Chinese char error
			// fullpathname = std.string.tolower(fullpathname);
			// fullpathname = Converter.tolower(fullpathname);
		}
		
		// 此EditItem尚未開啟
		EditItem ei = findEditItem( fullpathname );
		if( ei is null )
		{
			ei = new EditItem( this, iteminfo, fullpathname );
			if( line == -1 ) line = 0;
			//ei.updateFileParser(fullpathname);
		}
		
        // fix : 20060126 shawn liu
		// fire CTabFolder.Selection event, DWT will not fire this event when you call 
		// CTabFolder.setSelection(int) or CTabFolder.setSelection(CTabItem)
		setSelectionAndNotify(ei);

		if( focus ) ei.scintilla.forceFocus();

		if( line >=0 )
		{
			ei.scintilla.call( ei.scintilla.SCI_ENSUREVISIBLEENFORCEPOLICY, line );
			ei.setSelection( line );
		}
		
		return true;
	}
	
	/// prepare the items to Search, in opened documents 
	/// \param project, if project is null, then find all opened doc, else find docs in the project
	private EditItem[] prepareItemsToSearch(Project project) {
		EditItem[] eis = cast(EditItem[])getItems();
		EditItem[] result; 
		if(project) {
			foreach(EditItem ei; eis){
				if(ei.iteminfo && ei.iteminfo.project is project)
					result ~= ei;
			}
		}else{
			foreach(EditItem ei; eis){
				// the doc must belong to some project, if iteminfo is not null
				if(ei.iteminfo)
					result ~= ei;
			}
		}
		return result;
	}
	public void processMarkerCmd(char[] cmd){
		EditItem ei = cast(EditItem)getSelection();
		if(ei is null) return;
		switch(cmd){
			case "tb.markclr" :
				ei.markerClear();
				break;
			case "tb.marknext":
				ei.markerNext();
				break;
			case "tb.markprev":
				ei.markerPrevious();
				break;
			case "tb.marktoggle":
				ei.markerToggle();
				break;
			default : break;
		}
	}
	
	//  make it static so nested function can access freely
	/// \param savechanges 
	static int processAll(FindOption fop, int op, ScintillaEx scx, bool savechanges = false){
		// nested function
		void _output(Object obj){
			StringObj s = cast(StringObj)obj;
			sGUI.searchPanel.appendString(s.data);
		}
		
		Display display = Display.getCurrent();
		
		int nbReplaced = 0;
		
		char[] file = scx.getFileName();
		
		if ((op == SearchDlg.REPLACE_ALL) && scx.getReadOnly())
			return nbReplaced;
		
		int startPosition = 0;
		int docLength = scx.getLength();
		int endPosition = docLength;
		
		int flags = fop.bCase ? Scintilla.SCFIND_MATCHCASE : 0;
		flags |= fop.bWord ? Scintilla.SCFIND_WHOLEWORD : 0;
  		flags |= fop.bRegexp ? Scintilla.SCFIND_REGEXP | Scintilla.SCFIND_POSIX : 0;
		
		scx.setTargetStart(startPosition);
		scx.setTargetEnd(endPosition);
		scx.setSearchFlags(flags);
	
		if (op == SearchDlg.MARK_ALL){
			scx.markerDeleteAll(MARK_SYMBOLE);
		}
	
		int posFind = scx.searchInTarget(fop.strFind);
		
		while (posFind != -1 && !scx.isDisposed())
		{		
			int posFindBefore = posFind;
			int start = scx.getTargetStart();
			int end = scx.getTargetEnd();
			int foundTextLen = (end >= start)?end - start : start - end;
	
			if (foundTextLen < 0)
				return -1;
			
			if (op == SearchDlg.REPLACE_ALL)
			{
				int lineNumber = scx.lineFromPosition(posFind);
				char[] line = scx.getLine(lineNumber);
				char[] result = file ~ "("~ std.string.toString(lineNumber + 1) ~"): " ~ line;
				/*
				 * _output  method should be executed sync instead of async
				 * because processAll() maybe executed async in a thread other than the GUI thread				 
				 */
				display.syncExec(new StringObj(result ~ "\n"), &_output);

				
				scx.setTargetStart(start);
				scx.setTargetEnd(end);

				int replacedLength;
				if(fop.bRegexp){
					replacedLength = scx.replaceTargetRE(fop.strReplace);
				}else{
					replacedLength = scx.replaceTarget(fop.strReplace);
				}

				if( foundTextLen == 0 )
				{
					startPosition = posFind + replacedLength;
					if( posFind >= docLength ) return nbReplaced + 1;		
					endPosition = docLength = docLength - foundTextLen + replacedLength;
				}
				else
				{
					startPosition = posFind + replacedLength;
					endPosition = docLength = docLength - foundTextLen + replacedLength;
				}
			}
			else if (op == SearchDlg.MARK_ALL)
			{
				if( foundTextLen == 0 ) 
				{
					if( startPosition >= docLength ) return nbReplaced;
				}
				
				int lineNumber = scx.lineFromPosition(posFind);
				int state = scx.markerGet(lineNumber);
				if (!(state & (1 << MARK_SYMBOLE)))
					scx.markerAdd(lineNumber, MARK_SYMBOLE);
				startPosition = (!fop.bForward) ? posFind - foundTextLen : posFind + foundTextLen;
			}
			else if (op == SearchDlg.COUNT_ALL)
			{
				if( foundTextLen == 0 ) 
				{
					if( startPosition >= docLength ) return nbReplaced;
				}

				startPosition = posFind + foundTextLen;
			}
			else if (op == SearchDlg.FIND_ALL)
			{
				if( foundTextLen == 0 ) 
				{
					if( startPosition >= docLength ) return nbReplaced;
				}
				
				int lineNumber = scx.lineFromPosition(posFind);
				int lend = scx.getLineEndPosition(lineNumber);
				int lstart = scx.positionFromLine(lineNumber);
				int nbChar = lend - lstart;
				char[] line = scx.getLine(lineNumber);
				char[] result = file ~ "("~ std.string.toString(lineNumber + 1) ~"): " ~ line;
//				Util.trace(result);
				/*
				 * _output  method should be executed sync instead of async
				 * because processAll() maybe executed async in a thread other than the GUI thread				 
				 */
				display.syncExec(new StringObj(result ~ "\n"), &_output);

				startPosition = posFind + foundTextLen;
			}
			else
				return nbReplaced;
			
			scx.setTargetStart(startPosition);
			scx.setTargetEnd(endPosition);
	
			posFind = scx.searchInTarget(fop.strFind);
			nbReplaced++;
		}
		
		// save the file if replace operation, but the opened file should be keep unsaved
		if (!scx.isDisposed() && op == SearchDlg.REPLACE_ALL && savechanges){
			scx.saveFile(scx.getFileName());
		}
			
		return nbReplaced;
	}
	

	/**
	 * remove the redundance from source, return the left,
	 * Note : the source will be changed !!! make a copy if you want to keep source
	 */
	public static char[][] removeRedundance(char[][] source, char[][] redundance){
		
		for(int i=0; i<redundance.length; ++i)
			TVector!(char[]).remove(source, redundance[i]);
		return source;
	}
	
	public void rename(char[] fullname, char[] newname) {
		EditItem ei = findEditItem(fullname);
		if(ei) {
			ei.rename(newname);
		}
	}

	public void resetSettings() {
		EditItem[] items = cast(EditItem[])getItems();
		foreach(EditItem item; items) {
			Editor.settings.applySettings(item.scintilla, std.path.getExt(item.getFileName()));
		}
	}
	
	public void save() {
		 EditItem ei = cast(EditItem)getSelection();
		 if(ei) 
		 	ei.save();
	}

	public void saveAs() {
		 EditItem ei = cast(EditItem)getSelection();
		 if(ei) 
		 	ei.saveAs();
	}
	
	public ItemInfo getSelectedItemInfoHSU()
	{
		EditItem ei = cast(EditItem)getSelection();
		if( ei ) return ei.iteminfo;else return null;
	}

	public EditItem getSelectedEditItemHSU()
	{
		EditItem ei = cast(EditItem)getSelection();
		return ei;
	}

	public Project getSelectedProjectHSU()
	{
		ItemInfo iteminfo = getSelectedItemInfoHSU();
		if( iteminfo ) return iteminfo.getProject();else return null;
	}

	public boolean direct2EditItemHSU( int cases )
	{
		EditItem ei = cast(EditItem)getSelection();
		if( ei )
		{
			switch( cases )
			{
				case 0:
					return ei.scintilla.canUndo(); break;
				case 1:
					return ei.scintilla.canRedo(); break;
				case 2:
					return ei.scintilla.canPaste(); break;
				case 3:
					ei.toolbarDirectlyHSU( 5 ); return true; break;
				case 4: // toggle comment
					ei.toolbarDirectlyHSU( 6 ); return true; break;
				case 5: // stream comment
					ei.toolbarDirectlyHSU( 7 ); return true; break;
				case 6: // box comment
					ei.toolbarDirectlyHSU( 8 ); return true; break;
				case 7: // find
					ei.toolbarDirectlyHSU( 9 ); return true; break;
				case 8: // goto
					ei.showGotoLine(); return true; break;
				case 9: // nest comment
					ei.toolbarDirectlyHSU( 10 );; return true; break;					
			}
		}
		return false;		 
	}		
	
	public boolean saveAll() {
		EditItem[] eis = cast(EditItem[])getItems();
		foreach(EditItem ei; eis) {
			if(!ei.save())
				return false;
		}
		return true;
	}

	public boolean saveProjectFile()
	{
		EditItem[] 	eis = cast(EditItem[])getItems();
		char[][] 	files = sGUI.packageExp.getActiveProjectFiles();
		
		foreach( EditItem ei; eis )
		{
			foreach( char[] s; files )
			{
				if( ei.getFileName() == s )
				{
					if( !ei.save() ) return false;
				}
			}
		}

		return true;
	}	
	
	// not used in branch 0.2	
	/+
	private void sendEvent(int type, EditorEvent e) {
		_EditorEvent evt;
		_EditorEvent* event;
		if(e) 
			event = e;
		else{
			EditItem ei = cast(EditItem)getSelection();
			event = &evt;
			event.iteminfo = ei ? ei.iteminfo : null;
			event.scModified = ei ? ei.modified : false;
		}
				
		foreach(EvtHandler hand; eventHandlers) {
			if(hand.type == type)
				hand.func(event);
		}
	}
	+/
	void setSelectionAndNotify(EditItem item){
		int index = indexOf(item);
		super.setSelection(index, true);
	}
	
	public void showSearchDlg() {
		char[] selText = getSelText();
		scope dlg = new SearchDlg(getShell(), selText);

		dlg.setImageString( "search" );
		
		char[] result = dlg.open();
		if(result == "OK")
		{
			if(dlg.fop.strFind.length == 0)
				return;
			if(dlg.fop._scope == SS_CURFILE || 
				dlg.fop._scope == SS_OPENEDFILES)
			{
				int count = getItemCount();
				if(count == 0)
					return;
			}
			
			if(isSearchBusy()){
				MessageBox.showMessage(Globals.getTranslation("mb.search_in_progress"), Globals.getTranslation("WARNING"),
					getShell(), DWT.ICON_WARNING);
				return;
			}
				
			if(dlg.fop._scope == SS_CURPROJECT || dlg.fop._scope == SS_ALLPROJECTS){
				if(sGUI.packageExp.getProjectCount() == 0)
					return;
			}
				
			if(dlg.fop._scope == SS_CURPROJECT && (sGUI.packageExp.activeProject is null))
				return;
			
			scope wc = new WaitCursor(getShell());
			int action = dlg.action;
			doSearch(dlg.fop, action);
		}
	}
		
	public static void stopSearch() {
		if(Editor.searchObj !is null){
			Editor.searchObj._continue = false;
		}
	}
	
	
	public void toggleMaximized() {
		SashForm sash = cast(SashForm)this.getParent();
		assert(sash);
		if(sash.getMaximizedControl())
		{
			sash.setMaximizedControl( null );
			sGUI.menuMan.classBrowserItem.setSelection( true );
		}
		else
		{
			sash.setMaximizedControl( this );
			sGUI.menuMan.classBrowserItem.setSelection( false );
		}
	}

	// when update the project, ItemInfo is regenerated, must update them
	public void updateItemInfo(char[] filename, ItemInfo info) {
		
		EditItem edtitem = findEditItem(filename);
		if(edtitem){
			edtitem.iteminfo = info;
		}
	} 

	void updateI18N()
	{
		findDlg.updateI18N();
		if(contextMenu){
			MenuManager.updateMenuI18N(contextMenu);
		}
			
	}
}


