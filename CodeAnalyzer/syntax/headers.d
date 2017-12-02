module CodeAnalyzer.syntax.headers;
import CodeAnalyzer.syntax.core;


class DModule : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Module:
            ModuleDeclaration DeclDefs
            DeclDefs
    */
    public void parse()
    {
		// Kuan Hsu
		DMainSymbolNode = new CAnalyzerTreeNode( 0, D_MAINROOT );
		activeNode = DMainSymbolNode;
		// End of Kuan Hsu
		
        if( ts.next( TOK.Tmodule ) )
        {
            parseR!(ModuleDeclaration);
        }
        
        parseR!(DeclDefs);
    }
}

class ModuleDeclaration : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ModuleDeclaration:
            module ModuleName ;
    */
    public void parse()
    {
		globalDType = D_MODULE; // Kuan Hsu
        parseTerminal( TOK.Tmodule );
		
		if( compilerVersion > 1 ) // d 2.0
		{
			if( ts.next( TOK.Openparen, TOK.Identifier, TOK.Closeparen ) )
			{
				parseTerminal(); parseTerminal(); parseTerminal();
				tokenText = null;
			}
		}
		
        parseR!(ModuleName);
        parseTerminal( TOK.Semicolon );
		globalDType = 0; // Kuan Hsu
    }
}


class ImportDeclaration : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ImportDeclaration:
            import ImportList ;
     */
    public void parse()
    {
        parseTerminal( TOK.Timport );

		//if( ts.next( TOK.Openparen ) )
		//	parseR!(ImportExpression);
		//else
			parseR!(ImportList);
			
        parseTerminal( TOK.Semicolon );
    }
}

class ImportList : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ImportList:
            ImportItem
            ImportItem, ImportList
     */
    public void parse()
    {
        parseR!(ImportItem);

        while( ts.next( TOK.Comma ) )
        {
            parseTerminal();
            parseR!(ImportItem);
        }
    }
}

class ImportItem : ParseRule
{
    public this(TokenScanner ts) { super(ts); }
    
    /**
        ImportItem:
            ModuleName
            Identifier = ModuleName
            ModuleName : ImportBindList 
			Identifier = ModuleName : ImportBindList 
     */
    public void parse()
    {
		globalParams = globalTypeIdentifier = ""; // Kuan Hsu
		
        if( ts.next( TOK.Identifier, TOK.Tassign ) )
        {
			tokenText = null; // Kuan Hsu
            parseR!(Identifier);
			globalTypeIdentifier = tokenText; // Kuan Hsu
            parseTerminal();
        }

		globalDType = D_IMPORT; // Kuan Hsu
        parseR!(ModuleName);
		globalDType = 0; // Kuan Hsu

        if( ts.next( TOK.Colon ) )
        {
            parseTerminal();

            parseR!(ImportBindList);
        }

		activeNode.addLeaf( globalProt, D_IMPORT, globalIdentifier, globalTypeIdentifier, ts.peek().lineNumber, globalParams ); // Kuan Hsu
		globalTypeIdentifier = globalParams = "";
    }
}

class ImportBindList : ParseRule
{
    public  this(TokenScanner ts) { super(ts); }

    /**
        ImportBindList:
            ImportBindItem, ImportBindList 
     */
    public void parse()
    {
        parseR!(ImportBindItem);

        while( ts.next( TOK.Comma ) )
        {
			parseTerminal();
			globalParams ~= ","; // Kuan Hsu
            parseR!(ImportBindItem);
        }
    }
}

class ImportBindItem : ParseRule
{
    public this(TokenScanner ts) { super(ts); }

    /**
        ImportBindItem:
            Identifier
            Identifier = Identifier
     */
    public void parse()
    {
		tokenText = null; // Kuan Hsu
        parseR!(Identifier);
		globalParams ~= tokenText; // Kuan Hsu
		
        if( ts.next( TOK.Tassign ) )
        {
            parseTerminal();
			globalParams ~= "="; // Kuan Hsu
			tokenText = null; // Kuan Hsu
            parseR!(Identifier);
			globalParams ~= tokenText; // Kuan Hsu
        }
    }
}


class ModuleName : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        ModuleName:
            Identifier
            Identifier . ModuleName
     */
    public void parse()
    {
		tokenText = null; // Kuan Hsu
		
        parseR!(Identifier);
        while( ts.next( TOK.Tdot ) )
        {
            parseTerminal();
            parseR!(Identifier);
        }

		globalIdentifier = tokenText; // Kuan Hsu

		// Kuan Hsu
		if( globalDType == D_MODULE )
			activeNode.addLeaf( 0, D_MODULE, globalIdentifier, null, ts.peek().lineNumber );
		// Kuan Hsu
	}
}

class Identifier : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        Identifier:
            identifier (duh!)
            this
     */
    public void parse()
    {
        if( ts.next( TOK.Identifier ) )
            parseTerminal();
        else
            parseTerminal( TOK.Tthis );
    }
}
