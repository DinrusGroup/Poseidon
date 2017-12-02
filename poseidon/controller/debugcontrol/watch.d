module poseidon.controller.debugcontrol.watch;

private import dwt.all;
private import poseidon.controller.editor;
private import poseidon.controller.gui;
private import poseidon.globals;
private import poseidon.i18n.itranslatable;


class CWatchPanel : CTabFolder
{
private:
	const int		TAB_HEIGHT = 24;
	int[]			lastSashWeights;
	SashForm		_parent;
	Composite		tbContainer;	// tool bar container
	StackLayout		stackLayout;

	void initGUI()
	{
		//setMinimizeVisible( true );
		
		this.setSelectionBackground( [DWTResourceManager.getColor(0, 100, 255), DWTResourceManager.getColor(113, 166, 244), null ], 
									 [60, 100], true);
		this.setTabHeight( TAB_HEIGHT );
		this.setSimple( false );
		this.setSelectionForeground( DWTResourceManager.getColor( 255,255,255 ) );
		
		varItem = new CVariableItem( this );
		bpItem = new CBreakPointItem( this );
		regItem = new CRegisterItem( this );
		stackItem = new CStackItem( this );
		dllItem = new CDllItem( this );
		disassemblyItem = new CDisassemblyItem( this );
		
		this.setSelection( 0 );
		
		tbContainer = new Composite( this, DWT.NONE );
		stackLayout = new StackLayout();
		tbContainer.setLayout( stackLayout );

		Control top = varItem.getTbBar(tbContainer);
		bpItem.getTbBar( tbContainer );
		regItem.getTbBar( tbContainer );
		stackItem.getTbBar( tbContainer );
		dllItem.getTbBar( tbContainer );
		disassemblyItem.getTbBar( tbContainer );
		
		stackLayout.topControl = top;
		tbContainer.layout();
		setTopRight( tbContainer );
	}
	
	void onSashResize( Event e )
	{
		if( this.getMinimized() )
		{
			Point pt1 = _parent.getSize();
			int[] newWeights = [Math.max(0, pt1.y - TAB_HEIGHT), TAB_HEIGHT ];
			_parent.setWeights( newWeights );
			_parent.layout( true );
		}
	}

	void onTabFolderSelection( Event e ) 
	{
		CTabItem ti = cast(CTabItem) e.item;
		if( ti.getText() == "Registers" ) 
		{
			sGUI.debuggerDMD.dumpRegister( false );
			//sActionMan.actionDebugDumpRegister( e );
		}
		else if( ti.getText() == "Stack" ) 
		{
			sGUI.debuggerDMD.dumpStack( false );
			//sActionMan.actionDebugDumpStack( e );
		}

		CWatchPanel pthis = cast(CWatchPanel) e.widget;
		CWatchItem item = cast(CWatchItem)e.item;
		pthis.stackLayout.topControl = item.getTbBar(null);
		pthis.tbContainer.layout();		
	}	

public:	
	CVariableItem		varItem;
	CBreakPointItem		bpItem;
	CRegisterItem		regItem;
	CStackItem			stackItem;
	CDllItem			dllItem;
	CDisassemblyItem	disassemblyItem;
	
	
	this( SashForm parent )
	{
		super( parent, DWT.TOP | DWT.BORDER );
		_parent = parent;
		
		initGUI();

		this.handleEvent( null, DWT.Selection, &onTabFolderSelection );
	}
}


abstract class CWatchItem : CTabItem
{
	// ToolBar container
	Composite 	tbBar = null;
	ToolItem	tiStop;
	
	public this( CTabFolder parent )
	{
		super( parent, DWT.NONE );
	}
	
	abstract public Control getTbBar(Composite container);
	/+
	public void bringToFront()
	{
		CWatchPanel _parent = cast(CWatchPanel) getParent();
		if(_parent.getSelection() !is this)
		{
			/** 
			 * since CTabFolder.setSelection() will not trig DWT.Selection
			 * event, must set correct top right ToolBar manually
			 */
			_parent.setSelection( this );
			_parent.stackLayout.topControl = getTbBar( null );
			_parent.tbContainer.layout();
		}
		//_parent.onRestore(null);
	}
	+/
}



class CVariableItem : CWatchItem
{
private:
	//import poseidon.controller.debugcontrol.breakpoint;
	import poseidon.controller.debugcontrol.debugparser;

	Tree			tree;

	void initGUI( Composite parent )
	{
		setImage( Globals.getImage( "debug_varview") );
		tree = new Tree( parent, DWT.NONE );

		scope font = new Font( getDisplay, "Courier New", 8, DWT.BOLD );
		tree.setFont( font );
		tree.handleEvent(null, DWT.Expand, &onTreeExpand);
		//this.setControl( tree );
	}

	char[] getTreeVarName( TreeItem tItem )
	{
		return getTreeVarName( tItem.getText() );
	}

	char[] getTreeVarName( char[] text )
	{
		int equalPos = std.string.rfind( text, " = " );
		int spacePos = std.string.rfind( text[0..equalPos], " " );

		if( equalPos > -1 && spacePos < equalPos )
			return text[spacePos+1..equalPos];

		return null;
	}

	char[] getTreeVarValue( char[] text )
	{
		int equalPos = std.string.rfind( text, " = " );

		if( equalPos > -1 ) return text[equalPos+3..length];

		return null;
	}

	char[] getTreeVarFullName( TreeItem tItem )
	{
		TreeItem nowItem = tItem;
		
		char[] varName = getTreeVarName( tItem.getText() );

		if( varName.length )
		{
			while( nowItem !is null )
			{
				nowItem = nowItem.getParentItem();

				if( nowItem is null ) 
					break;
				else
				{
					if( nowItem.getParentItem() is null ) 
						break; // Tree Root
					else
					{
						if( getTreeVarValue( nowItem.getText() ) == "..." )
						{
							char[] parentVarName = getTreeVarName( nowItem );
							if( parentVarName.length )
							{
								if( varName[0] == '[' )
									varName = parentVarName ~ varName;
								else
									varName = parentVarName ~ "." ~ varName;
							}
						}
					}
				}
			}
		}

		return varName;
	}


	char[] parseVarByLine( char[][] variableAndValue, inout char[] name, inout char[] value, inout char[] hex )
	{
		if( variableAndValue.length == 1 )
		{
			if( variableAndValue[0].length > 6 )
			{
				if( variableAndValue[0][0..6] == "Scope:" )
					return std.string.strip( variableAndValue[0][6..length] );
			}

			if( variableAndValue[0].length > 1 )
			{
				if( variableAndValue[0][length-2..length] == "}," ) value = "},";
			}
		}
		else
		{
			name 	= variableAndValue[0];
			value 	= variableAndValue[1];

			try
			{
				std.utf.validate( value );
			}
			catch
			{
				// we got bad utf8 value
				return std.string.strip( name ~ " = ( UtfException! invalidate UTF8? )" );
			}

			if( value.length > 1 )
			{
				if( value[length - 1] == ',' )
				{
					value = value[0..length - 1];
				}
				else
				{
					if( value[0] == '"' && value[length - 1] == '"' )
						return std.string.strip( name ~ " = " ~ value );
				}
			}

			if( std.string.count( value, "0x" ) )
			{
				hex = value;
				value = std.string.toString( CDebugParser.hexString2Decimal( hex ) );
			}
			else
			{
				if( !std.string.count( value, "." ) )
					hex = "0x" ~ std.string.toString( cast(long) std.string.atoi( value ), cast(uint) 16 );							
			}

			return std.string.strip( name ~ " = " ~ value ~ ( hex.length ? " (" ~ hex ~ ")" :"" ) );
		}

		return null;
	}

	void paserVars( char[] input, TreeItem tItem )
	{
		if( tItem is null ) tree.removeAll();
		char[][] lines = std.string.splitlines( input );

		bool bIsMoudleRoot;//, bHaveChild;


		TreeItem 	ttiScope = tItem;

		for( int i = 0; i < lines.length; ++ i )
		{
			char[][] 	variableAndValue = std.string.split( std.string.strip( lines[i] ), " = " );
			char[] 		name, value, hex, type, iconName;
			
			if( variableAndValue.length == 1 )
			{
				char[] parsedText = parseVarByLine( variableAndValue, name, value, hex );

				if( parsedText.length )
				{
					if( tItem is null )
					{
						ttiScope = new TreeItem( tree, DWT.NONE );
						ttiScope.setText( parsedText );
						ttiScope.setImage( Globals.getImage( "debug_stackframe" ) );
						bIsMoudleRoot = true;
					}
				}
				else
				{
					if( value == "}," ) 
					{
						if( ttiScope !is null )	ttiScope = ttiScope.getParentItem();
					}
				}
			}
			else
			{
				if( ttiScope !is null )
				{
					bool 	bHaveSon, bHaveChild, bHaveChildFinished;
					char[] 	parsedText = parseVarByLine( variableAndValue, name, value, hex );
					
					if( value == "..." ) 
						bHaveSon = true;
					else if( value == "{" )
					{
						bHaveChild = true;
						parsedText = name;
						iconName = ">submodule<";
					}
					else if( value == "{}" )
					{
						bHaveChildFinished = bHaveChild = true;
						parsedText = name;
						iconName = ">submodulesingle<";
					}

					auto ttiChild = new TreeItem( ttiScope, DWT.NONE );

					if( !bHaveChild )
					{
						ttiChild.setText( std.string.strip( lines[i] ) );
						char[] varName = getTreeVarFullName( ttiChild );

						type = CDebugParser.getType( varName );

						if( type.length )
						{
							int index = std.string.find( type, " " );
							if( index > -1 ) iconName = type[0..index];
						}						
					}
					

					ttiChild.setText( ( type.length ? ( type ~ " " ) : "" ) ~ parsedText );					

				
					switch( iconName )
					{
						case "class":
						case "class*":
							ttiChild.setImage( Globals.getImage( "D_CLASS" ) );
							break;
						case "struct":
						case "struct*":
							ttiChild.setImage( Globals.getImage( "D_STRUCT" ) );
							break;
						case "union":
							ttiChild.setImage( Globals.getImage( "D_UNION" ) );
							break;
						case "enum":
							ttiChild.setImage( Globals.getImage( "D_ENUM" ) );
							break;
						case ">submodule<":
							ttiChild.setImage( Globals.getImage( "D_IMPORT" ) );
							break;
						case ">submodulesingle<":
							ttiChild.setImage( Globals.getImage( "D_IMPORT-PRIVATE" ) );
							break;
						default:
							ttiChild.setImage( Globals.getImage( "D_VARIABLE" ) );
							break;
							
					}					

					if( bHaveSon ) 
					{
						new TreeItem( ttiChild, DWT.NONE );
					}
					else if( bHaveChildFinished )
					{
					}
					else if( bHaveChild )
						ttiScope = ttiChild;
				}
			}
		}

		if( ttiScope !is null ) ttiScope.setExpanded( true );
	}	

	void onTreeExpand( Event e )
	{
		TreeItem item = cast(TreeItem) e.item;
		char[] text = item.getText();

		if( text.length > 3 )
		{
			if( text[length-3..length] == "..." )
			{
				if( item.getItemCount() == 1 )
				{
					TreeItem[] tis;
					tis = item.getItems();
					if( !tis[0].getText.length )
					{
						tis[0].dispose;

						char[] varName = getTreeVarFullName( item );
						char[] input = CDebugParser.getExpress( varName );
						
						paserVars( input, item );
						// call expresss
					}
				}
			}
		}
	}	


public:
	this( CTabFolder parent )
	{
		super( parent );
		initGUI( parent );
		updateI18N();
		//content.handleEvent(content, DWT.MouseDoubleClick, &onDBClick);
	}

	Control getTbBar( Composite container )
	{
		if( tbBar is null )
		{
			tbBar = new Composite( container, DWT.NONE );
			GridLayout gl = new GridLayout();
			tbBar.setLayout( gl );
			with( gl )
			{
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar( tbBar, DWT.FLAT | DWT.HORIZONTAL );
			toolbar.setLayoutData( new GridData( GridData.HORIZONTAL_ALIGN_END ) );

			with( new ToolItem( toolbar, DWT.CHECK ) )
			{
				setImage( Globals.getImage( "link" ) );
				setToolTipText( Globals.getTranslation( "debug.tooltip_link" ) );
				setSelection( sGUI.debuggerDMD.bLiveUpdateVar );
				handleEvent( this, DWT.Selection, delegate( Event e )
				{
					sGUI.debuggerDMD.bLiveUpdateVar = !sGUI.debuggerDMD.bLiveUpdateVar;
					setSelection( sGUI.debuggerDMD.bLiveUpdateVar );
				});				
			}
			
			with( tiStop = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage( Globals.getImage( "refresh" ) );
				setDisabledImage( Globals.getImage( "refresh_dis" ) );
				setToolTipText( Globals.getTranslation( "pop.refresh" ) );
				setEnabled( false );
				handleEvent(this, DWT.Selection, delegate(Event e)
				{
					sGUI.debuggerDMD.dumpVariables();
					//sActionMan.actionDebugListVariable( e );
				});
			}
		}
		
		return tbBar;
	}

	void updateToolBar() 
	{
		if( sGUI.debuggerDMD is null ) return;

		if( !sGUI.debuggerDMD.isPipeCreate() )
			tiStop.setEnabled( false );
		else
			if( sGUI.debuggerDMD.isRunning)
			{
				if( !tiStop.getEnabled() ) this.setControl( tree );
				tiStop.setEnabled( true );
			}
			else
				tiStop.setEnabled( false );
	}

	void parseLSV( char[] input, bool bForceRefresh = false )
	{
		scope colorOfValueChange = new Color( display, 255, 0, 0 );
		
		char[] _getTextAfterType( TreeItem ti, inout char[] type )
		{
			char[] itemText = ti.getText();
			int equalPos = std.string.rfind( itemText, " = " );
			int spacePos = std.string.rfind( itemText[0..equalPos], " " );

			if( equalPos > -1 && spacePos > -1 ) 
			{
				type = itemText[0..spacePos];
				return itemText[spacePos+1..length];
			}

			return null;
		}
		
		
		void _update( TreeItem _ti )
		{
			if( _ti.getExpanded() )
			{
				if( _ti.getParentItem() !is null )
				{
					char[] tiText = getTreeVarValue( _ti.getText() );
					if( tiText.length )	input = CDebugParser.getExpress( getTreeVarFullName( _ti ) );
				}
				
				char[][]	lines = std.string.splitlines( std.string.strip( input ) );
				int 		j;

				void _subUpdate( TreeItem _tti )
				{
					foreach( TreeItem ti; _tti.getItems() )
					{
						while( std.string.rfind( lines[j], " = " ) < 0 ) 
						{
							j ++;
						}

						if( j >= lines.length ) return;
						
						if( getTreeVarValue( ti.getText() ).length == 0 ) 
						{
							j ++;
							_subUpdate( ti );
						}
						else
						{
							char[]		name, value, hex, type;
							char[][] 	variableAndValue = std.string.split( std.string.strip(  lines[j] ), " = " );
							char[] 		parsedText = parseVarByLine( variableAndValue, name, value, hex );
							char[] 		treeitemText = _getTextAfterType( ti, type );

							if( treeitemText != parsedText )
							{
								if( value == "..." )
								{
									if( !ti.getItemCount() ) new TreeItem( ti, DWT.NONE );
								}
								else
								{
									if( treeitemText.length > 2 )
									{
										if( treeitemText[length-3..length] == "..." )
										{
											ti.setExpanded( false );
											foreach( TreeItem t; ti.getItems() )
											{
												t.dispose();
											}
										}
									}
								}

								char[] 		rootName = getTreeVarFullName( _ti );
								char[] 		varName = name;
								
								if( rootName.length )
								{
									if( name[0] == '[' )
										varName = rootName ~ name;
									else
										varName = rootName ~ "." ~ name;
								}

								char[] newType = CDebugParser.getType( varName );						

								ti.setForeground( colorOfValueChange );
								ti.setText( ( newType.length ? ( newType ~ " " ) : "" ) ~ parsedText );
							}
							else
							{
								ti.setForeground( null );
							}

							if( ti.getExpanded() ) _update( ti );

							j ++;
						}
					}
				}

				_subUpdate( _ti );
			}
		}

		if( bForceRefresh )
		{
			tree.removeAll();
			paserVars( input, null );
			return;
		}
		
		bool 		bCreateNewTree = true;
		TreeItem[] 	tis;

		tis = tree.getItems();
		if( tis.length )
		{
			// get current module name
			char[] 	currentScope = tis[0].getText();

			if( input.length > 6 )
			{
				if( input[0..6] == "Scope:" )
				{
					int CRLFPos = std.string.find( input, "\n" );
					if( CRLFPos > 7 )
					{
						char[] newScope = std.string.strip( input[6..CRLFPos] );
						if( newScope == currentScope ) bCreateNewTree = false;
					}
				}
			}
		}

		if( bCreateNewTree )
		{
			tree.removeAll();
			paserVars( input, null );
		}
		else
		{
			_update( tis[0] );
		}
	}

	
	void updateI18N(){ this.setText( Globals.getTranslation( "debug.vars" ) ); }

	void clean( bool bSetControlNull = true )
	{
		tree.removeAll();
		if( bSetControlNull ) this.setControl( null );
	}
}

class CBreakPointItem : CWatchItem
{
private:
	import poseidon.controller.edititem;

	Table			table;
	TableColumn[4] 	tc;

	private void initGUI(Composite parent)
	{
		setImage( Globals.getImage( "debug_bpview") );
		table = new Table( parent, DWT.CHECK | DWT.FULL_SELECTION );
        table.setHeaderVisible( true );
		table.setLinesVisible( true );
		scope font = new Font( getDisplay, "Courier New", 9, DWT.BOLD );

		
		tc[0] = new TableColumn( table, DWT.LEFT );
		tc[0].setText( "ID" );
		tc[0].setWidth( 40 );
		tc[1] = new TableColumn( table, DWT.LEFT );
		tc[1].setText( "FILE" );
		tc[1].setWidth( 80 );
		tc[2] = new TableColumn( table, DWT.LEFT );
		tc[2].setText( "LINENUM" );
		tc[2].setWidth( 80 );
		tc[3] = new TableColumn( table, DWT.LEFT );
		tc[3].setText( "FULLPATH" );
		tc[3].setWidth( 300 );
		

		//setBackground( i, new Color( display, 0x8f, 0xff, 0x8f ) );
		table.setFont( font );			
		this.setControl( table );

		table.handleEvent( null, DWT.DefaultSelection, &onDefaultSelection );
	}

	void onDefaultSelection( Event e )
	{
		TableItem item = cast(TableItem) e.item;
		//CBreakPoint bp = cast(CBreakPoint) item.getData();

		EditItem ei = sGUI.editor.findEditItem( std.string.strip( item.getText( 3 ) ) );
		if( ei !is null )
		{
			char[] path = ei.getFileName();
			if( sGUI.editor.isFileOpened( path ) ) sGUI.editor.openFile( path, null, -1, false );

			int lineNum = std.string.atoi( item.getText( 2 ) );
			sGUI.editor.setSelectionAndNotify( ei );
			ei.scintilla.forceFocus();
			ei.scintilla.call( 2234, lineNum - 1 );
			ei.setSelection( lineNum - 1 );
		}
	}

public:
	this( CTabFolder parent )
	{
		super( parent );
		initGUI( parent );
		updateI18N();
		//content.handleEvent(content, DWT.MouseDoubleClick, &onDBClick);
	}
	
	Control getTbBar( Composite container )
	{
		if( tbBar is null )
		{
			tbBar = new Composite( container, DWT.NONE );
			GridLayout gl = new GridLayout();
			tbBar.setLayout( gl );
			with( gl )
			{
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar( tbBar, DWT.FLAT | DWT.HORIZONTAL );
			toolbar.setLayoutData( new GridData( GridData.HORIZONTAL_ALIGN_END ) );

			with( new ToolItem( toolbar, DWT.NONE ) ) setEnabled( false );
			tiStop = new ToolItem( toolbar, DWT.NONE );
			tiStop.setImage(Globals.getImage( "close_view") );
			tiStop.setToolTipText( Globals.getTranslation( "debug.tooltip_cleanbps" ) );
			tiStop.handleEvent(this, DWT.Selection, delegate(Event e)
			{
				CBreakPointItem pthis = cast(CBreakPointItem) e.cData;

				foreach( TableItem ti; pthis.table.getItems() )
				{
					if( sGUI.debuggerDMD.isPipeCreate() )
						sGUI.debuggerDMD.write( "dbp " ~ std.string.strip( ti.getText( 3 ) ) ~ ":" ~ std.string.strip( ti.getText( 2 ) ) ~ "\n" );

					EditItem ei = sGUI.editor.findEditItem( std.string.strip( ti.getText( 3 ) ) );
					if( ei !is null ) ei.deleteAllDebugMarker();
				}

				pthis.table.removeAll();
			});
		}
		return tbBar;
	}
	
	void updateI18N(){ this.setText( Globals.getTranslation( "debug.bps" ) ); }

	void add( char[] fullPath, char[] moduleName, int lineNum )
	{
		TableItem[] tis = table.getItems();

		if( !tis.length )
		{
			add( fullPath, moduleName, lineNum, 0 );
		}
		else
		{
			for( int i = 0; i < 0x8fffffff; ++ i )
			{
				bool bGetID = true;
				foreach( TableItem ti; tis )
				{
					if( i == std.string.atoi( ti.getText( 0 ) ) )
					{
						bGetID = false;
						break;
					}
				}
				if( bGetID )
				{
					add( fullPath, moduleName, lineNum, i );
					break;
				}
			}
		}
	}

	void add( char[] fullPath, char[] moduleName, int lineNum, int id )
	{
		TableItem item = new TableItem( table, DWT.NULL );
		item.setText( 0, std.string.toString( id ) ~ "    " );
		item.setText( 1, moduleName ~ "      " );
		item.setText( 2, std.string.toString( lineNum ) ~ "      " );
		item.setText( 3, fullPath ~ "      " );
		tc[0].pack();
		tc[1].pack();
		tc[2].pack();
		tc[3].pack();
		
		//item.setImage( 1, Globals.getImage( "debug_bp") );
		item.setChecked( true );
	}	

	void del( int id )
	{
		TableItem[] tis = table.getItems();
		for( int i = 0; i < tis.length; ++ i )
		{
			if( std.string.atoi( tis[i].getText( 0 ) ) == id )
			{
				table.remove( i );
				break;
			}
		}
	}

	void del( char[] fullPath, int lineNum )
	{
		TableItem[] tis = table.getItems();
		for( int i = 0; i < tis.length; ++ i )
		{
			if( ( std.string.strip( tis[i].getText( 3 ) ) == fullPath | std.string.strip( tis[i].getText( 1 ) ) == fullPath )
				&& std.string.atoi( tis[i].getText( 2 ) ) == lineNum )
			{
				table.remove( i );
				break;
			}
		}
	}

	void cleanAllBps()
	{
		foreach( TableItem ti; table.getItems() )
		{
			if( sGUI.debuggerDMD.isPipeCreate() )
				sGUI.debuggerDMD.write( "dbp " ~ std.string.strip( ti.getText( 3 ) ) ~ ":" ~ std.string.strip( ti.getText( 2 ) ) ~ "\n" );

			EditItem ei = sGUI.editor.findEditItem( std.string.strip( ti.getText( 3 ) ) );
			if( ei !is null ) ei.deleteAllDebugMarker();
		}

		table.removeAll();
	}

	int getCount(){ return table.getItemCount(); }

	TableItem[] getAllItems(){ return table.getItems(); }

	/*
	CBreakPoint[] getBPs()
	{
		CBreakPoint[] bps;
		
		foreach( TableItem ti; table.getItems() )
		{
			CBreakPoint bp = cast(CBreakPoint) ti.getData();
			bps ~= bp;
		}

		return bps;
	}
	*/
}


class CRegisterItem : CWatchItem
{
private:
	Table			table;
	TableItem[5] 	tbItem;
	

	void initGUI( Composite parent )
	{
		setImage( Globals.getImage( "debug_register") );

		table = new Table( parent, DWT.BORDER );
        table.setHeaderVisible( true );
		table.setLinesVisible( true );
		
		scope font = new Font( getDisplay, "Courier New", 9, DWT.BOLD );
		table.setFont( font );

		TableColumn[8] tc;
		int i;

		for( i = 0; i < 8; ++ i )
		{
			tc[i] = new TableColumn( table, DWT.CENTER );
			if( i % 2 == 0 ) 
				tc[i].setText( Globals.getTranslation( "debug.reg" ) );
			else
				tc[i].setText( "  " ~ Globals.getTranslation( "debug.value" ) ~ "  " );

			tc[i].pack();
		}

        with( tbItem[0] = new TableItem( table, DWT.NONE ) )
		{
			setText( [ "EAX", "", "EBX", "", "ECX", "", "EDX", "" ] );
			for( i = 0; i < 8; i += 2 )
				setBackground( i, new Color( display, 0x8f, 0xff, 0x8f ) );
		}
		
        with( tbItem[1] = new TableItem( table, DWT.NONE ) )
		{
			setText( [ "EDI", "", "ESI", "", "EBP", "", "ESP", "" ] );
			for( i = 0; i < 8; i += 2 )
				setBackground( i, new Color( display, 0x8f, 0xff, 0x8f ) );
		}

		with( tbItem[2] = new TableItem( table, DWT.NONE ) )
		{
			setText(  [ "EIP", "", "EFL", "", "", "", "", "" ] );
			for( i = 0; i < 8; i += 2 )
				setBackground( i, new Color( display, 0x8f, 0xff, 0x8f ) );
		}
		
		with( tbItem[3] = new TableItem( table, DWT.NONE ) )
		{
			setText( [ "CS", "", "DS", "", "ES", "", "FS", "" ] );
			for( i = 0; i < 8; i += 2 )
				setBackground( i, new Color( display, 0x8f, 0xff, 0x8f ) );
		}

		with( tbItem[4] = new TableItem( table, DWT.NONE ) )
		{
			setText( [ "GS", "", "SS", "", "", "", "", "" ] );
			for( i = 0; i < 8; i += 2 )
				setBackground( i, new Color( display, 0x8f, 0xff, 0x8f ) );
		}

		//this.setControl( table );
	}

	
public:
	this( CTabFolder parent )
	{
		super( parent );
		initGUI( parent );
		updateI18N();
		//content.handleEvent(content, DWT.MouseDoubleClick, &onDBClick);
	}

	Control getTbBar( Composite container )
	{
		if( tbBar is null )
		{
			tbBar = new Composite( container, DWT.NONE );
			GridLayout gl = new GridLayout();
			tbBar.setLayout( gl );
			with( gl )
			{
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar( tbBar, DWT.FLAT | DWT.HORIZONTAL );
			toolbar.setLayoutData( new GridData( GridData.HORIZONTAL_ALIGN_END ) );

			with( new ToolItem( toolbar, DWT.NONE ) ) setEnabled( false );
			with( tiStop = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage( Globals.getImage( "refresh" ) );
				setDisabledImage( Globals.getImage( "refresh_dis" ) );
				setToolTipText( Globals.getTranslation( "pop.refresh" ) );
				setEnabled( false );
				handleEvent(this, DWT.Selection, delegate(Event e)
				{
					sGUI.debuggerDMD.dumpRegister();
					//sActionMan.actionDebugDumpRegister( e );
				});
			}
		}
		
		return tbBar;
	}

	void updateItems( char[][] regs )
	{
		if( regs.length == 16 )
		{
			for( int i = 0; i < 2; ++ i )
				for( int j = 0; j < 4; ++j )
					tbItem[i].setText( 1 + j * 2, regs[j + i * 4] );

			tbItem[2].setText( 1, regs[8] );
			tbItem[2].setText( 3, regs[9] );

			for( int j = 0; j < 4; ++j )
				tbItem[3].setText( 1 + j * 2, regs[10 + j] );
			
			tbItem[4].setText( 1, regs[14] );
			tbItem[4].setText( 3, regs[15] );
		}
		else
		{
			for( int i = 0; i < 5; ++ i )
				for( int j = 0; j < 4; ++j )
					tbItem[i].setText( 1 + j * 2, "" );
		}
	}

	void updateToolBar() 
	{
		if( sGUI.debuggerDMD is null ) return;

		if( !sGUI.debuggerDMD.isPipeCreate() )
			tiStop.setEnabled( false );
		else
			if( sGUI.debuggerDMD.isRunning )
			{
				if( !tiStop.getEnabled() ) this.setControl( table );
				tiStop.setEnabled( true );
			}
			else
				tiStop.setEnabled( false );
	}	
	
	void updateI18N(){ this.setText( Globals.getTranslation( "debug.regs" ) ); }

	void clean( bool bSetControlNull = true )
	{
		updateItems( null );
		if( bSetControlNull ) this.setControl( null );
	}		
}

class CStackItem : CWatchItem
{
private:
	Table		table;
	

	void initGUI( Composite parent )
	{
		setImage( Globals.getImage( "debug_stack") );
		table = new Table( parent, DWT.BORDER );
        //table.setHeaderVisible( false );
		table.setLinesVisible( true );
		scope font = new Font( getDisplay, "Courier New", 9, DWT.BOLD );
		table.setFont( font );
		//this.setControl( table );
	}

	
public:
	this( CTabFolder parent )
	{
		super( parent );
		initGUI( parent );
		updateI18N();
		//content.handleEvent(content, DWT.MouseDoubleClick, &onDBClick);
	}

	Control getTbBar( Composite container )
	{
		if( tbBar is null )
		{
			tbBar = new Composite( container, DWT.NONE );
			GridLayout gl = new GridLayout();
			tbBar.setLayout( gl );
			with( gl )
			{
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar( tbBar, DWT.FLAT | DWT.HORIZONTAL );
			toolbar.setLayoutData( new GridData( GridData.HORIZONTAL_ALIGN_END ) );

			with( new ToolItem( toolbar, DWT.NONE ) ) setEnabled( false );
			with( tiStop = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage(Globals.getImage( "refresh" ) );
				setDisabledImage( Globals.getImage( "refresh_dis" ) );
				setToolTipText( Globals.getTranslation( "pop.refresh" ) );
				setEnabled( false );
				handleEvent(this, DWT.Selection, delegate(Event e)
				{
					sGUI.debuggerDMD.dumpStack();
					//sActionMan.actionDebugDumpStack( e );
				});
			}
		}
		
		return tbBar;
	}
	
	void updateI18N(){ this.setText( Globals.getTranslation( "debug.stack" ) ); }

	void updateToolBar() 
	{
		if( sGUI.debuggerDMD is null ) return;

		if( !sGUI.debuggerDMD.isPipeCreate() )
			tiStop.setEnabled( false );
		else
			if( sGUI.debuggerDMD.isRunning ) 
			{
				if( !tiStop.getEnabled() ) this.setControl( table );
				tiStop.setEnabled( true );
			}
			else
				tiStop.setEnabled( false );
	}		

	void add( char[] str )
	{
		TableItem item = new TableItem( table, DWT.NULL );
		item.setText( str );
	}
	/*
	void delAll()
	{
		table.removeAll();
	}
	*/	
	void clean( bool bSetControlNull = true )
	{
		table.removeAll();
		if( bSetControlNull) this.setControl( null );
	}		
}


class CDllItem : CWatchItem
{
private:
	Table		table;

	void initGUI( Composite parent )
	{
		setImage( Globals.getImage( "debug_dll") );
		table = new Table( parent, DWT.BORDER );
        table.setHeaderVisible( true );
		table.setLinesVisible( true );
		
		scope font = new Font( getDisplay, "Courier New", 9, DWT.BOLD );
		table.setFont( font );

		TableColumn[2] tc;
		int i;

		tc[0] = new TableColumn( table, DWT.LEFT );
		tc[0].setText( Globals.getTranslation( "debug.base" ) );
		tc[1] = new TableColumn( table, DWT.LEFT );
		tc[1].setText( Globals.getTranslation( "debug.name" ) );

		tc[0].setWidth( 150 );
		tc[1].setWidth( 200 );

		//tc[0].pack();
		//tc[1].pack();

		//this.setControl( table );
	}

	
public:
	this( CTabFolder parent )
	{
		super( parent );
		initGUI( parent );
		updateI18N();
	}

	Control getTbBar( Composite container )
	{
		if( tbBar is null )
		{
			tbBar = new Composite( container, DWT.NONE );
			GridLayout gl = new GridLayout();
			tbBar.setLayout( gl );
			with( gl )
			{
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar( tbBar, DWT.FLAT | DWT.HORIZONTAL );
			toolbar.setLayoutData( new GridData( GridData.HORIZONTAL_ALIGN_END ) );

			with( new ToolItem( toolbar, DWT.NONE ) ) setEnabled( false );
			with( tiStop = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage(Globals.getImage( "refresh" ) );
				setDisabledImage( Globals.getImage( "refresh_dis" ) );
				setToolTipText( Globals.getTranslation( "pop.refresh" ) );
				setEnabled( false );
				handleEvent(this, DWT.Selection, delegate(Event e)
				{
					sGUI.debuggerDMD.dumpDll();
					//sActionMan.actionListDlls( e );
				});
			}
		}
		
		return tbBar;
	}
	
	void updateI18N(){ this.setText( Globals.getTranslation( "debug.dll" ) ); }

	void updateToolBar() 
	{
		if( sGUI.debuggerDMD is null ) return;

		if( !sGUI.debuggerDMD.isPipeCreate() )
			tiStop.setEnabled( false );
		else
			if( sGUI.debuggerDMD.isRunning )
			{
				if( !tiStop.getEnabled() ) this.setControl( table );
				tiStop.setEnabled( true );
			}
			else
				tiStop.setEnabled( false );
	}		

	void add( char[][] baseAndName )
	{
		TableItem item = new TableItem( table, DWT.NULL );
		item.setText( baseAndName );
	}

	//void delAll(){ table.removeAll(); }

	void clean( bool bSetControlNull = true )
	{
		table.removeAll();
		if( bSetControlNull) this.setControl( null );
	}	
}


class CDisassemblyItem : CWatchItem
{
private:
	import poseidon.controller.scintillaex;

	ScintillaEx 	scintilla;

	const static char[][] sKeyWords = 
	["aaa aad aam adc add and arpl bound bsf bsr bswap bt btc btr bts call cbw cdq clc cld cli clts cmc cmp cmps cmpsb cmpsd cmpsw cmpxchg cwd cwde daa das dec div emms enter f2xm1 fabs fadd faddp fbld fbstp fchs fclex fcmovb fcmovbe fcmove fcmovnb fcmovnbe fcmovne fcmovnu fcmovu fcom fcomi fcomip fcomp fcompp fcos fdecstp fdiv fdivp fdivr fdivrp femms ffree fiadd ficom ficomp fidiv fidivr fild fimul fincstp finit fist fistp fisub fisubr fld fld1 fldcw fldenv fldl2e fldl2t fldlg2 fldln2 fldpi fldz fmul fmulp fnclex fninit fnop fnsave fnstcw fnstenv fnstsw fpatan fprem1 fptan frndint frstor fsave fscale fsin fsincos fsqrt fst fstcw fstenv fstp fstsw fsub fsubp fsubr fsubrp ftst fucom fucomi fucomip fucomp fucompp fwait fxch fxtract fyl2xp1 hlt idiv imul in inc ins insb insd insw int into invd invlpg iret iretd iretw ja jae jb jbe jc jcxz je jecxz jg jge jl jle jmp jna jnae jnb jnbe jnc jne jng jnge jnl jnle jno jnp jns jnz jo jp jpe jpo js jz lahf lar lds lea leave les lfs lgdt lgs lidt lldt lmsw lock lods lodsb lodsd lodsw loop loope loopne loopnz loopz lsl lss ltr mov movd movq movs movsb movsd movsw movsx movzx mul neg nop not or out outs outsb outsd outsw packssdw packsswb packuswb paddb paddd paddsb paddsw paddusb paddusw paddw pand pandn pavgusb pcmpeqb pcmpeqd pcmpeqw pcmpgtb pcmpgtd pcmpgtw pf2id pfacc pfadd pfcmpeq pfcmpge pfcmpgt pfmax pfmin pfmul pfrcp pfrcpit1 pfrcpit2 pfrsqit1 pfrsqrt pfsub pfsubr pi2fd pmaddwd pmulhrw pmulhw pmullw pop popa popad popaw popf popfd popfw por prefetch prefetchw pslld psllq psllw psrad psraw psrld psrlq psrlw psubb psubd psubsb psubsw psubusb psubusw psubw punpckhbw punpckhdq punpckhwd punpcklbw punpckldq punpcklwd push pusha pushad pushaw pushf pushfd pushfw pxor rcl rcr rep repe repne repnz repz ret rol ror sahf sal sar sbb scas scasb scasd scasw seta setae setb setbe setc sete setg setge setl setle setna setnae setnb setnbe setnc setne setng setnge setnl setnle setno setnp setns setnz seto setp setpo sets setz sgdt shl shld shr shrd sidt sldt smsw stc std sti stos stosb stosd stosw str sub test verr verw wait wbinvd xadd xchg xlat xlatb xor"
	, "align and assume at b byte comm comment common compact d db dd df dq dt define dosseg dup dt dw dword elif else elseif end endif endm endp ends eq equ error even exitm extrn far fq ge group h high huge if ifdef ifndef include includelib irp irpc label large le length low local lt macro mask medium memory name near not o offset or org page para proc public purge q record rept seg segment shl short size shr small stack struc subttl this tiny title undef type use16 use32 width word xor code data nothing ptr"
	, "ax bx cx dx ex si di bp sp ss es ds cs fs gs ip al ah bl bh ch cl dh dl eh el eax ebx ebp ecx edi edx esi esp"
	];

	void initGUI( Composite parent )
	{
		setImage( Globals.getImage( "debug_disassembly") );

		scintilla = new ScintillaEx( parent, DWT.NONE );

		scintilla.setLexer( scintilla.SCLEX_ASM );

		scintilla.styleSetFont( scintilla.STYLE_DEFAULT, "Courier New" );
		scintilla.styleSetSize(	scintilla.STYLE_DEFAULT, 9 );

		scintilla.setMarginWidthN( 0, 24  );
		//scintilla.setMarginWidthN(1, 16 );
		//scintilla.setMarginTypeN(1, scintilla.SC_MARGIN_SYMBOL);
		//sc.setMarginSensitiveN(1, true);
		//scintilla.setMarginMaskN( 1, (1<<1) | (1<<2) | ( 1<<3) );

		scintilla.setKeyWords( 0, sKeyWords[0] );
		scintilla.setKeyWords( 1, sKeyWords[1] );
		scintilla.setKeyWords( 2, sKeyWords[2] );

		scintilla.styleSetFore( scintilla.SCE_ASM_CPUINSTRUCTION, 0x0000ff );
		scintilla.styleSetFore( scintilla.SCE_ASM_MATHINSTRUCTION, 0x1a2b77 );
		scintilla.styleSetFore( scintilla.SCE_ASM_REGISTER, 0xff0000 );
		scintilla.styleSetFore( scintilla.SCE_ASM_COMMENT, 0x007f00 );

		scintilla.setReadOnly( true );

		//this.setControl( scintilla );
	}

	void resetLineNumWidth()
	{
		if( scintilla.getMarginWidthN( 0 ) > 0 )
		{
			int len = scintilla.getLineCount();
			scintilla.setMarginWidthN( 0, 24 + 8 * ( cast(int) len / 1000 ) );
		}
	}

	void setString( char[] text )
	{
		scintilla.setReadOnly( false );
		scintilla.setText( text );
		scintilla.setReadOnly( true );		
	}

public:
	this( CTabFolder parent )
	{
		super( parent );
		initGUI( parent );
		updateI18N();
	}

	Control getTbBar( Composite container )
	{
		if( tbBar is null )
		{
			tbBar = new Composite( container, DWT.NONE );
			GridLayout gl = new GridLayout();
			tbBar.setLayout( gl );
			with( gl )
			{
				marginWidth = 0;
				marginHeight = 0;
			}
			ToolBar toolbar = new ToolBar( tbBar, DWT.FLAT | DWT.HORIZONTAL );
			toolbar.setLayoutData( new GridData( GridData.HORIZONTAL_ALIGN_END ) );

			with( new ToolItem( toolbar, DWT.CHECK ) )
			{
				setImage( Globals.getImage( "link" ) );
				setToolTipText( Globals.getTranslation( "debug.tooltip_link" ) );
				setSelection( sGUI.debuggerDMD.bLiveUpdateDisassembly );
				handleEvent( this, DWT.Selection, delegate( Event e )
				{
					sGUI.debuggerDMD.bLiveUpdateDisassembly = !sGUI.debuggerDMD.bLiveUpdateDisassembly;
					setSelection( sGUI.debuggerDMD.bLiveUpdateDisassembly );
				});				
			}
			
			with( tiStop = new ToolItem( toolbar, DWT.NONE ) )
			{
				setImage(Globals.getImage( "refresh" ) );
				setDisabledImage( Globals.getImage( "refresh_dis" ) );
				setToolTipText( Globals.getTranslation( "pop.refresh" ) );
				setEnabled( false );
				handleEvent(this, DWT.Selection, &disassemblyLine );
			}
		}
		
		return tbBar;
	}

	void updateI18N(){ this.setText( Globals.getTranslation( "debug.disassembly" ) ); }

	void updateToolBar() 
	{
		if( sGUI.debuggerDMD is null ) return;

		if( !sGUI.debuggerDMD.isPipeCreate() )
			tiStop.setEnabled( false );
		else
		{
			if( sGUI.debuggerDMD.isRunning ) 
			{
				if( !tiStop.getEnabled() ) this.setControl( scintilla );
				tiStop.setEnabled( true );
			}
			else
				tiStop.setEnabled( false );
		}
	}

	void disassemblyLine( Event e )
	{
		char[] result = sGUI.debuggerDMD.write( "dal\n", false );

		if( result.length > 3 )
		{
			setString( ";" ~ result[0..length-3] );
			resetLineNumWidth();
		}
		else
		{
			scintilla.setMarginWidthN( 0, 0 );
			setString( "" );
		}
	}	

	void clean( bool bSetControlNull = true )
	{
		setString( "" );
		if( bSetControlNull ) this.setControl( null );
	}
}