module poseidon.controller.statusbar;

private import dwt.all;
private import poseidon.i18n.itranslatable;
private import  poseidon.controller.editor;
private import poseidon.controller.gui;


class StatusBar : Composite, ITranslatable, EditorListener
{
	private import std.stream;
	private import std.string;

	CLabel statusbar;
	CLabel rowColIndicator;
	CLabel ovrIndicator;
	CLabel encoding;
	
	static char[][int] ENCODE_NAME;
	const int height = 22;
	
	this(Composite parent, int style = DWT.NONE){
		super(parent, style);
		initGUI();
		
		ENCODE_NAME[-2] 		= "UTF8";
		ENCODE_NAME[-1] 		= "DEFAULT";
		ENCODE_NAME[BOM.UTF8] 	= "UTF8.BOM";
		ENCODE_NAME[BOM.UTF16LE] = "UTF16LE";
		ENCODE_NAME[BOM.UTF16BE] = "UTF16BE";
		ENCODE_NAME[BOM.UTF32LE] = "UTF32LE";
		ENCODE_NAME[BOM.UTF32BE] = "UTF32BE";
	}

void mouseDoubleClick(Event e )
{

  char [] f = statusbar.getText();
  int pos = f.find("#") ;
  if ( pos != -1 )
    {
      
      

    }

}
	
	private void initGUI(){
		this.setSize(0, 24);
		this.setLayoutData(new GridData (GridData.GRAB_HORIZONTAL | GridData.HORIZONTAL_ALIGN_FILL));// | GridData.VERTICAL_ALIGN_FILL));

		GridLayout gridLayout = new GridLayout();
		with(gridLayout){
			marginWidth = 0;
			marginHeight = 0;
			numColumns = 7;
			makeColumnsEqualWidth = false;
			horizontalSpacing = 0;
			verticalSpacing = 0;
		}
		this.setLayout(gridLayout);
		
		statusbar = new CLabel(this, DWT.NONE);
		statusbar.setLayoutData(new GridData(GridData.GRAB_HORIZONTAL | GridData.HORIZONTAL_ALIGN_FILL));
		statusbar.setText("ready");
		statusbar.handleEvent(null, DWT.MouseDoubleClick, &mouseDoubleClick);
		//		statusbar.addMouseListener(&this.mouseDoubleClick );
		createSeparator();
		rowColIndicator = new CLabel(this, DWT.NONE);
		rowColIndicator.setText("0 : 0");
		rowColIndicator.setLayoutData(new GridData(90, height));
		createSeparator();
		ovrIndicator = new CLabel(this, DWT.NONE);
		ovrIndicator.setLayoutData(new GridData(50, height));
		createSeparator();
		encoding = new CLabel(this, DWT.NONE);
		encoding.setLayoutData(new GridData(70, height));
	}
	
	private Label createSeparator(){
		Label sep = new Label(this, DWT.VERTICAL|DWT.SEPARATOR|DWT.SHADOW_OUT);
		sep.setLayoutData(new GridData(4, height));
		return sep;
	}
	
	public void onActiveEditItemChanged(EditorEvent e) 
	{
		updateStatusBar();
	}
	public void onAllEditItemClosed(EditorEvent e){
		updateStatusBar();
	}
	public void onEditItemSaveStateChanged(EditorEvent e){
	}
	public void onEditItemDisposed(EditorEvent e){}
	
	public void updateLineInfo(int[] info) {
		if(info[0] != -1){
			// row / col is zerio based index, plus one here
			char[] s = std.string.format("%d : %d", info[0] + 1, info[1] + 1);
			rowColIndicator.setText(s);
			ovrIndicator.setText(info[2] ? "OVR" : "INS");
			int ibom = info[3];
			char[] encode = "";
			if(ibom in ENCODE_NAME)
				encode = ENCODE_NAME[ibom];
			encoding.setText(encode);
		}else{
			rowColIndicator.setText("");
			ovrIndicator.setText("");
			encoding.setText("");
		}		
	}

	public void setString(char[] text, bool hiLight = false){
		statusbar.setText(text);
		if(hiLight){
		}
	}
	public void updateStatusBar()
	{
		updateLineInfo(sGUI.editor.getLineInfo());
	}

	void updateI18N()
	{
	}
}
