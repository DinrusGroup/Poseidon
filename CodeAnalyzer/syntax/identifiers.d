module CodeAnalyzer.syntax.identifiers;
import CodeAnalyzer.syntax.core;

class IdentifierSequence : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        IdentifierSequence:
            IdentifierList
            IdentifierSequence ! TemplateArguments
            IdentifierSequence ! TemplateArguments . IdentifierSequence
     */
    public void parse()
    {
        parseR!(IdentifierList);

        if( ts.next( TOK.Tnot, TOK.Openparen ) || ( ( compilerVersion > 1 ) && ts.next( TOK.Tnot ) && !ts.next( TOK.Tnot, TOK.Tis ) ) )
        {
            parseTerminal();
            parseR!(TemplateArguments);

            if( ts.next( TOK.Tdot ) )
            {
                parseTerminal();
                parse(); //recursivly parse
            }
        }
    }
}

class IdentifierList : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        IdentifierList:
            Identifier . IdentifierList
            Identifier
            . Identifier
            . Identifier . IdentifierList
     */
    public void parse()
    {
        if( ts.next( TOK.Tdot ) )
        {
            parseTerminal();
        }
        parseR!(Identifier);
        
        while( ts.next( TOK.Tdot ) )
        {
            parseTerminal();
            parseR!(Identifier);
        }
    }
}

class TemplateArguments : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        TemplateArguments:
            ( TemplateArgumentList )
            ( )
     */
    public void parse()
    {
        if( ts.next( TOK.Openparen ) )
			parseTerminal( TOK.Openparen );
		else
		{	// D 2.0
			parseR!(TemplateArgumentList);
			return;
		}

        if( !ts.next( TOK.Closeparen ) )
        {
            parseR!(TemplateArgumentList);
        }

		parseTerminal( TOK.Closeparen );
    }
}

class TemplateArgumentList : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        TemplateArgumentList:
            TemplateArgument
            TemplateArgument, TemplateArgumentList
     */
    public void parse()
    {
        parseR!(TemplateArgument);
        if( ts.next( TOK.Comma ) )
        {
            parseTerminal();
            parse();
        }
    }
}

class TemplateArgument : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
		TemplateArgument:
			Type
			AssignExpression
			Symbol
     */
    public void parse()
    {
        parseR!(ExprType);
    }
}

class Number : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**

     */
    public void parse()
    {
        parseTerminal( TOK.Tnumber );
    }
}

class Character : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**

     */
    public void parse()
    {
        parseTerminal( TOK.Tcharconstant );
    }
}

class StringList : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        StringList:
            String
            String StringList
     */
    public void parse()
    {
        parseR!(String);
        if( ts.next( TOK.Tstring ) )
        {
            parse();
        }
    }
}

class String : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**

     */
    public void parse()
    {
        parseTerminal( TOK.Tstring );
    }
}




