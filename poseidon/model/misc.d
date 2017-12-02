module poseidon.model.misc;

private import dwt.all;
private import ak.xml.coreXML;
private import dwt.internal.converter;
private import std.thread;


extern (C) {
	void _searchenv( char *filename, char *varname, char *pathname );
}


class _ShortCut {
	// used in preference dialog to sort
	static int sortdirection;
	static int sorttype;
	enum{
		SORT_NAME,	// sort by name
		SORT_KEY,	// sort by keyname
	}
	
	char[] 	name;
	uint 	mask=0;
	uint 	code = 0;
	
	uint	mask_def=0;
	uint	code_def = 0;
	
	char[]	comment;
	
	this() {}
	
	public void dump() {
		debug{
			Util.trace("\r\n === dump of short cut ===");
			Util.trace("name : " ~ name);
			Util.trace("mask : " ~ std.string.toString(mask));
			Util.trace("code : " ~ std.string.toString(code));
			Util.trace("mask_def : " ~ std.string.toString(mask_def));
			Util.trace("code_def : " ~ std.string.toString(code_def)); 
		}
	}
	
	boolean match(uint mask, uint code) {
		return (this.mask == mask) && (this.code == code);
	}
	
	public char[] keyname() {
		char[] txt = null;
		if(mask & DWT.CTRL)
			txt = "CTRL";
		if(mask & DWT.ALT)
			txt ~= txt ? "+ALT" : "ALT";
		if(mask & DWT.SHIFT)
			txt ~= txt ? "+SHIFT" : "SHIFT";
		
		if(code < 256) {
			if(txt)
				txt ~= "+";
			// convert to upper case
			txt ~= cast(char)code - ('a' - 'A');
		}else if(code >= (DWT.F1)){
			int num = code - DWT.F1 + 1;
			if(txt)
				txt ~= "+";
			txt ~= "F"~std.string.toString(num);
		}
		return txt;
	}
	
	public char[] getFuncKey() {
		if(code < 255 || code > DWT.F14 || code < DWT.F1)
			return null;
		return "F"~std.string.toString(code - DWT.F1 + 1);
	}
	
	void load(XMLnode node) {
		XMLattrib attrib;
		attrib = node.getAttribEx("name", "");
		name = attrib.GetValue();
		attrib = node.getAttribEx("mask", "0");
		mask = cast(uint)std.string.atoi(attrib.GetValue());
		attrib = node.getAttribEx("code", "0");
		code = cast(uint)std.string.atoi(attrib.GetValue());
		attrib = node.getAttribEx("mask_def", "0");
		mask_def = cast(uint)std.string.atoi(attrib.GetValue());
		attrib = node.getAttribEx("code_def", "0");
		code_def = cast(uint)std.string.atoi(attrib.GetValue());
		
		attrib = node.getAttribEx("comment", "");
		comment = attrib.GetValue();
					
		validCheck(name);
		dump();
	}
	
	// reset to default value
	void reset() {
		this.mask = mask_def;
		this.code = code_def;
	}
	
	void save(XMLnode node) {
		node.addAttrib("name", name);
		node.addAttrib("mask", std.string.toString(mask));
		node.addAttrib("code", std.string.toString(code));
		node.addAttrib("mask_def", std.string.toString(mask_def));
		node.addAttrib("code_def", std.string.toString(code_def));
		node.addAttrib("comment", comment);
	}
	public _ShortCut clone() {
		_ShortCut result = new _ShortCut();
		result.name = name;
		result.mask = mask;
		result.code = code;
		result.mask_def = mask_def;
		result.code_def = code_def;
		result.comment = comment;
		return result;		
	} 
	
	/** 
	 * use name/keyname to sort
	 */
	int opCmp(Object obj){
		_ShortCut o = cast(_ShortCut)obj;
		int result = 0;
		if(sorttype == SORT_NAME) {
			result = std.string.cmp(this.name, o.name);
		}else{
			result = std.string.cmp(this.keyname, o.keyname);
		}
		if(sortdirection == DWT.UP)
			return result;
		return (0 - result);
	}
	
	private void validCheck(inout char[] string) {
		if(string is null) string = "";
	}
}

/**
 * customized tools enties
 */
class ToolEntry // 外部工具
{
	char[] name = "";
	char[] cmd = "";
	char[] dir = "";
	char[] args = "";
	
	static ToolEntry	lastTool;
	
	// Before Excute the customized command, save files
	boolean savefirst = true;
	boolean hideWnd = false;
	
	// capture the output 
	boolean capture = true;	
	
	private void validCheck(inout char[] string) {
		if(string is null) string = "";
	}
	
	void load(XMLnode node) {
		XMLattrib attrib;
		attrib = node.getAttribEx("name", "");
		name = attrib.GetValue();
		attrib = node.getAttribEx("savefirst", "1");
		savefirst = std.string.atoi(attrib.GetValue())>0;
		attrib = node.getAttribEx("hideWnd", "1");
		hideWnd = std.string.atoi(attrib.GetValue())>0;
		attrib = node.getAttribEx("capture", "1");
		capture = std.string.atoi(attrib.GetValue())>0;
		attrib = node.getAttribEx("dir", "");
		dir = attrib.GetValue();		
		attrib = node.getAttribEx("cmd", "");
		cmd = attrib.GetValue();
		attrib = node.getAttribEx("args", "");
		args = attrib.GetValue();
		
		validCheck(dir);
		validCheck(cmd);
		validCheck(name);
		validCheck(args);
		
		dump();
	}
	
	void save(XMLnode node) {
		node.addAttrib("name", name);
		node.addAttrib("savefirst", std.string.toString(savefirst));
		node.addAttrib("hideWnd", std.string.toString(hideWnd));
		node.addAttrib("capture", std.string.toString(capture));
		node.addAttrib("dir", dir);
		node.addAttrib("cmd", cmd);
		node.addAttrib("args", args);
	}
	
	public ToolEntry clone() {
		ToolEntry result = new ToolEntry();
		result.name = name;
		result.cmd = cmd;
		result.dir = dir;
		result.args = args;
		result.savefirst = savefirst;
		result.hideWnd = hideWnd;
		result.capture = capture;
		return result;		
	} 
	public void dump() {
		debug{
			Util.trace("name : " ~ name);
			Util.trace("dir : " ~ dir);
			Util.trace("args : " ~ args);
			Util.trace("cmd : " ~ cmd); 
		}
	}
}


class FindOption {
	boolean	bRegexp;
	boolean	bCase = true;
	boolean	bWord = true;
	boolean	bWrap = true;
	boolean	bForward = true;
	char[] strFind = "";
	char[] strReplace = "";
	int _scope = 0;
	
	public FindOption clone(){
		FindOption fop = new FindOption();
		fop.bRegexp = bRegexp;
		fop.bCase = bCase;
		fop.bWord = bWord;
		fop.bWrap = bWrap;
		fop.bForward = bForward;
		fop.strFind = strFind;
		fop.strReplace = strReplace;
		fop._scope = _scope;
		
		return fop;
	} 
}

class ThreadEx : Thread
{
	int delegate(Object) _dg;
	Object args;
	this(Object args, int delegate(Object) dg)
	{
		this.args = args;
		this._dg = dg;
	}
	
	// override the base class method
	int run()
    {
    	if(_dg)
	    	return _dg(args);
	    return -1;
    }
}
