module CodeAnalyzer.utilCA.nodeUtil;

/*
This util is for codecompletion live, it will be a hard work, I will do it as I can!!
*/

private import CodeAnalyzer.syntax.nodeHsu;

// For line-change, update codeanalyzer node line-number
public void fixLineNumber( CAnalyzerTreeNode root, int target, int add )
{
	if( root is null || add == 0 ) return;
	
	foreach( CAnalyzerTreeNode t; root.getAllLeaf() )
	{
		if( !( t.DType & D_MAINROOT ) )
		{
			if( t.lineNumber > target ) t.lineNumber += add;
			if( t.getLeafCount > 0 ) fixLineNumber( t, target, add );
		}
	}
}