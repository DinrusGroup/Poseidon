module poseidon.controller.ddoc.ddocparser;

class CDDocParser
{
private:
	import std.string;
	import dwt.extra.scintilla;
	import poseidon.controller.scintillaex;
	import poseidon.controller.gui;
	import dwt.graphics.rectangle;
	import CodeAnalyzer.syntax.nodeHsu;



public:
	static void showTip( Scintilla sc, int pos, char[] listToolTip, int foreColor, int backColor )
	{
		if( listToolTip.length )
		{
			sc.callTipCancel();
			if( listToolTip[length-1] == '\n' ) listToolTip = listToolTip[0..$-1]; // strip off last newline

			Rectangle rectEditorScreen = sGUI.editor.getBounds(); // get editor width
			int marginWidth = sc.getMarginWidthN( 0 ) + sc.getMarginWidthN( 1 ) + sc.getMarginWidthN( 2 );
			int screenWidth = rectEditorScreen.width - marginWidth;
			int currentX , currentY;

			if( pos < 0 )
			{
				currentX = sc.pointXFromPosition( sc.getCurrentPos() );
				currentY = sc.pointYFromPosition( sc.getCurrentPos() );
			}
			else
			{
				currentX = sc.pointXFromPosition( pos );
				currentY = sc.pointYFromPosition( pos );
			}
			
			int callTipX = currentX;
			int tipsTextLength = 0, tipsMaxWidth = -1;

			char[][] tips = std.string.splitlines( listToolTip );
			if( tips.length > 1 )
			{
				foreach( char[] s; tips )
				{
					if( s.length > tipsTextLength ) 
					{
						tipsTextLength = s.length;
						tipsMaxWidth = sc.textWidth( sc.STYLE_DEFAULT, s );
					}
				}
			}
				
			if( sc.getVScrollBar() ) screenWidth -= 30;

			// Nested Function
			void _insertChangeLine( inout char[] texts, in int listToolTipWidth )
			{
				char[] tempText;
					
				int lineWidth = screenWidth / sc.textWidth( sc.STYLE_DEFAULT, " " );

				if( lineWidth <= 2 )
				{
					texts.length = 0;
					return;
				}

				for( int i = 0; i < texts.length; ++ i )
				{
					if( i > 0 )
						if( i % lineWidth == 0 ) tempText ~= "\n";

					tempText ~= texts[i];
				}

				texts =  tempText;
			}

			listToolTip.length = 0;
			bool bMaxWidth;
				
			foreach( char[] s; tips )
			{
				int listWidth = sc.textWidth( sc.STYLE_DEFAULT, s );

				if( tipsMaxWidth > 0 )
				{
					if( listWidth > screenWidth )
					{
						if( !bMaxWidth )
						{
							if( listWidth >= tipsMaxWidth )
							{
								callTipX = marginWidth;
								bMaxWidth = true;
							}
						}
									
						_insertChangeLine( s, tipsMaxWidth );
					}
					else if( listWidth > screenWidth - currentX )
					{
						if( !bMaxWidth )
						{
							if( listWidth >= tipsMaxWidth )
							{
								callTipX = screenWidth + marginWidth - listWidth;
								bMaxWidth = true;
							}
						}							
					}
				}
				else
				{
					if( listWidth > screenWidth )
					{
						callTipX = marginWidth;
						_insertChangeLine( s, listWidth );
					}
					else if( listWidth > screenWidth - currentX )
					{
						callTipX = screenWidth + marginWidth - listWidth;
					}
				}

				listToolTip ~= ( s ~ "\n" );
			}

			sc.callTipSetBack( backColor );
			sc.callTipSetFore( foreColor );
			sc.callTipShow( sc.positionFromPoint( callTipX, currentY ), listToolTip[0..length - 1] );
		}
	}

	static char[] getText( CAnalyzerTreeNode node )
	{
		if( node !is null )
		{
			switch( node.DType )
			{
				case D_VARIABLE:
				case D_PARAMETER:
					return node.typeIdentifier ~ " " ~ node.identifier;

				case D_FUNCTION:
					if( node.parameterString.length )
						return node.typeIdentifier ~ " " ~ node.identifier ~ "( " ~ node.parameterString ~ " )";
					else
						return node.typeIdentifier ~ " " ~ node.identifier ~ "()";

				case D_CLASS:
					char[] listToolTip;
					foreach( CAnalyzerTreeNode t; node.getAllLeaf() )
					{
						if( t.DType & D_CTOR )
							listToolTip ~= ( t.identifier ~ "(" ~ t.parameterString ~ ")\n" );
					}
			
					return listToolTip;

				case D_STRUCT:
					char[] listToolTip;
					foreach( CAnalyzerTreeNode t; node.getAllLeaf() )
					{
						if( t.DType & D_FUNCTION )
							if( t.identifier == "opCall" )
								listToolTip ~= ( t.identifier ~ "(" ~ t.parameterString ~ ")\n" );
					}

					return listToolTip;

				case D_TEMPLATE:
					return node.identifier ~ "( " ~ node.parameterString ~ " )";

				default:
			}
		}

		return null;
	}

	

}