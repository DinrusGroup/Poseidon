module CodeAnalyzer.syntax.initializers;
import CodeAnalyzer.syntax.core;


class Initializer : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Initializer:
            AssignExpression
            ArrayInitializer
            StructInitializer
     */
    public void parse()
    {
		if( ts.next( TOK.Openparen, TOK.Openbracket ) )
		{
			parseTerminal( TOK.Openparen );
			parseR!(ArrayInitializer);
			parseTerminal( TOK.Closeparen );
			
			if( ts.next( TOK.Tdot ) ) parseR!( IdentifierSequence );
			return;
		}
		
        if( ts.next( TOK.Openbracket ) )
        {
            parseR!(ArrayInitializer);
        }
        else if( ts.next( TOK.Opencurly ) )
        {
            parseR!(StructInitializer);
        }
        else
        {
            parseR!(AssignExpression);
        }
    }
}

class ArrayInitializer : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        ArrayInitializer:
            [ ArrayMemberInitializations ]
            [ ]
     */
    public void parse()
    {
        parseTerminal( TOK.Openbracket );
        if( !ts.next( TOK.Closebracket ) )
        {
            parseR!(ArrayMemberInitializations);
        }
        parseTerminal( TOK.Closebracket );
    }
}

class ArrayMemberInitializations : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        ArrayMemberInitializations:
            ArrayMemberInitialization
            ArrayMemberInitialization ,
            ArrayMemberInitialization , ArrayMemberInitializations
     */
    public void parse()
    {
        while( true )
        {
            parseR!(ArrayMemberInitialization);
            if( ts.next( TOK.Comma ) )
            {
                parseTerminal();
            }
            if( ts.next( TOK.Closebracket ) )
            {
                break;
            }
        }
    }
}

class ArrayMemberInitialization : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        ArrayMemberInitialization:
            Initializer
            AssignExpression
            AssignExpression : Initializer
     */
    public void parse()
    {
        if( ts.next( TOK.Opencurly ) || ts.next( TOK.Openbracket ) )
        {
            parseR!(Initializer);
            return;
        }
        else
        {
            parseR!(AssignExpression);
            if( ts.next( TOK.Colon ) )
            {
                parseTerminal();
                parseR!(Initializer);
            }
        }
    }
}

class StructInitializer : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        StructInitializer:
            {  }
            { StructMemberInitializers }
     */
    public void parse()
    {
        parseTerminal( TOK.Opencurly );
        if( !ts.next( TOK.Closecurly ) )
        {
            parseR!(StructMemberInitializers);
        }
        parseTerminal( TOK.Closecurly );
    }
}

class StructMemberInitializers : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        StructMemberInitializers:
            StructMemberInitializer
            StructMemberInitializer ,
            StructMemberInitializer , StructMemberInitializers
     */
    public void parse()
    {
        while( true )
        {
            parseR!(StructMemberInitializer);
            if( ts.next( TOK.Comma ) )
            {
                parseTerminal();
            }
            if( ts.next( TOK.Closecurly ) )
            {
                break;
            }
        }
    }
}

class StructMemberInitializer : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        StructMemberInitializer:
            Initializer
            Identifier : Initializer
     */
    public void parse()
    {
        if( ts.next( TOK.Identifier ) )
        {
            if( ts.peektype(2) == TOK.Colon )
            {
                parseR!(Identifier);
                parseTerminal();
            }
        }
        parseR!(Initializer);
    }
}
