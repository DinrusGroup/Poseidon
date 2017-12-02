module poseidon.controller.packageexplorer;
 

private
{
	import poseidon.model.project;
	import dwt.all;
	import poseidon.controller.editor;
	import poseidon.model.misc;
	import poseidon.controller.property.prjproperty;
	import poseidon.model.navcache;
	import poseidon.globals; 
	import poseidon.util.miscutil;
	import poseidon.util.waitcursor;
	import poseidon.controller.gui;
	import poseidon.controller.actionmanager;
	import poseidon.controller.dialog.generaldialog;
	import poseidon.i18n.itranslatable;
	import poseidon.controller.edititem;
	import poseidon.controller.menumanager;
}


class ItemInfo
{
	enum
	{	// TreeItem Type
		FILE = 0x01,
		FOLDER = 0x02,
		ROOT = 0x04,
		TITLE = 0x08,
	}
	
	private uint mask = 0;
	private char[] _fullPath; 
	Project		project;	
	TreeItem 	treeitem;
	
	this( uint mask, char[] fullPath, Project project, TreeItem treeitem )
	{
		checkBits( mask );
		this.mask = mask;
		this._fullPath = fullPath;
		this.project = project;
		this.treeitem = treeitem;
	}
	
	boolean isFile(){ return mask & FILE; }
	boolean isRoot(){ return mask & ROOT; }
	boolean isTitle(){ return mask & TITLE; }
	boolean isPackage() { return mask & FOLDER; }

	private void checkBits( uint bits ){ assert( bits & ( FILE | ROOT | FOLDER  | TITLE ) );	}
	char[] getFileName(){ return _fullPath; }
	Project getProject(){ return project; }
}


class CFindAllFile
{
private:
	import std.file;
	
	char[][]	allFiles;
	char[][]	patterns;

	void search( char[] dirName )
	{
		char[][] files;

		files = listdir( dirName );

		foreach( char[] s; files )
		{
			char[] fullPath = std.path.join( dirName, s );
			if( std.file.isdir( fullPath ) ) 
				search( fullPath );
			else
			{
				if( patterns.length >= 1 )
				{
					foreach( char[] ext; patterns )
					{
						if( std.string.tolower( std.path.getExt( fullPath ) ) == ext )
						{
							allFiles ~= fullPath;
							break;
						}
					}
				}
				else
					allFiles ~= fullPath;
			}
		}
	}	
	
public:
	this( char[] dirName, char[] _pattern = null )
	{	
		try
		{
			if( _pattern.length )
			{
				char[][] splitPattern = std.string.split( _pattern, ";" );
				foreach( char[] s; splitPattern )
					patterns ~= std.string.tolower( std.path.getExt( s ) );
			}
			
			if( std.file.isdir( dirName ) ) search( dirName );
		}
		catch( Exception e )
		{
			throw new Exception( "The dirName -> " ~ dirName ~" isn't exist!!" );
		}
	}

	this( char[] dirName, char[][] _patterns )
	{	
		if( _patterns.length )
		{
			foreach( char[] s; _patterns )
				patterns ~= std.string.tolower( std.path.getExt( s ) );
		}

		try
		{
			if( std.file.isdir( dirName ) ) search( dirName );
		}
		catch( Exception e )
		{
			throw new Exception( "The dirName -> " ~ dirName ~" isn't exist!!" );
		}
	}	

	~this(){ allFiles.length = 0; }
	char[][] getFiles(){ return allFiles; }
	void	 reset(){ allFiles.length = patterns.length = 0; }
}


class CFileNode
{
private:
	char[]		name, fullPathName, fullDir;
	CFileNode[]	leafs;
	//CFileNode	root;

public:
	//~this(){ leafs.length = 0; }

	~this(){ foreach( CFileNode n; leafs ) delete n; }

	
	CFileNode addLeaf( char[] _name, char[] _fullName = null, char[] _fullDir = null )
	{
		CFileNode leaf = new CFileNode;

		leaf.name 			= _name;
		leaf.fullPathName 	= _fullName;
		leaf.fullDir		= _fullDir;
		//leaf.root 			= this;
		leafs 				~= leaf;
		return leaf;
	}

	void sort()
	{
		if( leafs.length )
		{
			CFileNode[] tempLeafs;
			
			foreach( CFileNode n; leafs )
				if( !n.fullPathName ) tempLeafs ~= n;

			foreach( CFileNode n; leafs )
				if( n.fullPathName ) tempLeafs ~= n;

			leafs = tempLeafs;
		}
	}
}


class PackageExplorer : ViewForm, ITranslatable, EditorListener
{
	private import std.file;
	private import std.path;
	private import std.stream;
	private import std.zip;
	private import poseidon.intellisense.search;
	private import poseidon.util.fileutil;
	private import poseidon.intellisense.autocomplete;
	private import poseidon.controller.property.rescompilerpage;
		
	private Project[] 	prjArray;
	private Project		activePrj;

	private bool[]	 	bUntitle;
	
	Editor editor;
	Tree 	tree;

	// static properties
	private static PackageExplorer  pthis;
	
	boolean linkEditor = true;

	private Menu	ResfileItemMenu;
	private Menu	fileItemMenu;
	private Menu	packItemMenu;
	private Menu	rootItemMenu;
	
	private CTabItem	tabItem;
	private CLabel		label;
	private ToolItem	tiCollapse, tiLinkEditor, tiClose;

	MenuItem rootAddItem, folderAddItem, fileRemoveItem;
	
	this( Composite parent, Editor editor )
	{
		super(parent, DWT.NONE);
		this.editor = editor;
		pthis = this;

		
		CTabFolder folder = cast(CTabFolder) parent;
		if( folder )
		{
			tabItem = new CTabItem(folder, DWT.NONE);
			tabItem.setImage( Globals.getImage( "package" ) );
			tabItem.setControl( this );
		}
		initGUI();
		updateI18N();

		// listen to the navcache event
		class NavListener : Listener
		{
			public void handleEvent( Event e )
			{
				if( e && e.cData )
				{
					NavPoint pt = cast(NavPoint) e.cData;
					/**
					 * go to navigation point
					 */
					pthis.openFile( pt.filename, pt.line );		
				}
			}
		}
		sActionMan.navCache.addListener( new NavListener() );

	}
	
	private boolean _validateString( char[] str ){ return MiscUtil.isValidFileName( str );	}
	
	private void initGUI()
	{
		label = new CLabel( this, DWT.NONE );
		ToolBar tbar = new ToolBar(this, DWT.FLAT);
		tree = new Tree(this, DWT.NONE); // DWT.CHECK
		scope font = new Font( getDisplay, "Arial", 8, DWT.NORMAL );
		tree.setFont( font );

		this.setTopLeft(label);
		this.setTopRight(tbar);
		this.setContent(tree);
		
		// CLabel
		label.setImage(Globals.getImage("package"));
		
		// ToolBar
		tbar.setLayoutData(new GridData(GridData.FILL_VERTICAL | GridData.HORIZONTAL_ALIGN_END | GridData.END));
		tiCollapse = new ToolItem(tbar, DWT.PUSH);
		tiCollapse.setImage(Globals.getImage("collapseall"));

	
		
		static int toggle = 0;
		tiCollapse.handleEvent(tree, DWT.Selection, delegate(Event e){
			Tree tree = cast(Tree)e.cData;
			TreeItem[] tis = tree.getItems();
			if(toggle++ % 2 == 0){
				foreach(TreeItem item; tis){
					item.setExpanded(false);
				} 
			}else{
				foreach(TreeItem item; tis){
					item.setExpanded(true);
					TreeItem[] subtis = item.getItems();
					foreach(TreeItem ti; subtis)
						ti.setExpanded(false);
				}
			}
		});
		tiLinkEditor = new ToolItem(tbar, DWT.CHECK);
		tiLinkEditor.setImage(Globals.getImage("synced"));
		tiLinkEditor.setSelection(linkEditor);
		tiLinkEditor.handleEvent(this, DWT.Selection, delegate(Event e){
			PackageExplorer pThis = cast(PackageExplorer)e.cData;
			ToolItem item = cast(ToolItem)e.widget;
			assert(item);
			pThis.linkEditor = item.getSelection();  
		});
		tiClose = new ToolItem(tbar, DWT.NONE);
		tiClose.setImage(Globals.getImage("close_view"));
		tiClose.handleEvent(this, DWT.Selection, delegate(Event e){ 
			sGUI.toggleSiderTabState();
		});

	
		
		// Tree
		tree.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.FILL_VERTICAL));
		tree.handleEvent(null, DWT.MouseUp, &onTreeMouseUp);
		tree.handleEvent(null, DWT.DefaultSelection, &onTreeDefaultSelection);
		tree.handleEvent(null, DWT.Selection, &onTreeSelection);
		tree.handleEvent(null, DWT.KeyDown, &onTreeKeyDown);
		initContextMenu();
	}
	
	private void activeProject( Project prj )
	{ 
		this.activePrj = prj; 
		if( prj )
			sShell.setText( prj.projectName ~ " - Poseidon" );
		else
			sShell.setText( "Poseidon" );
	}
	
	public Project activeProject()
	{ 
		if( prjArray.length == 0 ) activePrj = null;
		return activePrj;
	}
	
	public void addProject( Project prj )
	{
		assert( prj );

		scope wc = new WaitCursor( sShell );
		
		prjArray ~= prj;
		
		activeProject = prj;

		Globals.recentDir = prj.projectDir;

		TreeItem root = new TreeItem( tree, DWT.NONE );		
		root.setText( prj.projectName );
		root.setImage( Globals.getImage( "project_obj" ) );
		root.setData( new ItemInfo( ItemInfo.ROOT, prj.projectDir, prj, root ) );
		scope font = new Font( getDisplay, "Verdana", 9, DWT.BOLD );
		root.setFont( font );		

		char[][] allDirs;
		sGUI.statusBar.setString( "Project Loading....... " );
		enumDir( prj, prj.projectDir, root, allDirs );

		auto IParser = new ImportComplete( prj.projectDir ~ prj.scINIImportPath ~ prj.projectIncludePaths );
		sAutoComplete.projectImportParsers[prj.projectDir] = IParser;

		//sAutoComplete.importParser.addDirs( prj.projectDir , allDirs );

		root.setExpanded( true );
		TreeItem[] ti; 
		ti ~= root;
		// this will set active project as well
		tree.setSelection( ti );
		
		
		// update the recent project cache		
		Globals.addRecentPrj( prj );
		sGUI.menuMan.buildRecentPrjMenu();

		// do parse project here
		if( Globals.useCodeCompletion || Globals.showOnlyClassBrowser )
			sActionMan.actionParseProject( prj.projectFiles ~ prj.projectInterfaces );
		else
			sGUI.statusBar.setString( "Project Loaded Done. " );
	}
	

	public void closeProject()
	{	
		// the nested function
		void _enumItems( TreeItem item, Editor editor )
		{
			TreeItem[] tis = item.getItems();
			foreach(TreeItem ti; tis) {
				_enumItems(ti, editor);
			}
			item.dispose();
		}
		
		
		TreeItem root = findCurPrjItem();
		if( root is null ) return;
		
		/**
		 * try to close all opened files in this project, if user choose 
		 * cancel when prompt to save dirty document, stop the close operation 
		 * and escape
		 */
			
		ItemInfo info = cast(ItemInfo)root.getData();
		Project prj = info.project;
		
		if( !editor.closeProject(prj))
			return;
		
		/**
		 * I am wondering ???
		 * when I only dispose the root TreeItem, can its chirldren disposed automatically ?
		 */
		_enumItems( root, editor );
		
		sAutoComplete.deleteProjectParser( prj.projectName );
		sAutoComplete.deleteImportParser( prj.projectDir );

		TVector!(Project).remove(prjArray, prj);

		sShell.setText( "Poseidon" );
	}

	// 關閉所有的專案
	public void closeAllProject() 
	{	
		// the nested function( 關閉所有的treeItem節點 )
		void _enumItems( TreeItem item, Editor editor )
		{
			TreeItem[] tis = item.getItems();
			foreach( TreeItem ti; tis )
				_enumItems(ti, editor);

			item.dispose();
		}
		
		
		TreeItem[] treeItems = tree.getItems();

		if( !treeItems.length ) return;
		
		/**
		 * try to close all opened files in this project, if user choose 
		 * cancel when prompt to save dirty document, stop the close operation 
		 * and escape
		 */

		foreach( TreeItem t; treeItems )
		{
			if( t )
			{
				ItemInfo info = cast(ItemInfo) t.getData();
				Project prj = info.project;

				if( !editor.closeProject( prj ) ) continue;
				_enumItems( t, editor );
				sAutoComplete.deleteProjectParser( prj.projectName );
				sAutoComplete.deleteImportParser( prj.projectDir );
				TVector!( Project ).remove( prjArray, prj );
			}
		}
			
		sShell.setText( "Poseidon" );
	}	


	private void enumDir( Project prj, char[] currentDir, TreeItem rootItem, inout char[][] allDirs )
	{

		TreeItem headItem, item;
		CFileNode treeStartNode;	

		//-----------------------nested function start---------------------
		CFileNode _lookFileNode( CFileNode node, char[] dirName, char[] _fullDir )
		{
			foreach( CFileNode n; node.leafs )
			{
				if( n.name == dirName ) return n;
			}

			return node.addLeaf( dirName, null, _fullDir );
		}

		void _sortFileNode( CFileNode node )
		{
			foreach( CFileNode n; node.leafs )
				_sortFileNode( n );

			node.sort();
		}

		void _createFileNodes( char[][] files, CFileNode headNode )
		{
			// 分解
			foreach( char[] s; files )
			{
				char[] fileName = std.path.getBaseName( s );

				// 把目錄名稱分解 例如d:\path\foo.bat -> d:\path -> d: 及 path
				char[][] decomposeFile = std.string.split( std.path.getDirName( s ), "\\" );

				CFileNode currentNode = headNode;

				char[] fullDir;
				foreach( char[] d; decomposeFile )
				{
					// 找尋是否有此節點,有就把檔案放到該節點下;否則就新建
					fullDir ~= ( d ~ "\\" );
					currentNode = _lookFileNode( currentNode, d, fullDir );
				}
				currentNode.addLeaf( fileName, s ); // 加入檔案
			}
		}

		// 取得
		CFileNode _lookNodeWithChild( CFileNode node )
		{
			if( node.leafs.length == 1 )
			{
				char[][] prjSplitedDir = std.string.split( prj.projectDir, "\\" );

				if( node.leafs.length == 1 )
				{
					foreach( char[] s; prjSplitedDir )
					{
						if( node.leafs[0].name == s )
						{
							node = node.leafs[0];
							if( node.leafs.length != 1 ) break;
						}
					}
				}
			}

			return node;

			/+
			if( node.leafs.length )
			{
				if( node.leafs.length > 1 ) 
					return node;
				else
					return _lookNodeWithChild( node.leafs[0] );
			}

			return node;
			+/
		}			

		// Create TreeItem
		void _addTreeItem( CFileNode node, TreeItem treeItem, Image img = null )
		{
			// 有子節點
			if( node.leafs.length )
			{
				if( node != treeStartNode )
				{
					TreeItem t;
					t = new TreeItem( treeItem, DWT.NONE );
					t.setText( node.name );
					t.setImage(Globals.getImage( "module_obj" ));
					scope f = new Font( getDisplay, "Courier New", 8, DWT.BOLD );
					t.setFont( f );	
					t.setData( new ItemInfo( ItemInfo.FOLDER, node.fullDir, prj, t ));
					t.getParentItem().setExpanded( true );

					for( int i = 0; i < node.leafs.length; ++ i )
						_addTreeItem( node.leafs[i], t, img );
				}
				else
				{
					for( int i = 0; i < node.leafs.length; ++ i )
						_addTreeItem( node.leafs[i], headItem, img );//sourceTree );
				}
			}
			else
			{
				if( node.fullPathName )
				{
					TreeItem t = new TreeItem( treeItem, DWT.NONE );
					t.setText( node.name );
					ItemInfo info = new ItemInfo( ItemInfo.FILE, node.fullPathName, prj, t );
					
					t.setData( info );

					if( img is null )
						t.setImage( Globals.getImageByExt( std.path.getExt( node.name ) ) );
					else
						t.setImage( img );

					editor.updateItemInfo( node.fullPathName, info );
					t.getParentItem().setExpanded( true );
				}
			}
		}
		// ---------------------nested function end------------------------
		

		TreeItem sourceTree = new TreeItem( rootItem, DWT.NONE );
		sourceTree.setText( "Sources" );
		sourceTree.setImage(Globals.getImage( "repository" ));
		sourceTree.setData( new ItemInfo( ItemInfo.TITLE, prj.projectDir, prj, sourceTree ));
		scope font = new Font( getDisplay, "Verdana", 8, DWT.BOLD );
		sourceTree.setFont( font );	

		TreeItem interfaceTree = new TreeItem( rootItem, DWT.NONE );
		interfaceTree.setText( "Interfaces" );
		interfaceTree.setImage(Globals.getImage( "repository" ));
		interfaceTree.setData( new ItemInfo( ItemInfo.TITLE, prj.projectDir, prj, interfaceTree ));
		interfaceTree.setFont( font );		

		TreeItem resourceTree = new TreeItem( rootItem, DWT.NONE );
		resourceTree.setText( "Resources" );
		resourceTree.setImage( Globals.getImage( "repository" ) );
		resourceTree.setData( new ItemInfo( ItemInfo.TITLE, prj.projectDir, prj, resourceTree ));
		resourceTree.setFont( font );

		TreeItem othersDMDTree = new TreeItem( rootItem, DWT.NONE );
		othersDMDTree.setText( "Others(DMD)" );
		othersDMDTree.setImage( Globals.getImage( "repository" ) );
		othersDMDTree.setData( new ItemInfo( ItemInfo.TITLE, prj.projectDir, prj, othersDMDTree ));
		othersDMDTree.setFont( font );	
		
		TreeItem othersTree = new TreeItem( rootItem, DWT.NONE );
		othersTree.setText( "Others" );
		othersTree.setImage( Globals.getImage( "repository" ) );
		othersTree.setData( new ItemInfo( ItemInfo.TITLE, prj.projectDir, prj, othersTree ));
		othersTree.setFont( font );			
			
		char[][] sourceFiles, interfaceFiles, resourcefiles, othersDMDFiles, othersFiles;
			
		scope CCharsSort!( char[] ) sortList = new CCharsSort!( char[] )( prj.projectFiles );
		char[][] sortedFiles = sortList.pop();

		foreach( char[] s; sortedFiles )
			if( std.string.tolower( std.path.getExt( s ) ) == "d" )	sourceFiles ~= s;

		sortList.clear();
		sortList.push( prj.projectInterfaces );
		sortList.sort();
		sortedFiles = sortList.pop();
		foreach( char[] s; sortedFiles )
			if( std.string.tolower( std.path.getExt( s ) ) == "di" ) interfaceFiles ~= s;
			
		sortList.clear();
		sortList.push( prj.projectResources );
		sortList.sort();
		sortedFiles = sortList.pop();
		foreach( char[] s; sortedFiles )
			if( std.string.tolower( std.path.getExt( s ) ) == "res" ) resourcefiles ~= s;

		sortList.clear();
		sortList.push( prj.projectOthersDMD );
		sortList.sort();
		othersDMDFiles = sortList.pop();

		sortList.clear();
		sortList.push( prj.projectOthers );
		sortList.sort();
		othersFiles = sortList.pop();

		
		if( sourceFiles.length )
		{
			scope sourceNode = new CFileNode;//rootNode.addLeaf( "Source", null );
			_createFileNodes( sourceFiles, sourceNode );
			_sortFileNode( sourceNode );
			treeStartNode = _lookNodeWithChild( sourceNode );
			headItem = sourceTree;
			_addTreeItem( treeStartNode, headItem );
		}

		if( interfaceFiles.length )
		{
			scope interfaceNode = new CFileNode;//rootNode.addLeaf( "Interface", null );
			_createFileNodes( interfaceFiles, interfaceNode );
			_sortFileNode( interfaceNode );
			treeStartNode = _lookNodeWithChild( interfaceNode );
			headItem = interfaceTree;
			_addTreeItem( treeStartNode, headItem );
		}

		if( resourcefiles.length )
		{
			scope resourceNode = new CFileNode;//rootNode.addLeaf( "Interface", null );
			_createFileNodes( resourcefiles, resourceNode );
			_sortFileNode( resourceNode );
			treeStartNode = _lookNodeWithChild( resourceNode );
			headItem = resourceTree;
			_addTreeItem( treeStartNode, headItem );
		}

		if( othersDMDFiles.length )
		{
			scope othersDMDNode = new CFileNode;
			_createFileNodes( othersDMDFiles, othersDMDNode );
			_sortFileNode( othersDMDNode );
			treeStartNode = _lookNodeWithChild( othersDMDNode );
			headItem = othersDMDTree;
			_addTreeItem( treeStartNode, headItem, Globals.getImage( "file_addcompiler_obj" ) );
		}	

		if( othersFiles.length )
		{
			scope othersNode = new CFileNode;
			_createFileNodes( othersFiles, othersNode );
			_sortFileNode( othersNode );
			treeStartNode = _lookNodeWithChild( othersNode );
			headItem = othersTree;
			_addTreeItem( treeStartNode, headItem );
		}		
	}

	// 取得TreeItem節點的最上層的節點( 一般用於找出Project TreeItem節點 )
	private TreeItem findCurPrjItem()
	{
		TreeItem[] tis = tree.getSelection();
		if( !tis.length ) return null;
		
		TreeItem item = tis[0];
		TreeItem root = item;

		while( ( item = item.getParentItem() ) !is null ) 
			root = item;

		return root;
	}

	private char[] getTitleName( ItemInfo _info )
	{
		char[] titleName;
		TreeItem tItem = _info.treeitem;

		if( _info.isRoot )
			return null;
		else if( _info.isTitle )
			titleName = tItem.getText();
		else
		{
			while( !_info.isTitle && tItem !is null ) 
			{
				tItem = tItem.getParentItem();
				_info = cast(ItemInfo) tItem.getData();
			}

			if( _info.isTitle ) titleName = tItem.getText();
		}

		return titleName;
	}
	

	// 找出所有樹節點中符合檔案名稱的檔案
	private TreeItem findTreeItemByFullPath( TreeItem tItem, char[] fullPath )
	{
		TreeItem activeItem;
		
		void _find( TreeItem tr )
		{
			foreach( TreeItem _tr; tr.getItems )
			{
				if( activeItem is null )
				{
					ItemInfo INFO = cast(ItemInfo) _tr.getData();
					if( INFO.getFileName == fullPath )
					{
						activeItem = _tr;
						return;
					}
					else
						_find( _tr );
				}
				else
					return;
			}
		}

		_find( tItem );
		return activeItem;
	}

	// 清除特定樹節點下的所有樹節點
	private bool cleanAllLeafsUnderTreeItem( TreeItem root )
	{
		if( root is null ) return false;
			
		TreeItem[] tis = root.getItems();
		foreach( TreeItem item; tis )
			item.dispose();

		return true;
	}
	

	public Project[] getProjects(){ return prjArray; }
	
	public int getProjectCount(){ return prjArray.length; }

	public char[] getActiveProjectName(){ if( activePrj ) return activePrj.projectName;else return null; }

	public char[] getActiveProjectDir(){ if( activePrj ) return activePrj.projectDir;else return null; }

	public char[][] getActiveProjectFiles()
	{ 
		if( activePrj ) 
			return activePrj.projectFiles ~ activePrj.projectInterfaces;
		else
			return null; 
	}

	// return the files belong the project	 
	public char[][] getProjectFiles( Project prj, bool dOnly = false )
	{
		char[][] _projectFiles;

		if( prj )
		{
			if( dOnly )
			{
				foreach( char[] s; prj.projectFiles )
					if( std.string.tolower( std.path.getExt( s ) ) == "d" ) _projectFiles ~= s;
			}
			else
				_projectFiles ~= ( prj.projectFiles ~ prj.projectInterfaces );
		}

		return _projectFiles;
	}
	
	// return all files in the opened projects
	public char[][] getProjectsFiles()
	{
		char[][] allProjectsFiles;

		foreach( Project p; prjArray )
			allProjectsFiles ~= getProjectFiles( p );

		return allProjectsFiles;
	}

	public char[][] getAllFilesInProjectDir( char[] dir, char[][] exts )
	{
		scope t = new CFindAllFile( dir, exts );
		
		return t.getFiles();
	}
	

	public void compressProject()
	{
		if( !activePrj ) return;

		char[][] activePrjFiles = activePrj.projectFiles ~ activePrj.projectInterfaces ~ activePrj.projectResources;

		scope dlg = new EditDlg( getShell(), 0, ["*.d","*.*"], Globals.getTranslation( "diag.title5" ), activePrj.projectDir, 2 );
		dlg.setImageString( "zip" );
		
		char[] outputZipDir = std.string.strip( dlg.open() );
		char[] zipName;
		char[] zipDir = outputZipDir;
		
		if( !outputZipDir.length ) return;//outputZipDir = activePrj.projectDir;

		try
		{
			if( std.file.isdir( outputZipDir ) )
			{
				if( std.file.exists( outputZipDir ) ) zipName = std.path.join( outputZipDir, activePrj.projectName ~ ".zip" );
			}
		}
		catch
		{
			MessageBox.showMessage( "Wrong Path Name!! ->" ~ outputZipDir );
			return;
		}

		try
		{
			int CompressType = 1;//Globals.explorerType;
			
			ZipArchive comp = new ZipArchive();
			ArchiveMember am1;

			if( dlg.zipAll )
			{
				scope t = new CFindAllFile( activePrj.projectDir );
				activePrjFiles = t.getFiles();
				CompressType = 0;
			}
				

			foreach( char[] s; activePrjFiles )
			{
				am1 = new ArchiveMember();

				if( CompressType )
					am1.name = s;
				else
					am1.name = std.string.replace( s, activePrj.projectDir ~"\\", "" );
						
				am1.expandedData = cast(ubyte[])std.file.read( s );
				am1.compressionMethod = 8;
				comp.addMember(am1);
			}

			std.file.write( zipName, comp.build() );
			sGUI.outputPanel.appendString( "Project[ " ~ activePrj.projectName ~ "] Compress OK!!\n" );
		}catch
		{
			sGUI.outputPanel.appendString( "Project[ " ~ activePrj.projectName ~ "] Compress Error!!\n" );
		}
	}
	
	public ItemInfo getSelection() {
		TreeItem[] tis = tree.getSelection();
		if(tis){
			return cast(ItemInfo)tis[0].getData();
		}
		return null;
	}
	
	
	private void initContextMenu() {
		Menu newMenu = new Menu(getShell(), DWT.DROP_DOWN);

		MenuItem subitem = new MenuItem( newMenu, DWT.PUSH );
		subitem.setData(LANG_ID, "FOLDER");
		subitem.handleSelection(null, &onNewFolder);

		subitem = new MenuItem(newMenu, DWT.PUSH);
		subitem.setData(LANG_ID, "FILE");
		subitem.handleSelection(null, &onNewFile);			

		
		// Root item menu
		rootItemMenu = new Menu(getShell());

		MenuItem item = new MenuItem(rootItemMenu, DWT.CASCADE);
		item.setData(LANG_ID, "NEW");
		item.setMenu(newMenu);

		rootAddItem = new MenuItem( rootItemMenu, DWT.PUSH );
		rootAddItem.setData(LANG_ID, "ADD");
		rootAddItem.handleSelection( null, &onAddFile );
		
		new MenuItem(rootItemMenu, DWT.SEPARATOR);	
		
		item = new MenuItem(rootItemMenu, DWT.PUSH);
		item.setData(LANG_ID, "PROPERTY");
		item.handleEvent(null, DWT.Selection, delegate(Event e){
			sActionMan.actionShowPrjProperty(e);
		});
		item = new MenuItem(rootItemMenu, DWT.PUSH);
		item.setData(LANG_ID, "CLOSE");
		item.handleEvent(null, DWT.Selection, delegate(Event e){
			sActionMan.actionCloseProject(e);
		});
		item = new MenuItem(rootItemMenu, DWT.SEPARATOR);
		item = new MenuItem(rootItemMenu, DWT.PUSH);
		item.setData(LANG_ID, "REFRESH");
		item.handleEvent(null, DWT.Selection, delegate(Event e){
			sActionMan.actionRefreshProject(e);
		});

		item = new MenuItem(rootItemMenu, DWT.SEPARATOR);
		item = new MenuItem(rootItemMenu, DWT.PUSH);
		item.setData(LANG_ID,"prj.compress");
		item.handleEvent(null, DWT.Selection, delegate(Event e){
			sActionMan.actionCompressProject(e);
		});
		
		// Folder item menu
		packItemMenu = new Menu(getShell());
		item = new MenuItem(packItemMenu, DWT.CASCADE);
		item.setData(LANG_ID, "NEW");
		
		folderAddItem = new MenuItem( packItemMenu, DWT.PUSH );
		folderAddItem.setData(LANG_ID, "ADD");
		folderAddItem.handleSelection( null, &onAddFile );
		
		
		// the sub menu of "new" must be duplicated and can't use the one used by 
		// project menu
		// or it will be disposed twice and get exception
		newMenu = new Menu(getShell(), DWT.DROP_DOWN);
		subitem = new MenuItem(newMenu, DWT.PUSH);
		subitem.setData(LANG_ID, "FOLDER");
		subitem.handleSelection(null, &onNewFolder);
		subitem = new MenuItem(newMenu, DWT.PUSH);
		subitem.setData(LANG_ID, "FILE");
		subitem.handleSelection(null, &onNewFile);
		item.setMenu(newMenu);
		
		// File item menu
		fileItemMenu = new Menu(getShell());
		item = new MenuItem(fileItemMenu, DWT.PUSH);
		item.setData(LANG_ID, "OPEN");
		item.handleEvent(this, DWT.Selection, delegate(Event e) {
			PackageExplorer pThis = cast(PackageExplorer)e.cData;
			ItemInfo info = pThis.getSelection();
			if(info && info.isFile()){
				scope wc = new WaitCursor(pThis.tree);
				pThis.editor.openFile(info.getFileName, info, -1, true);
			} 
		});

		fileRemoveItem = new MenuItem( fileItemMenu, DWT.PUSH );
		fileRemoveItem.setData( LANG_ID, "REMOVE" );
		fileRemoveItem.handleEvent( this, DWT.Selection, delegate(Event e )
		{
			PackageExplorer pThis = cast(PackageExplorer) e.cData;
			onRemoveFile( pThis );
		});
		new MenuItem( fileItemMenu, DWT.SEPARATOR );	


		item = new MenuItem(fileItemMenu, DWT.PUSH);
		item.setData( LANG_ID, "DELETE" );
		item.handleEvent( this, DWT.Selection, &onDelete );


		item = new MenuItem(fileItemMenu, DWT.PUSH);
		item.setData(LANG_ID, "RENAME");
		item.handleEvent( null, DWT.Selection, &onRename );



		// Resource File item menu
		ResfileItemMenu = new Menu(getShell());
		item = new MenuItem(ResfileItemMenu, DWT.PUSH);
		item.setData(LANG_ID, "OPEN");
		item.handleEvent(this, DWT.Selection, delegate(Event e) {
			PackageExplorer pThis = cast(PackageExplorer)e.cData;
			ItemInfo info = pThis.getSelection();
			if(info && info.isFile()){
				scope wc = new WaitCursor(pThis.tree);
				pThis.editor.openFile(info.getFileName, info, -1, true);
			} 
		});

		fileRemoveItem = new MenuItem( ResfileItemMenu, DWT.PUSH );
		fileRemoveItem.setData( LANG_ID, "REMOVE" );
		fileRemoveItem.handleEvent( this, DWT.Selection, delegate(Event e )
		{
			PackageExplorer pThis = cast(PackageExplorer) e.cData;
			onRemoveFile( pThis );
		});

		new MenuItem( ResfileItemMenu, DWT.SEPARATOR );	

		item = new MenuItem(ResfileItemMenu, DWT.PUSH);
		item.setData( LANG_ID, "DELETE" );
		item.handleEvent( this, DWT.Selection, &onDelete );

		item = new MenuItem(ResfileItemMenu, DWT.PUSH);
		item.setData(LANG_ID, "RENAME");
		item.handleEvent( null, DWT.Selection, &onRename );

		new MenuItem( ResfileItemMenu, DWT.SEPARATOR );

		item = new MenuItem(ResfileItemMenu, DWT.PUSH);
		item.setText( "Resource Compiler" );
		//item.setEnabled = false;
		//item.setData( LANG_ID, "DELETE" );
		item.handleEvent( this, DWT.Selection, delegate(Event e )
		{
			PackageExplorer pThis = cast(PackageExplorer) e.cData;
			ItemInfo info = pThis.getSelection();
			
			auto dlg = new CResourceCompilerDialog( pthis.getShell(), Globals.getTranslation( "pp2.rc" ), info.getFileName );
			char[] command = dlg.open();

			sActionMan.actionRCCompile( info.getFileName, command );
		});
	}
	
	
	/**
	 * check to see whether a file is in the opened projects
	 */
	public ItemInfo isFileInProjects(char[][] files) {
		// nested function
		boolean isMatch(char[][] _files, char[] tomatch) {
			foreach(char[] name; _files){
				if(name == tomatch)
					return true;
			}
			return false;
		}
		
		// nested function
		ItemInfo findInfo(TreeItem[] treeitems, char[][] files){
			TreeItem[] dirItems;
			foreach(TreeItem item; treeitems){
				ItemInfo info = cast(ItemInfo)item.getData();
				Util.trace(info.getFileName);
				if(info.isFile()) {
					if(isMatch(files, info.getFileName))
						return info;
				}else
					dirItems ~= item;
			}
			foreach(TreeItem item; dirItems) {
				TreeItem[] items = item.getItems();
				ItemInfo info = findInfo(items, files);
				if(info) 
					return info;
			}
			return null;
		} // end of findInfo(...)
		
		TreeItem[] tis = tree.getItems();
		return findInfo(tis, files);
	}

	public bool isFileInProjects( char[] file )
	{
		foreach( char[] f; getProjectsFiles() )
			if( std.string.tolower( file ) == std.string.tolower( f ) ) return true;

		return false;
	}	
	
	/**
	 * check to see whether a directory is already opened by some project
	 */
	public boolean isProjectOpened(char[] path) {
		foreach(Project prj; prjArray) {
			if(prj.projectDir == path)
				return true;
		}
		return false;
	}
	
	/**
	 * if there is a project file, load it. Otherwise, load the dir as plain project
	 */
	public void loadProject(char[] dir) {
		if(isProjectOpened(dir)) {
			MessageBox.showMessage(Globals.getTranslation("mb.prj_already_opened"), Globals.getTranslation("INFORMATION"), 
				getShell(), DWT.ICON_WARNING);
			return;
		}
		
		Project prj = Project.loadProject(dir);
		if(prj)
			addProject(prj);
	}


	public void createUntitleFile()
	{
		int i;
		char[] untitledFileName;
		
		for( i = 0; i < bUntitle.length; ++ i )
		{
			if( !bUntitle[i] )
			{
				bUntitle[i] = true;
				break;
			}
		}

		if( i == bUntitle.length ) bUntitle ~= true;
		
		untitledFileName = "Untitled" ~ std.string.toString( i );

		try{
			// create UTF8 file as default, file auto closed
			scope File file = new File( untitledFileName, FileMode.OutNew );
			scope EndianStream f = new EndianStream( file, std.system.endian );
			f.writeBOM( BOM.UTF8 );
		}catch(Exception e)
		{
			MessageBox.showMessage( e.toString() );
			return;
		}		

		ItemInfo info;

		editor.openFile( untitledFileName, null, -1, true );
	}
	
	/**
	 * Params:
	 *	filename =  may be fullname or short name, and may be not in any opened projects
	 *	line = zero based line number
	 */
	public boolean openFile(char[] filename, int line, bool focus = true) {
	
		char[][] files;
		if(std.path.isabs(filename))
			files ~= filename;
		else{
			foreach(Project prj; prjArray) {
				files ~= std.path.join(prj.projectDir, filename);
			}
		}
		/**
		 * Is the files in one of the projects
		 */
		ItemInfo info = isFileInProjects(files);
		if(info) 
			filename = info.getFileName();

		return editor.openFile(filename, info, line, focus);
	}
	
	private void openFile(char[] filename, ItemInfo iteminfo) {
		editor.openFile(filename, iteminfo, -1, true);	
	}
	
	public void onActiveEditItemChanged(EditorEvent e) {
		EditItem ei = e.item;

		assert(ei);
			
		ItemInfo data = ei.iteminfo;
		if(data !is null){
			activeProject = data.project;
			if(linkEditor)
				setSelection(data);
		}
	}

	public void onAllEditItemClosed(EditorEvent e){}
	public void onEditItemSaveStateChanged(EditorEvent e){}
	public void onEditItemDisposed(EditorEvent e){}

	
	public void onNewFile( SelectionEvent e )
	{
		
		AskStringDlg dlg = new AskStringDlg(getShell(), Globals.getTranslation("ask_file_name"), null);
		dlg.setValidateDelegate(&_validateString);
		dlg.setText(Globals.getTranslation("new_file"));
		char[] filename = dlg.open();

		if( filename.length > 0 )
		{
			filename = std.string.strip( filename );
			if( !filename.length ) return;
				
			ItemInfo info = getSelection();
			char[] path = info.getFileName();
			char[] fullname = std.path.join( path, filename );
			if(std.file.exists(fullname)){
				MessageBox.showMessage(Globals.getTranslation("mb.file_exists") ~ "\n" ~ fullname, Globals.getTranslation("INFORMATION"), getShell(), DWT.ICON_INFORMATION);
				return;
			}
			
			try{
				// create UTF8 file as default, file auto closed
				scope file = new File(fullname, FileMode.OutNew);
				scope f = new EndianStream(file, std.system.endian);
				f.writeBOM(BOM.UTF8);
			}catch(Exception e) {
				MessageBox.showMessage(e.toString());
				return;
			}

			Project prj = info.getProject();
			char[] ext = std.string.tolower( std.path.getExt( filename ) );
			
			switch( ext )
			{
				case "d":
					prj.projectFiles ~= fullname;
					break;
				case "di":
					prj.projectInterfaces ~= fullname;
					break;
				case "res":
					prj.projectResources ~= fullname;
					break;
				default:
					char[] titleName = getTitleName( info );
					if( titleName == "Others(DMD)" )
						prj.projectOthersDMD ~= fullname;
					else
						prj.projectOthers ~= fullname;
						
					break;
			}

			TreeItem root = findCurPrjItem();
			if( cleanAllLeafsUnderTreeItem( root ) )
			{
				char[][] dummy;
				enumDir( prj, prj.projectDir, root, dummy );
				sAutoComplete.addSingleFileParser( fullname, prj.projectName );

				TreeItem activeItem = findTreeItemByFullPath( root, fullname );
				if( activeItem !is null ) editor.openFile( fullname, cast(ItemInfo) activeItem.getData(), -1, true );
				prj.save();
			}
			else 
				return;
		}
	}
	
	private void onNewFolder(SelectionEvent e) {
		AskStringDlg dlg = new AskStringDlg(getShell(), Globals.getTranslation("ask_folder_name"), null);
		dlg.setValidateDelegate(&_validateString);
		dlg.setText(Globals.getTranslation("new_folder"));
		char[] name = dlg.open();
		name = std.string.strip(name);
		if(name.length > 0){
			ItemInfo info = getSelection();
			char[] path = info.getFileName();
			char[] fullname = std.path.join(path, name);
			// check the existance of dir
 			if(!std.file.exists(fullname)){
				try{
					std.file.mkdir(fullname);
				}catch(Exception e){
					MessageBox.showMessage(e.toString());
					return;
				}
			}
			
			// the folder is created or exists already here
			
			TreeItem ti = new TreeItem(info.treeitem, DWT.NONE);
			ti.setText(name);
			ti.setImage(Globals.getImage("module_obj"));
			scope font = new Font( getDisplay, "Courier New", 8, DWT.BOLD );
			ti.setFont( font );				
			ti.setData(new ItemInfo(ItemInfo.FOLDER, fullname, info.project, ti));
			TreeItem[] tis; 
			tis ~= ti;
			tree.setSelection(tis);
		}
	}

	private void onAddFile( SelectionEvent e )
	{
		scope dlg = new EditDlg( getShell(), 1, ["*.d;*.di;*.di;*.res","*.d","*.di","*.res","*.*"], Globals.getTranslation( "diag.title0" ) );
		char[] filename = dlg.open();

		// if no Poject, exit!!
		ItemInfo info = getSelection();
		Project prj = info.getProject();
		if( !prj ) return;

		// if filename = "", exit!
		filename = std.string.strip( filename );
		if( !filename.length ) return;

		char[][] files;
		files = std.string.split( filename, ";" );
		if( !files.length ) return;

		foreach( char[] singleFile; files )
		{
			// if file isn't exist, exit!!
			if( !std.file.exists( singleFile ) ) return;

			//if extName isn't D, exit
			char[] ext = std.string.tolower( std.path.getExt( singleFile ) );
			//if( prj.isFiltered( ext ) ) return;

			// if filename is exist in project, exit!!
			switch( ext )
			{
				case "d":
					foreach( char[] s; prj.projectFiles )
						if( !std.string.icmp( s, singleFile ) ) return;

					prj.projectFiles ~= singleFile;
					break;
				case "di":
					foreach( char[] s; prj.projectInterfaces )
						if( !std.string.icmp( s, singleFile ) ) return;

					prj.projectInterfaces ~= singleFile;
					break;
				case "res":
					foreach( char[] s; prj.projectResources )
						if( !std.string.icmp( s, singleFile ) ) return;

					prj.projectResources ~= singleFile;
					break;
				default:
					if( getTitleName( info ) == "Others(DMD)" )
					{
						foreach( char[] s; prj.projectOthersDMD )
							if( !std.string.icmp( s, singleFile ) ) return;

						prj.projectOthersDMD ~= singleFile;
					}
					else
					{
						foreach( char[] s; prj.projectOthers )
							if( !std.string.icmp( s, singleFile ) ) return;

						prj.projectOthers ~= singleFile;
					}
					
					break;
			}

			if( ext == "d" || ext == "di" ) sAutoComplete.addSingleFileParser( singleFile, prj.projectName );
		}

		

		TreeItem root = findCurPrjItem();
		if( cleanAllLeafsUnderTreeItem( root ) )
		{
			char[][] dummy;
			enumDir( prj, prj.projectDir, root, dummy );
			//sAutoComplete.addSingleFileParser( filename, prj.projectName );

			prj.save();
			
			foreach( char[] s; files )
			{
				bool bFocus = isInExplorerOthers( s );

				TreeItem activeItem = findTreeItemByFullPath( root, s );
				if( activeItem !is null )
				{
					editor.openFile( s, cast(ItemInfo) activeItem.getData(), -1, bFocus );
					return;
				}
			}
		}		
	}


	private void onRename( Event e )
	{
		// nested function
		boolean _validate( char[] str )
		{
			if( str.length == 0 ) return false;
			return MiscUtil.isValidFileName( str );
		}

		ItemInfo info = getSelection();
		Project prj = info.getProject();
		char[] 	ori_filename = info.getFileName();
		char[] 	ori_ext = std.string.tolower( std.path.getExt( ori_filename ) );		
		char[] 	iniStr = std.path.getName( std.path.getBaseName( ori_filename ) );

		AskStringDlg dlg = new AskStringDlg( sShell, Globals.getTranslation( "ask_file_name" ), iniStr );
		dlg.setText( Globals.getTranslation( "RENAME" ) );
		dlg.setValidateDelegate( &_validate) ;
		char[] result = dlg.open();
		
		if( result.length )
		{
			result = result ~ "." ~ ori_ext;
			if( std.file.exists( result ) )
			{
				MessageBox.showMessage( result ~ " is existed!" );
				return;
			}

			/+
			// Check EXT
			if( info.project.isFiltered( std.path.getExt( result ) ) )
			{
				MessageBox.showMessage( "Wrong Extension!!" );
				return;
			}
			+/
			
			char[] path = std.path.getDirName( info.getFileName() );
			path = std.path.join( path, result );
			try
			{
				std.file.rename( info.getFileName(), path );
			}
			catch( Exception e )
			{
				MessageBox.showMessage( e.toString() );
				return;
			}

			switch( ori_ext )
			{
				case "d":
					for( int i = 0; i < prj.projectFiles.length; i ++ )
						if( prj.projectFiles[i] == ori_filename ) prj.projectFiles[i] = path;
					break;
				case "di":
					for( int i = 0; i < prj.projectInterfaces.length; i ++ )
						if( prj.projectInterfaces[i] == ori_filename ) prj.projectInterfaces[i] = path;
					break;
				case "res":
					for( int i = 0; i < prj.projectResources.length; i ++ )
						if( prj.projectResources[i] == ori_filename ) prj.projectResources[i] = path;
					break;
				default:
					if( getTitleName( info ) == "Others(DMD)" )
					{
						for( int i = 0; i < prj.projectOthersDMD.length; i ++ )
							if( prj.projectOthersDMD[i] == ori_filename ) prj.projectOthersDMD[i] = path;
					}
					else
					{
						for( int i = 0; i < prj.projectOthers.length; i ++ )
							if( prj.projectOthers[i] == ori_filename ) prj.projectOthers[i] = path;
					}
					break;				
			}			
					
			if( ori_filename == std.path.join( prj.projectDir, prj.mainFile ) ) prj.mainFile = result;
					
			prj.save();

			info._fullPath = path;
			info.treeitem.setText( result );
			if( ori_ext == "d" || ori_ext == "di" )
				sAutoComplete.renSingleFileParser( ori_filename, result, prj.projectName );
			editor.rename( info.getFileName(), path );
		}
	}
	

	private void onRemoveFile( PackageExplorer pThis )
	{
		ItemInfo info = pThis.getSelection();
		
		if( info )
		{
			if( info.isFile() )
			{
				scope wc = new WaitCursor(pThis.tree);

				if( pThis.editor.closeFile( info.getFileName ) )
				{
					char[] filename = info.getFileName();
					Project prj = info.getProject();

					sAutoComplete.removeSingleFileParser( filename, prj.projectName );

					/+
					if( !sAutoComplete.removeSingleFileParser( filename, prj.projectName ) )
						MessageBox.showMessage( "Error Remove " ~ filename ~ " Parser!!" );
					+/

					char[][] tempPrjFiles;
					switch( std.string.tolower( std.path.getExt( filename ) ) )
					{
						case "d":
							foreach( char[] s; prj.projectFiles )
								if( s != filename ) tempPrjFiles ~= s;

							prj.projectFiles = tempPrjFiles;
							break;
						case "di":
							foreach( char[] s; prj.projectInterfaces )
								if( s != filename ) tempPrjFiles ~= s;

							prj.projectInterfaces = tempPrjFiles;
							break;
						case "res":
							foreach( char[] s; prj.projectResources )
								if( s != filename ) tempPrjFiles ~= s;

							prj.projectResources = tempPrjFiles;
							break;
						default:
							char[] titleName = getTitleName( info );

							if( titleName == "Others(DMD)" )
							{
								foreach( char[] s; prj.projectOthersDMD )
									if( s != filename ) tempPrjFiles ~= s;
								prj.projectOthersDMD = tempPrjFiles;
							}
							else if( titleName.length )
							{
								foreach( char[] s; prj.projectOthers )
									if( s != filename ) tempPrjFiles ~= s;
								prj.projectOthers = tempPrjFiles;
							}
							break;
					}

					prj.save();
						
					void _reDrawTree( TreeItem activeItem )
					{
						ItemInfo INFO = cast(ItemInfo) activeItem.getData();
						if( INFO.isTitle ) return;
						
						TreeItem father = activeItem.getParentItem();
								
						if( father )
						{
							if( father.getParentItem() )
							{
								if( activeItem.getItemCount() == 0 )
								{
									delete INFO;
									activeItem.dispose();
									_reDrawTree( father );
								}
							}
							else
							{
								if( activeItem.getItemCount() == 0 ) activeItem.dispose();
							}
						}
						else
							return;
					}

					_reDrawTree( info.treeitem );
				}
			}
		} 
	}

	private void onDelete( Event e )
	{
		
		PackageExplorer pThis = cast(PackageExplorer) e.cData;
		ItemInfo info = pThis.getSelection();
			
		if( info )
		{
			if( info.isFile() )
			{
				char[] fileFullPath = info.getFileName;
				
				if( poseidon.util.fileutil.delFileToTrashCan( fileFullPath ) )
				{
					if( !std.file.exists( fileFullPath ) ) onRemoveFile( pThis );
				}
				/+
				if( DWT.OK == MessageBox.showMessage(Globals.getTranslation("mb.del_file"),
					Globals.getTranslation("QUESTION"), pThis.getShell(), DWT.OK|DWT.CANCEL|DWT.ICON_QUESTION ) )
				{
					try
					{
						onRemoveFile( pThis );
						version( Windows )
						{
							if( !poseidon.util.fileutil.delFileToTrashCan( fileFullPath,false ) ) MessageBox.showMessage( "File isn't exist!!!" );
						}
						else
						{
							if( std.file.isfile( fileFullPath ) )
								std.file.remove( fileFullPath );
							else
								MessageBox.showMessage( "File isn't exist!!!" );
						}
					}
					catch( Exception e )
					{
						MessageBox.showMessage( e.toString() );
					}
				}
				+/
			}
		} 
	}

	
	private void onTreeDefaultSelection( Event e )
	{
		TreeItem item = cast(TreeItem) e.item;
		ItemInfo data = cast(ItemInfo) item.getData();
		assert( data );
		
		activeProject = data.project;
		
		if( !data.isFile() )
			item.setExpanded( !item.getExpanded() );
		else
		{
			scope wc = new WaitCursor( getShell() );
			//if( sActionMan.actionResTool( data.getFileName ) ) return;
			
			char[] path = data.getFileName();
			editor.openFile( path, data, -1, true );
		}
	}

	private void onTreeKeyDown( Event e ){ if( e.keyCode == DWT.F5 ) refreshProject(); }
	
	private void onTreeSelection( Event e )
	{
		TreeItem item = cast(TreeItem) e.item;
		ItemInfo data = cast(ItemInfo) item.getData();
		assert( data );
		
		activeProject = data.project;
		
		if( data.isFile() && linkEditor )
		{
			scope wc = new WaitCursor( getShell( ));
			
			char[] path = data.getFileName();
			if( editor.isFileOpened( path ) )
			{
				editor.openFile( path, null, -1, false );
				EditItem ei = editor.getSelectedEditItemHSU();
				// set the focus back to the tree
				tree.forceFocus();
			}
		}
	}
	

	private void onTreeMouseUp( Event e )
	{
		if( e.button == 3 ) 
		{
			ItemInfo info = getSelection();
			if( info )
			{
				Point pt = tree.toDisplay( e.x, e.y );
				if( info.isRoot() )
				{
					rootAddItem.setEnabled( true );
					rootItemMenu.setLocation( pt );
					rootItemMenu.setVisible( true );
				}
				else if( info.isFile() )
				{
					char[] ext = std.string.tolower( std.path.getExt( info._fullPath ) );
					
					if( ext == "rc" )
					{
						fileRemoveItem.setEnabled( true );
						ResfileItemMenu.setLocation( pt );
						ResfileItemMenu.setVisible( true );
					}
					else
					{
						fileRemoveItem.setEnabled( true );
						fileItemMenu.setLocation( pt );
						fileItemMenu.setVisible( true );
					}
				}
				else if( info.isPackage() || info.isTitle() )
				{
					folderAddItem.setEnabled( true );
					packItemMenu.setLocation( pt );
					packItemMenu.setVisible( true );
				}
			}
		}
	}


	public void refreshProject()
	{
		TreeItem root = findCurPrjItem();
		if( cleanAllLeafsUnderTreeItem( root ) )
		{
			Project prj = ( cast(ItemInfo) root.getData() ).project;

			char[][] dummy;
			enumDir( prj, prj.projectDir, root, dummy );
			root.setExpanded( true );
			root.setText( prj.projectName );
			TreeItem[] ti;
			ti ~= root;
			// this will set active project as well
			tree.setSelection( ti );
		}
	}


	public void refreshAllProject()
	{
		foreach( TreeItem t; tree.getItems() )
		{
			ItemInfo info = cast(ItemInfo ) t.getData();
			if( info.isRoot )
			{
				TreeItem root = t;
				if( cleanAllLeafsUnderTreeItem( root ) )
				{
					Project prj = ( cast(ItemInfo) root.getData() ).project;

					char[][] dummy;
					enumDir( prj, prj.projectDir, root, dummy );
					root.setExpanded( true );
					root.setText( prj.projectName );
					TreeItem[] ti;
					ti ~= root;
					// this will set active project as well
					tree.setSelection( ti );
				}
			}
		}
	}

	
	public void setSelection( ItemInfo item )
	{
		if( item !is null )
		{
			TreeItem[] tis; 
			tis ~= item.treeitem;
			tree.setSelection( tis );
		}
	}
	
	public void showProjectProperty()
	{
		if( activeProject is null )	return;
		
		scope dlg = new PrjProperty( getShell(), activeProject );
		if( dlg.open() == "OK" )
		{
			scope wc = new WaitCursor( getShell() );
			refreshProject();
		}
	}

	void updateI18N()
	{
		if( tabItem )
		{
			tabItem.setText( Globals.getTranslation("pkgx.title") );
			tabItem.setImage( Globals.getImage("package") );
		}
		label.setText( Globals.getTranslation("pkgx.title") );
		label.setImage( Globals.getImage("package") );

		tiCollapse.setToolTipText( Globals.getTranslation("pkgx.collapse") );
		tiLinkEditor.setToolTipText( Globals.getTranslation("pkgx.link") );
		tiClose.setToolTipText(Globals.getTranslation("CLOSE"));

		MenuManager.updateMenuI18N(ResfileItemMenu);
		MenuManager.updateMenuI18N(fileItemMenu);
		MenuManager.updateMenuI18N(packItemMenu);
		MenuManager.updateMenuI18N(rootItemMenu);
	}

	public bool isInExplorerOthers( char[] fileName )
	{
		char[] ext = std.string.tolower( std.path.getExt( fileName ) );
		if( !ext.length ) ext = fileName;
		
		if( ext != "d" && ext != "di" )
			if( !poseidon.util.miscutil.MiscUtil.inArray!(char[])( ext, Globals.SplitedExplorerFilter ) )
				return false;

		return true;
	}
}