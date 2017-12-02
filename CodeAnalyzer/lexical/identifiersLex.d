module CodeAnalyzer.lexical.identifiersLex;

import CodeAnalyzer.lexical.token_tables;
import CodeAnalyzer.utilCA.textScanner;
import CodeAnalyzer.lexical.token_enum;
import CodeAnalyzer.lexical.numbers;

import std.uni;

public TOK scanIdentifier( TextScanner sc )
{
    dchar[] ident = "";
    while( isIdentifierPart( sc.peek() ) )
    {
        ident ~= sc.read();
    }
    
    if( isKeyword( ident ) )
    {
        return getTokenOfKeyword( ident );
    }
    else
    {
		switch( ident )
		{
			case "__FILE__":
			case "__DATA__":
			case "__TIME__":
			case "__TIMESTAMP__":
			case "__VENDOR__":
				return TOK.Tstring;

			case "__LINE__":
			case "__VERSION__":
				return TOK.Tnumber;
			
			default: break;
		}		
        return TOK.Identifier;
    }
}

public bool isIdentifierStart( dchar c )
{
    return isUniAlpha(c) || c == '_';
}

public bool isIdentifierPart( dchar c )
{
    return isUniAlpha(c) || isDigit(c) || c == '_';
}