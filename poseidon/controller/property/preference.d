module poseidon.controller.property.preference;

private import dwt.all;
private import poseidon.controller.gui;
private import poseidon.controller.dialog.generaldialog;
private import poseidon.globals;
private import poseidon.model.misc;
private import poseidon.i18n.itranslatable;
private import poseidon.controller.property.editorpage;
private import poseidon.controller.property.shortcutpage;
private import poseidon.controller.property.dpage;
private import poseidon.controller.property.ipropertypage;
private import poseidon.controller.property.generalpage;
private import poseidon.controller.editor;
private import poseidon.i18n.i18nshop;

private import poseidon.controller.property.compilerpage;
private import poseidon.controller.property.parserpage;


class Preference : GeneralDialog, ITranslatable
{
	Tree 		tree;
	Composite 	container;
	CLabel		titleLabel;
	
	// ShortCutPage	scPage;
	// DPage		dPage;
	// EditorPage		editorPage;
	StackLayout	theLayout;

	IPropertyPage[]	pages;
	
	Button closeButton, applyButton;

	Font font;
	
	this(Shell parent) 
	{
		super(parent);
	}

	private void createPages(Composite parent)
	{
		// create pages here
		AbstractPage page = new GeneralPage(parent, null, &onDirtyStateChanged);
		pages ~= page;
		
		// set the first page
		theLayout.topControl = page;
		titleLabel.setText(page.getTitle());
		
		pages ~= new ShortCutPage(parent, null, &onDirtyStateChanged);
		
		page = new EditorPage(parent, null, &onDirtyStateChanged);
		pages ~= page;

		pages ~= new DPage(parent, page, &onDirtyStateChanged);

		page = new CompilerPage(parent, null, &onDirtyStateChanged);
		pages ~= page;
		
		page = new ParserPage(parent, null, &onDirtyStateChanged);
		pages ~= page;		
		
	}
	
	// override super class method
	protected Shell createShell(Shell parent) 
	{
		Shell shell = new Shell(parent, DWT.CLOSE | DWT.RESIZE | DWT.APPLICATION_MODAL);
		// updateI18N need to access super's shell member
		super.shell = shell;
		
		shell.setText(Globals.getTranslation("pref.title"));
		GridLayout layout = new GridLayout();
		with(layout) {
			
		}
		shell.setLayout(layout);
		theLayout = new StackLayout();
		
		SashForm sash = new SashForm(shell, DWT.NONE);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		tree = new Tree(sash, DWT.NONE);
		Composite mainCP = new Composite(sash, DWT.NONE);
		mainCP.setLayout(LayoutShop.createGridLayout(1, 5, 0));
		sash.setWeights( [27, 73]);
		
		Label sep = new Label(shell, DWT.HORIZONTAL | DWT.SEPARATOR);
		sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		
		Button closeButton = new Button(shell, DWT.PUSH);
		closeButton.setText(Globals.getTranslation("CLOSE"));
		GridData data = new GridData(GridData.HORIZONTAL_ALIGN_END);
		data.widthHint = 80;
		closeButton.setLayoutData(data);
		closeButton.handleEvent(shell, DWT.Selection, delegate(Event e){
			Shell shell = cast(Shell)e.cData;
			shell.close();
		});

		with(titleLabel = new CLabel(mainCP, DWT.NONE)) {
			setLayoutData(LayoutDataShop.createGridData(GridData.FILL_HORIZONTAL));
		}
		FontData[] fontDatas = Display.getCurrent().getSystemFont().getFontData();
		titleLabel.setFont(font = new Font(Display.getCurrent(), fontDatas[0].getName(), 12, DWT.BOLD));
		
		with(new Label(mainCP, DWT.SEPARATOR|DWT.HORIZONTAL)) {
			setLayoutData(LayoutDataShop.createGridData(GridData.FILL_HORIZONTAL));
		}
		with(container = new Composite(mainCP, DWT.NONE)) {
			setLayoutData(LayoutDataShop.createGridData(GridData.FILL_BOTH));
			setLayout(theLayout);
		}

		// apply / restore bar
		Composite btnBar = new Composite(mainCP, DWT.NONE);
		with(btnBar) {
			setLayout(LayoutShop.createGridLayout(2, 0, 0, 10, 0, true));
			setLayoutData(LayoutDataShop.createGridData(GridData.HORIZONTAL_ALIGN_END));
		}
		with(new Button(btnBar, DWT.PUSH)) {
			setText(Globals.getTranslation("pref.restore"));
			setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			handleEvent(null, DWT.Selection, &onRestoreDefaults);
		}

		applyButton = new Button(btnBar, DWT.PUSH);
		with(applyButton) {
			setText(Globals.getTranslation("pref.apply"));
			setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			handleEvent(null, DWT.Selection, &onApplyChanges);
			setEnabled(false);
		}

		createPages(container);
		
		initTree();

		updateI18N();
		
		//shell.setSize(500, 400);
		shell.layout();

		shell.handleEvent(null, DWT.Close, &onClose);

		shell.pack();
		// seem too long, decrease the height
		Point pt = shell.getSize();
		pt.y -= 180;
		pt.x = pt.y * 10 / 11;
		shell.setSize(pt);
		shell.setMinimumSize(pt);	
		
		return shell;
	}
	
	private void initTree() {
		assert(tree);

		foreach(IPropertyPage page; pages) 
		{
			TreeItem treeitem;
			IPropertyPage parent = page.getParentPage();
			if(parent) 
				treeitem = new TreeItem(parent.getTreeItem(), DWT.NONE);
			else
				treeitem = new TreeItem(tree, DWT.NONE);
			page.setTreeItem(treeitem);
			treeitem.setData(cast(Object)page);
			treeitem.setText(page.getTitle());
		}
		
		tree.handleEvent(null, DWT.Selection, &onTreeSelChange);
		tree.handleEvent(null, DWT.DefaultSelection, &onTreeSelChange);
	}

	private void onApplyChanges(Event e) {
		IPropertyPage page = getActivePage();
		if(page)
			page.applyChanges();
		applyButton.setEnabled(false);
	}

	private void onClose(Event e) {
		/+
		foreach(IPropertyPage page; pages)
		{
			if(page.getDirty())
				page.applyChanges();
		}
		+/

		if(font)
			font.dispose();
		font = null;
	}

	private void onDirtyStateChanged(bool dirty) {
		applyButton.setEnabled(dirty);
	}

	private void onRestoreDefaults(Event e) {
		if(DWT.YES == MessageBox.showMessage(Globals.getTranslation("mb.restore_default"), 
			Globals.getTranslation("QUESTION"), getShell(), DWT.ICON_QUESTION|DWT.YES|DWT.NO)){
			IPropertyPage page = getActivePage();
			if(page)
				page.restoreDefaults();
		}
	}
	
	private void onTreeSelChange(Event e) {
		TreeItem item = cast(TreeItem)e.item;
		if(e.type == DWT.DefaultSelection && item.getItemCount() > 0){
			item.setExpanded(!item.getExpanded());
		}

		IPropertyPage page = cast(IPropertyPage)item.getData();
		assert(page);
		setActivePage(page);
	}

	private IPropertyPage getActivePage() {
		return cast(IPropertyPage)theLayout.topControl;
	}

	private void setActivePage(IPropertyPage page)
	{
		theLayout.topControl = cast(Control)page;
		
		titleLabel.setText(page.getTitle());

		applyButton.setEnabled(page.getDirty());
		
		container.layout();
	}

	public void updateI18N()
	{
		I18NShop.updateCompositeI18N(this.shell);
	}

}

