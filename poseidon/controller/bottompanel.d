module poseidon.controller.bottompanel;


private import dwt.all;

private import poseidon.controller.editor;
private import poseidon.controller.gui;
private import dwt.internal.converter;
private import dwt.internal.win32.os;
private import poseidon.model.executer;
private import poseidon.globals;
private import poseidon.i18n.itranslatable;

class BottomPanel : CTabFolder  {
	
	int[]		lastSashWeights;
	SashForm	_parent;
	const int	TAB_HEIGHT = 24;
	Composite	tbContainer;	// tool bar container
	
	OutputPanel			outputPanel;
	SearchPanel			searchPanel;
	//DebugOutputPanel	debugOutputPanel;
	StackLayout	stackLayout;

	this(SashForm parent) {
		super(parent, DWT.TOP | DWT.BORDER);
		_parent = parent;
		
		initGUI();
		
		_parent.handleEvent(null, DWT.Resize, &onSashResize);
		this.handleCTabFolderEvent(null, CTabFolder.MINIMIZE, &onMin);
		this.handleCTabFolderEvent(null, CTabFolder.RESTORE, &onRestore);
		this.handleEvent(null, DWT.MouseDown, delegate(Event e){
			BottomPanel pthis = cast(BottomPanel)e.widget;
			if(pthis.getItem(new Point(e.x, e.y))){
				pthis.onRestore(null);
			}
		});
		this.handleEvent(null, DWT.MouseDoubleClick, delegate(Event e){
			if(e.button == 1){
				BottomPanel pthis = cast(BottomPanel)e.widget;
				pthis.toggleMaximized();
			}
		});
		this.handleEvent(null, DWT.Selection, delegate(Event e) {
			BottomPanel pthis = cast(BottomPanel)e.widget;
			BottomItem item = cast(BottomItem)e.item;
			pthis.stackLayout.topControl = item.getTbBar(null);
			pthis.tbContainer.layout();
		});
	}
	
	private void initGUI()
	{
		setMinimizeVisible(true);
		
		static int[2] percentArray = [20, 100];
		setTabHeight(TAB_HEIGHT - 2);
		setSimple(false);
		setSelectionBackground(Editor.colorsActive.reverse, percentArray, true);
		setSelectionForeground(DWTResourceManager.getColor(255,255,255));	
		
		outputPanel 		= new OutputPanel( this );
		searchPanel 		= new SearchPanel( this );
		//debugOutputPanel 	= new DebugOutputPanel( this );
		
		this.setSelection(0);
		tbContainer = new Composite(this, DWT.NONE);
		stackLayout = new StackLayout();
		tbContainer.setLayout(stackLayout);
		
		Control top = outputPanel.getTbBar(tbContainer);
		searchPanel.getTbBar(tbContainer);
		//debugOutputPanel.getTbBar(tbContainer);
		stackLayout.topControl = top;
		tbContainer.layout();
		setTopRight(tbContainer);
	}
	
	private void onMin(CTabFolderEvent e) {
		if(!getMinimized()){
			lastSashWeights = _parent.getWeights();
			
			Globals.BottomPanelLastWeight = lastSashWeights;
			
			Point pt1 = _parent.getSize();
			int[] newWeights;
			newWeights ~= pt1.y - TAB_HEIGHT;
			newWeights ~= TAB_HEIGHT;
			_parent.setWeights(newWeights);
			this.setMinimized(true);
			_parent.layout(true);
		}
	}
	private void onRestore(CTabFolderEvent e) {
		if(this.getMinimized()){
			this.setMinimized(false);
			_parent.setWeights(lastSashWeights);
			Globals.BottomPanelLastWeight[] = 0;
			_parent.layout(true);
		}
	}
	
	private void onSashResize(Event e) {
		if(this.getMinimized()) {
			Point pt1 = _parent.getSize();
			int[] newWeights;
			newWeights ~= Math.max(0, pt1.y - TAB_HEIGHT);
			newWeights ~= TAB_HEIGHT;
			_parent.setWeights(newWeights);
			_parent.layout(true);
		}
	}
	
	public void toggleMaximized() {
		if(this.getMinimized()){
			onRestore(null);
		}else{
			onMin(null);
		}
	}

}

// may platform depended
class TextEx : Text {
	
	public this (Composite parent, int style) 
	{
		super (parent, style);
		setDoubleClickEnabled(false);
	}
	
	public void selectLine(int line = -1)
	{
		int start = OS.SendMessageA(handle, OS.EM_LINEINDEX, line, 0);
		int len = OS.SendMessageA(handle, OS.EM_LINELENGTH, start, 0);
		
		OS.SendMessage (handle, OS.EM_SETSEL, start, start + len);
		OS.SendMessage (handle, OS.EM_SCROLLCARET, 0, 0);
	}	
	
	char[] getLineText(int line = -1) {
		if(line == -1)
			line = getCaretLineNumber();
		int linePos = OS.SendMessageA(handle, OS.EM_LINEINDEX, line, 0);
		int len = OS.SendMessageA(handle, OS.EM_LINELENGTH, linePos, 0);
		len = Math.max(len, 2);
		CHAR[] buffer = new CHAR[len];
		buffer[0] = cast(CHAR)len & 0xFF;
		buffer[1] = cast(CHAR)len >> 8;
		OS.SendMessageA (handle, OS.EM_GETLINE, line, buffer.ptr);
		return Converter.MBCSzToStr(buffer.ptr, -1);
	}
	
}

abstract class BottomItem : CTabItem, ITranslatable  {
	
	private import std.thread;
	private import std.stream;
	private import std.regexp;
	
	private alias std.string.atoi toInt;
	
	// [^/:*?"<>|]
	const static char[] errRelativePath = `^(.+)[\s\t]*\((\d+)\):`;
	const static char[] errFullPath = `^([a-z]{1}\:.+)[\s\t]*\((\d+)\):`;
	const static char[] warnFullPath = `^warning - (.+)[\s\t]*\((\d+)\):`;
	const static char[] warnRelativePath = `^warning - (.+)[\s\t]*\((\d+)\):`;
	
	// ToolBar container
	Composite 	tbBar = null;
	ToolItem	tiStop;
	
	public this(CTabFolder parent) {
		super(parent, DWT.NONE);
	}
	
	abstract public Control getTbBar(Composite container);
	
	/**
	 * Clear the contents
	 */
	abstract public void clear();
	
	abstract public void setString(char[] str);
	
	abstract public void appendString(char[] str);
	
	abstract public void appendLine(char[] str);

	public boolean busy() {return false;}
	
	
	public void bringToFront() {
		BottomPanel _parent = cast(BottomPanel)getParent();
		if(_parent.getSelection() !is this){
			/** 
			 * since CTabFolder.setSelection() will not trig DWT.Selection
			 * event, must set correct top right ToolBar manually
			 */
			_parent.setSelection(this);
			_parent.stackLayout.topControl = getTbBar(null);
			_parent.tbContainer.layout();
		}
		_parent.onRestore(null);
	}
	
	protected void onDBClick(Event e) {
		TextEx text = cast(TextEx)e.cData;
		char[] sel = text.getLineText(-1);
		text.selectLine(-1);
		
		int line;
		char[] filename = parseConsoleLine(sel, line);
		filename = std.string.strip(filename);
		if(filename.length) {
			sGUI.packageExp.openFile(filename, line, true);
		}
	}
	
	/**
	 * Try to find the file name and error line of a console output
	 */
	public static char[] parseConsoleLine(char[] input, inout int lineNumber) {
		char[] txt;
		lineNumber = -1;
		if(input.length == 0)
			return null;
		// try to find absolute path file with extend "d"
		// "d:\path\subdir\file.d()"
		// test warning message first
		RegExp reg = new RegExp(warnFullPath, null);
		if(reg.test(input)){
			txt = reg.replace(`$1`);
			lineNumber = cast(int)toInt(reg.replace(`$2`)) - 1;
			return txt;
		}
		
		reg = new RegExp(warnRelativePath, null);
		if(reg.test(input)){
			txt = reg.replace(`$1`);
			lineNumber = cast(int)toInt(reg.replace(`$2`)) - 1;
			return txt;
		}
		
		reg = new RegExp(errFullPath, "i");
		if(reg.test(input)){
			txt = reg.replace(`$1`);
			lineNumber = cast(int)toInt(reg.replace(`$2`)) - 1;
			return txt;
		}
		
		reg = new RegExp(errRelativePath, null);
		if(reg.test(input)){
			txt = reg.replace(`$1`);
			lineNumber = cast(int)toInt(reg.replace(`$2`)) - 1;
			return txt;
		}
		return null;
	}
}

class OutputPanel : BottomItem {

	TextEx 		content;
	
	public this(CTabFolder parent) {
		super(parent);
		
		initGUI(parent);
		updateI18N();
		content.handleEvent(content, DWT.MouseDoubleClick, &onDBClick);
	}
	private void initGUI(Composite parent) {
		setImage(Globals.getImage("console_view"));
		content = new TextEx(parent, Globals.outputWRAP | DWT.MULTI | DWT.V_SCROLL | DWT.H_SCROLL );
		this.setControl(content);
		scope color = new Color( display, 0, 0x33, 0x66 );
		content.setForeground( color );

		scope font = new Font( display, Editor.settings._setting.outputStyle.font, Editor.settings._setting.outputStyle.size, DWT.NORMAL );
		content.setFont( font );
	}
	
	public void clear() {
		content.setText("");
	}
	
	public void setString(char[] str){
		content.setText(str);
	}

	public char[] getString(){ return content.getText(); }

	void setForeColor( int r, int g, int b )
	{
		scope color = new Color( display, r, g, b );
		content.setForeground( color );
	}
	
	public void appendLine(char[] str){
		content.append(str ~ "\n");
	}
	public void appendString(char[] str){
		content.append(str);
	}

	public Control getTbBar(Composite container) {
		if(tbBar is null){
			tbBar = new Composite(container, DWT.NONE);
			GridLayout gl = new GridLayout();
			tbBar.setLayout(gl);
			with(gl) {
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar(tbBar, DWT.FLAT | DWT.HORIZONTAL);
			toolbar.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			with(tiStop = new ToolItem(toolbar, DWT.NONE)){
				setImage(Globals.getImage("progress_stop"));	
				setDisabledImage(Globals.getImage("progress_stop_dis"));
				setToolTipText( Globals.getTranslation( "outputpanel.tooltip_stop" ) );
				setEnabled(false);
				handleEvent(null, DWT.Selection, delegate(Event e){
					ToolItem tiStop = cast(ToolItem)e.widget;
					tiStop.setData(new Integer(0)); // set _continue flag to false
					Globals.bOutputStop = true;
				});
			}				
			with(new ToolItem(toolbar, DWT.NONE)){
				setImage(Globals.getImage("close_view"));
				setToolTipText( Globals.getTranslation( "outputpanel.tooltip_clean" ) );
				handleEvent(this, DWT.Selection, delegate(Event e) {
					BottomItem pthis = cast(BottomItem)e.cData;
					pthis.clear();
				});
			}
		}
		
		return tbBar;
	}
	
	public void setBusy(boolean busy){
		tiStop.setEnabled(busy);
	}

	void updateI18N()
	{
		this.setText(Globals.getTranslation("outputpanel.title"));
	}
	
}



class SearchPanel : BottomItem {
	
	TextEx 		content;
	
	public this(CTabFolder parent) {
		super(parent);
		initGUI(parent);
		updateI18N();
		content.handleEvent(content, DWT.MouseDoubleClick, &onDBClick);
	}
	
	public void clear() {
		content.setText("");
	}
	
	public void setString(char[] str){
		content.setText(str);
	}
	public void appendLine(char[] str){
		content.append(str ~ "\n");
	}
	
	public void appendString(char[] str){
		content.append(str);
	}
	
	public Control getTbBar(Composite container) {
		if(tbBar is null){
			tbBar = new Composite(container, DWT.NONE);
			GridLayout gl = new GridLayout();
			tbBar.setLayout(gl);
			with(gl) {
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar(tbBar, DWT.FLAT | DWT.HORIZONTAL);
			toolbar.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			with(tiStop = new ToolItem(toolbar, DWT.NONE)){
				setImage(Globals.getImage("progress_stop"));	
				setDisabledImage(Globals.getImage("progress_stop_dis"));
				setToolTipText( Globals.getTranslation( "searchpanel.tooltip_stop" ) );
				setEnabled(false);
				handleEvent(null, DWT.Selection, delegate(Event e){
					ToolItem tiStop = cast(ToolItem)e.widget;
					Editor.stopSearch();
				});
			}			
			with(new ToolItem(toolbar, DWT.NONE)){
				setImage(Globals.getImage("close_view"));
				setToolTipText( Globals.getTranslation( "searchpanel.tooltip_clean" ) );
				handleEvent(this, DWT.Selection, delegate(Event e) {
					BottomItem pthis = cast(BottomItem)e.cData;
					pthis.clear();
				});
			}

		}
		return tbBar;
	}
	
	private void initGUI(Composite parent) {
		setImage(Globals.getImage("e_search_results_view"));
		content = new TextEx(parent, DWT.MULTI | DWT.V_SCROLL | DWT.H_SCROLL);
		this.setControl(content);

		scope font = new Font( display, Editor.settings._setting.searchStyle.font, Editor.settings._setting.searchStyle.size, DWT.NORMAL );
		content.setFont( font );		
	}
	
	public void setBusy(boolean busy){
		tiStop.setEnabled(busy);
	}

	void updateI18N()
	{
		this.setText(Globals.getTranslation("searchpanel.title"));
	}
}

/+
class DebugOutputPanel : BottomItem {
	
	TextEx 		content;
	
	public this(CTabFolder parent) {
		super(parent);
		initGUI(parent);
		updateI18N();
		//content.handleEvent(content, DWT.MouseDoubleClick, &onDBClick);
	}
	
	public void clear(){ content.setText( "" ); }
	
	public void setString( char[] str ){ content.setText( str ); }

	public void appendLine( char[] str ){ content.append( str ~ "\n" ); }
	
	public void appendString( char[] str ){ content.append( str ); }
	
	public Control getTbBar(Composite container) {
		if(tbBar is null){
			tbBar = new Composite(container, DWT.NONE);
			GridLayout gl = new GridLayout();
			tbBar.setLayout(gl);
			with(gl) {
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar(tbBar, DWT.FLAT | DWT.HORIZONTAL);
			toolbar.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			with(tiStop = new ToolItem(toolbar, DWT.NONE)){
				setImage(Globals.getImage("progress_stop"));	
				setDisabledImage(Globals.getImage("progress_stop_dis"));
				setToolTipText("Stop Searching");
				setEnabled(false);
				handleEvent(null, DWT.Selection, delegate(Event e){
					ToolItem tiStop = cast(ToolItem)e.widget;
					Editor.stopSearch();
				});
			}			
			with(new ToolItem(toolbar, DWT.NONE)){
				setImage(Globals.getImage("close_view"));
				setToolTipText("Clear Search Result");
				handleEvent(this, DWT.Selection, delegate(Event e) {
					BottomItem pthis = cast(BottomItem)e.cData;
					pthis.clear();
				});
			}

		}
		return tbBar;
	}
	
	private void initGUI(Composite parent) {
		setImage(Globals.getImage("debug_exc"));
		content = new TextEx( parent, DWT.MULTI | DWT.V_SCROLL | DWT.H_SCROLL );
		content.setEditable( false );
		this.setControl(content);

		scope font = new Font( display, Editor.settings._setting.searchStyle.font, Editor.settings._setting.searchStyle.size, DWT.NORMAL );
		content.setFont( font );		
	}
	
	public void setBusy(boolean busy){ tiStop.setEnabled( busy ); }

	void updateI18N()
	{
		this.setText( "Debug" );
		//this.setText(Globals.getTranslation("searchpanel.title"));
	}
}
+/