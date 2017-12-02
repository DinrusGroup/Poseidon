module poseidon.controller.property.compilerpage;

public
{
	import dwt.all;
	import poseidon.globals;
	import poseidon.controller.gui;
	import poseidon.i18n.itranslatable;
	import poseidon.util.layoutshop;
	import poseidon.util.miscutil;
	import poseidon.controller.property.ipropertypage;
}
private import poseidon.controller.dialog.generaldialog;
private import poseidon.util.waitcursor;
private import poseidon.model.project;


class CompilerPage : AbstractPage
{
private:
	import std.string;
	
	Text 	txtDMDPath, txtDMCPath, txtBudTool, txtDebugger, txtRC, txtED, txtEL;
	Button 	btnUseThreadBuild;
	Shell 	shell;
	List 	listSearchPath;


	bool hasSelect( List activeList )
	{
		if( activeList.getItemCount() == 0 ) return false;
		if( activeList.getFocusIndex() == -1 ) return false;
		if( activeList.getSelectionCount == 0 ) return false;

		return true;
	}	
	
	void touchDel( Event e )
	{
		if( hasSelect( listSearchPath ) )
		{
			listSearchPath.remove( listSearchPath.getSelectionIndices() );
			setDirty( true );
		}
	}

	void touchEdit( Event e )
	{
		if( hasSelect( listSearchPath ) )
		{
			scope dlg = new EditDlg( getShell(), 0, null, Globals.getTranslation( "diag.title8_1" ), listSearchPath.getItem( listSearchPath.getFocusIndex() ) );
			char[] str = std.string.strip( dlg.open() );
			
			if( !str.length ) return;

			int index = listSearchPath.getFocusIndex();
			listSearchPath.setItem( index, str );
			listSearchPath.deselectAll();
			listSearchPath.select( index );
			setDirty( true );
		}
	}
	
	void touchAdd( Event e )
	{
		scope dlg = new EditDlg( getShell(), 0, null, Globals.getTranslation( "diag.title8" ), null );
		char[] str = std.string.strip( dlg.open() );
		char[][] files = std.string.split( str, ";" );
		foreach( char[] s; files )
			listSearchPath.add( s );
			
		listSearchPath.setTopIndex( listSearchPath.getItemCount());
		listSearchPath.deselectAll();
		listSearchPath.select( listSearchPath.getItemCount() - files.length ,listSearchPath.getItemCount() - 1 );
		setDirty( true );
	}

	void onUp( Event e )
	{
		with( listSearchPath )
		{
			if( getItemCount() == 0 ) return;
			if( getFocusIndex() == -1 ) return;
			if( getSelectionCount() == 0 ) return;
			
			int index = getSelectionIndex();
			if( index <= 0 )
				return;
			else
				swapListItem( listSearchPath, index, index - 1 );

			setDirty( true );
		}
	}

	void onDown( Event e )
	{
		with( listSearchPath )
		{
			if( getItemCount() == 0 ) return;
			if( getFocusIndex() == -1 ) return;
			if( getSelectionCount() == 0 ) return;
			
			int index = getSelectionIndex();
			if( getItemCount() <= index )
				return;
			else
				swapListItem( listSearchPath, index, index + 1 );

			setDirty( true );
		}
	}

	void swapListItem( List activeList, int a, int b )
	{
		if( activeList is null ) return;
		
		with( activeList )
		{
			char[] temp = getItem( a );
			setItem( a, getItem( b ) );
			setItem( b, temp );
			setSelection( b );
		}
	}

	void onAction( Event e )
	{
		setDirty(true);
	}

	char[] browseDir()
	{
		scope wc = new WaitCursor(shell);
		
		scope dlg = new DirectoryDialog( shell, DWT.OPEN );
		dlg.setFilterPath(Globals.recentDir);
		return dlg.open();
	}		

	char[] browseFile( char[] fileExt = "*.exe" )
	{
		scope wc = new WaitCursor(shell);

		scope dlg = new FileDialog( shell, DWT.OPEN );

		char[][] FileExtensions;
		FileExtensions ~= fileExt;

		dlg.setFilterPath( Globals.recentDir );
		dlg.setFilterExtensions( FileExtensions );		
		return dlg.open();
	}


	void onBrowseDirDMD( Event e )
	{
		char[] fullpath = browseDir();
		if ( fullpath )	txtDMDPath.setText( fullpath );
	}

	void onBrowseDirDMC( Event e )
	{
		char[] fullpath = browseDir();
		if ( fullpath )	txtDMCPath.setText( fullpath );
	}

	void onBrowseBud( Event e )
	{
		char[] fullpath = browseFile();
		if ( fullpath )	txtBudTool.setText( fullpath );
	}

	void onBrowseDebugger( Event e )
	{
		char[] fullpath = browseFile();
		if ( fullpath )	txtDebugger.setText( fullpath );
	}

	void onBrowseRC( Event e )
	{
		char[] fullpath = browseFile();
		if( fullpath.length ) txtRC.setText( fullpath );
	}	


	void initGUI()
	{
		setLayout( LayoutShop.createGridLayout( 1 ) );

		Group compilerGroup = new Group( this, DWT.NONE );
		compilerGroup.setText( Globals.getTranslation( "cp.compiler" ) );
		auto gridLayout = new GridLayout();
		gridLayout.numColumns = 3;
		compilerGroup.setLayout( gridLayout );
		GridData gridData = new GridData( GridData.FILL_HORIZONTAL );
		compilerGroup.setLayoutData( gridData );
		
		// DMD's path
		with( new Label( compilerGroup, DWT.NONE ) )
		{
			setText( Globals.getTranslation("cp.dmd_path") );
		}

		with( txtDMDPath = new Text( compilerGroup, DWT.BORDER ) )
		{
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ));
			txtDMDPath.setText( Globals.DMDPath );
			handleEvent( null, DWT.Modify, &onAction );
		}

		// DMD's path button
		with( new Button( compilerGroup, DWT.PUSH ) )
		{
			setText( "..." );
			handleEvent( null, DWT.Selection, &onBrowseDirDMD );
		}

		// DMC's path
		with( new Label( compilerGroup, DWT.NONE ) )
		{
			setText( Globals.getTranslation("cp.dmc_path") );
		}

		with( txtDMCPath = new Text( compilerGroup, DWT.BORDER ) )
		{
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );
			txtDMCPath.setText( Globals.DMCPath );
			handleEvent( null, DWT.Modify, &onAction );
		}

		// DMC's path button
		with( new Button( compilerGroup, DWT.PUSH ) )
		{
			setText( "..." );
			handleEvent( null, DWT.Selection, &onBrowseDirDMC );
		}

		// Bud Tool
		with( new Label( compilerGroup, DWT.NONE ) )
		{
			setText( Globals.getTranslation("cp.build_path") );
		}

		with( txtBudTool = new Text( compilerGroup, DWT.BORDER ) )
		{
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );
			txtBudTool.setText( Globals.BudExe );
			handleEvent( null, DWT.Modify, &onAction );
		}

		// Bud tool button
		with( new Button( compilerGroup, DWT.PUSH ) )
		{
			setText( "..." );
			handleEvent( null, DWT.Selection, &onBrowseBud );
		}

		// Debugger
		with( new Label( compilerGroup, DWT.NONE ) )
		{
			setText( Globals.getTranslation("cp.ddbg_path") );
		}

		with( txtDebugger = new Text( compilerGroup, DWT.BORDER ) )
		{
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );
			setText( Globals.DebuggerExe );
			handleEvent( null, DWT.Modify, &onAction );
		}

		// Debugger button
		with( new Button( compilerGroup, DWT.PUSH ) ) 
		{
			setText( "..." );
			handleEvent( null, DWT.Selection, &onBrowseDebugger );
		}

		// RC
		with( new Label( compilerGroup, DWT.NONE ) )
		{
			setText( Globals.getTranslation("cp.rc_path") );
		}

		with( txtRC = new Text( compilerGroup, DWT.BORDER ) )
		{
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );
			setText( Globals.RCExe );
			handleEvent( null, DWT.Modify, &onAction );
		}

		// RC button
		with( new Button( compilerGroup, DWT.PUSH ) ) 
		{
			setText( "..." );
			handleEvent( null, DWT.Selection, &onBrowseRC );
		}


		// horizontal line
		with( new Label( compilerGroup, DWT.SEPARATOR | DWT.HORIZONTAL ) )
			setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 3, 1 ) );


		with( btnUseThreadBuild = new Button( compilerGroup, DWT.CHECK ) )
		{
			setData( LANG_ID, "cp.thread" );
			setSelection( Globals.backBuild );
			setLayoutData(LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 3 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}

		// horizontal line
		with( new Label( compilerGroup, DWT.SEPARATOR | DWT.HORIZONTAL ) )
			setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 3, 1 ) );
			
		Group ddbgGroup = new Group( this, DWT.NONE );
		ddbgGroup.setText( Globals.getTranslation( "cp.ddbg_path" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 2;
		ddbgGroup.setLayout( gridLayout );
		gridData = new GridData( GridData.FILL_HORIZONTAL );
		ddbgGroup.setLayoutData( gridData );	

		with( new Label( ddbgGroup, DWT.NONE) )
		{
			setData( LANG_ID, "pap.ed" );
		}

		txtED = new Text( ddbgGroup, DWT.BORDER );
		if( Globals.edDebug > 0 ) txtED.setText( std.string.toString( Globals.edDebug ) );
		txtED.handleEvent(null, DWT.KeyDown, &onAction);
		txtED.setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 1, 1 ) );
	

		with( new Label( ddbgGroup, DWT.NONE) )
		{
			setData( LANG_ID, "pap.el" );
		}

		txtEL = new Text( ddbgGroup, DWT.BORDER  );
		if( Globals.elDebug > 0 ) txtEL.setText( std.string.toString( Globals.elDebug ) );
		txtEL.handleEvent(null, DWT.KeyDown, &onAction);
		txtEL.setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 1, 1 ) );

		Group searchGroup = new Group( ddbgGroup, DWT.NONE );
		searchGroup.setText( Globals.getTranslation( "pap.path" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 5;
		searchGroup.setLayout( gridLayout );
		gridData = new GridData( GridData.FILL_HORIZONTAL );
		gridData.horizontalSpan = 2;
		searchGroup.setLayoutData( gridData );
		
		with( listSearchPath = new List( searchGroup, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 5, 5 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 6;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
		}

		if( Globals.debuggerSearchPath ) listSearchPath.setItems( Globals.debuggerSearchPath );
		
		// Buttons
		with( new Button( searchGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("add_obj") );
			setToolTipText( Globals.getTranslation( "pp.add" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &touchAdd );
		}

		with( new Button( searchGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("delete_obj") );
			setToolTipText( Globals.getTranslation( "pp.delete" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &touchDel );
		}

		with( new Button( searchGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("write_obj") );
			setToolTipText( Globals.getTranslation( "pp.edit" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &touchEdit );
		}

		with( new Button( searchGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("prev_nav") );
			setToolTipText( Globals.getTranslation( "pp.moveup" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &onUp );
		}

		with( new Button( searchGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("next_nav") );
			setToolTipText( Globals.getTranslation( "pp.movedown" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &onDown );
		}		
	}	

public:	

	this( Composite parent, IPropertyPage parentPage, void delegate(bool) dirtyListener )
	{
		super( parent, parentPage, dirtyListener );
		shell = parent.getShell();
		initGUI();
	}

	void applyChanges()
	{
		Globals.DMDPath			= std.string.strip( txtDMDPath.getText() );
		Globals.DMCPath 		= std.string.strip( txtDMCPath.getText() );
		Globals.BudExe			= std.string.strip( txtBudTool.getText() );
		Globals.DebuggerExe		= std.string.strip( txtDebugger.getText() );
		Globals.RCExe	 		= std.string.strip( txtRC.getText() );
		
		if( btnUseThreadBuild.getSelection() ) Globals.backBuild = 1; else Globals.backBuild = 0;

		int ed = std.string.atoi( std.string.strip( txtED.getText() ) );
		if( ed >= 0 ) Globals.edDebug = ed;

		int el = std.string.atoi( std.string.strip( txtEL.getText() ) );
		if( el >= 0 ) Globals.elDebug = el;

		Globals.debuggerSearchPath = listSearchPath.getItems();

		setDirty( false );
	}

	char[] getTitle()
	{
		return Globals.getTranslation( "pref.compiler" );
	}

	void restoreDefaults()
	{
		txtDMDPath.setText( "" );
		txtDMCPath.setText( "" );
		txtDebugger.setText( "" );
		txtRC.setText( "" );
		btnUseThreadBuild.setSelection( false );

		txtED.setText( "" );
		txtEL.setText( "" );

		listSearchPath.removeAll();
		
		setDirty( true );
	}
}
