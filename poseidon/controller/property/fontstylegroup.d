module poseidon.controller.property.fontstylegroup;

public
{
	import dwt.all;
	import poseidon.util.layoutshop;
	import poseidon.globals;
	import poseidon.style.stylekeeper;
}


class FontStyleGroup : Group
{
	const static int WIDTH = 22;
	private Button chkBold, chkItalic, chkUnderline;
	private ColorChooser ccBack, ccFore;
	private Text txtSize, txtFont;
	private Button fontBtn;

	private bool showClear;

	private bool enableDirtyNotify = true;

	private void delegate(bool) dirtyNotifier;

	private AStyle theStyle;

	
	public this(Composite parent, void delegate(bool) dirtyNotifier, bool showClear = false){
		super(parent, DWT.NONE);
		this.dirtyNotifier = dirtyNotifier;
		this.showClear = showClear;
		initGUI();
	}

	private void initGUI()
	{
		this.setLayout(LayoutShop.createGridLayout(3, 5, 5, 8, 5, false));

		txtFont = createText("fs.font");
		txtFont.setLayoutData(LayoutDataShop.createGridData(GridData.GRAB_HORIZONTAL, 2, 1, 80, DWT.DEFAULT));
		txtSize = createText("fs.size");
		txtSize.setLayoutData(LayoutDataShop.createGridData(0, 1, 1, 40, DWT.DEFAULT));
		with(fontBtn = new Button(this, DWT.PUSH)){
			setText("...");
			setLayoutData(LayoutDataShop.createGridData(0, 1, 1, WIDTH, WIDTH));
			handleEvent(null, DWT.Selection, &onChooseFont);
		}
		
		
		ccFore = createColorChooser("fs.fore");
		ccBack = createColorChooser("fs.back");
		
		chkBold = createCheckBox("fs.bold");
		chkItalic = createCheckBox("fs.italic");
		chkUnderline = createCheckBox("fs.underline");
	}

	public void clear(){
		this.ccBack.setColor(-1);
		this.ccFore.setColor(-1);
		chkBold.setSelection(false);
		chkItalic.setSelection(false);
		chkUnderline.setSelection(false);

		// since setText() will fire DWT.Modify event, prevent it by set enableDirtyNotify to false
		enableDirtyNotify = false;
		txtSize.setText("");
		txtFont.setText("");
		enableDirtyNotify = true;
	}

	private ColorChooser createColorChooser(char[] langId)
	{
		Label label = new Label(this,DWT.NONE);
		label.setData(LANG_ID, langId);
		ColorChooser cc = new ColorChooser(this, dirtyNotifier);
		cc.label.setLayoutData(LayoutDataShop.createGridData(GridData.HORIZONTAL_ALIGN_BEGINNING, 1, 1, ColorChooser.WIDTH, ColorChooser.HEIGHT));

		Button btn = new Button(this, DWT.PUSH);
		btn.setText("X");
		btn.handleEvent(cc, DWT.Selection, &onClearColor);
		btn.setLayoutData(LayoutDataShop.createGridData(0, 1, 1, WIDTH, WIDTH));
		
		if(!showClear)
			btn.setVisible(false);
		return cc;
	}

	private Button createCheckBox(char[] langId)
	{
		Button button = new Button(this, DWT.CHECK);
		with(button) {
			if(langId)
				setData(LANG_ID, langId);
			setLayoutData(LayoutDataShop.createGridData(GridData.HORIZONTAL_ALIGN_BEGINNING|GridData.GRAB_HORIZONTAL, 3));
			handleEvent(null, DWT.Selection, &notifyDirty);
		}
		return button;
	}

	private Text createText(char[] langId) {
		Label label = new Label(this, DWT.NONE);
		label.setData(LANG_ID, langId);

		Text text = new Text(this, DWT.BORDER);
		text.handleEvent(null, DWT.Modify, &notifyDirty);
		return text;
	}

	private void onChooseFont(Event e)
	{
		FontDialog dlg = new FontDialog(this.getShell(), DWT.OPEN);
		FontData data;
		if(txtFont.getText().length > 0){
			int style = 0;
			if(chkBold.getSelection()) style |= DWT.BOLD;
			if(chkItalic.getSelection()) style |= DWT.ITALIC;
			data = new FontData(txtFont.getText(), std.string.atoi(txtSize.getText()),style); 
			version(Windows){
				data.data.lfUnderline = chkUnderline.getSelection();
			}
			dlg.setFontData(data);
		}
		
		data = dlg.open();
		if(data) {
			this.txtFont.setText(data.getName());
			this.txtSize.setText(std.string.toString(data.getHeight()));
			int style = data.getStyle();
			chkBold.setSelection(style & DWT.BOLD);
			chkItalic.setSelection(style & DWT.ITALIC);
			version(Windows){
				chkUnderline.setSelection(data.data.lfUnderline);
			}
			notifyDirty(null);
		}
	}

	private void onClearColor(Event e)
	{
		ColorChooser cc = cast(ColorChooser)e.cData;
		cc.setColor(-1);
		notifyDirty(null);
	}

	private void notifyDirty(Event e)
	{
		if(dirtyNotifier && enableDirtyNotify)
			dirtyNotifier(true);
	}

	public void setAStyle(AStyle astyle){
		// copy style content
		theStyle = astyle;
		
		this.ccBack.setColor(astyle.back);
		this.ccFore.setColor(astyle.fore);
		chkBold.setSelection(astyle.bold);
		chkItalic.setSelection(astyle.italic);
		chkUnderline.setSelection(astyle.underline);

		// since setText() will fire DWT.Modify event, prevent it by set enableDirtyNotify to false
		enableDirtyNotify = false;
		txtSize.setText(std.string.toString(astyle.size));
		txtFont.setText(astyle.font);
		enableDirtyNotify = true;
	}

	public AStyle getAStyle()
	{
		assert(!isDisposed());
		
		theStyle.back = ccBack.getColor();
		theStyle.fore = ccFore.getColor();
		theStyle.bold = chkBold.getSelection();
		theStyle.italic = chkItalic.getSelection();
		theStyle.underline = chkUnderline.getSelection();
		theStyle.size = std.string.atoi(txtSize.getText());
		theStyle.font = txtFont.getText();

		return theStyle;
	}
}

class ColorChooser
{
	const int WIDTH = 40;
	const int HEIGHT = 16;
	
	Color color;
	int colorValue;
	Label label;

	void delegate(bool) dirtyNotifier;
	
	this(Composite parent, void delegate(bool) dirtyNotifier)
	{
		label  = new Label(parent, DWT.BORDER|DWT.CENTER);
		initGUI();
		this.dirtyNotifier = dirtyNotifier;
	}

	private void initGUI()
	{
		// label.handleEvent(null, DWT.Paint, &onPaint);
		label.handleEvent(null, DWT.Dispose, &onDispose);
		label.handleEvent(null, DWT.MouseDown, &onSelection);
		label.handleEvent(null, DWT.MouseDoubleClick, &onSelection);
		label.setSize(WIDTH, HEIGHT);
		label.setLayoutData(LayoutDataShop.createGridData(GridData.HORIZONTAL_ALIGN_BEGINNING, 1, 1, WIDTH, HEIGHT));
	}

	void setColor(int value){
		if(color)
			color.dispose();
		label.setText("");
		colorValue = value;
		if(value == -1){
			label.setText("none");
			color = label.getDisplay().getSystemColor(DWT.COLOR_WIDGET_BACKGROUND);
		}else
			color = new Color(label.getDisplay(), value & 0xFF, (value>>8) & 0xFF, (value >> 16) & 0xFF);
		label.setBackground(color);
	}

	int getColor(){
		return colorValue;
	}
	
	private void onSelection(Event e){
		ColorDialog dlg = new ColorDialog(label.getShell(), DWT.DIALOG_TRIM|DWT.APPLICATION_MODAL);
		if(color)
			dlg.setRGB(color.getRGB());
		RGB result = dlg.open();
		if(result !is null){
			if(color)
				color.dispose();
			color = new Color(label.getDisplay(), result);
			label.setBackground(color);	
			label.setText("");
			colorValue = result.red | (result.green << 8) | (result.blue << 16);

			if(dirtyNotifier)
				dirtyNotifier(true);
		}
	}
	
	private void onDispose(Event e){
		if(color)
			color.dispose();
		color = null;
	}

	// override super method
	public void setEnabled (boolean enabled) {
		label.setEnabled(enabled);
		label.update();
	}

}


