module poseidon.controller.property.shortcutpage;

private import dwt.all;
private import poseidon.controller.dialog.generaldialog;
private import poseidon.globals;
private import poseidon.model.misc;
private import poseidon.controller.property.ipropertypage;
private import poseidon.util.layoutshop;

// private import poseidon.i18n.itranslatable;


class ShortCutPage : AbstractPage
{
	static char[][] columnTitles = ["Name", "Key"];
	private Table table;
	private import poseidon.controller.gui;
	
	this(Composite parent, IPropertyPage parentPage, void delegate(bool) dirtyListener) {
		super(parent, parentPage, dirtyListener);
		initGUI();
	}

	public void applyChanges() 
	{
		setDirty(false);
		sGUI.menuMan.addShortCutKeyName();
	}
	
	private char[] getFixedKeys() {
		char[] str;
		str = "Fixed Key\t\tAction\n";
		str ~="CTRL+/\t\tWord Part Left\n";
		str ~="CTRL+SHIFT+/\tWord Part Left Extend\n";
		str ~="CTRL+\\\t\tWord Part Right\n";
		str ~="CTRL+SHIFT+\\\tWord Part Right Extend\n";
		str ~="CTRL+[\t\tParagraph Up\n";
		str ~="CTRL+SHIFT+[\tParagraph Up Extend\n";
		str ~="CTRL+]\t\tParagraph Down\n";
		str ~="CTRL+SHIFT+]\tParagraph Down Extend\n";
		str ~="CTRL+MouseWheel\tZoom In/Out\n";
		return str;
	}

	public char[] getTitle() 
	{
		return Globals.getTranslation("pref.shortcut");
	}
	
	protected void initGUI() {

		this.setLayout( new FillLayout() );
		Composite styleCop = new Composite( this, DWT.NONE );

		styleCop.setLayout(LayoutShop.createFillLayout( 5, 5 ) );
		ScrolledComposite scrollComposite = new ScrolledComposite( styleCop, DWT.V_SCROLL|DWT.H_SCROLL );
		scrollComposite.setExpandVertical( true );
		scrollComposite.setExpandHorizontal( true );
		Composite inner = new Composite( scrollComposite, DWT.NONE );
		scrollComposite.setContent( inner );
		inner.setLayout( new GridLayout() );

		Label title = new Label(inner, DWT.NONE);
		title.setText( Globals.getTranslation( "sc.title" ) );

		table = new Table(inner, DWT.BORDER | DWT.SINGLE | DWT.VIRTUAL | DWT.FULL_SELECTION | DWT.V_SCROLL | DWT.H_SCROLL);
		//table.setLayoutData(new GridData(GridData.FILL));

		int ListHeight = table.getItemHeight() * 32;
		GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
		Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
		innergridData.heightHint = trim.height;
		table.setLayoutData( innergridData );
		
		table.setHeaderVisible(true);
		table.setLinesVisible(true);
		table.setItemCount(Globals.hotkeys.length);
		table.handleEvent(null, DWT.SetData, &onSetData);
		Globals.hotkeys.sort;
		
		/* Fill the table with data */
		for (int i = 0; i < columnTitles.length; i++) {
			TableColumn tableColumn = new TableColumn(table, DWT.NONE);
			tableColumn.setText(columnTitles[i]);
			tableColumn.setWidth(150);
			tableColumn.handleEvent(null, DWT.Selection, &onColumnSelection);
		}
		
		table.setSortColumn(table.getColumn(0));
		table.setSortDirection(DWT.DOWN);
		table.handleEvent(null, DWT.DefaultSelection, &onDefaultSelection);
		
		Label label = new Label(inner, DWT.BORDER);
		label.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_FILL));
		label.setText(getFixedKeys());
		scrollComposite.setMinSize(inner.computeSize(DWT.DEFAULT, DWT.DEFAULT));
	}
	
	private void onSetData(Event e) {
		TableItem item = cast(TableItem) e.item;
		int i = table.indexOf(item);
		_ShortCut[] hotkeys = Globals.hotkeys;
		item.setText(0, hotkeys[i].name);
		item.setText(1, hotkeys[i].keyname);
		item.setData(hotkeys[i]);
	}
	
	private void onColumnSelection(Event e) {
			// determine new sort column and direction
			TableColumn sortColumn = table.getSortColumn();
			TableColumn currentColumn = cast(TableColumn) e.widget;
			int dir = table.getSortDirection();
			if (sortColumn is currentColumn) {
				dir = dir == DWT.UP ? DWT.DOWN : DWT.UP;
			} else {
				table.setSortColumn(currentColumn);
				dir = DWT.UP;
			}
			// sort the data based on column and direction
			_ShortCut.sorttype = currentColumn.getText() == "Name" ? _ShortCut.SORT_NAME : _ShortCut.SORT_KEY;
			_ShortCut.sortdirection = dir;
			Globals.hotkeys.sort;

			// update data displayed in table
			table.setSortDirection(dir);
			table.clearAll();
	}
	
	private void onDefaultSelection(Event e){
		// nested class
		class _Dlg : GeneralDialog {
			Button	chkCtl, chkAlt, chkSft;
			Combo	combo;
			_ShortCut	hkey;
			this(Shell parent, _ShortCut sc){
				super(parent);
				hkey = sc;
			}
			private Button createCheckBox(Composite parent, char[] text, boolean init) {
				Button check = new Button(parent, DWT.CHECK);
				check.setText(text);
				check.setSelection(init);
				return check;
			}

			protected Shell createShell(Shell parent){
				Shell shell = new Shell(parent, DWT.DIALOG_TRIM|DWT.APPLICATION_MODAL);
				setText( Globals.getTranslation( "sc.diag_title" ) );
				shell.setLayout(LayoutShop.createGridLayout(1, 8, 8, 5, 5, true));
				Composite container = new Composite(shell, DWT.NONE);
				container.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_FILL));
				container.setLayout(new GridLayout(2, true));
				Label label = new Label(container, DWT.NONE);
				label.setLayoutData(LayoutDataShop.createGridData(GridData.FILL_HORIZONTAL|GridData.VERTICAL_ALIGN_CENTER, 1, 1, 160));
				label.setText( Globals.getTranslation( "sc.diag_action" ) ~ " " ~ hkey.name);
				label = new Label(container, DWT.NONE);				
				label.setLayoutData(new GridData(GridData.BEGINNING, GridData.CENTER, true, false, 2, 1));
				label.setText( Globals.getTranslation( "sc.diag_current" ) ~ " " ~ hkey.keyname);
			
				label.setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, 2, 1));
				chkCtl	= createCheckBox(container, "CTRL", hkey.mask & DWT.CTRL);				
				chkSft	= createCheckBox(container, "SHIFT", hkey.mask & DWT.SHIFT);
				chkAlt	= createCheckBox(container, "ALT", hkey.mask & DWT.ALT);
				combo	= new Combo(container, DWT.BORDER | DWT.READ_ONLY);
				combo.setVisibleItemCount(16);
				for(int i = cast(int)'A'; i<=cast(int)'Z'; ++i) {
					char[] a;
					a ~= cast(char)i;
					combo.add(a);
				}
				for(int i=0; i<14; ++i){
					char[] s = std.string.format("F%d", i+1);
					combo.add(s);
				}
				if(hkey.code < 255) {
					combo.select(cast(int)(hkey.code - 'a'));
				}else
					combo.select(cast(int)(hkey.code - DWT.F1 + 26));
					
				// btns[0] is OK button, btns[1] is Cancel button
				Button[] btns = createButtonBar(shell, true, true);
				shell.setDefaultButton(btns[0]);
				btns[0].handleEvent(null, DWT.Selection, &onOK);
				
				shell.pack();

				return shell;
			}
			
			protected void onOK(Event e) {
				int mask = 0;
				int code = 0;
				if(chkAlt.getSelection()) mask |= DWT.ALT;
				if(chkCtl.getSelection()) mask |= DWT.CTRL;
				if(chkSft.getSelection()) mask |= DWT.SHIFT;
				
				int sel = combo.getSelectionIndex();
				if(sel < 26) {
					code = sel + 'a';
				}else{
					code = sel - 26 + DWT.F1;
				}
				
				_ShortCut sc = Globals.isHotKeyOccupied(mask, code, hkey);
				if(sc !is null) {
					MessageBox.showMessage(Globals.getTranslation("mb.key_occupied") ~ " \""  ~ sc.name~`"`);
					return;
				}else{
					setDirty(true);
					hkey.mask = mask;
					hkey.code = code;
					result = "OK";
					getShell().close();
				}
			}
		} // end of nested class
		
		
		// code start here
		TableItem item = cast(TableItem)e.item;
		_ShortCut sc = cast(_ShortCut)item.getData();
		
		scope dlg = new _Dlg(getShell(), sc);
		char[] result = dlg.open();
		if(result == "OK") {
			item.setText(1, sc.keyname);
			table.getColumn(1).pack();
			// TODO: save to xml file here
			Globals.saveConfig();
		}
	}

	public void restoreDefaults()
	{
		Globals.resetHotKey();
		table.clearAll();
		Globals.saveConfig();
	}

}
