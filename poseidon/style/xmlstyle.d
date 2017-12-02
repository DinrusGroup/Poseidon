module poseidon.style.xmlstyle;

public
{
	import poseidon.style.stylekeeper;
	import dwt.extra.scintilla;
}


class XMLStyle : AbstractStyleKeeper
{
	const char[] LEXER_NAME = "SCLEX_XML";
	char[] getLexerName() { return LEXER_NAME;}
	int getLexerID() { return Scintilla.SCLEX_XML; }

	void applySettings(ScintillaEx sc) 
	{		
		super.applySettings(sc);

		// do extra xml settings here
	}

	void resetKeyWords()
	{
	}

	void resetStyles()
	{
	}
}