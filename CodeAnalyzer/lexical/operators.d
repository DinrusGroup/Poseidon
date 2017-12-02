module CodeAnalyzer.lexical.operators;

import CodeAnalyzer.lexical.token_tables;
import CodeAnalyzer.utilCA.textScanner; 
import CodeAnalyzer.lexical.token_enum;
import std.stdio;

public TOK scanOperator( TextScanner sc )
{
    for( int i = 4; i >= 1; i-- )
    {
        dchar[] op = sc.peek(i);
        if( isKnownSymbol(op) )
        {
            sc.read(i);
            return getTokenOfSymbol( op );
        }
    }
    
    writefln( "faild to detect symbol/operator at\n" ~ sc.peek(4) );
    assert( false );
}

public bool isOperator(dchar c)
{
    switch (c)
    {
        case '+':
        case '-':
        case '*':
        case '/':
        case '=':
        case '|':
        case '&':
        case '!':
        case '<':
        case '>':
        case '[':
        case ']':
        case ':':
        case '$':
        case '^':
        case '%':
        case '?':
        case '~':
        case '{':
        case '}':
        case '(':
        case ')':
        case ',':
        case ';':
        case '.':
            return true;
        default:
            return false;
    }
}