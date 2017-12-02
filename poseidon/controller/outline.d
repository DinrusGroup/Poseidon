module poseidon.controller.outline;

private
{
	import dwt.all;
	import poseidon.controller.gui;
	import poseidon.globals;
	import poseidon.i18n.itranslatable;
	import poseidon.util.waitcursor;
	import poseidon.controller.editor;
	import poseidon.controller.edititem;
	import poseidon.model.misc;
	import CodeAnalyzer.syntax.nodeHsu;
	import std.thread;
	import poseidon.controller.toolbarmanager;
	import poseidon.intellisense.search;
}

private Image getTreeIcon( CAnalyzerTreeNode l )
{
	Image image;
	
	switch( l.DType )
	{
		case D_FUNCTION:
		case D_INTERFACE:
		case D_CLASS:
		case D_ENUM:
		case D_STRUCT:
		case D_UNION:
		case D_VARIABLE:
			if( l.prot & D_Private )
				image = Globals.getImage( dTypeToChars( l.DType ) ~ "-PRIVATE" );
			else if( l.prot & D_Protected ) 
				image = Globals.getImage( dTypeToChars( l.DType ) ~ "-PROTECTED" );
			else
				image = Globals.getImage( dTypeToChars(l.DType ) );
			break;

		case D_FUNLITERALS:
			if( l.identifier == "delegate" || l.identifier == "function" )
			{
				image = Globals.getImage( dTypeToChars( l.DType ) );
				break;
			}
				
			if( l.prot & D_Private )
				image = Globals.getImage( "D_FUNPOINTER-PRIVATE" );
			else if( l.prot & D_Protected ) 
				image = Globals.getImage( "D_FUNPOINTER-PROTECTED" );
			else
				image = Globals.getImage( "D_FUNPOINTER" );
			break;	

		case D_IMPORT:
			if( l.prot & D_Public )
				image = Globals.getImage( "D_IMPORT" );
			else
				image = Globals.getImage( "D_IMPORT-PRIVATE" );
			break;

		case D_CONDITIONSPEC:
			if( l.typeIdentifier == "version" )
				image = Globals.getImage( "D_VERSIONSPEC" );
			else
				image = Globals.getImage( "D_DEBUGSPEC" );

			break;

		case D_MIXIN:
			image = Globals.getImage( "D_MIXIN" );
			break;

		case D_ANONYMOUSBLOCK:
			image = Globals.getImage( "D_ANONYMOUSBLOCK" );
			break;

		default:
			image = Globals.getImage( dTypeToChars( l.DType ) );
			break;
	}

	if( image is null ) image = Globals.getImage( "unknown" );
	
	return image;
}


class OLItem
{
	private import poseidon.intellisense.search;

    dwt.widgets.treeitem.Tree	tree;
    EditItem 					editItem;
	private int 				toggle;
	private bool 				bSort;
	private CAnalyzerTreeNode	sortedAnalyzer;
	private TreeItem[]			treeItems;

	const int D_FUNS = D_FUNCTION | D_DTOR | D_CTOR | D_STATICCTOR | D_STATICDTOR;

    this( dwt.widgets.treeitem.Tree tree, EditItem editItem)
    {
		this.tree = tree;
		this.editItem = editItem;

		tree.handleEvent(null, DWT.DefaultSelection, &onTreeDefaultSelection);
    }

	~this()
	{
		if( sortedAnalyzer ) delete sortedAnalyzer;
	}

    public void dispose()
	{
		if( tree ) tree.dispose();
		tree = null;
		editItem = null;
    }

	// 建立TreeItem
    private void populateTree( CAnalyzerTreeNode parser )
    {
		tree.removeAll();
		treeItems.length = 0;
		
		if( parser ) 
		{
			if( this.bSort )
			{
				if( sortedAnalyzer ) delete sortedAnalyzer;
				sortedAnalyzer = parser.dup();
				addTreeItemSorted( sortedAnalyzer, null );
			}
			else
			{
				if( sortedAnalyzer ) delete sortedAnalyzer;
				addTreeItem( parser, null );
			}
		}
    }


	private void addTreeItem( CAnalyzerTreeNode analyzerNode, TreeItem treeItem )
	{
		int skipDTYPE = D_MODULE | D_PARAMETER;
		
		version( SHOWBLOCK )
		{
		}
		else
		{
			skipDTYPE = skipDTYPE | D_BLOCK;
		}
		
		// 有子節點
		foreach( CAnalyzerTreeNode t; analyzerNode.getAllLeaf() )
		{
			if( !( t.DType & skipDTYPE ) )
			{
				TreeItem tItem;
				if( !treeItem )
				{
					tItem = new TreeItem( tree, DWT.NONE );
					tItem.setData( t );
					treeItems ~= tItem;
					/*
					scope font = new Font( tree.getDisplay(), Editor.settings._setting.outputStyle.font, Editor.settings._setting.outputStyle.size, DWT.NORMAL );
					tItem.setFont( font );
					*/
				}else
				{
					tItem = new TreeItem( treeItem, DWT.NONE );
					tItem.setData( t );
					treeItems ~= tItem;
					/*
					scope font = new Font( tree.getDisplay(), Editor.settings._setting.outputStyle.font, Editor.settings._setting.outputStyle.size, DWT.NORMAL );
					tItem.setFont( font );
					*/
				}

				//if( !( t & D_FUNS ) ) addTreeItem( t, tItem );
				addTreeItem( t, tItem );
			}
		}
	}


	private void addTreeItemSorted( CAnalyzerTreeNode analyzerNode, TreeItem treeItem )
	{
		// 有子節點
		if( analyzerNode.getLeafCount() )
		{
			CAnalyzerTreeNode[] leafs = analyzerNode.getAllLeaf();
			// 對 DType 排列
			scope CDTypeSort!( CAnalyzerTreeNode ) sortDtypeList = new CDTypeSort!( CAnalyzerTreeNode )( leafs );
			leafs = sortDtypeList.pop();
			delete sortDtypeList;
			

			// 對Identifier作排列
			CAnalyzerTreeNode[] newLeafs, tempLeafs;
			
			
			int prevDType = leafs[0].DType;

			for( int i = 0; i < leafs.length; ++ i )
			{
				if( leafs[i].DType != prevDType )
				{
					scope CIdentSort!( CAnalyzerTreeNode ) sortIdentList = new CIdentSort!( CAnalyzerTreeNode )( tempLeafs );
					tempLeafs = sortIdentList.pop();
					newLeafs ~= tempLeafs;
					tempLeafs.length = 0;
					tempLeafs ~= leafs[i];
					prevDType = leafs[i].DType;

					if( i == leafs.length - 1 ) newLeafs ~= leafs[i];
				}else
				{
					tempLeafs ~= leafs[i];
					if( i == leafs.length - 1 )
					{
						scope CIdentSort!( CAnalyzerTreeNode ) sortIdentList = new CIdentSort!( CAnalyzerTreeNode )( tempLeafs );
						tempLeafs = sortIdentList.pop();
						newLeafs ~= tempLeafs;
					}
				}
			}

			int skipDTYPE = D_MODULE | D_PARAMETER;
			
			version( SHOWBLOCK )
			{
			}
			else
			{
				skipDTYPE = skipDTYPE | D_BLOCK;
			}		

			foreach( CAnalyzerTreeNode t; newLeafs )
			{
				if( !( t.DType & skipDTYPE ) )
				{
					TreeItem tItem;
					if( !treeItem )
					{
						tItem = new TreeItem( tree, DWT.NONE );
						tItem.setData( t );
						treeItems ~= tItem;
					}else
					{
						tItem = new TreeItem( treeItem, DWT.NONE );
						tItem.setData( t );
						treeItems ~= tItem;
					}

					//if( !( t & D_FUNS ) ) addTreeItemSorted( t, tItem );
					addTreeItemSorted( t, tItem );
				}
			}
		}
	}


	

    /***
     * updateTreeItem, eg, can do a show "return type", show "param" option
     * check here
     */
    private void updateTreeItem( TreeItem treeitem )
    {
		CAnalyzerTreeNode l = cast(CAnalyzerTreeNode) treeitem.getData();

		if( !l ) return;

		char[] title, typeDisplayName;
		int t = l.DType;

		if( sGUI.outline.showParamsRetType & 1 ) typeDisplayName = l.typeIdentifier.length ? " : " ~ l.typeIdentifier : "";

		if( t & ( D_CTOR | D_DTOR  | D_TEMPLATE ) )
		{
			if( sGUI.outline.showParamsRetType & 2 )
				title = l.identifier ~ " (" ~ l.parameterString ~ ")" ;
			else
				title = l.identifier;
		}
		else if( t & ( D_STATICCTOR | D_STATICDTOR | D_FUNCTION ) )
		{
			if( sGUI.outline.showParamsRetType & 2 )
				title = l.identifier ~ " (" ~ l.parameterString ~ ")" ~ typeDisplayName;
			else
				title = l.identifier ~ typeDisplayName;
		}
		else if( t & D_FUNLITERALS )
		{
			char[] arrayString = l.baseClass.length ? " " ~ l.baseClass : "";
			
			if( sGUI.outline.showParamsRetType & 2 )
				title = l.identifier ~ " (" ~ l.parameterString ~ ")" ~ arrayString ~ typeDisplayName;
			else
				title = l.identifier ~ arrayString ~ typeDisplayName;
		}
		else if( t & ( D_VARIABLE | D_ALIAS | D_TYPEDEF | D_ENUMMEMBER ) )
		{
			title = l.identifier ~ typeDisplayName;
		}
		else if( t & D_ENUM )
		{
			title = l.identifier ~ ( ( l.typeIdentifier.length ) ? typeDisplayName : null );
		}
		else if( t & D_CLASS )
		{
			title = l.identifier ~ ( ( l.baseClass.length ) ? " : " ~ l.baseClass : null );
		}
		else if( t & D_IMPORT )
		{
			title = ( l.typeIdentifier.length ? l.typeIdentifier ~ " = " : "" ) ~ l.identifier ~
					( l.parameterString.length ? " : " ~ l.parameterString : "" );
		}
		else if( t & D_MIXIN )
		{
			title = ( l.typeIdentifier.length ? l.typeIdentifier ~ " : " : "" ) ~
						l.identifier ~ ( l.parameterString.length ? " !(" ~ l.parameterString ~ ")" : "" );
		}
		else if( t & D_ANONYMOUSBLOCK )
		{
			title = "-anonymous-";
		}
		else
		{
			title = l.identifier ;
		}

		treeitem.setText( title );

		Image image= getTreeIcon( l );;
		treeitem.setImage( image );
	}


    private void enumTreeItems( void delegate( TreeItem ) func )
	{
		// nested funciton
		void _do( TreeItem[] tis, void delegate( TreeItem ) func )
		{
			foreach( TreeItem ti; tis ) 
			{
				func( ti );
				_do( ti.getItems(), func );
			}
		}
		
		_do( tree.getItems(), func );
    }

    private void expandAll(){ foreach( TreeItem item; tree.getItems() ) item.setExpanded(true); }	

    private void updateTree(){ enumTreeItems( &updateTreeItem ); }

    private void onTreeDefaultSelection( Event e )
	{
		TreeItem item = cast(TreeItem) e.item;
		if( item && item.getData() )
		{
			CAnalyzerTreeNode l = cast(CAnalyzerTreeNode) item.getData();
			scope wc = new WaitCursor( sShell );

			sGUI.editor.setSelectionAndNotify( editItem );
			editItem.scintilla.forceFocus();
			editItem.scintilla.call( 2234, l.lineNumber - 1 );
			editItem.setSelection( l.lineNumber - 1 );
			
			//sGUI.outputPanel.appendString( l.path ~ " " ~ std.string.toString( l.lineNumber ) ~ "\n" );
			//sGUI.packageExp.openFile( l.path, l.lineNumber - 1, true );
		}
    }

    private int _reparseThread()
    {
		// nested functions
		void _populate(Object o){
			OLItem pthis = cast(OLItem)o;
			//if( sAutoComplete.fileParser is null )
				pthis.populateTree( pthis.editItem.fileParser );
			//else
			//	pthis.populateTree( sAutoComplete.fileParser );
		}

		void _update(Object o) {
			OLItem pthis = cast(OLItem)o;
			pthis.updateTree();
		}

		void _expand(Object o) {
			OLItem pthis = cast(OLItem)o;
			pthis.expandAll();
		}

		// code start here

		tree.getDisplay().asyncExec(this, &_populate);
		tree.getDisplay().asyncExec(this, &_update);
		tree.getDisplay().asyncExec(this, &_expand);
		
		return 0;
    }

	
    // parse the file and populate the tree, in the background thread
	public void reparse()
	{
		tree.removeAll();
		Thread thread = new Thread( &_reparseThread );
		thread.start();
	}

	public void toggleStates()
	{
		if(toggle++ % 2 == 0)
		{
			foreach( TreeItem item; tree.getItems() )
				item.setExpanded(false);
		}
		else
			expandAll();
	}

	public void sortStates()
	{
		bSort = !bSort;
		_reparseThread();
	}
}

class OutLine : ViewForm, ITranslatable, EditorListener
{
	private import poseidon.controller.imagecombo;

	
    private CTabItem 	tabItem;
    private CLabel 		label;
    private ToolItem 	tiClose;
    private Composite 	container;
    private StackLayout theLayout;
	private ImageCombo 	quickFind;
	private int			searchIndex;

    private OLItem[] 	items;
	private OLItem 		activeItem;

    private int 		showParamsRetType = 3;
	private ToolItem 	tiPR, tiRefresh;


    this(Composite parent, int style) {
	super(parent, DWT.NONE);
		
	CTabFolder folder = cast(CTabFolder)parent;
	if(folder) {
	    tabItem = new CTabItem(folder, DWT.NONE);
	    tabItem.setImage(Globals.getImage("outline_co"));
	    tabItem.setControl(this);
	}
	initGUI();
	updateI18N();
    }
	
    private void initGUI() 
    {
	// Create the CLabel for the top left, which will have an image and text
	label = new CLabel(this, DWT.NONE);
	label.setImage(Globals.getImage("outline_co"));
	label.setAlignment(DWT.LEFT);
	this.setTopLeft(label);
	// Create the downward-pointing arrow to display the menu
	// and set it as the top center
	ToolBar tbCenter = new ToolBar(this, DWT.FLAT);
	this.setTopCenter(tbCenter);

	Composite co = new Composite( this, DWT.NONE );
	GridLayout g = new GridLayout( );
    g.numColumns=1;
	g.marginWidth = 0;
	g.marginHeight = 0;
	g.horizontalSpacing = 0;
	g.verticalSpacing = 1;
	co.setLayout( g );
	
	with( quickFind = new ImageCombo( co, DWT.READ_ONLY ) )
	{
		setLayoutData( new GridData(GridData.FILL_HORIZONTAL ));// | GridData.FILL_VERTICAL));
		scope font = new Font( getDisplay, "Arial", 8, DWT.NONE );
		setFont( font );
		select(0);
		pack();
		setEnabled( false );
		setVisibleItemCount( 4 );
		//handleEvent( null, DWT.Modify, &onCobBuildToolHSU );
	}

	class modifyListener : ModifyListener
	{
		public void modifyText( ModifyEvent e )
		{
			if( !quickFind.isDropped() ) onCheckImageComboModify();
		}
	}

	class keyboardListener_text : KeyAdapter
	{
		public void keyPressed( KeyEvent e )
		{
			if( !quickFind.isDropped() )
			{
				if( e.keyCode == DWT.CR || e.keyCode == DWT.F3 || e.keyCode == DWT.KEYPAD_CR )
				{
					if( !searchTreeItem() ) 
						quickFind.dropDown( true );
					else
					{
						TreeItem[] tis = activeItem.tree.getSelection();
						if( tis.length > 0 )
						{
							CAnalyzerTreeNode t = cast(CAnalyzerTreeNode) tis[0].getData();
							if( t !is null ) sGUI.packageExp.openFile( sGUI.editor.getSelectedFileName(), t.lineNumber - 1, true );
						}
					}
				}
			}
		}
	}

	class keyboardListener_table : KeyAdapter
	{
		public void keyPressed( KeyEvent e )
		{
			if( e.keyCode == DWT.CR ) onCheckImageComboModify();
		}
	}		

	/*
	class mouseListener : MouseListener
	{
		public void mouseDown( MouseEvent e ){ quickFind.text.selectAll(); }
		public void mouseUp( MouseEvent e ){}
		public void mouseDoubleClick( MouseEvent e ){}
	}
	*/

	class sListener : SelectionListener
	{
		public void widgetDefaultSelected( SelectionEvent e ){}
		public void widgetSelected( SelectionEvent e ){	searchTreeItem();	}
	}	

	quickFind.addModifyListener( new modifyListener );
	quickFind.addSelectionListener( new sListener );	
	quickFind.text.addKeyListener( new keyboardListener_text );
	quickFind.table.addKeyListener( new keyboardListener_table );
	//quickFind.text.addMouseListener( new mouseListener );



	container = new Composite( co, DWT.NONE );
	container.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL));
	
	theLayout = new StackLayout();
	container.setLayout(theLayout);
		
	this.setContent( co );

	tiRefresh = new ToolItem(tbCenter, DWT.PUSH);
    tiRefresh.setToolTipText( Globals.getTranslation( "pop.refresh" ) );
	tiRefresh.setImage(Globals.getImage("refresh"));
	tiRefresh.setDisabledImage(Globals.getImage("refresh_dis"));
	tiRefresh.setEnabled = false;
	tiRefresh.handleEvent(this, DWT.Selection, delegate void(Event e)
	{
		EditItem ei = sGUI.editor.getSelectedEditItemHSU();
		if( ei !is null )
		{
			if( !sGUI.packageExp.isFileInProjects( ei.getFileName() ) ) return;
			
			OutLine pthis = cast(OutLine) e.cData;
			
			OLItem item = pthis.findOLItem( ei );
			if( item !is null ) // item.reparse();
			{
				try
				{
					if( !std.string.icmp( std.path.getExt( ei.getFileName ), "d" ) ||
						!std.string.icmp( std.path.getExt( ei.getFileName ), "di" ) ) ei.updateFileParser( ei.getFileName );
						
					item.tree.setEnabled( true );
				}
				catch( Exception e ) 
				{ 
					/* too many errors */ 
					sGUI.outputPanel.setForeColor( 0, 0, 0 );
					sGUI.outputPanel.appendString( "File[ " ~ ei.getFileName ~ " ] Parsed Failure.\n" );
					item.tree.setEnabled( false );
				}
				item.reparse();
				pthis.resetImageCombo( ei );
			}
			else
			{
				//MessageBox.showMessage( "No Find " ~ ei.getFileName  );
			}
		}
	});


	ToolItem tiCollapse = new ToolItem(tbCenter, DWT.PUSH);
	tiCollapse.setImage(Globals.getImage("collapseall"));
	tiCollapse.setToolTipText( Globals.getTranslation("pkgx.collapse") );
		
	static int toggle = 0;
	tiCollapse.handleEvent(this, DWT.Selection, delegate void(Event e){
	    OutLine pthis = cast(OutLine)e.cData;
		if(pthis.activeItem is null)
			return;
		pthis.activeItem.toggleStates();
	});

	ToolItem tiSort = new ToolItem( tbCenter, DWT.PUSH );
	tiSort.setImage(Globals.getImage("sort"));
	tiSort.setToolTipText( Globals.getTranslation( "outln.sort" ) );
	tiSort.handleEvent( this, DWT.Selection, delegate void( Event e ){
	    OutLine pthis = cast(OutLine)e.cData;
		if( pthis.activeItem is null ) return;
		pthis.activeItem.sortStates();
	});	

	
	//MessageBox.showMessage( std.string.toString( showParamsRetType ) );
	
	tiPR = new ToolItem(tbCenter, DWT.PUSH);
	tiPR.setToolTipText( "Show Params And Return Type" );
	tiPR.setImage(Globals.getImage( "show_all" ));
	tiPR.handleEvent(this, DWT.Selection, delegate void(Event e)
	{
		OutLine pthis = cast(OutLine)e.cData;

		if( pthis.showParamsRetType == 0 )
			pthis.showParamsRetType = 3;
		else
			pthis.showParamsRetType -= 1;

		switch( pthis.showParamsRetType )
		{
			case 0:
				pthis.tiPR.setImage(Globals.getImage("show_none"));
				pthis.tiPR.setToolTipText( "Hide Params And Return Type" );
				break;
			case 1:
				pthis.tiPR.setImage(Globals.getImage("show_rettype"));
				pthis.tiPR.setToolTipText( Globals.getTranslation( "outln.showrettype" ) );
				break;
			case 2:
				pthis.tiPR.setImage(Globals.getImage("show_params"));
				pthis.tiPR.setToolTipText( Globals.getTranslation( "outln.showparameter" ) );
				break;
			default:
				pthis.tiPR.setImage(Globals.getImage("show_all"));
				pthis.tiPR.setToolTipText( "Show Params And Return Type" );
				break;
		}
			
		if( pthis.activeItem ) pthis.activeItem.updateTree();
	});

	// Create the close button and set it as the top right
	ToolBar tbClose = new ToolBar(this, DWT.FLAT);
	tiClose = new ToolItem(tbClose, DWT.PUSH);
	tiClose.setImage(Globals.getImage("close_view"));
	tiClose.handleSelection(null, delegate void(SelectionEvent e){
	    sGUI.toggleSiderTabState();
	});

	this.setTopRight(tbClose);
    }

    void updateI18N()
    {
		if( tabItem ) tabItem.setText( Globals.getTranslation("outln.title") );
		label.setText( Globals.getTranslation("outln.title") );
		tiClose.setToolTipText( Globals.getTranslation("CLOSE") );
    }

    // the editor events
    public void onActiveEditItemChanged(EditorEvent e) 
    {
		EditItem ei = e.item;
		assert( ei );

		OLItem item = findOLItem(ei);
		bool newly = false;
		if( item is null )
		{
			newly = true;
			dwt.widgets.treeitem.Tree tree = new dwt.widgets.treeitem.Tree( container, DWT.NONE );
			scope font = new Font( getDisplay, "Arial", 8, DWT.NONE );
			tree.setFont( font );
			
			item = new OLItem( tree, ei );
			items ~= item;
		}

		theLayout.topControl = item.tree;
		container.layout();
		activeItem = item;

		
		if( newly )
		{
			item.reparse();
			if( sAutoComplete.fileParser is null ) item.tree.setEnabled( false );
		}

		if( ei.fileParser )
		{
			if( !item.tree.getEnabled )
			{
				item.tree.setEnabled( true );
				item.reparse();
			}
		}

		resetImageCombo( ei );
		if( sGUI.packageExp.isFileInProjects( ei.getFileName() ) ) tiRefresh.setEnabled = true;else  tiRefresh.setEnabled = false;
    }
	
    public void onAllEditItemClosed( EditorEvent e )
	{ 
		quickFind.removeAll();
		quickFind.setEnabled( false );
		container.layout();
	}


	// 儲存及載入時重新分析
	// 載入時 -> edititem.onSavePointChanged() ->  outline.onEditItemSaveStateChanged() -> outline.onActiveEditItemChanged()
	// 儲存時 -> edititem.onSavePointChanged() ->  outline.onEditItemSaveStateChanged() -> edititem.updateFileParser ->
	// item.reparse();
	
	public void onEditItemSaveStateChanged( EditorEvent e )
	{
		EditItem ei = e.item;
		// only do reparse when save/load, not modify
		if( ei.modified() ) return;
		
		if( !sGUI.packageExp.isFileInProjects( ei.getFileName() ) && !sAutoComplete.getParserFromProjectParser( ei.getFileName() ) ) return;

		OLItem item = findOLItem( ei );

		if( Globals.useCodeCompletion || Globals.showOnlyClassBrowser )
		{
			if( item ) // item.reparse();
			{
				try
				{
					if( !std.string.icmp( std.path.getExt( ei.getFileName ), "d" ) ||
						!std.string.icmp( std.path.getExt( ei.getFileName ), "di" ) ) ei.updateFileParser( ei.getFileName );
						
					item.tree.setEnabled( true );
				}
				catch( Exception e ) 
				{ 
					/* too many errors */ 
					sGUI.outputPanel.setForeColor( 0, 0, 0 );
					sGUI.outputPanel.appendString( "File[ " ~ ei.getFileName ~ " ] Parsed Failure.\n" );
					item.tree.setEnabled( false );
				}
				item.reparse();
				resetImageCombo( ei );
			}
			else
			{
				if( sAutoComplete )
				{
					char[] filePath = ei.getFileName;
					CAnalyzerTreeNode fileParser = sAutoComplete.getParserFromProjectParser( filePath );
					
					if( fileParser !is null )
					{
						if( sGUI.packageExp.isFileInProjects( ei.getFileName() ) )
						{
							sGUI.outputPanel.setForeColor( 0, 0, 0 );
							sGUI.outputPanel.appendString( "File[ " ~ filePath ~ " ] Parser Loaded.\n" );
							ei.fileParser = fileParser;
						}
						else
						{
							sGUI.outputPanel.setForeColor( 0, 0, 0 );
							sGUI.outputPanel.appendString( "Extra File[ " ~ filePath ~ " ] Parser Loaded.\n" );
							ei.fileParser = fileParser;
							ei.scintilla.setReadOnly( true );
						}
						return;
					}
					else
					{
						// 有可能一開始parser錯誤,也有可能新增
						sGUI.outputPanel.appendString( "File[ " ~ filePath ~ " ] Parser Loaded Failure.\n" );
						return;
					}
				}
			}
		}
    }

	public void singleFileToProjectFile( EditItem ei )
	{
		OLItem item = findOLItem( ei );
		if( item !is null )
		{
			char[] filePath = ei.getFileName;
			CAnalyzerTreeNode fileParser = sAutoComplete.getParserFromProjectParser( filePath );
				
			if( fileParser !is null )
			{
				sGUI.outputPanel.setForeColor( 0, 0, 0 );
				sGUI.outputPanel.appendString( "File[ " ~ filePath ~ " ] Parser Loaded.\n" );

				ei.fileParser = fileParser;
				item.tree.setEnabled( true );
				item.reparse();

				if( sGUI.editor.getSelectedFileName() == filePath )
				{
					removeAllImageComboItems();
					quickFind.setEnabled( true );
					onCheckImageComboModify();
					tiRefresh.setEnabled = true;
				}			
			}
		}		
	}
	
	
    public void onEditItemDisposed( EditorEvent e )
	{
		EditItem ei = e.item;
		assert(ei);
		OLItem item = findOLItem(ei);
		//theLayout.topControl = null;
		//activeItem = null;
		TVector!(OLItem).remove( items, item );
		item.dispose();
    }

    // find an Outline Item by EditItem
    private OLItem findOLItem( EditItem ei )
	{
		foreach( OLItem item; items )
			if( item.editItem is ei ) return item;

		return null;
    }

	// For ImageCombo( quickFind ) function

	private void removeAllImageComboItems() // No clean imageCombo's text
	{
		int count = quickFind.getItemCount();
		quickFind.remove( 0, count - 1);		
	}

	/*
	private void resetImageCombo()
	{
		if( sAutoComplete.fileParser is null )
		{
			removeAllImageComboItems();
			quickFind.select( -1 );
			quickFind.setEnabled( false );
		}
		else
		{
			removeAllImageComboItems();
			quickFind.setEnabled( true );
			onCheckImageComboModify();
		}
	}
	*/

	private void resetImageCombo( EditItem ei )
	{
		if( ei.fileParser is null )
		{
			removeAllImageComboItems();
			quickFind.select( -1 );
			quickFind.setEnabled( false );
		}
		else
		{
			removeAllImageComboItems();
			quickFind.setEnabled( true );
			onCheckImageComboModify();
		}
	}	

	private void onCheckImageComboModify()
	{
		char[] text = std.string.strip( quickFind.getText() );
		int textLength = text.length;
		removeAllImageComboItems();
		searchIndex = 0;
		
		if( textLength > 0 )
		{
			if( activeItem )
			{
				CAnalyzerTreeNode[] tempLeafs;
				
				void _getItemAnalyzerNode( TreeItem _tr )
				{
					CAnalyzerTreeNode t = cast(CAnalyzerTreeNode) _tr.getData;

					if( textLength <= t.identifier.length )
						if( t.identifier[0..textLength] == text ) tempLeafs ~= t;//quickFind.add( t.identifier, getTreeIcon( t ) );
						
					foreach( TreeItem tr; _tr.getItems() )
						_getItemAnalyzerNode( tr );
				}

				foreach( TreeItem tr; activeItem.tree.getItems() )
					_getItemAnalyzerNode( tr );

				scope CIdentSort!( CAnalyzerTreeNode ) sortIdentList = new CIdentSort!( CAnalyzerTreeNode )( tempLeafs );
				tempLeafs = sortIdentList.pop();

				foreach( CAnalyzerTreeNode t; tempLeafs )
					quickFind.add( t.identifier, getTreeIcon( t ) );
			}
		}
	}

	private bool searchTreeItem()
	{
		TreeItem[] treeItems = activeItem.treeItems;
		char[] text = std.string.strip( quickFind.getText() );
		bool bFound = false;

		if( treeItems.length && text.length )
		{
			int i;
			
			void _findItem()
			{
				for( i = searchIndex; i < treeItems.length; i ++ )
				{
					CAnalyzerTreeNode t = cast(CAnalyzerTreeNode) treeItems[i].getData();
					
					if( text == t.identifier )
					{
						TreeItem[] tItems;
						tItems ~= treeItems[i];
						activeItem.tree.setSelection( tItems );
						searchIndex = i + 1;
						bFound = true;
						return;
					}
				}
			}

			_findItem();
			 
			if( i >= treeItems.length )
			{
				searchIndex = 0;
				_findItem();
			}
		}
		else
			return true; 
		

		return bFound;
		/+
		sGUI.outputPanel.appendLine( "Items = " ~ std.string.toString( treeItems.length ) ~ "   " ~
		"searchIndex = " ~ std.string.toString( searchIndex ) );+/
		
	}
}


