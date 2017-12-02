module CodeAnalyzer.lexical.strings;

import CodeAnalyzer.utilCA.textScanner;
import CodeAnalyzer.lexical.numbers;
import CodeAnalyzer.lexical.token_enum;
import CodeAnalyzer.lexical.coreLex;

public TOK scanWysiwygString( TextScanner sc )
{
    assert( sc.peek(2) == `r"` );
    sc.read(2); //consume r"
    sc.readUntil('"', `terminate r" wysiwyg string`);
    assert( sc.peek() == '"' );
    sc.read();
    scanStringPostfix( sc );
    return TOK.Tstring;
}

public TOK scanAlternateWysiwygString( TextScanner sc )
{
    assert( sc.peek() == '`' );
    sc.read(); //consume `
    sc.readUntil('`', "terminate wysiwyg string");
    assert( sc.peek() == '`' );
    sc.read(); //consume `
    scanStringPostfix( sc );
    return TOK.Tstring;
}

public TOK scanOldschoolString( TextScanner sc )
{
    scanOldSchool( '"', sc );
    scanStringPostfix( sc );
    return TOK.Tstring;
}

public TOK scanChar( TextScanner sc )
{
    scanOldSchool( '\'', sc );
    return TOK.Tcharconstant;
}

public TOK scanHexString( TextScanner sc )
{
    assert( sc.peek(2) == `x"` );
    sc.read(2); //consume x"
    sc.readUntil('"', "terminate hex string");
    assert( sc.peek() == '"' );
    sc.read();
    scanStringPostfix( sc );
    return TOK.Tstring;
}

public TOK scanEscapeSequence( TextScanner sc )
{
    assert( sc.peek() == '\\' );
    sc.read(); //consume \
    
    switch( sc.peek() )
    {
        case '\\':
        case '\'':
        case '?':
        case '"':
            sc.read();
            return TOK.Tescaped;
        case '&':
            sc.read();
            break;
        default:
            break;
    }
    
    bool isSequencePart( dchar c )
    {
        return isDigit(c) || isLetter(c);
    }

    while( isSequencePart( sc.peek() ) )
    {
        sc.read();
    }
    return TOK.Tstring;
}

void scanOldSchool( char bound, TextScanner sc )
{
    assert( sc.peek() == bound );
    sc.read();
    
    while( sc.peek() != bound )
    {
        dchar c = sc.read();
        if( c == '\\' ) //skip escape sequence, as it may containg a 'bound'
        {
            sc.read();
        }                
		if( sc.reachedEnd() ) 
		{
			throw new LexerException("Found EOF before terminating the string", sc); 
 		}
    }
    
    assert( sc.peek() == bound );
    sc.read();
}

void scanStringPostfix( TextScanner sc )
{
    switch( sc.peek() )
    {
        case 'c':
        case 'w':
        case 'd':
            sc.read();
            break;
        default:
            break;
    }
}

public TOK scanDelimitedStrings( TextScanner sc )
{
    assert( sc.peek(2) == `q"` );
    sc.read(2); //consume q"
	dchar beginSign = sc.read();
	dchar endSign;
	switch( beginSign )
	{
		case '{': endSign = '}'; break;
		case '[': endSign = ']'; break;
		case '<': endSign = '>'; break;
		case '(': endSign = ')'; break;
		default:
			if( ( beginSign >= 65 && beginSign <= 90 ) || ( beginSign >= 97 && beginSign <= 122 ) )
			{
				dchar[] beginChars;
				beginChars ~= beginSign;
				while( sc.peek() != '\n' )
				{
					beginChars ~= sc.read();
					if( sc.reachedEnd() ) throw new Exception( "Found EOF when looking for [scanDelimitedStrings]" );
				}
				
				beginChars = beginChars[0..length-1]; // skip "\"
				sc.read(); // skip "\n"

				sc.readUntil(beginChars, `terminate " Delimited Strings`);
				sc.read(beginChars.length);
				assert( sc.peek() == '"' );
				sc.read();
			}
			else
			{
				sc.readUntil(beginSign, `terminate " Delimited Strings`);
				assert( sc.peek() == beginSign );
				sc.read();
				assert( sc.peek() == '"' );
				sc.read();				
			}

			scanStringPostfix( sc );
			return TOK.Tstring;		
	}

	int countSign;
    while( sc.peek() != endSign || countSign != 0 )
    {
		dchar d = sc.read();
		if( d == beginSign )
			countSign ++;
		else if( d == endSign )
			countSign --;
		
		if( sc.reachedEnd() )
		{
			throw new Exception( "Found EOF when looking for [scanDelimitedStrings]" );
			//throw new LexerException("Found EOF when looking for [scanTokenString]");
		}
	}
	
	assert( sc.peek() == endSign );
	sc.read();
    assert( sc.peek() == '"' );
    sc.read();
    scanStringPostfix( sc );
    return TOK.Tstring;
}

public TOK scanTokenString( TextScanner sc )
{
    assert( sc.peek(2) == `q{` );
    sc.read(2); //consume q{

	int countOpencurly;
    while( sc.peek() != '}' || countOpencurly != 0 )
    {
		dchar d = sc.read();
		if( d == '{' )
			countOpencurly ++;
		else if( d == '}' )
			countOpencurly --;
		
		if( sc.reachedEnd() )
		{
			throw new Exception( "Found EOF when looking for [scanTokenString]" );
			//throw new LexerException("Found EOF when looking for [scanTokenString]");
		}
	}

    assert( sc.peek() == '}' );
    sc.read();
    scanStringPostfix( sc );
    return TOK.Tstring;
}

