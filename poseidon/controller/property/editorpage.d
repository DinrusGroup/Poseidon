module poseidon.controller.property.editorpage;

public
{
	import dwt.all;
	import poseidon.globals;
	import poseidon.controller.gui;
	import poseidon.i18n.itranslatable;
	import poseidon.util.layoutshop;
	import poseidon.util.miscutil;
	import poseidon.controller.property.ipropertypage;
	import poseidon.model.editorsettings;
	import poseidon.controller.property.fontstylegroup;
	import poseidon.controller.editor;
}

class EditorPage : AbstractPage
{
	Setting setting;

	Button 			chkLineNum, chkMarker, chkFolding, chkGuide, chkCurLine, chkTABAsSpace, btnSysColor, wordWrap;
	ColorChooser 	ccCurLine, ccSelFore, ccSelBack, ccCursor, ccLineNumFore, ccLineNumBack, ccFold;
	FontStyleGroup 	fsGroup;
	Text 			txtTabWidth, txtTabIndents;
	List			styleFontList;
	AStyle[3]		fontAStyles;
	int				prevListIndex;

	
	this(Composite parent, IPropertyPage parentPage, void delegate(bool) dirtyListener)
	{
		super(parent, parentPage, dirtyListener);
		// make a copy of the EditorSettings
		this.setting = Editor.settings._setting;
		initComponents();
		initData();
		setDirty(false);
	}

	public void applyChanges() 
	{
		setting.showLineNumber = chkLineNum.getSelection();
		setting.showBookMark = chkMarker.getSelection();
		setting.showFoldingMargin = chkFolding.getSelection();
		setting.showIndentationGuides = chkGuide.getSelection();
		setting.wrapMode = wordWrap.getSelection();
		setting.tabAsSpace = chkTABAsSpace.getSelection();
		
		setting.curLineHiLight = chkCurLine.getSelection();
		setting.clCurLine = ccCurLine.getColor();
		
		setting.clSelFore = ccSelFore.getColor();
		setting.clSelBack = ccSelBack.getColor();

		setting.clFoldingMargin = ccFold.getColor();
		setting.clCursor = ccCursor.getColor();
		setting.clLineNumFore = ccLineNumFore.getColor();
		setting.clLineNumBack = ccLineNumBack.getColor();

		
		//setting.defaultStyle = fsGroup.getAStyle();
		fontAStyles[prevListIndex] = fsGroup.getAStyle();
		setting.defaultStyle 	= fontAStyles[0];
		setting.outputStyle 	= fontAStyles[1];
		setting.searchStyle 	= fontAStyles[2];

		setting.tabWidth = Math.max(1, cast(int)std.string.atoi(txtTabWidth.getText()));
		setting.tabIndents = Math.max(1, cast(int)std.string.atoi(txtTabIndents.getText()));

		// apply the settings
		Editor.settings._setting = this.setting;

		scope font = new Font( display, fontAStyles[1].font, fontAStyles[1].size, DWT.NORMAL );
		sGUI.outputPanel.content.setFont( font );

		font = new Font( display, fontAStyles[2].font, fontAStyles[2].size, DWT.NORMAL );
		sGUI.searchPanel.content.setFont( font );
		
		sGUI.editor.resetSettings();

		/+
		FontData[] fontData = Display.getDefault().getFontList( null, false );
		MessageBox.showMessage( std.string.toString( fontData.length ) );
		+/

		setDirty(false);
	}

	private void initComponents()
	{
		this.setLayout(LayoutShop.createGridLayout(4, 5, 5, 12));
		chkLineNum = createCheckBox("ep.sw_ln_num");
		chkMarker = createCheckBox("ep.sw_marker", true);
		chkFolding = createCheckBox("ep.sw_fold");
		chkGuide = createCheckBox("ep.sw_guide", true);
		chkCurLine = createCheckBox("ep.hl_curline");
		wordWrap = createCheckBox("ep.word_wrap");
		chkTABAsSpace = createCheckBox("ep.tab_space");
		new Label(this, DWT.NONE);
		new Label(this, DWT.NONE);
		

		/*
		// current line high light
		ccCurLine = new ColorChooser(this, &setDirty);
		ccCurLine.setColor(setting.clCurLine);
		ccCurLine.setEnabled(setting.curLineHiLight);
		*/
		// Table Width
		Label label = new Label(this, DWT.NONE);
		label.setData(LANG_ID, "ep.tab_width");
		with(txtTabWidth = new Text(this, DWT.BORDER)){
			setLayoutData(new GridData(ColorChooser.WIDTH, DWT.DEFAULT));
			handleEvent(null, DWT.Modify, &onAction);
		}
		label = new Label(this, DWT.NONE);
		label.setData(LANG_ID, "ep.tab_indents");

		with(txtTabIndents = new Text(this, DWT.BORDER))
		{
			setLayoutData(new GridData(ColorChooser.WIDTH, DWT.DEFAULT));
			handleEvent(null, DWT.Modify, &onAction);
		}
		
		Group group = new Group(this, DWT.NONE);
		with(group){
			setData(LANG_ID, "ep.color_font");
			setLayoutData(LayoutDataShop.createGridData(GridData.HORIZONTAL_ALIGN_BEGINNING, 4));
			setLayout(LayoutShop.createGridLayout(4, 5, 5, 12, 5));
		}

		btnSysColor = new Button(group, DWT.PUSH);
		btnSysColor.setData(LANG_ID, "ep.sys_color");
		btnSysColor.handleEvent(null, DWT.Selection, &onAction);
		btnSysColor.setLayoutData(LayoutDataShop.createGridData(GridData.GRAB_HORIZONTAL, 2));

		// current line high light
		with(new Label(group, DWT.NONE)) 
		{
			setData(LANG_ID, "ep.curline_color" );
		}		
		ccCurLine = new ColorChooser(group, &setDirty);
		ccCurLine.setColor(setting.clCurLine);
		ccCurLine.setEnabled(setting.curLineHiLight);
		
		// selection color
		ccSelFore = createColorChooser(group, "ep.selfore");
		ccSelBack = createColorChooser(group, "ep.selback");

		ccLineNumFore = createColorChooser(group, Globals.getTranslation( "ep.ln_num_fore" ) );
		ccLineNumBack = createColorChooser(group,  Globals.getTranslation( "ep.ln_num_back" ) );
		
		ccFold = createColorChooser(group, Globals.getTranslation( "ep.fold_color" ) );
		ccCursor = createColorChooser(group, Globals.getTranslation( "ep.cursor_color") );

		with( styleFontList = new List( group, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 2, 1 );
			add(  Globals.getTranslation( "ep.def_style" ) );
			add( Globals.getTranslation( "outputpanel.title" ) );
			add( Globals.getTranslation( "searchpanel.title" ) );
			select( 0 );
			int ListHeight = getItemHeight() * 15;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			
			setLayoutData( innergridData );

			handleEvent(null, DWT.Selection, &onListAction );
		}

		
		fsGroup = new FontStyleGroup(group, &setDirty);
		with(fsGroup) {
			setData(LANG_ID, "ep.def_style");
			setLayoutData(LayoutDataShop.createGridData(GridData.FILL_HORIZONTAL|GridData.GRAB_HORIZONTAL, 2));
		}
	}

	private void initData()
	{
		chkLineNum.setSelection(setting.showLineNumber);
		chkMarker.setSelection(setting.showBookMark);
		chkFolding.setSelection(setting.showFoldingMargin);
		chkGuide.setSelection(setting.showIndentationGuides);
		chkCurLine.setSelection(setting.curLineHiLight);
		wordWrap.setSelection(setting.wrapMode );
		chkTABAsSpace.setSelection( setting.tabAsSpace );

		ccCurLine.setColor(setting.clCurLine);
		ccSelFore.setColor(setting.clSelFore);
		ccSelBack.setColor(setting.clSelBack);

		ccFold.setColor( setting.clFoldingMargin );
		ccCursor.setColor( setting.clCursor );
		ccLineNumFore.setColor( setting.clLineNumFore );
		ccLineNumBack.setColor( setting.clLineNumBack );

		txtTabWidth.setText(std.string.toString(setting.tabWidth));
		txtTabIndents.setText(std.string.toString(setting.tabIndents));

		fontAStyles[0] = setting.defaultStyle;
		fontAStyles[1] = setting.outputStyle;
		fontAStyles[2] = setting.searchStyle;
		

		switch( styleFontList.getSelectionIndex() )
		{
			case 0:
				fsGroup.setAStyle(setting.defaultStyle); break;
			case 1:
				fsGroup.setAStyle(setting.outputStyle);	break;
			case 2:
				fsGroup.setAStyle(setting.searchStyle);	break;
			default:
				break;
		}
				
	}

	private Button createCheckBox(char[] langId, bool fill = false)
	{
		Button button = new Button(this, DWT.CHECK);
		with(button) {
			setData(LANG_ID, langId);
			/*
			int style = GridData.HORIZONTAL_ALIGN_BEGINNING;
			if(fill)
				style |= GridData.FILL_HORIZONTAL;
			setLayoutData(LayoutDataShop.createGridData(style));
			*/
			setLayoutData( new GridData( GridData.BEGINNING, GridData.CENTER, true, false, 2, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}
		return button;
	}

	public char[] getTitle() {
		return Globals.getTranslation("pref.editor");
	}

	private void onAction(Event e)
	{
		Widget w = e.widget;
		if(w is chkCurLine) {
			ccCurLine.setEnabled(chkCurLine.getSelection());
		}
		else if(w is btnSysColor) {
			EditorSettings.getSysColors(&this.setting);
			ccSelFore.setColor(setting.clSelFore);
			ccSelBack.setColor(setting.clSelBack);

			Font ft = Display.getDefault().getSystemFont();
			FontData[] data = ft.getFontData();
			
			setting.defaultStyle.font = data[0].getName();
			setting.defaultStyle.size = data[0].getHeight();
			setting.defaultStyle.bold = data[0].getStyle() & DWT.BOLD;
			setting.defaultStyle.italic = data[0].getStyle() & DWT.ITALIC;
			version(Windows){
				setting.defaultStyle.underline = data[0].data.lfUnderline;
			}
			fsGroup.setAStyle(setting.defaultStyle);
			styleFontList.select( 0 );
		}
		
		setDirty(true);
	}

	private void onListAction( Event e )
	{
		fontAStyles[prevListIndex] = fsGroup.getAStyle();
		prevListIndex = styleFontList.getSelectionIndex();
		
		switch( prevListIndex )
		{
			case 0:
				fsGroup.setAStyle( fontAStyles[0] ); break;
			case 1:
				fsGroup.setAStyle( fontAStyles[1] ); break;
			case 2:
				fsGroup.setAStyle( fontAStyles[2] ); break;
			default:
				break;
		}
	}

	public void restoreDefaults()
	{
		// copy all default value to this
		this.setting = Setting();
		initData();
		
		setDirty(true);
	}

	private ColorChooser createColorChooser(Composite parent, char[] langId)
	{
		with(new Label(parent, DWT.NONE)) {
			setData(LANG_ID, langId);
		}
		ColorChooser cc = new ColorChooser(parent, &setDirty);
		return cc;
	}

}