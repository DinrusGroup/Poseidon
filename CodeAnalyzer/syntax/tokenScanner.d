module CodeAnalyzer.syntax.tokenScanner;

public
{
import CodeAnalyzer.utilCA.scanner;
import CodeAnalyzer.lexical.token;
}

class TokenScanner : Scanner!(Token)
{
    private static Token badToken;
    public:
    this( TokenList list )
    {
        super( list );
        badToken = new Token(0,0,"",0,TOK.INVALID);
    }

    Token invalid()
    {
        return badToken;
    }

    /** skips nested parenthesis ... */
    void skipParens()
    {
        skipNestedSymbols( TOK.Openparen, TOK.Closeparen );
    }

    void skipBrackets()
    {
        skipNestedSymbols( TOK.Openbracket, TOK.Closebracket );
    }

    void skipNestedSymbols( TOK topen, TOK tclose)
    {
        assert( next( topen ) );
        while( !next( tclose ) )
        {
            read();
            if( next( topen ) )
            {
                skipNestedSymbols(topen, tclose); //recursion            
            }
        }
        read();
        return;
    }

    
/*
    bool next( TOK t )
    {
        return peek().type == t;
    }
    */

    //check that the next tokens are in the order given in expectedTokens
    bool next( TOK[] expectedTokens ... )
    {
        assert( expectedTokens.length != 0 );

		//if( reachedEnd() ) throw new Exception( "Out of Tokens!!" ); // Kuan Hsu

        Token[] ourTokens = peek(expectedTokens.length);
        
        //if lengthes are not equal, then there aren't enough
        //tokens ahead, hence the next tokens are not as expected!
        if( ourTokens.length != expectedTokens.length )
        {
            return false;
        }

        //compare tokens one by one
        for( int i = 0; i < expectedTokens.length; i++ )
        {
            if( ourTokens[i].type != expectedTokens[i] )
            {
                return false;
            }
        }
        return true;
    }

    //k look ahead
    TOK peektype(int k)
    {
        return get(cursor+k-1).type;
    }
}