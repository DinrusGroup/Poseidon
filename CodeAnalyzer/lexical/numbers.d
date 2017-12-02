module CodeAnalyzer.lexical.numbers;

import CodeAnalyzer.utilCA.textScanner;
import CodeAnalyzer.lexical.token_enum;

public TOK scanNumber( TextScanner sc )
{
    while( true )
    {
        sc.read();
        if( !isNumberPart( sc.peek() ) )
        {
            break;
        }
        if( sc.peek(2) == ".." )
        {
            break;
        }
    }
    
    return TOK.Tnumber;
}

bool isNumberStart( dchar c )
{
    return isDigit( c );
}

bool isDotFloatStart( dchar[] cc )
{
    return cc[0] == '.' && isDigit( cc[1] );
}
    
bool isNumberPart( dchar c )
{
    return isDigit(c) || isLetter(c) || c == '.' || c == '_';
}

bool isInRange( dchar c, dchar a, dchar b )
{
    return (c >= a && c <= b);
}

bool isDigit( dchar c )
{
    return isInRange(c, '0','9');
}

bool isLetter( dchar c )
{
    return isInRange(c, 'a','z') || isInRange(c, 'A','Z');
}

