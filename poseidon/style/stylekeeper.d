/*************************
 * Make scintilla to support multiple style documents
 */

module poseidon.style.stylekeeper;

public
{
	import poseidon.controller.scintillaex;
	import poseidon.util.xmlutil;
	import dwt.all;
	import ak.xml.coreXML;
	import poseidon.controller.scintillaex;
}


 static public int rgb (int r, int g, int b) {
	return (r & 0xff) | ((g & 0xff) << 8) | ((b & 0xff) << 16);
}
	
/**
 * detail of a scintilla style
 */
struct AStyle
{
	char[] name; // the text field same to id
	int id;

	char[] font = null;	// font name
	int fore = -1;
	int back = -1;
	int size = 0;		// font size
	int bold = 0;
	int italic = 0;
	int underline = 0;

	// default value
	char[] dfont = "Courier New";
	int dfore = 0;
	int dback = 0xFFFFFF;
	int dsize = 11;
	int dbold, ditalic, dunderline;
	

	// the return sequency is "fore, back, size, bold, italic, underline"
	static int[] decode(char[] text, inout char[] font)
	{
		font = null;
		int[] result = new int[6];
		result[0] = result[1] = -1;
		char[][] strings = std.string.split(text, "|");

		foreach(char[] str; strings)
		{
			char[][] strs2 = std.string.split(str, ":");
			if(strs2.length == 2)
			{
				if(strs2[0] == "ft")
					font = strs2[1].dup;
				else
				{
					int ii = cast(int)std.string.atoi(strs2[1]);
					if(strs2[0] == "fg")
						result[0] = ii;
					else if(strs2[0] == "bg")
						result[1] = ii;
					else if(strs2[0] == "sz")
						result[2] = ii;
					else if(strs2[0] == "b")
						result[3] = ii;
					else if(strs2[0] == "i")
						result[4] = ii;
					else if(strs2[0] == "u")
						result[5] = ii;
				}
			}
		}
		return result;
	}

	char[] encodeValue()
	{
		char[] result;
		result ~= "ft:" ~ font;
		result ~= "|fg:" ~ std.string.toString(fore);
		result ~= "|bg:" ~ std.string.toString(back);
		result ~= "|sz:" ~ std.string.toString(size);
		result ~= "|b:" ~ std.string.toString(bold);
		result ~= "|i:" ~ std.string.toString(italic);
		result ~= "|u:" ~ std.string.toString(underline);
		return result;
	}

	// default value
	char[] encodeDefValue()
	{
		char[] result;
		result ~= "ft:" ~ dfont;
		result ~= "|fg:" ~ std.string.toString(dfore);
		result ~= "|bg:" ~ std.string.toString(dback);
		result ~= "|sz:" ~ std.string.toString(dsize);
		result ~= "|b:" ~ std.string.toString(dbold);
		result ~= "|i:" ~ std.string.toString(ditalic);
		result ~= "|u:" ~ std.string.toString(dunderline);
		return result;
	}

	// the string is like 
	// "font:Courier New|fore:-1|back:-1|size:0|bold:0|italic:0|underline:0"
	// "ft:Courier New|fg:-1|bg:-1|sz:0|b:0|i:0|u:0"
	static AStyle opCall(char[] id, char[] name, char[] value, char[] defValue)
	{
		AStyle style;
		style.id = cast(int)std.string.atoi(id);
		style.name = name;
		
		int[] rets = decode(value, style.font);
		style.fore = rets[0];
		style.back = rets[1];
		style.size = rets[2];
		style.bold = rets[3];
		style.italic = rets[4];
		style.underline = rets[5];

		rets = decode(defValue, style.dfont);
		style.dfore = rets[0];
		style.dback = rets[1];
		style.dsize = rets[2];
		style.dbold = rets[3];
		style.ditalic = rets[4];
		style.dunderline = rets[5];
		
		return style;
	}

	void resetToDefault()
	{
		font = dfont;
		fore = dfore;
		back = dback;
		size = dsize;
		bold = dbold;
		italic = ditalic;
		underline = dunderline;

		font = dfont;
	}

}


/**
 * Interface to represent one kind doc/language
 */
interface IStyleKeeper
{
	char[][] getKeyWords();
	AStyle[] getStyles();

	char[] getLexerName();
	
	int getLexerID();

	void applySettings(ScintillaEx sc);

	void save(XMLnode node);

	// Reset To Default
	void resetKeyWords();

	void resetStyles();

	void setKeyWords(char[][] keywords);

	void setStyles(AStyle[] styles);

	// wether the style need to serialize to disk
	void needSerialize(bool value);
	bool needSerialize();
}

abstract class AbstractStyleKeeper : IStyleKeeper
{
	protected char[][] keyWords;
	protected AStyle[] styles;
	protected bool _needSerialize = false;
	
	this() 
	{
	}

	AStyle[] getStyles() { return styles; }
	char[][] getKeyWords() { return keyWords; }
	void setKeyWords(char[][] keywords) { this.keyWords = keywords; }
	void setStyles(AStyle[] styles) { this.styles = styles; }
	void needSerialize(bool value) { _needSerialize = value; };
	bool needSerialize() { return _needSerialize; };
	
	void applySettings(ScintillaEx sc) 
	{
		applyStyles(sc);
		applyKeyWords(sc);
		
		// repaint the document
		sc.colourise(0, -1);
	}
	
	void applyStyles(ScintillaEx sc)
	{
		foreach(AStyle style; getStyles()) {
			setAStyle(sc, &style);
		}
	}

	void applyKeyWords(ScintillaEx sc)
	{
		for(int i=0; i<getKeyWords().length; ++i)
		{
			Util.trace(keyWords[i]);
			sc.setKeyWords(i, keyWords[i]);
		}
	}

	void loadKeyWords(XMLnode keeperNode) {
		keyWords = null;
		
		XMLnode node = keeperNode.getChild("keywords");
		if(node){
			int count = node.getChildCount();
			for(int i=0; i<count; ++i)
			{
				char[] value = XMLUtil.getAttrib(node.getChild(i), "value", null);
				keyWords ~= value;
			}
		}
	}

	void loadStyles(XMLnode keeperNode) {
		styles = null;
		
		XMLnode node = keeperNode.getChild("styles");
		if(node){
			int count = node.getChildCount();
			styles  = new AStyle[count];
			for(int i=0; i<count; ++i)
			{
				XMLnode child = node.getChild(i);
				
				char[] id = XMLUtil.getAttrib(child, "id", null);
				char[] name = XMLUtil.getAttrib(child, "name", null);
				char[] value = XMLUtil.getAttrib(child, "value", null);
				char[] defvalue = XMLUtil.getAttrib(child, "defvalue", null);
				styles[i] = AStyle(id, name, value, defvalue);
			}
		}
	}

	void resetStyles()
	{
		for(int i=0; i<styles.length; ++i)
		{
			styles[i].resetToDefault();
		}
	}

	void save(XMLnode keeperNode){
		// add root
		XMLnode node = keeperNode.addNode("lexer", null);
		node.addAttrib("name", getLexerName());
		
		// save key words
		XMLnode child = node.addNode("keywords", null);
		for(int i=0; i<keyWords.length; ++i) {
			XMLnode keynode = child.addNode("keywords", null);
			keynode.addAttrib("id", std.string.toString(i));
			keynode.addAttrib("value",  keyWords[i]);
		}
		
		// save styles
		child = node.addNode("styles", null);
		foreach(AStyle style; styles) {
			XMLnode styleNode = child.addNode("styles", null);
			styleNode.addAttrib("id", std.string.toString(style.id));
			styleNode.addAttrib("name", style.name);
			styleNode.addAttrib("value", style.encodeValue());
			styleNode.addAttrib("defvalue", style.encodeDefValue());
		}
	}

	static void setAStyle(ScintillaEx sc, AStyle* style) {
		sc.setAStyle(style.id, style.fore, style.back, style.size, style.font, style.bold, style.italic, style.underline);
	}
}

