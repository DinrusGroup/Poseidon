/**
    The Lexical Analyzer is a tool that reads source code and splits it
    into tokens; this prepares the source code for syntax.

    To use the lexer, instantiate one of the subclasses of DLexer, and 
    invoke its "lex" method against a Module object or a string representing
    the file name.
    //Internally, the file content will be transcoded to UTF32.
	Kuan Hsu modify: Internally, the file content will be transcoded to UTF8.
 */

module CodeAnalyzer.lexical.coreLex;

public
{
import CodeAnalyzer.lexical.token;
import CodeAnalyzer.lexical.module_file;
import CodeAnalyzer.utilCA.textScanner; 
}

import CodeAnalyzer.lexical.whitespace,
       CodeAnalyzer.lexical.numbers,
       CodeAnalyzer.lexical.identifiersLex,
       CodeAnalyzer.lexical.strings,
       CodeAnalyzer.lexical.operators;

import std.string,
       CodeAnalyzer.utilCA.string;

class DLexer
{
    public this(){}

    /**
        This function takes a string (d module code) and performs lexical analysiz on 
        it, parsing it into tokens, then returns an array of tokens, representing the 
        tokenized module content.
        
        The reason for this method being abstract is to give options, for example, do 
        we want to tokenize white space? comments? doc comments? maybe one is only 
        interested in actual code, and maybe one is only interested in doc comments!
    */
    public abstract TokenList lex( dchar[] text );    

	public TokenList lex( Module m ) 
	{
		return lex( m.getText() ); 
	}  
}

/**
    scans the next token in the text scanner and returns its type
*/
public TOK nextToken( TextScanner sc )
{
    dchar c = sc.peek();
    dchar[] cc = sc.peek(2);
    dchar[] ccc = sc.peek(3);
    
    /*
        scan comments and other non-code tokens
    */
    switch( ccc )
    {
        case "///" : return scanLineDocComment( sc );
        case "/**" : return scanBlockDocComment( sc );
        case "/++" : return scanNestingDocComment( sc );
        default: break;
        
    }
    switch( cc )
    {
        case "//" : return scanLineComment( sc );
        case "/*" : return scanBlockComment( sc );
        case "/+" : return scanNestingComment( sc );
        default: break;
    }
    switch( c )
    {
        case ' ', '\t', '\f': return scanSpaces( sc );
        case '\n', '\r': return scanNewLine( sc );
        case '#': return scanSpecialTokenSequence( sc );
        default: break;
    }
    
    /*
        scan string tokens
    */
    switch( cc )    //it's EXTREMELY important that this test comes before the test for identifiers
    {
		case `q"`: return scanDelimitedStrings( sc );
		case `q{`: return scanTokenString( sc );
        case `r"`: return scanWysiwygString( sc );
        case `x"`: return scanHexString( sc );
        default: break;
    }
    switch( c )
    {
        case '`': return scanAlternateWysiwygString( sc );
        case '"': return scanOldschoolString( sc );
        case '\'': return scanChar( sc );
        case '\\': return scanEscapeSequence( sc );
        default: break;
    }
    
    /*
        scan number tokens
    */
    if( isNumberStart( c ) || isDotFloatStart( cc ) )
    {
        return scanNumber( sc );
    }
    
    /*
        scan operators
    */
    if( isOperator( c ) )
    {
        return scanOperator( sc );
    }
    
    /*
        scan identifiers and keywords
    */
    if( isIdentifierStart( c ) )
    {
        return scanIdentifier( sc );
    }
    
    /*
        we cannot reach here!
    */
    throw new LexerException("Unknown Token @ location: " ~ std.string.toString(sc.cursor) ~ \n ~ sc.read(10).utf8() ~ \n, sc);
    
}


class DCodeOnlyLexer : DLexer
{
    /**
        See: super.lex( char[] text )
        
        This implementation omits whitespace, comments, doc comment,
        and the special token 
            #line integer ["filespec"]
     */
    public TokenList lex( dchar[] text )
    {
        TextScanner sc = new TextScanner( text );
        TokenList tokens = null;
        
        while( !sc.reachedEnd() )
        {
            /*
                skip comments, whitespace, and the special token sequence #line
            */
            if( isCommentStart( sc.peek(2) ) || isWhiteSpace( sc.peek() ) || sc.peek() == '#' )
            {
                nextToken( sc ); //scan but skip it
                continue;
            }
            
            /*
                scan the next token and add it to our token list
            */
            int start = sc.cursor;
            TOK t = nextToken( sc );
            int end = sc.cursor;
            assert( end > start );
            dchar[] txt = sc.slice(start, end);
            tokens ~= new Token( start, end, txt, sc.getLineNumber(), t );
        }
        
        return tokens;
    }
}

class DFullLexer : DLexer
{
    /**
        See: super.lex( char[] text )
        
        This implementation grabs everything    
     */
    public TokenList lex( dchar[] text )
    {
        TextScanner sc = new TextScanner( text );
        TokenList tokens = null;
        
        while( !sc.reachedEnd() )
        {
            /*
                scan the next token and add it to our token list
            */
            int start = sc.cursor;
            TOK t = nextToken( sc );
            int end = sc.cursor;
            assert( end > start );
            dchar[] txt = sc.slice(start, end);
            tokens ~= new Token( start, end, txt,sc.getLineNumber(), t );
        }
        
        return tokens;
    }
}

class LexerException : Exception
{
	TextScanner sc; 
	public this( char[] msg, TextScanner s ) 
	{
		sc = s;
        super(msg);
    }
}

private const DLexer mcodeLexer;
private const DLexer mfullLexer;

static this()
{
    mcodeLexer = new DCodeOnlyLexer();
    mfullLexer = new DFullLexer();
}

/**
    Gives a prepared instance of a lexer that converts source code
    into a list of tokens, while ignoring whitespace and comments
 */
public DLexer codeLexer()
{
    return mcodeLexer;
}

/**
    Gives a prepared instance of a lexer that converts source code into 
    a list of tokens while preserving everything of the source, so that
    the original source code can be reconstructed from the token list.
 */
public DLexer fullLexer()
{
    return mfullLexer;
}