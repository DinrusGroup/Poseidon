/**
	The core of the syntax analyzer, a.k.a parser.
	
    To parse a .d file, the following general steps need to be taken: <br>
	1. read the content of the file (i.e. the text) <br>
	2. perform lexical analysis (see lexical.core) <br>
	3. pass the result of the lexer to one of the overloaded parse(..) 
	methods in this module <br>

	Reading a file can be done by calling util.file.readFile on a file name, or 
	constructing a lexical.module_file.Module object, (which does the same thing).

	For lexical analysis, you must pass the text read from the file (or just pass the 
	module object) to one of the lexers in lexical.core module. Right now there are 
	two lexers: <br>
	code lexer: ignores comments and whitespace, i.e. doesn't include them in the returned 
	token list. <br>
	full lexer: puts all tokens, including comments and whitespace, in the resulting token 
	list. <br>
	Note: at the time of writing this, the parser can only deal with a list that doesn't
	include comments and white space.

	The simplest thing to do is just read the text of the file, pass to a lexer and get 
	the token list, then pass the token list to parse(Token[])
		
    Example:
    ---------------------------
    import lexical.core;
    import syntax.core;

    char[] filename = r"path\input.d"

	//decode the file to UTF-32
    auto text = util.file.readFile(filename); 
	//lexical analysis, returns a token list
    auto tokList = lexical.core.codeLexer.lex(text); 
	//syntax analysis, return the root node of the parse tree
    auto root = syntax.core.parse(tokList); 
    ---------------------------

    For convenience, a method 
        ParseNode parseFile( char[] fileName )
    has been provided, which only needs the file name as input.
    
 */
module CodeAnalyzer.syntax.core;

public
{
import CodeAnalyzer.syntax.node; 
import CodeAnalyzer.syntax.terminal; 
import CodeAnalyzer.syntax.rule; 
import CodeAnalyzer.syntax.tokenScanner; 
import CodeAnalyzer.syntax.decldefs; 
import CodeAnalyzer.syntax.headers; 
import CodeAnalyzer.syntax.identifiers; 
import CodeAnalyzer.syntax.declarations; 
import CodeAnalyzer.syntax.expressions; 
import CodeAnalyzer.syntax.baseExpressions; 
import CodeAnalyzer.syntax.statements; 
import CodeAnalyzer.syntax.aggregates; 
import CodeAnalyzer.syntax.attributes; 
import CodeAnalyzer.syntax.conditionalCompilation; 
import CodeAnalyzer.syntax.initializers; 
import CodeAnalyzer.syntax.templates; 
import CodeAnalyzer.syntax.nodeHsu;
}

import std.stdio,
       std.utf,
	   CodeAnalyzer.utilCA.string,
	   CodeAnalyzer.lexical.coreLex;


/** 
	low level parser interface: 
	takes a token scanner as input. 
	return the root node of the resulting parse tree. 
*/ 
public ParseNode parse( TokenScanner ts ) 
{ 
	return parseRuleT!(DModule).using(ts); 
} 
 
/** 
	somewhat low level parser interface: 
	takes a token list as input. 
	return the root node of the resulting parse tree. 
*/ 
public ParseNode parse( Token[] tokList ) 
{ 
	scope tokScanner = new TokenScanner(tokList); 
	return parse( tokScanner ); 
}

// /**
    // This function parses a tokenized D Module file. That is, a D module
    // that has been lexed and has a representation in a tokenized form. This 
    // can be achieved by passing a Module object to the lexical.core.lex function

    // Returns: a parsed module, which contains the original module and the 
    // syntax parse tree that was generated.
 // */
// public ParsedModule parse( TokenizedModule tm )
// {
	// auto root = parse(new TokenScanner(tm.getTokenList())); 
	// auto tree = new ParseTree( root ); 
    // return new ParsedModule( tm, tree );
// }

/**
    Shortcut for getting a parse tree out of a file, there 
    are no guarantees on what options are used when lexing
    and parsing the file.
 */
public ParseNode parseFile( char[] fileName )
{
    return parse( codeLexer().lex( new Module( fileName ) ) );
}


// Kuan Hsu
public CAnalyzerTreeNode parseFileHSU( char[] fileName )
{
	parseFile( fileName );
	CAnalyzerTreeNode root = DMainSymbolNode.dup();
	delete DMainSymbolNode;
	CodeAnalyzer.syntax.nodeHsu.clean();

	bool bFoundModule;
	foreach( CAnalyzerTreeNode t; root.getAllLeaf() )
	{
		if( t.DType & D_MODULE ) 
		{
			t.typeIdentifier = fileName;
			bFoundModule = true;
			break;
		}
	}

	if( !bFoundModule )
	{
		CAnalyzerTreeNode t	= new CAnalyzerTreeNode( 0, D_MODULE, std.path.getName( std.path.getBaseName( fileName ) ),
							fileName  );
		root.insertLeaf( t, 0 );
	}
	
	return root;
}


public CAnalyzerTreeNode parseTextHSU( char[] _text, char[] fileName, bool bAddDModule = true )
{
	scope m = new Module;
	m.setText( std.utf.toUTF32( _text ) );
	
	parse( codeLexer().lex( m ) );
	
	CAnalyzerTreeNode root = DMainSymbolNode.dup();
	delete DMainSymbolNode;
	CodeAnalyzer.syntax.nodeHsu.clean();

	
	bool bFoundModule;
	if( bAddDModule )
	{
		foreach( CAnalyzerTreeNode t; root.getAllLeaf() )
		{
			if( t.DType & D_MODULE ) 
			{
				t.typeIdentifier = fileName;
				bFoundModule = true;
				break;
			}
		}
	}
	else
		bFoundModule = true;

	if( !bFoundModule )
	{
		CAnalyzerTreeNode t	= new CAnalyzerTreeNode( 0, D_MODULE, std.path.getName( std.path.getBaseName( fileName ) ),
							fileName  );
		root.insertLeaf( t, 0 );
	}
	
	return root;
}
// End of Kuan Hsu

abstract class AbstractParseHandler
{
    protected ParseDelegate[TOK] handle;

    public ParseDelegate opIndex( TOK t )
    {
        return handle[t];
    }

    public bool handles( TOK t )
    {
        return (t in handle) !is null;
    }

    template assign(T:ParseRule)
    {
        void toParse(TOK type)
        {
            handle[type] = delegate ParseNode(TokenScanner ts)
            {
                return parseRuleT!( T ).using( ts );
            };
        }
    }

    this()
    {
        initializeHandler();
    }

    protected abstract void initializeHandler();
}

void expect( TokenScanner ts, TOK[] toks ... )
{
    Token[] tokens = ts.peek( toks.length );
    foreach( int i, Token token; tokens )
    {
        if( token.type != toks[i] )
        {
            failedexpectation( ts, toks );
        }
    }
}


void failedexpectation( TokenScanner ts, TOK[] toks )
{
    char[] msg = getRawText( ts.peek(toks.length) ).utf8();

    char[] type = toString( ts.peek().type );
    char[] expectedType = toString( toks[0] );
    
    throw new ParserException( ts, "expected " ~ expectedType ~ " but got " ~ type ~ ".");
}

class ParserException : Error
{
    TokenScanner ts;
    public this( TokenScanner ts, char[] msg )
    {
        char[] lineNum = std.string.toString( ts.peek().lineNumber );
        this.ts = ts;
        msg ~= \n
        "Parser Error!! @line " ~ lineNum ~ \n ~
        getRawText( ts.peek(10) ).utf8();
        super( msg );
    }
}

alias ParseNode delegate( TokenScanner ts ) ParseDelegate;

char[] except(T:ParseRule)()
{
	throw new Exception( "Got Error!!" );  // Kuan Hsu
    //return T.classinfo.name ~ " threw an exception";
}

import std.c.stdlib;
template parseRuleT(Rule:ParseRule)
{
    ParseNode using( TokenScanner ts )
    {
        scope(failure)
        {
            writefln( except!(Rule) );
        }
        Rule rule = new(alloca(Rule.classinfo.init.length)) Rule(ts);
        rule.parse();
        return rule.getNode();
    }
}
