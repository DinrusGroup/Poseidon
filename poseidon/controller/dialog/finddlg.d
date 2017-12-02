module poseidon.controller.dialog.finddlg;


private import dwt.all;
private import poseidon.model.misc;
private import poseidon.controller.editor;
private import ak.xml.coreXML;
private import poseidon.globals;
private import poseidon.controller.edititem;
private import poseidon.i18n.itranslatable;
private import poseidon.util.miscutil;
private import poseidon.i18n.i18nshop;


// find scope
enum{
	FS_FILE,
	FS_SELECTION
}


class FindDlg : Shell, ITranslatable
{
	// items limit of find/replace history
	const uint 	ITEM_LIMIT = 20;
	const int	SMALL_BTN_WIDTH = 22;
	
	private bool _opened;
	FindOption	fop;
	
	private Combo cobFind, cobReplace;
	private Editor editor;
	// regexp and substitute button
	private Button 	btnReg, btnSub;
	private Menu	menuReg, menuSub;
	private Button 	btnMarkAll, btnReplace, btnReplaceAll;
	private CLabel	statusBar;
	
	// find/replace history
	private char[][] str2Find;
	private char[][] str2Replace;
	
	const char[] STR_CASE = "Case Sensitive";
	const char[] STR_WRAP = "Wrap Search";
	const char[] STR_WORD = "Whole Word";
	const char[] STR_INCE = "Incremental";
	const char[] STR_REGX = "Regluar Expressions";
	
	this(Shell parent, Editor editor)
	{
		super(parent, DWT.DIALOG_TRIM | DWT.RESIZE );
		this.editor = editor;
		fop = new FindOption();
		initGUI();
		updateI18N();
		this.handleEvent(this, DWT.Close, delegate(Event e) {
			// don't close me, just hide
			(cast(Shell)e.cData).setVisible(false);
			e.doit = false;
		});
		this.handleEvent(this, DWT.Activate, delegate(Event e) {
			// don't close me, just hide
			(cast(FindDlg)e.cData).setStatus("");
		});
	}
	
	private void initGUI()
	{
		setData(LANG_ID, "find.find_title");
		GridLayout layout = new GridLayout(2, true);
		setLayout(layout);
		with(layout){
			verticalSpacing = 10;
			marginWidth = 8;
		}
		Composite top = new Composite(this, DWT.NONE);
		with(top){
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, 2, 1));
			setLayout(new GridLayout(3, false));
		}
		
		Group groupDir = new Group(this, DWT.NONE);
		with(groupDir)
		{
			setData(LANG_ID, "find.direction");
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, false, false));
			RowLayout rl = new RowLayout(DWT.VERTICAL);
			rl.wrap = false;
			setLayout(rl);
		}
		Group groupScope = new Group(this, DWT.NONE);
		with(groupScope)
		{
			setData(LANG_ID, "find.scope");
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, false, false));
			RowLayout rl = new RowLayout(DWT.VERTICAL);
			rl.wrap = false;
			setLayout(rl);
		}
		Group groupOptions = new Group(this, DWT.NONE);
		with(groupOptions){
			setData(LANG_ID, "OPTIONS");
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, 2, 1));
			setLayout(new GridLayout(2,false));
		}
		
		Composite btnBar = new Composite(this, DWT.NONE);
		with(btnBar){
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, 2, 1));
			GridLayout innerlayout = new GridLayout(2, true);
			innerlayout.marginWidth = 0;
			setLayout(innerlayout);
		}
		
		Composite bottom = new Composite(this, DWT.NONE);
		with(bottom){
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, 2, 1));
			GridLayout innerlayout = new GridLayout(2, false);
			innerlayout.marginWidth = 0;
			setLayout(innerlayout);
		}			
		
		// controls in top composite
		with(new Label(top, DWT.NONE)){
			setData(LANG_ID, "find.find_what");
		}
		with(cobFind = new Combo(top, DWT.BORDER)){
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false));
			setVisibleItemCount(16);
			handleEvent(null, DWT.Dispose, &onComboDispose);
		}
		with(btnReg = new Button(top, DWT.ARROW | DWT.RIGHT)){
			setLayoutData(new GridData(SMALL_BTN_WIDTH, SMALL_BTN_WIDTH));
			setEnabled(fop.bRegexp);
			handleSelection(getRegMenu(this), delegate(SelectionEvent e) {
				Button btn = cast(Button)e.widget;
				Menu menu = cast(Menu)e.cData;
				Rectangle rc = btn.getBounds();
				Point pt = btn.toDisplay(0, rc.height);
				menu.setLocation(pt);
				menu.setVisible(true);
			});
		}
		with(new Label(top, DWT.NONE)){
			setData(LANG_ID, "find.replace_with");
		}
		with(cobReplace = new Combo(top, DWT.BORDER)){
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false));
			setVisibleItemCount(16);
			handleEvent(null, DWT.Dispose, &onComboDispose);
		}
		with(btnSub = new Button(top, DWT.ARROW | DWT.RIGHT)){
			setLayoutData(new GridData(SMALL_BTN_WIDTH, SMALL_BTN_WIDTH));
			setEnabled(fop.bRegexp);
			handleSelection(getSubstituteMenu(this), delegate(SelectionEvent e) {
				Button btn = cast(Button)e.widget;
				Menu menu = cast(Menu)e.cData;
				Rectangle rc = btn.getBounds();
				Point pt = btn.toDisplay(0, rc.height);
				menu.setLocation(pt);
				menu.setVisible(true);
			});
		}
		
		// controls in direction group
		createRadioBox(groupDir, "find.forward", fop.bForward, 0, &onDirChange);
		createRadioBox(groupDir, "find.backward", !fop.bForward, 1, &onDirChange);
		
		// controls in scope group
		createRadioBox(groupScope, "find.all", fop.bForward, 0, &onScopeChange);
		createRadioBox(groupScope, "find.selection", !fop.bForward, 1, &onScopeChange, false);
		
		// controls in options group
		createCheckBox(groupOptions, "fop.case", 	fop.bCase);
		createCheckBox(groupOptions, "fop.wrap", 	fop.bWrap);
		createCheckBox(groupOptions, "fop.word", 	fop.bWord);
		createCheckBox(groupOptions, "fop.incr",	false, false);
		Button btnReg = createCheckBox(groupOptions, ("fop.regx"), fop.bRegexp);
		btnReg.setLayoutData(new GridData(GridData.BEGINNING, GridData.CENTER, true, false, 2, 1));
		
		// controls in button bar
		Button btnFind = createButton(btnBar, "find.find", &onFind);
		createButton(btnBar, "find.replace_find", &onReplaceFind);
		createButton(btnBar, "find.replace", &onReplace);
		createButton(btnBar, "find.replace_all", &onReplaceAll);
		createButton(btnBar, "find.count_all", &onCountAll);
		createButton(btnBar, "find.mark_all", &onMarkAll);
		
		// controls in bottom composite
		with(statusBar = new CLabel(bottom, DWT.NONE)){
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false));
		}
		with(new Button(bottom, DWT.PUSH)){
			setData(LANG_ID, "CLOSE");
			setLayoutData(new GridData(GridData.END, GridData.CENTER, false, false));
			handleEvent(this, DWT.Selection, delegate(Event e){
				(cast(Shell)e.cData).setVisible(false);
			});
		}
		
		
		// set default button to "Find", when use press VK_RETURN on any non-button control,
		// the "Find" button fired
		setDefaultButton(btnFind, true);
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
	
	private Button createButton(Composite parent, char[] lang_id, void delegate(Event) func) {
		Button btn = new Button(parent, DWT.PUSH);
		with(btn){
			setData(LANG_ID, lang_id);
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false));
			handleEvent(null, DWT.Selection, func);
		}
		return btn;
	}
	
	private Button createCheckBox(Composite parent, char[] lang_id, boolean initVal, bool enabled = true) {
		Button check = new Button(parent, DWT.CHECK);
		with(check){
			setData(LANG_ID, lang_id);
			setEnabled(enabled);
			setSelection(initVal);
			handleSelection(null, &onCheckBox);
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false));
		}
		return check;
	}
	
	private Button createRadioBox(Composite parent, char[] lang_id, boolean initVal, int id, void delegate(Event e) func, bool enalbed = true) {
		Button radio = new Button(parent, DWT.RADIO);
		with(radio){
			setData(LANG_ID, lang_id);
			setData(new Integer(id));
			setEnabled(enalbed);
			setSelection(initVal);
			handleEvent(null, DWT.Selection, func);
		}
		return radio;
	}	
	// override the Shell.open();
	public void open(){
		super.open();
		_opened = true;
		initData();
	}
	
	public bool opened() { return _opened; }
	
	void initData(){
		loadHistory();
		
		if(str2Find.length > 0){
			cobFind.setItems(str2Find);
			cobFind.select(0);
		}
		if(str2Replace.length > 0){
			cobReplace.setItems(str2Replace);
			cobReplace.select(0);
		}
		// release the buffer
		str2Find = null;
		str2Replace = null;
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
	private void onMenuItem(Event e) {
		Combo cob = cast(Combo)e.cData;
		assert(cob);
		MenuItem mi = cast(MenuItem)e.widget;
		StringObj sobj = cast(StringObj)mi.getData();
		char[] text = cob.getText();
		cob.setText(text ~ sobj.data);
	}	
	private void onCheckBox(SelectionEvent e) {
		StringObj obj = cast(StringObj)e.widget.getData(LANG_ID);
		if(obj is null || obj.data is null)
			return;
		Button btn = cast(Button)e.widget;
		switch(obj.data)
		{
			case "fop.case" :
				fop.bCase = btn.getSelection();
				break;
			case "fop.word" :
				fop.bWord = btn.getSelection();
				break;
			case "fop.wrap" :
				fop.bWrap = btn.getSelection();
				break;
			case "fop.regx" :
				fop.bRegexp = btn.getSelection();
				btnSub.setEnabled(fop.bRegexp);
				btnReg.setEnabled(fop.bRegexp);
				break;
			default : break;
		}
	}
	
	private void onDirChange(Event e) {
		Button radio = cast(Button)e.widget;
		/**
		 * since both selection and unselection of a radio box, will issue 
		 * the DWT.Selection event. ignore the unselection event
		 */
		if(!radio.getSelection())
			return;
		Integer ii = cast(Integer)radio.getData();
		assert(ii);
		int dir = ii.intValue();
		fop.bForward = !dir;
	}
	
	private void onFind(Event e) {
		fop.strFind = cobFind.getText();
		addToCache(fop.strFind, cobFind);
		setStatus("");
		switch(fop._scope){
		case FS_FILE:
			EditItem ei = cast(EditItem)editor.getSelection();
			if(ei)
				ei.findText(fop.strFind, fop.bForward);
			break;
		case FS_SELECTION:
			editor.findInSelection(fop);
			break;
		default:break;
		}
		
	}
	private void onReplace(Event e) 
	{
		fop.strFind = cobFind.getText();
		fop.strReplace = cobReplace.getText();
		addToCache(fop.strFind, cobFind);
		addToCache(fop.strReplace, cobReplace);
		setStatus("");
		EditItem ei = cast(EditItem)editor.getSelection();
		if(ei)
			ei.replaceSel(false);
	}
	
	private void onReplaceFind(Event e) 
	{
		fop.strFind = cobFind.getText();
		fop.strReplace = cobReplace.getText();
		addToCache(fop.strFind, cobFind);
		addToCache(fop.strReplace, cobReplace);
		setStatus("");
		EditItem ei = cast(EditItem)editor.getSelection();
		if(ei)
			ei.replaceSel(true);
	}
	
	private void onReplaceAll(Event e) {
		fop.strFind = cobFind.getText();
		fop.strReplace = cobReplace.getText();
		addToCache(fop.strFind, cobFind);
		addToCache(fop.strReplace, cobReplace);
		setStatus("");
		EditItem ei = cast(EditItem)editor.getSelection();
		if(ei)
			ei.replaceAll();
	}
	
	private void onCountAll(Event e){
		fop.strFind = cobFind.getText();
		fop.strReplace = cobReplace.getText();
		addToCache(fop.strFind, cobFind);
		setStatus("");
		EditItem ei = cast(EditItem)editor.getSelection();
		if(ei)
			ei.countAll();
	}
	
	private void onMarkAll(Event e){
		fop.strFind = cobFind.getText();
		fop.strReplace = cobReplace.getText();
		addToCache(fop.strFind, cobFind);
		setStatus("");
		EditItem ei = cast(EditItem)editor.getSelection();
		if(ei)
			ei.markAll();
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
	}
	
	public void setTextToFind(char[] text) {
		//if selection is empty or spans multiple lines use old find text
		if (text.length > 0 && std.string.find(text,"\n\r") == -1) {
			fop.strFind = text;
			cobFind.setText(fop.strFind);
		}
		cobFind.forceFocus();
	}
	
	public void setStatus(char[] line){
		statusBar.setText(line);
	}
	
	private boolean loadHistory() {
		
		XML xml = new XML();
		char[] filename = std.path.join(Globals.appDir, "findhistory.xml");
		if(xml.Open(filename) < 0 )
			return false; // failed
		XMLnode root = xml.m_root.getChildEx("findhistory", null);
		XMLnode child = root.getChild("history");
		if(child)
			_updateFindReplace(child, false, this.str2Find, this.str2Replace);
		
		delete xml; // auto close
		return true;
	}
	
	private void onComboDispose(Event e){
		saveHistory();
	}
	
	private void saveHistory() {
		if(!_opened)
			return;
			
		if(cobReplace.isDisposed() || cobFind.isDisposed() )
			return;
		str2Find = cobFind.getItems();
		str2Replace = cobReplace.getItems();
		str2Find.length = Math.min(str2Find.length, ITEM_LIMIT);
		str2Replace.length = Math.min(str2Replace.length, ITEM_LIMIT);
		
		char[] filename = std.path.join(Globals.appDir, "findhistory.xml");
		
		XML xml = new XML();
		{
			xml.m_attributes ~= new XMLattrib("version", "1.0");
			xml.m_attributes ~= new XMLattrib("encoding", "UTF-8");
		}
		
		XMLnode root = xml.m_root.getChildEx("findhistory", null);
		XMLnode child = root.getChildEx("history", null);
		
		_updateFindReplace(child, true, this.str2Find, this.str2Replace);
		child = root.getChildEx("option", null);
		
		xml.Save(filename);
		
		delete xml; // auto close
	}
	
	// make it static so the SearchDlg can share to use the method
	public static void _updateFindReplace(XMLnode parent, boolean save, inout char[][] _str2Find, inout char[][] _str2Replace) {
		/**
		 * It seems that ak.xml can't support Chinese chars as node name ???
		 * implemented as attrib to support Chinese characters
		 * 
		 */
		assert(parent);
		if(save) {
			XMLnode child = parent.getChildEx("find", null);
			int count = child.getChildCount();
			for(int i=count-1; i>=0; --i)
				child.deleteNode(i);
			foreach(char[] str; _str2Find){
				XMLnode node = child.addNode(`a`, null);
				node.addAttrib(`b`, str);
			}
			
			child = parent.getChildEx("replace", null);
			count = child.getChildCount();
			for(int i=count-1; i>=0; --i)
				child.deleteNode(i);
			foreach(char[] str; _str2Replace){
				XMLnode node = child.addNode(`a`, null);
				node.addAttrib(`b`, str);
			}
		}else{
			_str2Replace = null;
			_str2Find = null;
			XMLnode child = parent.getChild("find");
			if(child){
				int count = child.getChildCount();
				for(int i=0; i<count; ++i) {
					XMLnode node = child.getChild(i);
					XMLattrib attrib = node.getAttribEx("b", "");
					char[] val = attrib.GetValue();;
					if(val.length>0)
						_str2Find ~= val;
				}
			}
			child = parent.getChild("replace");
			if(child){
				int count = child.getChildCount();
				for(int i=0; i<count; ++i) {
					XMLnode node = child.getChild(i);
					XMLattrib attrib = node.getAttribEx("b", "");
					char[] val = attrib.GetValue();
					if(val.length>0)
						_str2Replace ~= val;
				}
			}
		}
	}

	public void updateI18N()
	{
		I18NShop.updateCompositeI18N(this);

		pack();
		// seem too narrow, increase the width
		Point pt = getSize();
		pt.x += 20;
		setSize(pt);
		setMinimumSize(pt);				
	}

	
}

