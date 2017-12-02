module poseidon.controller.filelist;


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
}

class FileList : ViewForm, ITranslatable, EditorListener
{
    private CLabel 		label;
    private ToolItem 	tiClose, tiShowFullPath;
	private Tree		tree;
	private SashForm	_parent;

	private int			bShowFullPath;
    private bool		bMinView;
	private int[]		lastSashWeights = [80, 20];;
	

    this( Composite parent, int style )
	{
		super( parent, DWT.DEFAULT );
		_parent = cast(SashForm) parent;

		bMinView = true;
		setParentWeights();
		_parent.handleEvent(null, DWT.Resize, &onSashResize);		

		initGUI();
		updateI18N();
    }
	
    private void initGUI() 
    {
		// Create the CLabel for the top left, which will have an image and text
		label = new CLabel(this, DWT.NONE);
		label.setImage( Globals.getImage( "copy" )) ;
		label.setAlignment(DWT.LEFT);
		this.setTopLeft(label);

		// Create the close button and set it as the top right
		ToolBar tbClose = new ToolBar(this, DWT.FLAT);

		with( new ToolItem( tbClose, DWT.CHECK ) )
		{
			//setData(LANG_ID, "show_params");
			//setToolTipText( Globals.getTranslation( "outln.showparameter" ) );
			setToolTipText( Globals.getTranslation( "fl.tooltip_show" ) );
			setImage(Globals.getImage("show_params"));
			setSelection( bShowFullPath );
			handleEvent(this, DWT.Selection, &showFullPath );
		}

		tiClose = new ToolItem(tbClose, DWT.PUSH);
		tiClose.setImage(Globals.getImage("max_view"));
		tiClose.handleEvent(null, DWT.Selection, &toggleMaximized );
		this.setTopRight( tbClose );

		tree = new Tree( this, DWT.NONE );
		scope font = new Font( getDisplay, "Courier New", 8, DWT.NONE );
		tree.setFont( font );		
		this.setContent( tree );
		tree.handleEvent( null, DWT.Selection, &onTreeSelection );
    }
	

    void updateI18N()
    {
		label.setText( Globals.getTranslation( "fl.title" ) );
		tiClose.setToolTipText( Globals.getTranslation( "CLOSE" ) );
    }

	private void onTreeSelection( Event e )
	{
		TreeItem item = cast(TreeItem) e.item;
		assert( item );

		EditItem ei = cast(EditItem) item.getData();
		
		scope wc = new WaitCursor( getShell( ));
		char[] path = ei.getFileName();
		if( sGUI.editor.isFileOpened( path ) )
		{
			sGUI.editor.openFile( path, null, -1, false );
			// set the focus back to the tree
			tree.forceFocus();
		}
	}

	public void onActiveEditItemChanged( EditorEvent e )
	{
		EditItem ei = e.item;
		assert(ei);
		
		// 找尋是否有重複
		foreach( TreeItem tr; tree.getItems() )
		{
			EditItem _ei = cast(EditItem) tr.getData();
			if( ei == _ei )
			{
				TreeItem[] tis;
				tis ~= tr;
				tree.setSelection( tis );				
				return;
			}
		}

		//增加樹節點
		TreeItem tItem = new TreeItem( tree, DWT.NONE );
		if( bShowFullPath )
			tItem.setText( ei.getFileName() );
		else
			tItem.setText( std.path.getBaseName( ei.getFileName() ) );

		if( sGUI.packageExp.isFileInProjects( ei.getFileName() ) )
			tItem.setImage( Globals.images["project_file"] );
		else
			tItem.setImage( Globals.images["file_obj"] );
		
		tItem.setData( ei );

		TreeItem[] tis;
		tis ~= tItem;
		tree.setSelection( tis );
	}

	public void changeImage( char[] fileName )
	{
		foreach( TreeItem tr; tree.getItems() )
		{
			EditItem _ei = cast(EditItem) tr.getData();
			if( _ei.getFileName() == fileName )
			{
				tr.setImage( Globals.images["project_file"] );
				return;
			}
		}
	}

	public void onAllEditItemClosed( EditorEvent e ){ tree.removeAll(); }

	public void onEditItemSaveStateChanged(EditorEvent e){}

	public void onEditItemDisposed(EditorEvent e)
	{
		EditItem ei = e.item;
		assert(ei);
		
		foreach( TreeItem tr; tree.getItems() )
		{
			EditItem _ei = cast(EditItem) tr.getData();
			if( ei == _ei )	
			{
				tr.dispose();
			}
		}				
	}

	public void refresh()
	{
		tree.removeAll();
		foreach( EditItem ei; cast(EditItem[]) sGUI.editor.getItems() )
		{
			//增加樹節點
			TreeItem tItem = new TreeItem( tree, DWT.NONE );
			if( bShowFullPath )
				tItem.setText( ei.getFileName() );
			else
				tItem.setText( std.path.getBaseName( ei.getFileName() ) );

			if( sGUI.packageExp.isFileInProjects( ei.getFileName() ) )
				tItem.setImage( Globals.images["project_file"] );
			else
				tItem.setImage( Globals.images["file_obj"] );
			
			tItem.setData( ei );

			TreeItem[] tis;
			tis ~= tItem;
			tree.setSelection( tis );			
		}
	}

	private void showFullPath( Event e )
	{
		FileList pthis = cast(FileList) e.cData;
		pthis.bShowFullPath = (cast(ToolItem) e.widget).getSelection();

		if( pthis.bShowFullPath )
		{
			foreach( TreeItem tr; tree.getItems() )
			{
				EditItem _ei = cast(EditItem) tr.getData();
				tr.setText( _ei.getFileName() );
			}
		}
		else
		{
			foreach( TreeItem tr; tree.getItems() )
			{
				EditItem _ei = cast(EditItem) tr.getData();
				tr.setText( std.path.getBaseName( _ei.getFileName() ) );
			}
		}
	}
	
	private void toggleMaximized( Event e )
	{
		try
		{
			if( !bMinView )
			{
				lastSashWeights = _parent.getWeights();
				setParentWeights();
				bMinView = true;
				tiClose.setImage(Globals.getImage("max_view"));
			}
			else
			{
				_parent.setWeights( lastSashWeights );
				bMinView = false;
				tiClose.setImage( Globals.getImage("min_view") );				
			}
		}
		catch( Exception e )
		{
			MessageBox.showMessage( e.toString );
		}
	}

	private void onSashResize( Event e ){ if( bMinView ) setParentWeights(); }

	private void setParentWeights()
	{
		Point pt1 = _parent.getSize();
		int[] newWeights = [ Math.max(0, pt1.y - 24), 24 ];
		_parent.setWeights( newWeights );
	}
}


