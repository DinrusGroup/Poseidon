module CodeAnalyzer.syntax.conditionalCompilation;
import CodeAnalyzer.syntax.core;


class ConditionalCompilation : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ConditionalCompilation:
            Condition :
            Condition DeclDefBlock    
            Condition DeclDefBlock else DeclDefBlock
     */
    public void parse()
    {
		// Kuan Hsu
		bool bStaicif = true;
        if( ts.next( TOK.Tversion ) )
			bStaicif = false;
        else if( ts.next( TOK.Tdebug ) )
			bStaicif = false;
		// End of Kuan Hsu
		
        parseR!(Condition);

		int DType = activeNode.DType;

        if( ts.next( TOK.Colon ) )
        {
            parseTerminal();
            return;
        }
        parseR!(DeclDefBlock);

		if( !bStaicif ) activeNode = activeNode.getRoot(); // Kuan Hsu

		if( ts.next( TOK.Telse, TOK.Tversion ) || ts.next( TOK.Telse, TOK.Tdebug ) )
		{
			parseTerminal();
            parseR!(ConditionalCompilation); 
		}
        else if( ts.next( TOK.Telse ) )
        {
			if( !bStaicif ) activeNode = activeNode.addLeaf( 0, DType, "-else-", null, ts.peek().lineNumber ); // Kuan Hsu

			parseTerminal();
            parseR!(DeclDefBlock);

			if( !bStaicif ) activeNode = activeNode.getRoot(); // Kuan Hsu
        }
    }
}

class Condition : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Condition:
            VersionCondition
            DebugCondition
            StaticIfCondition
     */
    public void parse()
    {
		int lineNum = ts.peek().lineNumber;
		
        if( ts.next( TOK.Tversion ) )
        {
            parseR!(VersionCondition);
			activeNode = activeNode.addLeaf( 0, D_VERSION, globalIdentifier, null, lineNum ); // Kuan Hsu
        }
        else if( ts.next( TOK.Tdebug ) )
        {
            parseR!(DebugCondition);
			activeNode = activeNode.addLeaf( 0, D_DEBUG, ( globalIdentifier.length ? globalIdentifier : "-anonymous-" ), null, lineNum ); // Kuan Hsu
        }
        else
        {
            parseR!(StaticIfCondition);
        }
    }
}

class VersionCondition : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        VersionCondition:
            version ( Identifier )
            version ( Number )
     */
    public void parse()
    {
        parseTerminal( TOK.Tversion );
        parseTerminal( TOK.Openparen );

		tokenText = null; // Kuan Hsu
        if( ts.next( TOK.Identifier ) )
        {
            parseR!(Identifier);
        }
        else
        {
			if( compilerVersion > 1 ) // D 2.0
			{
				if( ts.next( TOK.Tunittest ) )
				{
					parseTerminal( TOK.Tunittest );
					globalIdentifier = "unittest";
					parseTerminal( TOK.Closeparen );
					return;
				}
			}

            parseR!(Number);
        }

		globalIdentifier = tokenText; // Kuan Hsu
		
        parseTerminal( TOK.Closeparen );
    }
}

class DebugCondition : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        DebugCondition:
            debug
            debug ( Identifier )
            debug ( Number )
     */
    public void parse()
    {
        parseTerminal( TOK.Tdebug );
        if( !ts.next( TOK.Openparen ) )
        {
			globalIdentifier = null; // Kuan Hsu
            return;
        }
        parseTerminal();

		tokenText = null; // Kuan Hsu
        if( ts.next( TOK.Identifier ) )
        {
            parseR!(Identifier);
        }
        else
        {
            parseR!(Number);
        }

		globalIdentifier = tokenText; // Kuan Hsu
		
        parseTerminal( TOK.Closeparen );
    }
}

class StaticIfCondition : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        StaticIfCondition:
            static if ( AssignExpression )
     */
    public void parse()
    {
        parseTerminal( TOK.Tstatic );
        parseTerminal( TOK.Tif );
        parseTerminal( TOK.Openparen );
        parseR!(AssignExpression);
        parseTerminal( TOK.Closeparen );
    }
}

class ConditionalSpecification : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ConditionalSpecification:
            debug = Number ;
            debug = Identifier ;
            version = Number ;
            version = Identifier ;
     */
    public void parse()
    {
		int lineNum = ts.peek().lineNumber;
		bool bIsDebug;

        if( ts.next( TOK.Tdebug ) )
        {
			bIsDebug = true;
            parseTerminal();
        }
        else
        {
            parseTerminal( TOK.Tversion );
        }
        parseTerminal( TOK.Tassign );

		tokenText = "";
		
        if( ts.next( TOK.Identifier ) )
        {
            parseR!(Identifier);
        }
        else
        {
            parseR!(Number);
        }

		if( bIsDebug )
			activeNode.addLeaf( 0, D_CONDITIONSPEC, tokenText, "debug", lineNum ); // Kuan Hsu
		else
			activeNode.addLeaf( 0, D_CONDITIONSPEC, tokenText, "version", lineNum ); // Kuan Hsu
		
        parseTerminal( TOK.Semicolon );
    }
}

class StaticAssert : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        StaticAssert:
            static assert ( Expression ) ;
     */
    public void parse()
    {
        parseTerminal( TOK.Tstatic );
        parseTerminal( TOK.Tassert );
        parseTerminal( TOK.Openparen );
        parseR!(Expression);
        parseTerminal( TOK.Closeparen );
        parseTerminal( TOK.Semicolon );
    }
}

class ConditionalCompilationStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ConditionalCompilationStatement:
            Condition :
            Condition Statement    
            Condition Statement else Statement
     */
    public void parse()
    {
		// Kuan Hsu
		bool bStaicif = true;
        if( ts.next( TOK.Tversion ) )
			bStaicif = false;
        else if( ts.next( TOK.Tdebug ) )
			bStaicif = false;
		// End of Kuan Hsu
		
        parseR!(Condition);

		int DType = activeNode.DType;

        if( ts.next( TOK.Colon ) )
        {
            parseTerminal();
            return;
        }
        parseR!(Statement);
		if( !bStaicif ) activeNode = activeNode.getRoot(); // Kuan Hsu

		if( ts.next( TOK.Telse, TOK.Tversion ) || ts.next( TOK.Telse, TOK.Tdebug ) )
		{
			parseTerminal();
            parseR!(ConditionalCompilationStatement); 
		}		
        if( ts.next( TOK.Telse ) )
        {
			if( !bStaicif ) activeNode = activeNode.addLeaf( 0, DType, "-else-", null, ts.peek().lineNumber ); // Kuan Hsu
			
            parseTerminal();
            parseR!(Statement);
			
			if( !bStaicif ) activeNode = activeNode.getRoot(); // Kuan Hsu
        }
    }
}