module CodeAnalyzer.lexical.token;
public import CodeAnalyzer.lexical.token_enum;

import std.stdio,
       std.utf;

alias Token[] TokenList;

class Token
{
public:
    TOK type;
	int start;
	int end;
	dchar[] text;
	int lineNumber;     
		int length;

public:
    this( int start, int end, dchar[] text, int lineNumber, TOK type )
    {
        this.start = start; 
		this.end = end; 
		this.type = type;                
		this.length = end - start; 
		this.text = text; 
		this.lineNumber = lineNumber; 

		assert( length == text.length ); 
    }
    
    dchar[] typeName()
    {
		return toUTF32(CodeAnalyzer.lexical.token_enum.toString( type ));//return CodeAnalyzer.lexical.token_enum.toString( type ); // Kuan Hsu
    }
}

///for debugging purposes .. 
void printTokenList(TokenList tokens)
{
    foreach( Token t; tokens )
    {
        writefln("%s", t.text);
    }
}

///for debugging purposes .. 
void printTokensWithLineNumbers(TokenList tokens)
{
    foreach( Token t; tokens )
    {
        writefln("Line %d:    Token: %s", t.lineNumber, t.text);
    }
}

///for debugging purposes .. 
dchar[] getRawText( TokenList tokens )
{
    int start = tokens[0].start;
	int end = tokens[$-1].end;
    int len = end-start;
    dchar * s = &(tokens[0].text[0]);
    dchar[] text = s[0..len];
    return text;
}
