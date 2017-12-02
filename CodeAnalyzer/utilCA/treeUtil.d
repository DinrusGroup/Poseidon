module CodeAnalyzer.utilCA.treeUtil;
alias char[] string;

//This is a pointless wrapper .. no?
// interface ITree
// {
    // INode getRoot();
// }

interface INode
{
    void addChild( INode );
    char[] getName();
    INode[] getChildren();
    NodeItem[] getItems();
}

struct NodeItem
{
    char[] key;
    char[] value;

static:
    NodeItem opCall( char[] k, char[] v )
    {
        NodeItem x;
        x.key = k;
        x.value = v;
        return x;
    }

    //for convenience
    NodeItem[] createNodeItems( char[][] strings ... )
    {
        if( strings.length % 2 != 0 )
        {
            throw new Exception("incorrect call to util.tree.createNodeItems, the array should be of even length (divisible by two");
        }
        NodeItem[] array = null;
        for( int i = 0; i < strings.length; i+=2 )
        {
            array ~= NodeItem( strings[i], strings[i+1] );
        }
        return array;
    }
}

char[] getValue( INode node, char[] key )
{
    auto items = node.getItems();
    foreach( item; items )
    {
        if( item.key == key )
        {
            return item.value;
        }
    }
    return null;
}

bool isLeaf( INode n )
{
    return n.getChildren == null;
}

INode getFirstChild( INode n )
{
    return n.getChildren[0];
}

// what a pointless wrapper .. 
// class Tree : ITree 
// {
    // private
    // {
        // INode root;
    // }
    
    // public
    // {
        // this( Node node )
        // {
            // root = node;
        // }
        
        // INode getRoot()
        // {
            // return root;
        // }
    // }
// }


abstract class Node : INode
{
    private
    {
        INode[] children = null;
    }

    public
    {
        this()
        {
            children = null;
        }
        
        void addChild( INode node )
        {
            children ~= node ;
        }
        
        INode[] getChildren()
        {
            return children;
        }

        NodeItem[] getItems()
        {
            return null;
        }
    }
}
