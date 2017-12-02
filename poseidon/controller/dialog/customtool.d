module poseidon.controller.dialog.customtool;

 
private import dwt.all;
private import poseidon.model.misc;
private import poseidon.controller.gui;
private import poseidon.globals;

class CustToolEditor : Shell 
{
	boolean returnValue = false;
private
{
	ToolEntry[] entries;
	
	List list;
 	int lastSelection = -1;
	Text txtName, txtArg, txtDir, txtCmd;
	Button chkCapture, chkHideWnd, chkSave;
	Button btnRemove;
	Menu argMenu, dirMenu;
}
	this(Shell parent)
	{
		super(parent, DWT.CLOSE | DWT.RESIZE | DWT.APPLICATION_MODAL);
		const int colCount = 3;
		
		setText("External Tools Configuration");
		this.handleEvent(this, DWT.Dispose, delegate(Event e) {
			CustToolEditor pThis = cast(CustToolEditor)e.cData;
			if(pThis.argMenu)
				pThis.argMenu.dispose();
			if(pThis.dirMenu)
				pThis.dirMenu.dispose();
			
		});
		GridLayout theLayout = new GridLayout();
		with(theLayout) {
			numColumns = colCount;
		}
		setLayout(theLayout);
		
		list = new List(this, DWT.BORDER | DWT.V_SCROLL);
		list.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, colCount - 1 , 5));
		
		Button btn = new Button(this, DWT.PUSH);
		btn.setText("Add");
		btn.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_FILL));
		btn.handleEvent(null, DWT.Selection, &onAddButton);
		btnRemove = new Button(this, DWT.PUSH);
		btnRemove.setText("Remove");
		btnRemove.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_FILL));
		btnRemove.handleEvent(null, DWT.Selection, &onRemoveButton);
		
		btn = new Button(this, DWT.PUSH);
		btn.setText("Up");
		btn.setEnabled(false);
		GridData gd = new GridData(GridData.FILL, GridData.END, false, true, 1, 2);
		gd.minimumHeight = 22;
		btn.setLayoutData(gd);
		btn = new Button(this, DWT.PUSH);
		btn.setText("Down");
		btn.setEnabled(false);
		btn.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_FILL));
		
		// Name
		with(new Label(this, DWT.NONE)){
			setText("Name");			
		}
		with(txtName = new Text(this, DWT.BORDER)) {
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, colCount - 1, 1));
		}
		
		// command
		with(new Label(this, DWT.NONE)){
			setText("Command");			
		}
		with(txtCmd = new Text(this, DWT.BORDER)) {
			setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		with(new Button(this, DWT.PUSH)) {
			setText("...");
			setLayoutData(new GridData(22, 22));
			handleEvent(null, DWT.Selection, &onBrowseCmd);
		}
		
		// Arguments
		with(new Label(this, DWT.NONE)){
			setText("Arguments");			
		}
		with(txtArg = new Text(this, DWT.BORDER)) {
			setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		with(new Button(this, DWT.ARROW | DWT.RIGHT)) {
			setLayoutData(new GridData(22, 22));
			handleEvent(getArgMenu(), DWT.Selection, &showEnvMenu);
		}
		
		// Init dir
		with(new Label(this, DWT.NONE)){
			setText("Initial Dir");			
		}
		with(txtDir = new Text(this, DWT.BORDER)) {
			setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		with(new Button(this, DWT.ARROW | DWT.RIGHT)) {
			setLayoutData(new GridData(22, 22));
			handleEvent(getDirMenu(), DWT.Selection, &showEnvMenu);
		}
		
		// flags
		Composite composite = new Composite(this, DWT.NONE);
		composite.setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, colCount, 1));
		RowLayout rowLayout = new RowLayout();
		rowLayout.wrap = false;
		rowLayout.justify = true;
		composite.setLayout(rowLayout);
		
		with(chkCapture = new Button(composite, DWT.CHECK)) {
			setText("Capture Output");
			setToolTipText("Don't check for Windows applications !!!");
		}
		with(chkHideWnd = new Button(composite, DWT.CHECK)) {
			setText("Hide Window");
			setToolTipText("Don't check for Windows applications !!!");
		}
		with(chkSave = new Button(composite, DWT.CHECK)) {
			setText("Save Files First");
		}
		
		composite = new Composite(this, DWT.NONE);
		composite.setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, colCount, 1));
		
		with(rowLayout = new RowLayout(DWT.HORIZONTAL)) 
		{
			marginRight = 40;
			marginLeft = 40;
			wrap = false;
			marginTop = 8;
			justify = true;
		}
		composite.setLayout(rowLayout);
		
		Button button = new Button(composite, DWT.PUSH);
		button.setLayoutData(new RowData(80, DWT.DEFAULT));		
		button.setText(Globals.getTranslation("OK"));
		button.handleEvent(null, DWT.Selection, &onOK);
		button = new Button(composite, DWT.PUSH);
		button.setLayoutData(new RowData(80, DWT.DEFAULT));		
		button.setText(Globals.getTranslation("CANCEL"));
		button.handleEvent(this, DWT.Selection, delegate(Event e) {
			CustToolEditor pThis = cast(CustToolEditor)e.cData;
			pThis.dispose(); 
		});
		
		initData();
		
		this.setSize(420, 340);
		setMinimumSize(420, 340);
		this.layout();
		this.centerWindow(parent);
	}	
	
	private void initData() {
		
		// make a copy of tool entries
		int i = 0;
		this.entries.length = Globals.toolEntries.length;
		foreach(ToolEntry item; Globals.toolEntries) {
			this.entries[i++] = item.clone();
		}
				
		list.handleEvent(null, DWT.Selection, &onListSelChange);
		foreach(ToolEntry item; entries) {
			list.add(item.name);
		}
		if(entries.length) {
			list.select(0);
			updateEntry(0);
			lastSelection = 0;
		}else{
			btnRemove.setEnabled(false);
		}
	}
	
//	private ToolEntry findEntry(char[] name) {
//		foreach(ToolEntry item; entries) {
//			if(name == item.name)
//				return item;
//		}
//		return null;
//	}
	
	private void onListSelChange(Event e) {
		int pos = list.getSelectionIndex();
		if(pos >= 0 && pos != lastSelection){
			// save last
			saveEntry(lastSelection);
			// update to current
			updateEntry(pos);
			lastSelection = pos;
		}
	}
	
	private void updateEntry(int pos) {
		ToolEntry entry = entries[pos];
		if(entry) {
			chkCapture.setSelection(entry.capture);
			chkHideWnd.setSelection(entry.hideWnd);
			chkSave.setSelection(entry.savefirst);
			txtName.setText(entry.name);
			txtCmd.setText(entry.cmd);
			txtDir.setText(entry.dir);
			txtArg.setText(entry.args);
		}
	}
	
	private void saveEntry(int index) {
		assert(index < entries.length);
		
		ToolEntry entry = entries[index];
		entry.capture =	chkCapture.getSelection();
		entry.hideWnd = chkHideWnd.getSelection();
		entry.savefirst = chkSave.getSelection();
		entry.name = txtName.getText();		
		entry.cmd = txtCmd.getText();
		entry.dir = txtDir.getText();
		entry.args = txtArg.getText();
		
		list.setItem(index, entry.name);
	}
	
	private void onOK(Event e) {
		// save the last entry
		saveEntry(list.getSelectionIndex());
		
		Globals.toolEntries = this.entries;
		/**
		 * the lastTool field need to be update here
		 */
		if(ToolEntry.lastTool !is null) {
			char[] temp = ToolEntry.lastTool.name;
			ToolEntry.lastTool = null;
			foreach(ToolEntry entry; Globals.toolEntries) {
				if( temp == entry.name)
					ToolEntry.lastTool = entry;
			}
		}
		returnValue = true;
		dispose();
	}
	
	private void onBrowseCmd(Event e) {
		scope dlg = new FileDialog(this);
		char[][] filter;
		filter ~= "*.exe;*.com;*.bat";
		filter ~= "*.*";
		dlg.setFilterExtensions(filter);
		dlg.setFilterPath(Globals.recentDir);
		char[] fullpath = dlg.open();
		if(fullpath) {
			txtCmd.setText(fullpath);
		}
	}
	
	private void showEnvMenu(Event e) {
		Menu menu = cast(Menu)e.cData;
//		Point pt = getDisplay().getCursorLocation();
		// another way
		Control btn = cast(Control)e.widget;
		Rectangle rc = btn.getBounds();
		menu.setLocation(btn.toDisplay(0, rc.height));
		menu.setVisible(true);
	}
	
	private Menu getArgMenu() {
		if(argMenu is null) {
			argMenu = new Menu(this);
			buildArgMenu(argMenu);
			MenuItem[] mis = argMenu.getItems();
			foreach(MenuItem item; mis){
				item.handleEvent(txtArg, DWT.Selection, &onEnvMenu);
			}
		}
		return argMenu;
	}
	
	private Menu getDirMenu() {
		if(dirMenu is null) {
			dirMenu = new Menu(this);
			buildDirMenu(dirMenu);
			MenuItem[] mis = dirMenu.getItems();
			foreach(MenuItem item; mis){
				item.handleEvent(txtDir, DWT.Selection, &onEnvMenu);
			}
		}
		return dirMenu;
	}
	
	public void buildDirMenu(Menu menu) {
		MenuItem item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(ItemDir)`);
		
		item = new MenuItem(menu, DWT.SEPARATOR);
		
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(ProjectDir)`);
	}
	
	public void buildArgMenu(Menu menu) {
		MenuItem item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(ItemPath)`);
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(ItemDir)`);
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(ItemFileName)`);
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(ItemExt)`);
		
		item = new MenuItem(menu, DWT.SEPARATOR);
		
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(CurLine)`);
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(CurCol)`);
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(CurText)`);
		
		item = new MenuItem(menu, DWT.SEPARATOR);
		
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(ProjectDir)`);
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(ProjectName)`);
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(ProjectMainFile)`);
		item = new MenuItem(menu, DWT.PUSH);
		item.setText(`$(ProjectAll)`);
	}
	
	private void onEnvMenu(Event e) {
		Text txt = cast(Text)e.cData;
		MenuItem item = cast(MenuItem)e.widget;
		txt.insert(item.getText());
	}
	
	private void onAddButton(Event e) {
		if(list.getItemCount() > 0){
			saveEntry(lastSelection);
		}
		char[] name = "New Tool";
		int count = list.getItemCount();
		ToolEntry entry = new ToolEntry();
		entry.name = name;
		entries ~= entry;
		list.add(name);	
		list.setSelection(count);
		lastSelection = count;
		updateEntry(count);
		btnRemove.setEnabled(true);
	}
	
	private void onRemoveButton(Event e) {
		if(DWT.YES != MessageBox.showMessage(Globals.getTranslation("mb.remove_item"),
			 Globals.getTranslation("QUESTION"), getShell(), DWT.ICON_QUESTION | DWT.YES | DWT.NO))
			return;
		int pos = list.getSelectionIndex();
		if(pos >= 0) {
			TVector!(ToolEntry).remove(entries, pos);
			list.remove(pos);
		}
		
		if(list.getItemCount() > 0 )
		{
			if(pos > 0)
				--pos;
			list.select(pos);
			lastSelection = pos;
			updateEntry(pos);
		}else{
			btnRemove.setEnabled(false);
			clearFields();	
		}
	}
	private void clearFields() {
		txtName.setText("");
		txtCmd.setText("");
		txtArg.setText("");
		txtDir.setText("");
		chkCapture.setSelection(false);
		chkSave.setSelection(true);
		chkHideWnd.setSelection(false);
	}
}