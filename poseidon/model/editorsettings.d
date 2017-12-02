module poseidon.model.editorsettings;

public
{
	import dwt.all;
	import ak.xml.coreXML;
	import poseidon.style.stylekeeper;
	import poseidon.style.stylefactory;
	import poseidon.controller.scintillaex;
}

static public int rgb (int r, int g, int b) {
	return (r & 0xff) | ((g & 0xff) << 8) | ((b & 0xff) << 16);
}

struct Setting 
{
	
	boolean showLineNumber = true;
	boolean showBookMark = true;
	boolean showFoldingMargin = true;
	boolean showIndentationGuides = true;
	boolean curLineHiLight = true;
	boolean wrapMode = false;
	boolean tabAsSpace = false;
		
	int	tabWidth = 4;
	int	tabIndents = 4;

	// default colors
	int clCurLine = 227 | (227 << 8) | (247 << 16);
	int clSelFore = 0xFFFFFF;
	int clSelBack = 49 | (106 << 8) | (197 << 16);
	int clFoldingMargin = 0xC8D0D4;
	int clCursor = 0;
	int clLineNumFore = 0;
	int clLineNumBack = 0xC8D0D4;

	AStyle defaultStyle = {"STYLE_DEFAULT", Scintilla.STYLE_DEFAULT, "Courier New", 0, 0xFFFFFF, 11, 0, 0, 0, "Courier New", 0, 0xFFFFFF, 11, 0, 0, 0};
	AStyle outputStyle = {"STYLE_DEFAULT", Scintilla.STYLE_DEFAULT, "Tahoma", 0, 0xFFFFFF, 8, 0, 0, 0, "Tahoma", 0, 0xFFFFFF, 8, 0, 0, 0};
	AStyle searchStyle = {"STYLE_DEFAULT", Scintilla.STYLE_DEFAULT, "Tahoma", 0, 0xFFFFFF, 10, 0, 0, 0, "Tahoma", 0, 0xFFFFFF, 10, 0, 0, 0};

	static Setting opCall() {
		Setting s;
		return s;
	}
}
	
/**
 * EditItem call applySettings() to update Scintilla styles
 */
class EditorSettings
{
	private import poseidon.style.xpm;
	
	Setting _setting;

	boolean colorInited = false;

	/**
	 * indicate whether the settings changed from Preference page
	 */
	public bool dirty = false;

	this() 
	{
	}

	// get default text forgournd/background color from windows, as well as the selection text color
	// since this need to access Display, don't call it in ctor because the Display is not available in ctor, and EditorSettings is not responsibe to create it
	public static void getSysColors(Setting* setting)
	{
		Display display = Display.getDefault();
		
		Color color = display.getSystemColor(DWT.COLOR_LIST_BACKGROUND);
		setting.defaultStyle.back = cast(int)color.handle & 0xFFFFFF;
		color.dispose();

		color = display.getSystemColor(DWT.COLOR_LIST_FOREGROUND);
		setting.defaultStyle.fore = cast(int)color.handle & 0xFFFFFF;
		color.dispose();

		color = display.getSystemColor(DWT.COLOR_LIST_SELECTION);
		setting.clSelBack = cast(int)color.handle & 0xFFFFFF;
		color.dispose();

		color = display.getSystemColor(DWT.COLOR_LIST_SELECTION_TEXT);
		setting.clSelFore = cast(int)color.handle & 0xFFFFFF;
		color.dispose();

		color = display.getSystemColor(DWT.COLOR_WIDGET_BACKGROUND);
		setting.clFoldingMargin = setting.clLineNumBack = cast(int)color.handle & 0xFFFFFF;
		color.dispose();
	}

	public void _updateEditorSettings(XMLnode root, boolean save)
	{
		if(save)
			saveSettings(root);
		else
			loadSettings(root);
	}
	
	/**
	 * load from xml
	 */
	private void loadSettings(XMLnode root)
	{
		assert(root);
		
		XMLnode child = root.getChild("editorsettings");
		if(child){
			// load global settings
			XMLnode node = child.getChild("global");
			if(node)
			{
				_setting.tabWidth = XMLUtil.getAttribInt(node, "tabwidth", _setting.tabWidth);
				_setting.tabIndents = XMLUtil.getAttribInt(node, "tabIndents", _setting.tabIndents);
				_setting.showLineNumber = XMLUtil.getAttribInt(node, "showlinenumber", _setting.showLineNumber);
				_setting.showBookMark = XMLUtil.getAttribInt(node, "showbookmark", _setting.showBookMark);
				_setting.showFoldingMargin = XMLUtil.getAttribInt(node, "showfoldingmargin", _setting.showFoldingMargin);
				_setting.showIndentationGuides = XMLUtil.getAttribInt(node, "showindentationguides", _setting.showIndentationGuides);
				_setting.wrapMode = XMLUtil.getAttribInt(node, "wrapmode", _setting.wrapMode);
				_setting.tabAsSpace = XMLUtil.getAttribInt(node, "tabAsSpace", _setting.tabAsSpace);
				
				//current line high light
				_setting.curLineHiLight = XMLUtil.getAttribInt(node, "curlinehilight", _setting.curLineHiLight);
				_setting.clCurLine = XMLUtil.getAttribInt(node, "clcurline", _setting.clCurLine);
				
				// selection color
				_setting.clSelFore = XMLUtil.getAttribInt(node, "clselfore", _setting.clSelFore);
				_setting.clSelBack = XMLUtil.getAttribInt(node, "clselback", _setting.clSelBack);

				
				_setting.clFoldingMargin = XMLUtil.getAttribInt( node, "clFoldingMargin", _setting.clFoldingMargin );
				_setting.clCursor = XMLUtil.getAttribInt( node, "clCursor", _setting.clCursor );

				_setting.clLineNumFore = XMLUtil.getAttribInt( node, "clLineNumFore", _setting.clLineNumFore );
				_setting.clLineNumBack = XMLUtil.getAttribInt( node, "clLineNumBack", _setting.clLineNumBack );

				// default style
				// _setting.defaultStyle.font = XMLUtil.getAttrib(node, "deffont", _setting.defaultStyle.font);
				// _setting.defaultStyle.fore = XMLUtil.getAttribInt(node, "deffore", _setting.defaultStyle.fore);
				// _setting.defaultStyle.back = XMLUtil.getAttribInt(node, "defback", _setting.defaultStyle.back);
				// _setting.defaultStyle.size = XMLUtil.getAttribInt(node, "defsize", _setting.defaultStyle.size);
				// _setting.defaultStyle.bold = XMLUtil.getAttribInt(node, "defbold", _setting.defaultStyle.bold);
				// _setting.defaultStyle.italic = XMLUtil.getAttribInt(node, "defitalic", _setting.defaultStyle.italic);
				// _setting.defaultStyle.underline = XMLUtil.getAttribInt(node, "defunderline", _setting.defaultStyle.underline);
				
			}

			// load font style
			XMLnode fnode = child.getChild("fontstyle");
			if(fnode){
			  //			  MessageBox.showMessage("FONTSTYLE");
				char[] id = XMLUtil.getAttrib(fnode, "id", std.string.toString(_setting.defaultStyle.id));
				char[] name = XMLUtil.getAttrib(fnode, "name", _setting.defaultStyle.name);
				char[] value = XMLUtil.getAttrib(fnode, "value", _setting.defaultStyle.encodeValue());
				char[] defvalue = XMLUtil.getAttrib(fnode, "defvalue", _setting.defaultStyle.encodeDefValue());
				_setting.defaultStyle = AStyle(id, name, value, defvalue);
			}

			fnode = child.getChild("outputstyle");
			if(fnode)
			{
				char[] id = XMLUtil.getAttrib(fnode, "id", std.string.toString(_setting.outputStyle.id));
				char[] name = XMLUtil.getAttrib(fnode, "name", _setting.outputStyle.name);
				char[] value = XMLUtil.getAttrib(fnode, "value", _setting.outputStyle.encodeValue());
				char[] defvalue = XMLUtil.getAttrib(fnode, "defvalue", _setting.outputStyle.encodeDefValue());
				_setting.outputStyle = AStyle(id, name, value, defvalue);
			}

			fnode = child.getChild("searchstyle");
			if(fnode)
			{
				char[] id = XMLUtil.getAttrib(fnode, "id", std.string.toString(_setting.searchStyle.id));
				char[] name = XMLUtil.getAttrib(fnode, "name", _setting.searchStyle.name);
				char[] value = XMLUtil.getAttrib(fnode, "value", _setting.searchStyle.encodeValue());
				char[] defvalue = XMLUtil.getAttrib(fnode, "defvalue", _setting.searchStyle.encodeDefValue());
				_setting.searchStyle = AStyle(id, name, value, defvalue);
			}			
		}
	}

	/**
	 * save to xml
	 */
	private void saveSettings(XMLnode root) 
	{
		assert(root);

		// remove it first
		int index = root.getChildIndex("editorsettings");
		if(index >= 0)
			root.deleteNode(index);
		XMLnode node = root.addNode("editorsettings", null);
		
		// save global settings
		XMLnode child = node.addNode("global", null);
		child.addAttrib("tabwidth", std.string.toString(_setting.tabWidth));
		child.addAttrib("tabIndents", std.string.toString(_setting.tabIndents));
		child.addAttrib("showlinenumber", std.string.toString(_setting.showLineNumber));
		child.addAttrib("showbookmark", std.string.toString(_setting.showBookMark));
		child.addAttrib("showfoldingmargin", std.string.toString(_setting.showFoldingMargin));
		child.addAttrib("showindentationguides", std.string.toString(_setting.showIndentationGuides));
		child.addAttrib("wrapmode", std.string.toString(_setting.wrapMode));
		child.addAttrib("tabAsSpace", std.string.toString(_setting.tabAsSpace));
		
		//current line high light
		child.addAttrib("curlinehilight", std.string.toString(_setting.curLineHiLight));
		child.addAttrib("clcurline", std.string.toString(_setting.clCurLine));
		child.addAttrib( "clFoldingMargin", std.string.toString( _setting.clFoldingMargin ) );
		child.addAttrib( "clCursor", std.string.toString( _setting.clCursor ) );
		child.addAttrib( "clLineNumFore", std.string.toString( _setting.clLineNumFore ) );
		child.addAttrib( "clLineNumBack", std.string.toString( _setting.clLineNumBack ) );

		// selection color
		child.addAttrib("clselfore", std.string.toString(_setting.clSelFore));
		child.addAttrib("clselback", std.string.toString(_setting.clSelBack));

		// default style
		// child.addAttrib("deffont", _setting.defaultStyle.font);
		// child.addAttrib("deffore", std.string.toString(_setting.defaultStyle.fore));
		// child.addAttrib("defback", std.string.toString(_setting.defaultStyle.back));
		// child.addAttrib("defsize", std.string.toString(_setting.defaultStyle.size));
		// child.addAttrib("defbold", std.string.toString(_setting.defaultStyle.bold));
		// child.addAttrib("defitalic", std.string.toString(_setting.defaultStyle.italic));
		// child.addAttrib("defunderline", std.string.toString(_setting.defaultStyle.underline));

		child = node.addNode("fontstyle", null);
		child.addAttrib("id", std.string.toString(_setting.defaultStyle.id));
		child.addAttrib("name", _setting.defaultStyle.name);
		child.addAttrib("value", _setting.defaultStyle.encodeValue());
		child.addAttrib("defvalue", _setting.defaultStyle.encodeDefValue());

		child = node.addNode("outputstyle", null);
		child.addAttrib("id", "");
		child.addAttrib("name","");
		child.addAttrib("value", _setting.outputStyle.encodeValue());
		child.addAttrib("defvalue", _setting.outputStyle.encodeDefValue());

		child = node.addNode("searchstyle", null);
		child.addAttrib("id", "");
		child.addAttrib("name", "");
		child.addAttrib("value", _setting.searchStyle.encodeValue());
		child.addAttrib("defvalue", _setting.searchStyle.encodeDefValue());		
		
		// save all style keepers
		try{
			foreach(IStyleKeeper keeper; StyleFactory.styleKeepers)
			{
				if(keeper.needSerialize)
					StyleFactory.saveStyleKeeper(keeper);
			}
		}catch(Exception e){
			Util.trace(e.toString());
		}
	}

	/**
	 * apply global editor settings
	 */
	void applySettings(ScintillaEx sc, char[] fileExt)
	{
		assert(sc);

		sc.styleClearAll();
		
		sc.setTabWidth(_setting.tabWidth);
		sc.setTabIndents(_setting.tabIndents);
		sc.setUseTabs( !_setting.tabAsSpace );

		sc.setIndentationGuides(_setting.showIndentationGuides);

		sc.setWrapMode(_setting.wrapMode);

		// setup markers
		int white = rgb(255,255,255);
		int grey  = rgb(128,128,128);
		sc.defineMarker(Scintilla.SC_MARKNUM_FOLDEROPEN, Scintilla.SC_MARK_BOXMINUS, white, grey);
		sc.defineMarker(Scintilla.SC_MARKNUM_FOLDER, Scintilla.SC_MARK_BOXPLUS, white, grey);
		sc.defineMarker(Scintilla.SC_MARKNUM_FOLDERSUB, Scintilla.SC_MARK_VLINE, white, grey);
		sc.defineMarker(Scintilla.SC_MARKNUM_FOLDERTAIL, Scintilla.SC_MARK_LCORNER, white, grey);
		sc.defineMarker(Scintilla.SC_MARKNUM_FOLDEREND, Scintilla.SC_MARK_BOXPLUSCONNECTED, white, grey);
		sc.defineMarker(Scintilla.SC_MARKNUM_FOLDEROPENMID, Scintilla.SC_MARK_BOXMINUSCONNECTED, white, grey);
		sc.defineMarker(Scintilla.SC_MARKNUM_FOLDERMIDTAIL, Scintilla.SC_MARK_TCORNER, white, grey);

		// selection color
		sc.setSelFore(true, _setting.clSelFore);
		sc.setSelBack(true, _setting.clSelBack);

		// High light current line
		sc.setCaretLineVisible(_setting.curLineHiLight);
		sc.setCaretLineBack(_setting.clCurLine);

		// set the backgroundcolor of brace highlights
		sc.styleSetBack(Scintilla.STYLE_BRACELIGHT, rgb(0,255,0));
		sc.styleSetFore(Scintilla.STYLE_BRACELIGHT, rgb(255,0,0));
		sc.styleSetBold(Scintilla.STYLE_BRACELIGHT, 1);

	
		sc.setMarginWidthN(0, 24 * (_setting.showLineNumber > 0));
		sc.setMarginWidthN(1, 16 * (_setting.showBookMark > 0));
		sc.setMarginTypeN(1, Scintilla.SC_MARGIN_SYMBOL);
		sc.setMarginSensitiveN(1, true);
		//sc.setMarginWidthN(1, 0);
		sc.setMarginMaskN( 1, (1<<1) | (1<<2) | ( 1<<3) );
		
		//setup folding	
		sc.setMarginWidthN(2, 16 * (_setting.showFoldingMargin > 0));
		sc.setFoldFlags(16);
		sc.setMarginSensitiveN(2, true);
		sc.setMarginMaskN(2, Scintilla.SC_MASK_FOLDERS);
		
		sc.setProperty("fold", "1");
		sc.setProperty("fold.html", "1");
		sc.setProperty("fold.html.preprocessor", "1");
		sc.setProperty("fold.comment", "1");
		sc.setProperty("fold.nestcomment", "1");
		sc.setProperty("fold.at.else", "1");
		sc.setProperty("fold.flags", "1");
		sc.setProperty("fold.preprocessor", "1");
		sc.setProperty("styling.within.preprocessor", "1");
		sc.setProperty("asp.default.language", "1");

		sc.autoCSetMaxHeight( 10 );

		//sc.setViewEOL( true );
		//sc.callTipSetBack( rgb(0,255,0) );

		// set FoldingMargin color
		sc.setFoldMarginColour( true, _setting.clFoldingMargin );
		
		// set LineNum Color
		sc.styleSetFore( sc.STYLE_LINENUMBER, _setting.clLineNumFore );
		sc.styleSetBack( sc.STYLE_LINENUMBER,  _setting.clLineNumBack );

		// set Cursor Color
		sc.setCaretFore( _setting.clCursor );
		
		//setup xpm image
		sc.call( sc.SCI_REGISTERIMAGE, 0, cast(int) private_method_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE, 1, cast(int) protected_method_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE, 2, cast(int) public_method_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE, 3, cast(int) private_variable_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE, 4, cast(int) protected_variable_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE, 5, cast(int) public_variable_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE, 6, cast(int) class_private_obj_xpm, true );			
		sc.call( sc.SCI_REGISTERIMAGE, 7, cast(int) class_protected_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE, 8, cast(int) class_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE, 9, cast(int) struct_private_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,10, cast(int) struct_protected_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,11, cast(int) struct_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,12, cast(int) interface_private_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,13, cast(int) interface_protected_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,14, cast(int) interface_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,15, cast(int) union_private_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,16, cast(int) union_protected_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,17, cast(int) union_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,18, cast(int) enum_private_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,19, cast(int) enum_protected_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,20, cast(int) enum_obj_xpm, true );

		sc.call( sc.SCI_REGISTERIMAGE,21, cast(int) normal_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,22, cast(int) import_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,23, cast(int) autoWord_xpm, true );

		sc.call( sc.SCI_REGISTERIMAGE,24, cast(int) parameter_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,25, cast(int) enum_member_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,26, cast(int) template_obj_xpm, true );

		sc.call( sc.SCI_REGISTERIMAGE,27, cast(int) alias_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,28, cast(int) mixin_template_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,29, cast(int) functionpointer_obj_xpm, true );

		sc.call( sc.SCI_REGISTERIMAGE,30, cast(int) template_function_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,31, cast(int) template_class_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,32, cast(int) template_struct_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,33, cast(int) template_union_obj_xpm, true );
		sc.call( sc.SCI_REGISTERIMAGE,34, cast(int) template_interface_obj_xpm, true );

		//sc.call( sc.SCI_MARKERDEFINEPIXMAP, sc.SC_MARK_PIXMAP, cast(int) debug_obj_xpm, true );

	
		// setup auto completion
		// sc.autoCSetSeparator(10); //Use a separator of line feed
		sc.autoCSetSeparator( ' ' );
		sc.autoCSetIgnoreCase(true);

		
		// setup call tips
		sc.setMouseDwellTime(1000);

		applyLexer(sc, fileExt);

		sc.resetLineNumWidth();
	}
	
	// apply language specified key words and styles
	// current doctype can be "d", "xml"
	private void applyLexer(ScintillaEx sc, char[] fileExt) 
	{
		int lexer = StyleFactory.findLexerFromExt(fileExt);
		if(lexer != -1)
		{
			if( lexer == Scintilla.SCLEX_XML )
			{
				sc.setStyleBits( 7 );
				sc.setLexer( Scintilla.SCLEX_XML );
			}
			else
			{
				sc.setStyleBits( 5 );
				sc.setLexer(lexer);
			}
			resetStyles(sc);
			
			IStyleKeeper keeper = StyleFactory.getStyleKeeper(lexer);
			if(keeper)
				keeper.applySettings(sc);
		}else
			resetStyles(sc);
	}

	public void resetToDefault() 
	{
		this._setting = Setting();
	}

	private void resetStyles(ScintillaEx sc) 
	{
		// user defined style from 0~31, Scintilla.STYLE_DEFAULT = 32
		for(int i=0; i<33; ++i)
		{
			_setting.defaultStyle.id = i;
			AbstractStyleKeeper.setAStyle(sc, &_setting.defaultStyle);
		}
		
		_setting.defaultStyle.id = Scintilla.STYLE_DEFAULT;
	}

}
