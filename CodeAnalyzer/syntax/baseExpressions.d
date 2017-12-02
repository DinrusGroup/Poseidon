module CodeAnalyzer.syntax.baseExpressions;
import CodeAnalyzer.syntax.core;
import std.stdio;
class UnaryExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        UnaryExpression:
            PostfixExpression
            & UnaryExpression
            ++ UnaryExpression
            -- UnaryExpression
            * UnaryExpression
            - UnaryExpression
            + UnaryExpression
            ! UnaryExpression
            ~ UnaryExpression
            cast ( Type ) UnaryExpression
            NewExpression
            DeleteExpression
     */
    public void parse()
    {
        if( nextopUnary( ts ) )
        {
            parseTerminal();
            parseR!(UnaryExpression);
        }
        else if( ts.next( TOK.Tcast ) )
        {
            parseTerminal();
            parseTerminal( TOK.Openparen );
            parseR!(Type);
            parseTerminal( TOK.Closeparen );
            parseR!(UnaryExpression);
        }
        else if( ts.next( TOK.Tnew ) )
        {
            parseR!(NewExpression);
        }
        else if( ts.next( TOK.Tdelete ) )
        {
            parseR!(DeleteExpression);
        }
        else
        {
            parseR!(PostfixExpression);
        }
    }

    bool nextopUnary( TokenScanner ts )
    {
        switch( ts.peek().type )
        {
            case TOK.Tand:             // &
            case TOK.Tplusplus:     // ++
            case TOK.Tminusminus:    // --
            case TOK.Tmul:             // *
            case TOK.Tadd:             // +
            case TOK.Tmin:             // -
            case TOK.Tnot:             // !
            case TOK.Ttilde:         // ~
                return true;
            default:
                return false;
        }
    }
}

class NewExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        Newexpression:
            NewArguments Type [ AssignExpression ]
            NewArguments Type ( Expression )
            NewArguments Type ( )
            NewArguments Type
            NewArguments AnonymousClass 
     */
    public void parse()
    {
        parseR!(NewArguments);
        if( ts.next( TOK.Tclass ) )
        {
            parseR!(AnonymousClass);
        }
        else
        {
			// Kuan Hsu
			if( activeNode.DType & D_BLOCK )
			{
				if( activeNode.baseClass == "with" )
					tokenText = tokenText ~ " ";
				else
					tokenText = "";
			}
			else
				tokenText = ""; // Kuan Hsu

            parseR!(Type);
            if( ts.next( TOK.Openbracket ) )
            {
                parseTerminal();
                parseR!(AssignExpression);
                parseTerminal( TOK.Closebracket );
            }
            else if( ts.next( TOK.Openparen ) )
            {
                parseTerminal();
                if( !ts.next( TOK.Closeparen ) )
                {
                    parseR!(Expression);
                }
                parseTerminal( TOK.Closeparen );
            }
        }
    }
}

class DeleteExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        DeleteExpression:
            delete UnaryExpression
     */
    public void parse()
    {
        parseTerminal( TOK.Tdelete );
        parseR!(UnaryExpression);
    }
}

class NewArguments : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        NewArguments:
            new ( Expression )
            new ( )
            new    
     */
    public void parse()
    {
        parseTerminal( TOK.Tnew );
        if( ts.next( TOK.Openparen ) )
        {
            parseTerminal();
            if( !ts.next( TOK.Closeparen ) )
            {
                parseR!(Expression);
            }
            parseTerminal( TOK.Closeparen );
        }
    }
}

class AnonymousClass : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        AnonymousClass:
            AnonClassArguments ClassBody
            AnonClassArguments BaseClassList ClassBody    
     */
    public void parse()
    {
		int lineNum = ts.peek().lineNumber;
		
        parseR!(AnonClassArguments);
        if( !ts.next( TOK.Opencurly ) )
        {
            parseR!(BaseClassList);
        }

		activeNode = activeNode.addLeaf( D_Private, D_CLASS, "-anonymous-", null, lineNum, null, globalBaseClass );
		
        parseR!(ClassBody);

		activeNode = activeNode.getRoot;
    }
}

class AnonClassArguments : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        AnonClassArguments:
            class ( Expression )
            class ( )
            class
     */
    public void parse()
    {
        parseTerminal( TOK.Tclass );
        if( ts.next( TOK.Openparen ) )
        {
			parseTerminal( TOK.Openparen ); // Kuan Hsu -- Bug Fix
            if( !ts.next( TOK.Closeparen ) )
            {
                parseR!(Expression);
            }
            parseTerminal( TOK.Closeparen );
        }
    }
}

class PostfixExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        PostfixExpression:
            PrimaryExpression    
            PostfixExpression ++
            PostfixExpression --
            PostfixExpression . IdentifierSequence
            PostfixExpression ArrayIndex
            PostfixExpression CallParameters    
     */
    public void parse()
    {
        parseR!(PrimaryExpression);
        while( true )
        {
            if( ts.next( TOK.Tplusplus ) || ts.next( TOK.Tminusminus ) )
            {
                parseTerminal();
            }
            else if( ts.next( TOK.Tdot ) )
            {
                parseTerminal();
                parseR!(IdentifierSequence);
            }
            else if( ts.next( TOK.Openbracket ) )
            {
                parseR!(ArrayIndex);
            }
            else if( ts.next( TOK.Openparen ) )
            {
                parseR!(CallParameters);
            }
            else
            {
                break;
            }
        }
    }
}

class ArrayIndex : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ArrayIndex:
            [ ]
            [ Expression ]
            [ Expression .. Expression ]
     */
    public void parse()
    {
        parseTerminal( TOK.Openbracket );
        if( !ts.next( TOK.Closebracket ) )
        {
            parseR!(Expression);
            if( ts.next( TOK.Tslice ) )
            {
                parseTerminal();
                parseR!(Expression);
            }
        }
        parseTerminal( TOK.Closebracket );
    }
}

class CallParameters : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        CallParameters:
            ( )
            ( Expression )
     */
    public void parse()
    {
        parseTerminal( TOK.Openparen );
        if( !ts.next( TOK.Closeparen ) )
        {
            parseR!(Expression);
        }
        parseTerminal( TOK.Closeparen );
    }
}

class AssertExpression : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        AssertExpression
            assert ( Expression )
     */
    public void parse()
    {
        parseTerminal( TOK.Tassert );
        parseTerminal( TOK.Openparen );
        parseR!(Expression);
        parseTerminal( TOK.Closeparen );
    }
}

class PrimaryExpression : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        PrimaryExpression:
            IdentifierSequence
            Number
            Character
            $
            StringList
            ( Expression )                  //| need (k) look-ahead to distinguish
            ( Expression TypeSuffixes )     //| from anonymous delegate
            Typeof
            AssertExpression;
			MixinExpression					// Kuan Hsu
            typeid ( Type )
            FunctionLiteral
            ArrayLiteral
			IsExpression					// Kuan Hsu
    */
    public void parse()
    {
        switch( ts.peek().type )
        {
            case TOK.Identifier:
                parseR!(IdentifierSequence);
				if( ts.next( TOK.Tassign, TOK.Openbracket ) )
				{
					parseTerminal( TOK.Tassign );
					parseR!(ArrayInitializer);
				}
				return;
			
            case TOK.Tdot:
            //case TOK.Identifier:
            case TOK.Tthis: //TEMP
                parseR!(IdentifierSequence);
                return;
            case TOK.Tnumber:
                parseR!(Number);
                return;
            case TOK.Tcharconstant:
                parseR!(Character);
                return;
            case TOK.Tdollar:
                parseTerminal();
                return;
            case TOK.Tstring:
                parseR!(StringList);
                return;
            case TOK.Openparen:
                if( !isAnonDelegate(ts) ) //( expression ....
                {
                    parseTerminal();
                    parseR!(Expression);
                    if( !ts.next( TOK.Closeparen ) )
                    {
                        parseR!(TypeSuffixes);
                    }
                    parseTerminal( TOK.Closeparen );
                    return;
                }
                else
                    goto anondeleg; //Note: goto
            case TOK.Ttypeof:
                parseR!(Typeof);
                return;
            case TOK.Tassert:
                parseR!(AssertExpression);
                return;
			case TOK.Tmixin:
				parseTerminal();
				if( ts.next( TOK.Openparen ) ) parseR!(MixinExpression);
				return;
            case TOK.Ttypeid:
                parseTerminal();
                parseTerminal( TOK.Openparen );
				tokenText = ""; // Kuan Hsu
                parseR!(Type);
                parseTerminal( TOK.Closeparen );
                return;
            case TOK.Tfunction:
            case TOK.Tdelegate:
            case TOK.Opencurly:
            anondeleg:
                parseR!(FunctionLiteral);
                return;
            case TOK.Tis:
                parseR!(IsExpression);
                return;
            case TOK.Openbracket:
                parseR!(ArrayLiteral);
                return;
			case TOK.Timport: // ImportExpression:
				parseTerminal();
				if( ts.next( TOK.Openparen ) ) parseR!(ImportExpression); 
				return;
			
            default:
                throw new ParserException( ts, "Cannot parse Expression!!! (hint, check the switch that controls me)" );
        }
    }
}

class FunctionLiteral : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        FunctionLiteral:
            function FunctionBody
            function FunctionParameters FunctionBody
            function Type FunctionParameters FunctionBody
            delegate FunctionBody
            delegate FunctionParameters FunctionBody
            delegate Type FunctionParameters FunctionBody
            FunctionParameters FunctionBody
            FunctionBody
     */
    public void parse()
    {
		char[] 	ident; // Kuan Hsu
		int		prevProt = globalProt, prevGlobalDType = globalDType;
		
        if( ts.next( TOK.Tfunction ) || ts.next( TOK.Tdelegate ) )
        {
			tokenText = null; // Kuan Hsu
            parseTerminal();
			// Kuan Hsu
			ident = tokenText;
			globalDType = D_FUNLITERALS;
			globalProt = D_Private;
			// End of Kuan Hsu
			
			/*
			Think below:
			char[] r = sub("hello", "ll", delegate char[] (Regex r) { return "ss"; });
			*/
        }
        
        if( ts.next( TOK.Tdot ) || ts.next( TOK.Identifier ) )
        {
			tokenText = ""; // Kuan Hsu
            parseR!(Type);
			globalTypeIdentifier = tokenText; 	// Kuan Hsu
			globalDType = prevGlobalDType;		// Kuan Hsu
			
			activeNode = activeNode.addLeaf( globalProt, D_FUNCTION, ident.length > 0 ? ident : "-anonymous-", globalTypeIdentifier, ts.peek().lineNumber, globalParams ); // Kuan Hsu
            parseR!(FunctionParameters);
			activeNode.parameterString = globalParams; // Kuan Hsu
			
        }
        else if( ts.next( TOK.Openparen ) )
        {
			activeNode = activeNode.addLeaf( globalProt, D_FUNCTION, ident.length > 0 ? ident : "-anonymous-", null, ts.peek().lineNumber, globalParams ); // Kuan Hsu
			globalDType = prevGlobalDType;		// Kuan Hsu
            parseR!(FunctionParameters);
			activeNode.parameterString = globalParams; // Kuan Hsu
        }
		else if( ts.next( TOK.Opencurly ) ) // Kuan Hsu
		{
			activeNode = activeNode.addLeaf( globalProt, D_FUNCTION, ident.length > 0 ? ident : "-anonymous-", null, ts.peek().lineNumber, globalParams ); // Kuan Hsu
			globalDType = prevGlobalDType;		// Kuan Hsu
		}
        
        parseR!(FunctionBody);
		// Kuan Hsu
		activeNode.DType = D_FUNLITERALS;
		activeNode = activeNode.getRoot();
		globalProt = prevProt;
		// End of Kuan Hsu
    }
}

class ArrayLiteral : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ArrayLiteral:
            [ Expression ]
     */
    public void parse()
    {
        parseTerminal( TOK.Openbracket );
		if( compilerVersion > 1 ) // D 2.0
		{
			if( !ts.next( TOK.Closebracket ) ) parseR!(Expression);
		}
		else
			parseR!(Expression);
			
        parseTerminal( TOK.Closebracket );
    }
}
/+
class AssocArrayLiteral : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
	AssocArrayLiteral:
		[ KeyValuePairs ]
     */
    public void parse()
    {
        parseTerminal( TOK.Openbracket );
        parseR!( KeyValuePairs );
        parseTerminal( TOK.Closebracket );
    }
}

class KeyValuePairs : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**	
	KeyValuePairs:
		KeyValuePair
		KeyValuePair , KeyValuePairs
	*/
    public void parse()
    {
		if( ts.next( TOK.Comma ) )
		{
			parseTerminal( TOK.Comma );
			parseR!( KeyValuePairs );
		}
		else
		{
			parseR!( KeyValuePair );
		}
    }
}

class KeyValuePair : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
	/**	
	KeyValuePair:
		KeyExpression : ValueExpression

	KeyExpression:
		ConditionalExpression

	ValueExpression:
		ConditionalExpression		
	*/
    public void parse()
    {
		parseR!( ConditionalExpression );
		parseTerminal( TOK.Colon );
		parseR!( ConditionalExpression );
    }
}
+/

/**
    This only works in a certain context .. 
    NOT made for public use
 */
private bool isAnonDelegate( TokenScanner ts )
{
    if( ts.next( TOK.Opencurly ) ) { return true; }
    if( ts.next( TOK.Openparen ) )
    {
        //we're gonna look ahead, so restore cursor when done!
        int c = ts.cursor;
        scope(exit) ts.cursor = c;
        
        ts.skipParens();
        if( ts.next( TOK.Opencurly ) )
            return true;
        else
            return false;
    }
}
