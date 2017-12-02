module CodeAnalyzer.lexical.whitespace;

import CodeAnalyzer.utilCA.textScanner;
import CodeAnalyzer.lexical.token_enum;
import CodeAnalyzer.lexical.coreLex;

public bool isCommentStart( dchar[] cc )
{
    switch( cc )
    {
        case "//":
        case "/*":
        case "/+":
            return true;
        default:
            return false;
    }
}

public bool isWhiteSpace( dchar c )
{
    switch( c )
    {
        case ' ':
        case '\t':
        case '\n':
        case '\r':
        case '\f':
            return true;
        default:
            return false;
    }
}

TOK scanNewLine( TextScanner sc )
{
    if( sc.peek() == '\n' )
    {
        sc.read();
    }
    else
    {
        assert( sc.peek() == '\r' );
        sc.read();
        if( sc.peek() == '\n' ) // treat \r\n as one new line token
        {
            sc.read();
        }
    }
    return TOK.Newline;
}

TOK scanSpaces( TextScanner sc )
{
    while( isSpace( sc.peek() ) )
    {
        sc.read();
    }
    return TOK.Whitespace;
}

bool isSpace( char c )
{
    switch( c )
    {
        case ' ':
        case '\t':
        case '\f':
            return true;
        default:
            return false;
    }
}


TOK scanSpecialTokenSequence( TextScanner sc )
{
    sc.readToLineEnd();
    return TOK.SpecialTokenSequence;
}

TOK scanLineComment( TextScanner sc )
{
    sc.readToLineEnd();
    return TOK.LineComment;
}

TOK scanBlockComment( TextScanner sc )
{
    assert( sc.peek(2) == "/*" );
    sc.read(2); //read the "/*"
    sc.readUntil("*/", "terminate block comment"); 
    sc.read(2); //read the "*/"
    
    return TOK.BlockComment;
}

TOK scanNestingComment( TextScanner sc )
{
    assert( sc.peek(2) == "/+" );
    sc.read(2);
    
    while( sc.peek(2) != "+/" )
    {
        if( sc.peek(2) == "/+" )
        {
            scanNestingComment( sc );
        }
        else if( sc.reachedEnd() )
        {
            throw new LexerException("found EOF before closing nesting comment", sc);
        }
        else
        {
            sc.read();
        }
    }
    
    assert( sc.peek(2) == "+/" );
    sc.read(2);

    return TOK.NestingComment;
}

TOK scanLineDocComment( TextScanner sc )
{
    scanLineComment( sc );
    return TOK.LineDocComment;
}

TOK scanBlockDocComment( TextScanner sc )
{
    scanBlockComment( sc );
    return TOK.BlockDocComment;
}

TOK scanNestingDocComment( TextScanner sc )
{
    scanNestingComment( sc );
    return TOK.NestingDocComment;
}

