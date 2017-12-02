/**
    see syntax.tree
 */
module CodeAnalyzer.syntax.terminal;

import CodeAnalyzer.syntax.node;
import CodeAnalyzer.syntax.core;
import CodeAnalyzer.lexical.token;
import std.utf;

import CodeAnalyzer.utilCA.string;

class Terminal : ParseNode
{
    private
    {
        Token token;
    }
    
    public
    {
        this()
        {
            super();
        }
        
        this( Token token )
        {
            this.token = token;
			tokenText ~= std.utf.toUTF8(token.text);
        }
        
        public Token getToken()
        {
            return token;
        }

        char[] getName()
        {
            //return token.text;
            return "Token";
        }

        NodeItem[] getItems()
        {
            return NodeItem.createNodeItems
            (
                "Type", token.typeName().utf8(),
                "Text", token.text.utf8()
            );
        }
    }
}

