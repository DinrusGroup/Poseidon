module CodeAnalyzer.syntax.expressions;
import CodeAnalyzer.syntax.core;

class Expression : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Expression:
            AssignExpression
            AssignExpression, Expression
     */
    public void parse()
    {
        parseR!(AssignExpression);
        if( ts.next( TOK.Comma ) )
        {
            parseTerminal();
            parse();
        }
    }
}
class AssignExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        AssignExpression:
            ConditionalExpression
            ConditionalExpression = AssignExpression
            ConditionalExpression += AssignExpression
            ConditionalExpression -= AssignExpression
            ConditionalExpression *= AssignExpression
            ConditionalExpression /= AssignExpression
            ConditionalExpression %= AssignExpression
            ConditionalExpression &= AssignExpression
            ConditionalExpression |= AssignExpression
            ConditionalExpression ^= AssignExpression
            ConditionalExpression ~= AssignExpression
            ConditionalExpression <<= AssignExpression
            ConditionalExpression >>= AssignExpression
            ConditionalExpression >>>= AssignExpression    
     */
    public void parse()
    {
        parseR!(ConditionalExpression);
        if( nextop( ts ) )
        {
            parseTerminal();
            parse();
        }
    }

    bool nextop( TokenScanner ts )
    {
        switch( ts.peek().type )
        {
            case TOK.Tassign: // =
            case TOK.Taddass: // +=
            case TOK.Tminass: // -=
            case TOK.Tmulass: // *=
            case TOK.Tdivass: // /=
            case TOK.Tmodass: // %=
            case TOK.Tandass: // &=
            case TOK.Torass:  // |=
            case TOK.Txorass: // ^=
            case TOK.Tcatass: // ~=
            case TOK.Tshlass: // <<=
            case TOK.Tshrass: // >>=
            case TOK.Tushrass: // >>>=
                return true;
            default:
                return false;
        }
    }
}

class ConditionalExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        ConditionalExpression:
            OrOrExpression
            OrOrExpression ? Expression : ConditionalExpression        
     */
    public void parse()
    {
        parseR!(OrOrExpression);
        if( ts.next(  TOK.Tquestion ) )
        {
            parseTerminal();
            parseR!(Expression);
            parseTerminal( TOK.Colon );
            parseR!(ConditionalExpression);
        }
    }
}

class OrOrExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        OrOrExpression:
            AndAndExpression
            AndAndExpression || OrOrExpression
     */
    public void parse()
    {
        parseR!(AndAndExpression);
        if( ts.next( TOK.Toror ) )
        {
            parseTerminal();
            parseR!(OrOrExpression);
        }
    }
}

class AndAndExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        AndAndExpression:
            OrExpression
            OrExpression && AndAndExpression    
     */
    public void parse()
    {
        parseR!(OrExpression);
        if( ts.next(  TOK.Tandand ) )
        {
            parseTerminal();
            parseR!(AndAndExpression);
        }
    }
}

class OrExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        OrExpression:
            XorExpression
            XorExpression | OrExpression
    */
    public void parse()
    {
        parseR!(XorExpression);
        if( ts.next( TOK.Tor ) )
        {
            parseTerminal();
            parseR!(OrExpression);
        }
    }
}

class XorExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }
    
    /**
        XorExpression:
            AndExpression
            AndExpression ^ XorExpression
    */
    public void parse()
    {
        parseR!(AndExpression);
        if( ts.next( TOK.Txor ) )
        {
            parseTerminal();
            parseR!(XorExpression);
        }
    }
}

class AndExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        AndExpression:
            EqualExpression
            EqualExpression & AndExpression
     */
    public void parse()
    {
        parseR!(EqualExpression);
        if( ts.next( TOK.Tand ) )
        {
            parseTerminal();
            parseR!(AndExpression);
        }
    }
}

class EqualExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        EqualExpression:
            RelExpression
            RelExpression == EqualExpression
            RelExpression != EqualExpression
            RelExpression is EqualExpression
            RelExpression !is EqualExpression
     */
    public void parse()
    {
        parseR!(RelExpression);
        if( nextop( ts ) )
        {
            if( ts.next( TOK.Tnot ) )
            {
                parseTerminal();
				parseTerminal( TOK.Tis );
            }
            else
            {
                parseTerminal();
            }
            parse();
        }
    }
/+
    public void parse()
    {
        parseR!(RelExpression);
        if( nextop( ts ) )
        {
            if( ts.next( TOK.Tnot ) )
            {
                parseTerminal();

				if( compilerVersion > 1 )
				{
					if( ts.next( TOK.Tis ) ) parseTerminal( TOK.Tis );
				}
				else
					parseTerminal( TOK.Tis );
            }
            else
            {
                parseTerminal();
            }
            parse();
        }
    }
+/
    bool nextop( TokenScanner ts )
    {
        switch( ts.peek().type )
        {
            case TOK.Teqeq:  // ==
            case TOK.Tnoteq: // !=
            case TOK.Tis:     // is
            case TOK.Tnot:   // !
                return true;
            default:
                return false;
        }
    }
}

class RelExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        RelExpression:
            ShiftExpression
            ShiftExpression < RelExpression
            ShiftExpression <= RelExpression
            ShiftExpression > RelExpression
            ShiftExpression >= RelExpression
            ShiftExpression !<>= RelExpression
            ShiftExpression !<> RelExpression
            ShiftExpression <> RelExpression
            ShiftExpression <>= RelExpression
            ShiftExpression !> RelExpression
            ShiftExpression !>= RelExpression
            ShiftExpression !< RelExpression
            ShiftExpression !<= RelExpression
            ShiftExpression in RelExpression
     */
    public void parse()
    {
        parseR!(ShiftExpression);
        if( nextop( ts ) )
        {
            parseTerminal();
            parseR!(RelExpression);
        }
    }

    bool nextop( TokenScanner ts )
    {
        switch( ts.peek().type )
        {
            case TOK.Tlt:      // <
            case TOK.Tle:      // <=
            case TOK.Tgt:      // >
            case TOK.Tge:      // >=
            case TOK.Tunord: // !<>=
            case TOK.Tue:     // !<>
            case TOK.Tlg:      // <>
            case TOK.Tleg:     // <>=
            case TOK.Tug:    // !>
            case TOK.Tuge:   // !>=
            case TOK.Tul:    // !<
            case TOK.Tule:   // !<=
            case TOK.Tin:     // in
                return true;
            default:
                return false;
        }
    }
}

class ShiftExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        ShiftExpression:
            AddExpression
            AddExpression << ShiftExpression
            AddExpression >> ShiftExpression
            AddExpression >>> ShiftExpression
     */
    public void parse()
    {
        parseR!(AddExpression);
        if( nextop( ts ) )
        {
            parseTerminal();
            parse();
        }
    }

    bool nextop( TokenScanner ts )
    {
        switch( ts.peek().type )
        {
            case TOK.Tshl:  // <<
            case TOK.Tshr:  // >>
            case TOK.Tushr:    // >>>
                return true;
            default:
                return false;
        }
    }
}

class AddExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        AddExpression:
            MulExpression
            MulExpression + AddExpression
            MulExpression - AddExpression
            MulExpression ~ AddExpression
     */
    public void parse()
    {
        parseR!(MulExpression);
        if( nextop( ts ) )
        {
            parseTerminal();
            parse();
        }
    }

    bool nextop( TokenScanner ts )
    {
        switch( ts.peek().type )
        {
            case TOK.Tadd:   // +
            case TOK.Tmin:   // -
            case TOK.Ttilde: // ~     //a.k.a TOKcat
                return true;
            default:
                return false;
        }
    }
}

class MulExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        MulExpression:
            UnaryExpression
            UnaryExpression * MulExpression
            UnaryExpression / MulExpression
            UnaryExpression % MulExpression
     */
    public void parse()
    {
        parseR!(UnaryExpression);
        if( nextop( ts ) )
        {
            //HACK: I'm not sure how reliable this check is ..
            //when seeing a mul, make sure there's no ) or ] or [ after it, it would be a type suffix
            switch( ts.peektype(2) )
            {
                case TOK.Closeparen, TOK.Openbracket, TOK.Closebracket, TOK.Comma:
                    return;
                default:
                    break;
            }
            parseTerminal();
            parse();
        }
    }

    bool nextop( TokenScanner ts )
    {
        switch( ts.peek().type )
        {
            case TOK.Tmul:  // *
            case TOK.Tdiv:  // /
            case TOK.Tmod:  // %
                return true;
            default:
                return false;
        }
    }
}

class MixinExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }
	/**
		MixinExpression:
			mixin ( AssignExpression )
	*/

    public void parse()
    {
        parseTerminal( TOK.Openparen );
        parseR!(AssignExpression);
        parseTerminal( TOK.Closeparen );
    }	
}

class ImportExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }
	/**
		ImportExpression:
			import ( AssignExpression )
	*/

    public void parse()
    {
        parseTerminal( TOK.Openparen );
        parseR!(AssignExpression);
        parseTerminal( TOK.Closeparen );
    }	
}

class TypeSpecialization : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        TypeSpecialization:
            Type
            typedef
            struct
            union
            class
            interface
            enum
            function
            delegate
			super		// Kuan Hsu
			return		// Kuan Hsu

			D 2.0
			const
			invariant  
			immutable
     */
    public void parse()
    {
        switch( ts.peek().type )
        {
            case TOK.Ttypedef, TOK.Tstruct, TOK.Tunion,
            TOK.Tclass, TOK.Tinterface, TOK.Tenum,
            TOK.Tfunction, TOK.Tdelegate,
			TOK.Tsuper, TOK.Treturn:	// Kuan Hsu
                parseTerminal();
                break;

			case TOK.Tconst, TOK.Tinvariant, TOK.Timmutable:
				if( compilerVersion > 1 ) // D 2.0
				{
					if( ts.peektype( 2 ) == TOK.Closeparen ) // enum hasRawAliasing = !is(U == invariant);
					{
						parseTerminal();
						break;
					}
					tokenText = ""; // Kuan Hsu
					parseR!(Type);
				}
				break;
			
            default:
				tokenText = ""; // Kuan Hsu
                parseR!(Type);
                break;
        }
    }
}


class IsExpression : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        IsExpression:
            is ( Type )
            is ( Type : TypeSpecialization )
            is ( Type == TypeSpecialization )
            is ( Type Identifier )
            is ( Type Identifier : TypeSpecialization )
            is ( Type Identifier == TypeSpecialization )

			D 2.0
			is ( Type Identifier : TypeSpecialization , TemplateParameterList )
			is ( Type Identifier == TypeSpecialization , TemplateParameterList )
			
     */
    public void parse()
    {
        parseTerminal( TOK.Tis );
        parseTerminal( TOK.Openparen );

		tokenText = ""; // Kuan Hsu
        parseR!(Type);
        if( ts.next( TOK.Identifier ) )
        {
            parseR!(Identifier);
        }
        
        if( ts.next( TOK.Colon ) || ts.next( TOK.Teqeq ) )
        {
            parseTerminal();
            parseR!(TypeSpecialization);

			if( compilerVersion > 1 )
			{
				if( ts.next( TOK.Comma ) )
				{
					parseTerminal( TOK.Comma );
					parseR!(TemplateParameterList);
				}
			}
        }
        
        parseTerminal( TOK.Closeparen );
    }
}

