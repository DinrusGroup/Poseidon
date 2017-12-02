/**
    see syntax.tree
 */
module CodeAnalyzer.syntax.rule;

import CodeAnalyzer.syntax.node;
import CodeAnalyzer.syntax.terminal;
import CodeAnalyzer.syntax.core;
import CodeAnalyzer.syntax.tokenScanner;
import CodeAnalyzer.lexical.token;

/++
	//TODO: polish this doc ..
	
	ParseRule class .. to understand this class, you must first understand
	the parsing process we're following here.
	
    Parsing is constructing a parse tree from a token list based on a pre-defined
	grammar. The grammar is defined by a series of rules. <br>
	The parser operates on a token scanner. It works by requesting various objects of
	subclasses of ParseRule to parse the tokenlist. This request is a bit abstracted if
	you try to just look at the code, but what's happening under the hood is that 
	an object of a ParseRule subclass is created and it's given the token scanner as
	a part of itself, then the parse() method is invoked.
    
    There are three typical tasks involved in the "parse" methods of each
    ParseRule:
        -Look ahead to determine which rule(s) must be applied.
        -Request another rule to parse from the current position. (sort of recursive)		
        -Request to parse a terminal rule, i.e. leaf node, i.e. single token. (recursion end)

	The parse rules also keep a node reference within themselves, and the result of parsing
	is put into that node. This node will be then a part of the parse tree.

	The starting rule is the DModule rule. All the terminal rules are just tokens, there's
	no class for terminal rules; there's a terminal node class, which is constructed when
	parsing a terminal.

	Why go thru all this trouble? To make the code more readable.
	Doesn't this piece of code look very self explanatory?
	------------
		/**
			ArrayIndex:
				[ ]
				[ Expression ]
				[ Expression .. Expression ]
		 */
		public void parse()
		{
			parseTerminal( TOK.Openbracket );
			if( !ts.next( TOK.Closebracket ) )
			{
				parseR!(Expression);
				if( ts.next( TOK.Tslice ) )
				{
					parseTerminal();
					parseR!(Expression);
				}
			}
			parseTerminal( TOK.Closebracket );
		}
	------------
	

	(( I hope that makes at least some sense .. ))
		
 +/
class ParseRule
{
    protected
    {
        TokenScanner ts;
        ParseNode node;
    }
 
	///enable stack based allocation .. 
	new(size_t sz, void *p) 
	{ 
		return p; 
	} 
	
    public
    {
        this(TokenScanner ts)
        {
            this.ts = ts;
            node = new ParseNode(getRuleName());
        }

        char[] getRuleName()
        {
            return this.classinfo.name;
        }

        ParseNode getNode()
        {
            return node;
        }
        
        template parseR(Rule : ParseRule) 
        {
            void parseR() 
			{                 
				this.node.addChild( parseRuleT!(Rule).using(ts) );
			}
        }

        void parseWith( ParseDelegate parse )
        {
            node.addChild( parse(ts) );
        }

        void parseTerminal()
        {
            node.addChild( new Terminal( ts.read() ) );
        }

        void parseTerminal( TOK t )
        {
            expect( t );
            parseTerminal();
        }

        void expect( TOK[] toks ... )
        {
            CodeAnalyzer.syntax.core.expect( ts, toks );
        }

		bool next( TOK[] toks ... )
		{
			return ts.next(toks);
		}		
    }
}