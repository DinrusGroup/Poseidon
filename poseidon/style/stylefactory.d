module poseidon.style.stylefactory;

public
{
	import poseidon.style.stylekeeper;
	import poseidon.style.dstyle;
	import poseidon.style.xmlstyle;
	import dwt.extra.scintilla;
	import poseidon.controller.scintillaex;
	import poseidon.globals;
}

// all in lower case
static char[][]	FILE_EXTS = [
	"d|di","c|cpp|h|cxx|hpp|java|js|rc", "xml", "py", "html|htm", 
	"vb", "rb", "asp", "php",
	
];

static int[]	LEXER_ID = [

        DStyle.SCLEX_D, Scintilla.SCLEX_CPP, Scintilla.SCLEX_XML, Scintilla.SCLEX_PYTHON, Scintilla.SCLEX_HTML, 
	Scintilla.SCLEX_VB, Scintilla.SCLEX_RUBY, Scintilla.SCLEX_ASP, Scintilla.SCLEX_PHP,
];

static char[][] LEXER_NAME = [
	"SCLEX_D", "SCLEX_CPP", "SCLEX_XML", "SCLEX_PYTHON", "SCLEX_HTML", 
	"SCLEX_VB", "SCLEX_RUBY", "SCLEX_ASP", "SCLEX_PHP",
];

class StyleFactory
{
	private static IStyleKeeper[] _styleKeepers;

	public static IStyleKeeper[] styleKeepers() { return _styleKeepers; }

	public static IStyleKeeper getStyleKeeper(int lexer)
	{
		if(lexer == -1 )
			return null;

		// check whether the StyleKeeper has been loaded already
		foreach(IStyleKeeper keeper; _styleKeepers) {
			if(lexer == keeper.getLexerID())
				return keeper;
		}

		// try to load the StyleKeeper from disk
		
		// find the LEXER_NAME
		int index;
		for(index = 0;index<LEXER_ID.length; ++index) {
			if(LEXER_ID[index] == lexer)
				break;
		}

		assert(index < LEXER_NAME.length);
		
		if(index >= LEXER_NAME.length)		
			return null;
			
		IStyleKeeper keeper = createKeeper(LEXER_NAME[index]);
		if(keeper)
			_styleKeepers ~= keeper;
		return keeper;
	}
	
	private static IStyleKeeper createKeeper(char[] lexerName)
	{
		AbstractStyleKeeper keeper;
		
		if(lexerName == DStyle.LEXER_NAME){
			keeper = new DStyle();
		}else if(lexerName == XMLStyle.LEXER_NAME){
			keeper = new XMLStyle();
		}else
			return null;
		
		char[] filename = std.path.join(Globals.lexerDir, lexerName ~ ".xml");
		XML xml = new XML();
		if(xml.Open(filename) < 0 ){
			delete xml;
			return keeper; // failed
		}
			
		XMLnode root = xml.m_root.getChildEx("config", null);
		XMLnode node = root.getChild("lexer");
		if(node){
			keeper.loadKeyWords(node);
			keeper.loadStyles(node);
		}
		
		delete xml; // auto close
		
		return keeper;
	}

	public static int findLexerFromExt(char[] fileExt)
	{
		int index = -1;
		bool found = false;
		char[] ext = std.string.tolower(fileExt);
		
		for(int i=0; i<FILE_EXTS.length && !found;++i){
			char[][] arExt = std.string.split(FILE_EXTS[i], "|");
			foreach(char[] temp; arExt){
				if(ext == temp){
					index = i;
					found = true;
					break;
				}
			}
		}
		
		if(index >= 0 )
			return LEXER_ID[index];
		return -1;
	}

	public static int saveStyleKeeper(IStyleKeeper keeper)
	{
		assert(keeper);
	
		
		char[] filename = std.path.join(Globals.lexerDir, keeper.getLexerName() ~ ".xml");
		if(std.file.exists(filename))
			std.file.remove(filename);
			
		XML xml = new XML();
		{
			xml.m_attributes ~= new XMLattrib("version", "1.0");
			xml.m_attributes ~= new XMLattrib("encoding", "UTF-8");
		}
		
		XMLnode root = xml.m_root.addNode("config", null);

		keeper.save(root);

		xml.Save(filename);
		
		delete xml; // auto close
		
		return 0;
	}

}