module poseidon.controller.dialog.searchdlg;


private import dwt.all;
private import ak.xml.coreXML;
private import poseidon.controller.dialog.generaldialog;
private import poseidon.model.misc;
private import poseidon.controller.dialog.finddlg;
private import poseidon.globals;
private import poseidon.i18n.itranslatable;
private import poseidon.i18n.i18nshop;
private import poseidon.util.miscutil;
private import poseidon.util.layoutshop;


// the search scope
enum {
	SS_CURFILE, 
	SS_OPENEDFILES,
	SS_CURPROJECT,
	SS_ALLPROJECTS,
	SS_MAX,
}
	
class SearchDlg : GeneralDialog, ITranslatable
{
	// action
	enum{
		FIND_ALL,
		COUNT_ALL,
		REPLACE_ALL,
		MARK_ALL,
	}

	FindOption fop;
	
	int action;
	
	// items limit of find/replace history
	const uint ITEM_LIMIT = 20;
	

	const char[][] strOption = [
		"Match Case", "Whole Word Only", "Reqular Expression"
	];
	
	// find/replace history
	private char[][] str2Find;
	private char[][] str2Replace;
	
		
	private Combo cobFind, cobReplace;
	// regexp and substitute button
	private Button 	btnReg, btnSub;
	private Menu	menuReg, menuSub;
	private Button 	btnMarkAll;
	
	private char[]	initStr;
	
	this(Shell parent, char[] initStr)
	{
		this.initStr = initStr;
		super(parent);
	}
	
	protected Shell createShell(Shell parent){
		fop = new FindOption;
		loadHistory();
		Shell shell = new Shell(parent, DWT.DIALOG_TRIM | DWT.RESIZE | DWT.APPLICATION_MODAL);
		
		initGUI(shell);
		initData();

		// since updateI18N() will access shell, pass the local shell to this.shell
		this.shell = shell;

		updateI18N();
			
		return shell;
	}
	
	/**
	 *  Add text to combo box or pop it to top  
	 */
	public void addToCache(char[] text, Combo combo = null) {
		if(text.length == 0 ) return;
		
		// default to find combo
		if(combo is null)
			combo = cobFind;
		boolean found = false;
		char[][] items = combo.getItems();
		for(int index = 0; index < items.length; ++index){
			if(items[index] == text){
				combo.remove(index);
				break;
			}
		}
		combo.add(text, 0);
		combo.setText(text);
	}
	
	void initData(){
		
		if(str2Find.length > 0){
			cobFind.setItems(str2Find);
			if(initStr.length == 0)
				cobFind.select(0);
		}
		if(str2Replace.length > 0){
			cobReplace.setItems(str2Replace);
			cobReplace.select(0);
		}
		// release the buffer
		str2Find = null;
		str2Replace = null;
		if(initStr.length > 0)
			cobFind.setText(initStr);
	}
	
	private void initGUI(Shell shell) {
		shell.setData(LANG_ID, "find.search_title");
		shell.setLayout(LayoutShop.createGridLayout(5, 10, 10));
		Label label = new Label(shell, DWT.NONE);
		label.setData(LANG_ID, "find.find_what");			
		
		cobFind = new Combo(shell, DWT.BORDER);
		with(cobFind){
			GridData gd = new GridData(GridData.FILL, GridData.CENTER, true, false, 2, 1);
			gd.minimumWidth = 180;
			setLayoutData(gd);
			setVisibleItemCount(16);
			handleEvent(null, DWT.Dispose, &onComboDispose);
		}
		with(btnReg = new Button(shell, DWT.ARROW | DWT.RIGHT)){
			setLayoutData(new GridData(FindDlg.SMALL_BTN_WIDTH, FindDlg.SMALL_BTN_WIDTH));
			setEnabled(fop.bRegexp);
			handleSelection(getRegMenu(shell), delegate(SelectionEvent e) {
				Button btn = cast(Button)e.widget;
				Menu menu = cast(Menu)e.cData;
				Rectangle rc = btn.getBounds();
				Point pt = btn.toDisplay(0, rc.height);
				menu.setLocation(pt);
				menu.setVisible(true);
			});
		}

		Button button = createButton(shell, "find.find_all", &onAction, FIND_ALL);
		label = new Label(shell, DWT.NONE);
		label.setData(LANG_ID, "find.replace_with");
		
		with(cobReplace = new Combo(shell, DWT.BORDER)){
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, 2, 1));
			setVisibleItemCount(16);
			handleEvent(null, DWT.Dispose, &onComboDispose);
		}
		
		with(btnSub = new Button(shell, DWT.ARROW | DWT.RIGHT)){
			setLayoutData(new GridData(FindDlg.SMALL_BTN_WIDTH, FindDlg.SMALL_BTN_WIDTH));
			setEnabled(fop.bRegexp);
			handleSelection(getSubstituteMenu(shell), delegate(SelectionEvent e) {
				Button btn = cast(Button)e.widget;
				Menu menu = cast(Menu)e.cData;
				Rectangle rc = btn.getBounds();
				Point pt = btn.toDisplay(0, rc.height);
				menu.setLocation(pt);
				menu.setVisible(true);
			});
		}
		
		createButton(shell, "find.count_all", &onAction, COUNT_ALL);
		
		Group leftGroup = new Group(shell, DWT.NONE);
		with(leftGroup){
			setData(LANG_ID, "OPTIONS");
			setLayoutData(new GridData(GridData.FILL, GridData.FILL, false, true, 2, 3));
			RowLayout layout = new RowLayout(DWT.VERTICAL);
			layout.marginTop = 8;
			layout.marginLeft = 12;
			layout.marginRight = 32;  
			layout.wrap = false;
			setLayout(layout);
		}
		Group rightGroup = new Group(shell, DWT.NONE);
		with(rightGroup) {
			setData(LANG_ID, "find.scope");
			setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 2, 3));
			RowLayout layout = new RowLayout(DWT.VERTICAL);
			layout.marginTop = 8;
			layout.marginLeft = 12;  
			layout.wrap = false;
			setLayout(layout);
		}
		
		createButton(shell, "find.replace_all", &onAction, REPLACE_ALL);
		btnMarkAll = createButton(shell, "find.mark_all", &onAction, MARK_ALL, (fop._scope != SS_CURPROJECT && fop._scope != SS_ALLPROJECTS ));
		Button btn = createButton(shell, "CLOSE", &onClose, -1);
		// reset Close button alignment
		GridData data = new GridData(GridData.FILL, GridData.END, false, false);
		data.horizontalIndent = 5;
		btn.setLayoutData(data);
		
		createCheckBox(leftGroup, "fop.case", fop.bCase);
		createCheckBox(leftGroup, "fop.word", fop.bWord);
		createCheckBox(leftGroup, "fop.regx", fop.bRegexp);

		createRadioBox(rightGroup, "find.whole_file", fop._scope == SS_CURFILE,  SS_CURFILE);
		createRadioBox(rightGroup, "find.all_opened_files", fop._scope == SS_OPENEDFILES, SS_OPENEDFILES);
		createRadioBox(rightGroup, "find.cur_project", fop._scope == SS_CURPROJECT, SS_CURPROJECT);
		createRadioBox(rightGroup, "find.all_projects", fop._scope == SS_ALLPROJECTS, SS_ALLPROJECTS);
	}
	
	/**
	 * create the right side button
	 */	
	private Button createButton(Composite parent, char[] lang_id, void delegate(Event) func, int action, boolean enabled = true) {
		Button button = new Button(parent, DWT.PUSH);
		button.setData(LANG_ID, lang_id);
		GridData data = new GridData(GridData.FILL, GridData.CENTER, false, false);
		data.horizontalIndent = 5;
		button.setLayoutData(data);
		button.handleEvent(null, DWT.Selection, func);
		button.setData(new Integer(action));
		button.setEnabled(enabled);
		return button;
	}
	
	private Button createCheckBox(Composite parent, char[] lang_id, boolean initVal) {
		Button check = new Button(parent, DWT.CHECK);
		check.setData(LANG_ID, lang_id);
		check.setSelection(initVal);
		check.handleSelection(null, &onCheckBox);
		return check;
	}
	
	private Button createRadioBox(Composite parent, char[] lang_id, boolean initVal, int id) {
		Button radio = new Button(parent, DWT.RADIO);
		radio.setData(LANG_ID, lang_id);
		radio.setSelection(initVal);
		radio.setData(new Integer(id));
		radio.handleEvent(null, DWT.Selection, &onScopeChange);
		return radio;
	}
	
	private MenuItem createMenuItem(Menu parent, Control receiver, char[] text, char[] data){
		MenuItem item = new MenuItem(parent, DWT.NONE);
		item.setText(text);
		item.setData(new StringObj(data));
		item.handleEvent(receiver, DWT.Selection, &onMenuItem);
		return item;
	}
 	private Menu getRegMenu(Shell shell) {
		if(menuReg is null) {
			menuReg = new Menu(shell, DWT.CASCADE);
			createMenuItem(menuReg, cobFind, `.  Any character`, `.`);
			createMenuItem(menuReg, cobFind, `*  0 or more times`, `*`);
			createMenuItem(menuReg, cobFind, `+  1 or more times`, `+`);
			new MenuItem(menuReg, DWT.SEPARATOR);
			createMenuItem(menuReg, cobFind, `^  Start of line`, `^`);
			createMenuItem(menuReg, cobFind, `$  End of line`, `$`);
			createMenuItem(menuReg, cobFind, `<  Start of word`, `<`);
			createMenuItem(menuReg, cobFind, `>  End of word`, `>`);
			new MenuItem(menuReg, DWT.SEPARATOR);
			createMenuItem(menuReg, cobFind, `[]  Character in range`, `[]`);
			createMenuItem(menuReg, cobFind, `[^]  Character not in range`, `[^]`);
			createMenuItem(menuReg, cobFind, `()  Tagged expression`, `()`);
			createMenuItem(menuReg, cobFind, `\  Exact character`, "\\");
		}
		return menuReg;
	} 
	
	// get Substitute menu
 	private Menu getSubstituteMenu(Shell shell) {
		if(menuSub is null) {
			menuSub = new Menu(shell, DWT.CASCADE);
			for(int i=1; i<=9; ++i){
				createMenuItem(menuSub, cobReplace, std.string.format("Tagged Expression %d", i), std.string.format("\\%d", i));
			}
		}
		return menuSub;
	} 
	
	private void onCheckBox(SelectionEvent e) {
		StringObj obj = cast(StringObj)e.widget.getData(LANG_ID);
		if(obj is null || obj.data is null)
			return;
		Button btn = cast(Button)e.widget;
		
		switch(obj.data){
			case "fop.case" :
				fop.bCase = btn.getSelection();
				break;
			case "fop.word" :
				fop.bWord = btn.getSelection();
				break;
			case "fop.regx" :
				fop.bRegexp = btn.getSelection();
				btnSub.setEnabled(fop.bRegexp);
				btnReg.setEnabled(fop.bRegexp);
				break;
			default : break;
		}
	}
	private void onScopeChange(Event e){
		Button radio = cast(Button)e.widget;
		/**
		 * since both selection and unselection of a radio box, will issue 
		 * the DWT.Selection event. ignore the unselection event
		 */
		if(!radio.getSelection())
			return;
		Integer ii = cast(Integer)radio.getData();
		assert(ii);
		int findScope = ii.intValue();
		fop._scope = findScope;
		
		boolean enabled = (findScope != SS_CURPROJECT)&&(findScope != SS_ALLPROJECTS);
		btnMarkAll.setEnabled(enabled);
	}
	
	private void onAction(Event e){
		Button btn = cast(Button)e.widget;
		Integer ii = cast(Integer)btn.getData();
		assert(ii);
		
		action = ii.intValue();
		
		if(action == REPLACE_ALL && fop._scope > SS_OPENEDFILES){
			if(DWT.NO == MessageBox.showMessage(Globals.getTranslation("mb.replace_warning"),
				Globals.getTranslation("find.replace_all"), getShell(), DWT.ICON_WARNING | DWT.YES | DWT.NO))
				return;
		}
		fop.strFind = cobFind.getText();
		fop.strReplace = cobReplace.getText();
		
		addToCache(fop.strFind, cobFind);
		addToCache(fop.strReplace, cobReplace);
		
		result = "OK";
		this.close();
	}

	public static char[] replaceTextSel(char[] old, char[] insert, Point pt){
		if(old.length == 0)
			return insert;
		
		assert(old.length >= pt.y);
		
		if(pt.x == 0)	return insert ~ old[pt.y..$];
		if(pt.y >= old.length) return old[0..pt.x] ~ insert;

		return old[0..pt.x] ~ insert ~ old[pt.y..$];
	}
	
	private void onMenuItem(Event e) {
		Combo cob = cast(Combo)e.cData;
		assert(cob);
		MenuItem mi = cast(MenuItem)e.widget;
		StringObj sobj = cast(StringObj)mi.getData();
//		Point pt = cob.getSelection();
//		Util.trace(pt.toString());
//		char[] text = cob.getText();
//		replaceTextSel(text, sobj.data, pt);
		cob.setText(cob.getText() ~ sobj.data);
	}
	
	void onClose(Event e){
		this.result = null;
		this.close();
	}
	
	private boolean loadHistory() {
		
		XML xml = new XML();
		char[] filename = std.path.join(Globals.appDir, "searchhistory.xml");
		if(xml.Open(filename) < 0 )
			return false; // failed
		XMLnode root = xml.m_root.getChildEx("searchhistory", null);
		XMLnode child = root.getChild("history");
		if(child){
			FindDlg._updateFindReplace(child, false, this.str2Find, this.str2Replace);
		}
		// load option
		if((child = root.getChild("option")) !is null){
			XMLattrib at = child.getAttrib("bcase");
			if(at)
				fop.bCase = std.string.atoi(at.GetValue()) > 0;
			at = child.getAttrib("bword");
			if(at)
				fop.bWord = std.string.atoi(at.GetValue()) > 0;
			at = child.getAttrib("bregexp");
			if(at)
				fop.bRegexp = std.string.atoi(at.GetValue()) > 0;
			at = child.getAttrib("scope");
			if(at)
				fop._scope = Math.min(cast(int)std.string.atoi(at.GetValue()), SS_MAX - 1);
		}
		
		delete xml; // auto close
		return true;
	}
	
	private void onComboDispose(Event e){
		saveHistory();
	}
	
	private void saveHistory() {
		/**
		 * we can't determine which combo dispose first, 
		 */
		if(cobReplace.isDisposed() || cobFind.isDisposed() )
			return;
		str2Find = cobFind.getItems();
		str2Replace = cobReplace.getItems();
		str2Find.length = Math.min(str2Find.length, ITEM_LIMIT);
		str2Replace.length = Math.min(str2Replace.length, ITEM_LIMIT);
		
		char[] filename = std.path.join(Globals.appDir, "searchhistory.xml");
		
		XML xml = new XML();
		{
			xml.m_attributes ~= new XMLattrib("version", "1.0");
			xml.m_attributes ~= new XMLattrib("encoding", "UTF-8");
		}
		
		XMLnode root = xml.m_root.getChildEx("searchhistory", null);
		XMLnode child = root.getChildEx("history", null);
		
		FindDlg._updateFindReplace(child, true, this.str2Find, this.str2Replace);
		
		// save options
		child = root.getChildEx("option", null);
		child.addAttrib("bcase", std.string.toString(fop.bCase));
		child.addAttrib("bword", std.string.toString(fop.bWord));
		child.addAttrib("bregexp", std.string.toString(fop.bRegexp));
		child.addAttrib("scope", std.string.toString(fop._scope));
		
		xml.Save(filename);
		
		delete xml; // auto close
	}

	public void updateI18N()
	{
		I18NShop.updateCompositeI18N(shell);
		
		shell.pack();
		Point pt = shell.getSize();
		pt.x = pt.y * 9 / 4;
		shell.setSize(pt);
		shell.setMinimumSize(pt);
	}
}
