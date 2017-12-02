/**
    see syntax.tree
 */
module CodeAnalyzer.syntax.node;

import std.stdio;
import CodeAnalyzer.syntax.rule;

public
{
	import CodeAnalyzer.syntax.tokenScanner;
	import CodeAnalyzer.utilCA.treeUtil;
}


class ParseNode : Node
{
    private
    {
        char[] name;
    }

    protected
    {
        this()
        {
            super();
        }
        
        void setName( char[] name )
        {
            this.name = name;
        }

        char[] getName()
        {
            return name;
        }
    }
    
    public
    {
        this(char[] name)
        {
            setName(name);
        }
    }
}

