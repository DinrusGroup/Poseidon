module poseidon.controller.property.dpage;

public
{
	import dwt.all;
	import poseidon.globals;
	import poseidon.controller.gui;
	import poseidon.i18n.itranslatable;
	import poseidon.util.layoutshop;
	import poseidon.util.miscutil;
	import poseidon.controller.property.ipropertypage;
	import poseidon.controller.property.fontstylegroup;
	import poseidon.style.dstyle;
	import poseidon.style.stylefactory;
}


class DPage : AbstractPage
{
	TabFolder folder;
	Text[] texts;
	List list;
	int listIndex = -1;
	FontStyleGroup fsGroup;
	IStyleKeeper keeper;
	AStyle[] styles;
	char[][] keywords;

	
	
	this(Composite parent, IPropertyPage parentPage, void delegate(bool) dirtyListener)
	{
		super(parent, parentPage, dirtyListener);
		initGUI();
		updateI18N();
		
		keeper = StyleFactory.getStyleKeeper(DStyle.SCLEX_D);
		assert(keeper);

		// make a copy of styles, so don't change the styles directly in case 
		// user discard the changes
		styles = keeper.getStyles().dup;
		keywords = keeper.getKeyWords().dup;
		
		initData();
		setDirty(false);
	}

	public void applyChanges() 
	{
		char[][] keywords;
		foreach(Text txt; texts){
			keywords ~= txt.getText();
		}
		keeper.setKeyWords(keywords);

		saveRecentlyAStyle();

		keeper.setStyles(this.styles);
		
		sGUI.editor.resetSettings();
		
		setDirty(false);
	}

	public char[] getTitle() {
		return "D Styles";
	}

	private void initData()
	{
		list.removeAll();
		listIndex = -1;
		
		foreach(AStyle style; this.styles){
			list.add(std.string.toString(style.id) ~ " " ~ style.name);
		}
		
		for(int i=0; i<keywords.length && i<texts.length; ++i){
			texts[i].setText(keywords[i]);
		}
	}

	private void initGUI()
	{
		this.setLayout(new FillLayout());
		folder = new TabFolder(this, DWT.NONE);
		TabItem styleItem = new TabItem(folder, DWT.NONE);
		Composite styleCop = new Composite(folder, DWT.NONE);

		Composite keyWordComposite = new Composite(folder, DWT.NONE);
		keyWordComposite.setLayout(LayoutShop.createFillLayout(5, 5));
		ScrolledComposite scrollComposite = new ScrolledComposite(keyWordComposite, DWT.V_SCROLL|DWT.H_SCROLL);
		scrollComposite.setExpandVertical(true);
		scrollComposite.setExpandHorizontal(true);
		Composite inner = new Composite(scrollComposite, DWT.NONE);
		scrollComposite.setContent(inner);
		with(styleItem){
			setData(LANG_ID, "dp.styles");
			setControl(styleCop);
		}
		TabItem keyWordItem = new TabItem(folder, DWT.NONE);
		with(keyWordItem){
			setData(LANG_ID, "dp.keywords");
			setControl(keyWordComposite);
		}

		// init style page
		styleCop.setLayout(new GridLayout(2, false));
		list = new List(styleCop, DWT.BORDER|DWT.V_SCROLL|DWT.H_SCROLL);
		list.setLayoutData(LayoutDataShop.createGridData(GridData.FILL_BOTH, 1, 2));
		list.handleEvent(null, DWT.Selection, &onListSelChange);
		fsGroup = new FontStyleGroup(styleCop, &this.setDirty, true);
		fsGroup.setLayoutData(LayoutDataShop.createGridData(GridData.VERTICAL_ALIGN_BEGINNING));

		// the comment
		Label label = new Label(styleCop, DWT.WRAP|DWT.BORDER);
		label.setData(LANG_ID, "dp.remark");
		label.setLayoutData(LayoutDataShop.createGridData(GridData.HORIZONTAL_ALIGN_FILL|GridData.VERTICAL_ALIGN_FILL));
		// init keywords page
		inner.setLayout(new GridLayout());
		for(int i=0; i<7; ++i){
			Label innerlabel = new Label(inner, DWT.NONE);
			innerlabel.setText("Key Words " ~ std.string.toString(i+1));
			Text text = new Text(inner, DWT.BORDER|DWT.WRAP|DWT.MULTI|DWT.V_SCROLL);
			text.setLayoutData(LayoutDataShop.createGridData(GridData.FILL_HORIZONTAL, 1, 1, DWT.DEFAULT, 40));
			text.handleEvent(null, DWT.Modify, &onSetDirty);

			texts ~= text;
		}
		scrollComposite.setMinSize(inner.computeSize(DWT.DEFAULT, DWT.DEFAULT));
	}


	// when e is null, that means we call this directly, not the DWT event fired
	private void onListSelChange(Event e){
		
		if(dirty && e !is null)
			saveRecentlyAStyle();
			
		listIndex = list.getSelectionIndex();
		if(listIndex >= 0)
		{
			char[] text = list.getItem(listIndex);
			int pos = std.string.find(text, " ");
			text = text[0..pos];
			int id = std.string.atoi(text);

			foreach(AStyle style; this.styles){
				if(style.id == id){
					fsGroup.setAStyle(style);
					break;
				}
			}
		}
	}

	private void onSetDirty(Event e)
	{
		setDirty(true);
		keeper.needSerialize = true;
	}

	public void restoreDefaults()
	{
		keeper.resetKeyWords();
		
		foreach( inout AStyle style; this.styles)
		{
			style.resetToDefault();
		}

		// int index = list.getSelectionIndex();
		
		initData();

		fsGroup.clear();

		// list.select(index);

		// onListSelChange(null);
		
		setDirty(true);
	}

	private void saveRecentlyAStyle()
	{
		if(listIndex < 0)
			return;
			
		// save the last AStyle
		AStyle style = fsGroup.getAStyle();
		if(style.id >= 0)
		{
			for(int i=0; i<this.styles.length; ++i)
			{
				if(style.id == styles[i].id){
					this.styles[i] = style;
					break;
				}
			}
		}
	}

	public void updateI18N()
	{
		TabItem[] items = folder.getItems();
		foreach(TabItem item; items){
			StringObj obj = cast(StringObj)item.getData(LANG_ID);
			if(obj && obj.data){
				char[] text = Globals.getTranslation(obj.data);
				item.setText(text);
			}
		}
	}
}