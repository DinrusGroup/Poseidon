module poseidon.controller.property.prjproperty;

private import dwt.all;
private import poseidon.model.project;
private import poseidon.controller.dialog.generaldialog;
private import poseidon.controller.gui;
private import poseidon.util.waitcursor;
private import poseidon.globals;
private import poseidon.util.miscutil;


class PrjProperty : GeneralDialog
{
	private import poseidon.model.misc;
	private import poseidon.intellisense.autocomplete;
	private import std.stream;
	private alias ArbitraryObj!(char[][]) FileArguments;
	private import poseidon.controller.edititem;
	
	Project project;
	boolean createNew = true;
	private :
	Combo		cobBuildType;
	Text 		txtName, txtDir, txtFilter, txtMainFile, txtExeName, txtExtraCompilerOption, txtObjDir, txtComment, txtExeArgs,
				txtDocumentDir, txtInterfaceDir, txtExtraToolOption, txtDMDPath, txtDMCPath, txtBudTool;
	Button 		btnOK, btnDir, btnMainFile, chkEmtyFolder, chkUseImpilb, chkGCstub, chkMap, chkCombine, chkNoFiles, btnByPath, btnOld;
	List    	listFiles, listIncludePaths, listLinkLibs, listJ, selectedList; // , listIgnoreModules
	TabItem		libTabItem;
	TabFolder 	tabFolder;
	bool		bRefreshParser = false;

	Table		tableDMD, tableTool, tableLIB, tableImplib;

	Composite tab1_Comp, tab2_Comp, tab3_Comp, tab4_Comp, tab5_Comp;

	
	public this( Shell parent, Project prj )
	{		
		super( parent );
		project = prj;
	}
	
	private void initData()
	{
		if( project !is null )
		{
			createNew = false;
			if( project.style )
			{
				btnByPath.setSelection( true );
				btnOld.setSelection( false );
			}
			txtName.setText( project.projectName );
			txtDir.setText( project.projectDir );
			txtDir.setEditable( false );
			btnDir.setEnabled( false );
			cobBuildType.select( project.projectBuildType );
			chkEmtyFolder.setSelection( project.showEmptyFolder );
			chkCombine.setSelection( project.mergeOption );
			chkNoFiles.setSelection( project.nonFiles );

			char[][] files;
			if( project.projectFiles.length > 0 ) files = project.projectFiles;
			if( project.projectInterfaces.length > 0 ) files ~= project.projectInterfaces;
			if( project.projectResources.length > 0 ) files ~= project.projectResources;
			if( project.projectOthers.length > 0 ) files ~= project.projectOthers;
			if( files.length ) listFiles.setItems( files );
			
			if( project.projectIncludePaths.length > 0 ) listIncludePaths.setItems( project.projectIncludePaths );
			if( project.projectLibs.length > 0 ) listLinkLibs.setItems( project.projectLibs );
			if( project.projectImportExpressions.length > 0 ) listJ.setItems( project.projectImportExpressions );
			//if( project.projectIgnoreModules.length > 0 ) listIgnoreModules.setItems( project.projectIgnoreModules );

			
			txtFilter.setText( project.getFilter() );
			txtMainFile.setText( project.mainFile );
			txtExeName.setText( project.projectTargetName );
			txtComment.setText( project.comment );
			txtExeArgs.setText( project.projectEXEArgs );
			txtExtraCompilerOption.setText( project.projectExtraCompilerOption );
			txtExtraToolOption.setText( project.projectExtraToolOption );
			txtDMDPath.setText(  project.DMDPath );
			txtDMCPath.setText(  project.DMCPath );
			txtBudTool.setText( project.BudExe );

			if( project.projectBuildType == 1 )
			{
				createLibOption();
				tableLIB.setEnabled( true );
				tableImplib.setEnabled( false );

				chkUseImpilb.setEnabled( false );
				chkMap.setEnabled( false );
				chkGCstub.setEnabled( false );
			}
			else if( project.projectBuildType == 2 )
			{
				createLibOption();
				tableImplib.setEnabled( true );
				tableLIB.setEnabled( false );

				chkUseImpilb.setEnabled( true );
				chkMap.setEnabled( true );
				chkGCstub.setEnabled( true );
			}
		}
		else
		{
			btnOK.setEnabled( false );
			btnMainFile.setEnabled( false );
		}
		
	}
	
	protected Shell createShell( Shell parent )
	{
		Shell shell = new Shell( parent, DWT.DIALOG_TRIM | DWT.RESIZE | DWT.APPLICATION_MODAL );
		shell.setImage( Globals.getImage( "property" ) );
		
		GridLayout gridLayout = new GridLayout();
 		gridLayout.numColumns = 3;

		with( shell )
		{
			setText( Globals.getTranslation( "pp.title" ));
			setSize( 400, 400 ); 
			shell.setLayout( gridLayout );
		}


		tabFolder = new TabFolder( shell, DWT.NONE );
		tabFolder.setLayoutData( new GridData(GridData.FILL, GridData.BEGINNING, true, false, 3, 1 ) );
		tabFolder.handleEvent( null, DWT.Selection, &onTabFolderSelection );
		

		// TabItem 1:
		tab1_Comp = new Composite( tabFolder, DWT.NONE );

		gridLayout = new GridLayout();
 		gridLayout.numColumns = 5;
 		tab1_Comp.setLayout( gridLayout );

		// Load Style
		with( new Label( tab1_Comp, DWT.NONE ) )setText( Globals.getTranslation( "pp.style" ) );

		btnOld = new Button( tab1_Comp, DWT.RADIO );
		btnOld.setText( Globals.getTranslation( "pp.byoldschool" ) );
		btnOld.setSelection( true );
		
		btnByPath = new Button( tab1_Comp, DWT.RADIO );
		btnByPath.setText( Globals.getTranslation( "pp.bypath" ) );
		btnByPath.setLayoutData( new GridData(GridData.FILL, GridData.CENTER, true, false, 3, 1 ) );
		
		// Project Name
		with( new Label( tab1_Comp, DWT.NONE ) )setText( Globals.getTranslation( "pp.name" ) );

		with( txtName = new Text( tab1_Comp, DWT.BORDER ) )
		{
			setLayoutData( new GridData(GridData.FILL, GridData.BEGINNING, true, false, 2, 1 ) );
			handleEvent( null, DWT.Modify, &onValidate );
		}		
		// empty_folder filter
		with( chkEmtyFolder = new Button( tab1_Comp, DWT.CHECK ) )
		{
			setText( Globals.getTranslation( "pp.empty_folder" ) );
			setLayoutData( new GridData(GridData.BEGINNING, GridData.CENTER, true, false, 1, 1 ) );
		}
		new Label( tab1_Comp, DWT.NONE );

		// Project Path
		with( new Label( tab1_Comp, DWT.NONE ) ) setText( Globals.getTranslation( "pp.path" ) );

		with( txtDir = new Text( tab1_Comp, DWT.BORDER ) )
		{
			setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 3, 1 ) );
			handleEvent(null, DWT.Modify, &onValidate);
		}
		with( btnDir = new Button( tab1_Comp, DWT.PUSH ) )
		{
			setText("...");
			setToolTipText( Globals.getTranslation( "pp.browse" ) );
			handleEvent( null, DWT.Selection, &onBrowseDir );
		}

		// Type
		with( new Label( tab1_Comp, DWT.NONE ) ) setText( Globals.getTranslation( "pp.type" ) );
		
		with( cobBuildType = new Combo( tab1_Comp, DWT.BORDER ) )
		{
			add( Globals.getTranslation( "pp.type1" ) );
			//add( "Win32 GUI Application");
			add( Globals.getTranslation( "pp.type2" ) );
			add( Globals.getTranslation( "pp.type3" ) );
			select( 0 );
			setLayoutData( new GridData(GridData.FILL, GridData.CENTER, true, false, 1, 1 ) );
			handleEvent( null, DWT.Modify, &onCoBuildType );
		}
		//new Label( tab1_Comp, DWT.NONE );

		// Filter
		with( new Label( tab1_Comp, DWT.NONE ) ) setText( Globals.getTranslation( "pp.filter" ) );

		with( txtFilter = new Text( tab1_Comp, DWT.BORDER ) )
		{
			setText( "*.d" );
			setToolTipText( Globals.getTranslation( "pp.info_sep" ) );
			setLayoutData(new GridData( GridData.FILL, GridData.CENTER, true, false, 1, 1 ) );
		}
		new Label( tab1_Comp, DWT.NONE );
		

		// Main File
		with( new Label( tab1_Comp, DWT.NONE ) ) setText( Globals.getTranslation( "pp.main_file" ) );
		
		with( txtMainFile = new Text( tab1_Comp, DWT.BORDER ) )
		{
			setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 3, 1 ) );
			setToolTipText( Globals.getTranslation( "pp.mainfile_tip" ) );
		}
		with( btnMainFile = new Button( tab1_Comp, DWT.PUSH ) )
		{
			setText("...");
			setToolTipText( Globals.getTranslation( "pp.mainfile_browser_tip" ) );
			handleEvent( null, DWT.Selection, &onBrowseMainFile );
		}

		with( new Label( tab1_Comp, DWT.NONE ) ) setText( Globals.getTranslation( "pp.target_name" ) );
		with( txtExeName = new Text( tab1_Comp, DWT.BORDER ) )
		{
			setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 3, 1 ) );
		}
		new Label( tab1_Comp, DWT.NONE );

		with( new Label( tab1_Comp, DWT.NONE ) ){ setText( Globals.getTranslation( "pp2.args" ) ); }
		with( txtExeArgs = new Text( tab1_Comp, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL | DWT.WRAP )) 
		{
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 3, 1 );
			innergridData.heightHint = 28;
			setLayoutData( innergridData );			
		}
		new Label( tab1_Comp, DWT.NONE );
		
		// Comment
		with( new Label( tab1_Comp, DWT.NONE ) ) setText( Globals.getTranslation( "pp.comment" ) );
		with( txtComment = new Text( tab1_Comp, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL | DWT.WRAP ) )
		{
			scope color = new Color( display, 0, 0x66, 0 );
			setForeground( color );
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 3, 1 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			innergridData.heightHint = 28;
			setLayoutData( innergridData );
		}
		new Label( tab1_Comp, DWT.NONE );

		
		Group fileListGroup = new Group( tab1_Comp, DWT.NONE );
		fileListGroup.setText( Globals.getTranslation( "pp.filelist" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 2;
		fileListGroup.setLayout( gridLayout );
		GridData gridData = new GridData( GridData.FILL_HORIZONTAL );
		gridData.horizontalSpan = 5;
		fileListGroup.setLayoutData( gridData );
		
		
		with( listFiles = new List( fileListGroup, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 5 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 9;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
			handleEvent( this, DWT.MouseDown, delegate( Event e )
			{
				PrjProperty pThis = cast(PrjProperty) e.cData;
				pThis.selectedList = pThis.listFiles;
			} );			
		}
		
		with( new Button( fileListGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("add_obj") );
			setToolTipText( Globals.getTranslation( "pp.add" ) );
			handleEvent( null, DWT.Selection, &onAdd );
		}

		with( new Button( fileListGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("delete_obj") );
			setToolTipText( Globals.getTranslation( "pp.delete" ) );
			handleEvent( null, DWT.Selection, &onDel );
		}

		with( new Button( fileListGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("write_obj") );
			setToolTipText( Globals.getTranslation( "pp.edit" ) );
			handleEvent( null, DWT.Selection, &onEdit );
		}

		with( new Button( fileListGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("importfile") );
			setToolTipText( Globals.getTranslation( "pp.importall" ) );
			handleEvent( null, DWT.Selection, &onImportFiles );
		}


		// ********************************************************************
		// TabItem 2( Include & Libs ):
		tab2_Comp = new Composite( tabFolder, DWT.NONE );

		gridLayout = new GridLayout();
 		gridLayout.numColumns = 5;
		gridLayout.makeColumnsEqualWidth = true;
 		tab2_Comp.setLayout( gridLayout );

		// Directory
		Group directoryGroup = new Group( tab2_Comp, DWT.NONE );
		
		gridData = new GridData( GridData.FILL_HORIZONTAL );
		gridData.horizontalSpan = 5;
		directoryGroup.setLayoutData( gridData );
				
		directoryGroup.setText( Globals.getTranslation( "pp1.directory" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 1;
		directoryGroup.setLayout( gridLayout );


		with( listIncludePaths = new List( directoryGroup, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 6;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
			handleEvent( this, DWT.MouseDown, delegate( Event e )
			{
				PrjProperty pThis = cast(PrjProperty) e.cData;
				pThis.selectedList = pThis.listIncludePaths;
				pThis.listLinkLibs.deselectAll();
				pThis.listJ.deselectAll();				
			} );
		}

		// Library
		Group libsGroup = new Group( tab2_Comp, DWT.NONE );
		libsGroup.setText( Globals.getTranslation( "pp1.library" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 1;
		libsGroup.setLayout( gridLayout );
			
		gridData = new GridData( GridData.FILL_HORIZONTAL );
		gridData.horizontalSpan = 5;
		libsGroup.setLayoutData( gridData );

		with( listLinkLibs = new List( libsGroup, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 6;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
			handleEvent( this, DWT.MouseDown, delegate( Event e )
			{
				PrjProperty pThis = cast(PrjProperty) e.cData;
				pThis.selectedList = pThis.listLinkLibs;
				pThis.listIncludePaths.deselectAll();
				pThis.listJ.deselectAll();				
			} );
		}		

		Group JGroup = new Group( tab2_Comp, DWT.NONE );
		JGroup.setText( Globals.getTranslation( "pp1.importexpression" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 1;
		JGroup.setLayout( gridLayout );
			
		gridData = new GridData( GridData.FILL_HORIZONTAL );
		gridData.horizontalSpan = 5;
		JGroup.setLayoutData( gridData );

		with( listJ = new List( JGroup, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 6;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
			handleEvent( this, DWT.MouseDown, delegate( Event e )
			{
				PrjProperty pThis = cast(PrjProperty) e.cData;
				pThis.selectedList = pThis.listJ;
				pThis.listIncludePaths.deselectAll();
				pThis.listLinkLibs.deselectAll();				
			} );			
		}	

		// Buttons
		with( new Button( tab2_Comp, DWT.FLAT ) )
		{
			setImage( Globals.getImage("add_obj") );
			setToolTipText( Globals.getTranslation( "pp.add" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &onAdd );
		}

		with( new Button( tab2_Comp, DWT.FLAT ) )
		{
			setImage( Globals.getImage("delete_obj") );
			setToolTipText( Globals.getTranslation( "pp.delete" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &onDel );
		}

		with( new Button( tab2_Comp, DWT.FLAT ) )
		{
			setImage( Globals.getImage("write_obj") );
			setToolTipText( Globals.getTranslation( "pp.edit" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &onEdit );
		}

		with( new Button( tab2_Comp, DWT.FLAT ) )
		{
			setImage( Globals.getImage("prev_nav") );
			setToolTipText( Globals.getTranslation( "pp.moveup" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &onUp );
		}

		with( new Button( tab2_Comp, DWT.FLAT ) )
		{
			setImage( Globals.getImage("next_nav") );
			setToolTipText( Globals.getTranslation( "pp.movedown" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &onDown );
		}

	
		// ********************************************************************
		// TabItem 3( Complier Options ):

		
		tab3_Comp = new Composite( tabFolder, DWT.NONE );

		gridLayout = new GridLayout();
 		//gridLayout.numColumns = 2;
		//gridLayout.makeColumnsEqualWidth = true;
 		tab3_Comp.setLayout( gridLayout );


		with( tableDMD = new Table( tab3_Comp, DWT.BORDER | DWT.CHECK ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 15;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
			handleEvent( null, DWT.DefaultSelection, &onTableDefaultSelection );
			handleEvent( null, DWT.Selection, &onTableItemCheck );
		}

		for( int i = 0; i < 50; ++ i )
		{
			char[] 	beTransOptionName =  "pp2.o" ~ std.string.toString( i );
			char[] 	optionName = Globals.getTranslation( beTransOptionName );

			if( beTransOptionName == optionName ) break;

			bool 	bChecked;
			if( project !is null ) getOptionName( project.buildOptionDMD, optionName, bChecked );
			
			with( new TableItem( tableDMD, DWT.NULL ) )
			{
				setText( optionName );
				setChecked( bChecked );

				if( bChecked )
				{
					scope color = new Color( display, 0x99, 0xff, 0x66 );
					setBackground( 0, color );
				}
			}
		}

		// horizontal line
		with( new Label( tab3_Comp, DWT.SEPARATOR | DWT.HORIZONTAL ) )
			setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 1, 1 ) );


		with( new Label( tab3_Comp, DWT.NONE ) )
		{
			setText( Globals.getTranslation( "pp2.extra" ) );
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );
		}

		with( txtExtraCompilerOption = new Text( tab3_Comp, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL | DWT.WRAP )) 
		{
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			setLayoutData( new GridData( GridData.FILL, GridData.FILL, true, true, 1, 1) );
		}


		// horizontal line
		with( new Label( tab3_Comp, DWT.SEPARATOR | DWT.HORIZONTAL ) )
			setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 1, 1 ) );		

		/+	
		with( new Label( tab3_Comp, DWT.NONE ) )
		{
			setText( Globals.getTranslation( "pp2.lib_label" ) );
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );
		}

		with( tableLIB = new Table( tab3_Comp, DWT.BORDER | DWT.CHECK ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 2;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
			setEnabled( false );
			handleEvent( null, DWT.DefaultSelection, &onTableDefaultSelection );
			handleEvent( null, DWT.Selection, &onTableItemCheck );
		}

		for( int i = 0; i < 50; ++ i )
		{
			char[] 	beTransOptionName =  "pp2.lib_o" ~ std.string.toString( i );
			char[] 	optionName = Globals.getTranslation( beTransOptionName );

			if( beTransOptionName == optionName ) break;

			bool 	bChecked;
			if( project !is null ) getOptionName( project.buildOptionLIB, optionName, bChecked );

			with( new TableItem( tableLIB, DWT.NULL ) )
			{
				setText( optionName );
				setChecked( bChecked );

				if( bChecked )
				{
					scope color = new Color( display, 0x99, 0xff, 0x66 );
					setBackground( 0, color );
				}
			}
		}
		+/
		Group compilerPathGroup = new Group( tab3_Comp, DWT.NONE );
		
		gridData = new GridData( GridData.FILL_HORIZONTAL );
		//gridData.horizontalSpan = 5;
		compilerPathGroup.setLayoutData( gridData );
				
		compilerPathGroup.setText( Globals.getTranslation( "pp2.path" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 6;
		compilerPathGroup.setLayout( gridLayout );

		// DMD's path
		with( new Label( compilerPathGroup, DWT.NONE ) )
		{
			setText( Globals.getTranslation("cp.dmd_path") );
		}

		with( txtDMDPath = new Text( compilerPathGroup, DWT.BORDER ) )
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );

		// DMD's path button
		with( new Button( compilerPathGroup, DWT.PUSH ) )
		{
			setText( "..." );
			handleSelection( this, delegate( SelectionEvent e )
			{
				PrjProperty pThis = cast(PrjProperty)e.cData;
				
				scope dlg = new DirectoryDialog( pThis.getShell, DWT.OPEN );
				dlg.setFilterPath(Globals.recentDir);
				pThis.txtDMDPath.setText( dlg.open() );
			});
		}

		// DMC's path
		with( new Label( compilerPathGroup, DWT.NONE ) )
		{
			setText( Globals.getTranslation("cp.dmc_path") );
		}

		with( txtDMCPath = new Text( compilerPathGroup, DWT.BORDER ) )
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );

		// DMC's path button
		with( new Button( compilerPathGroup, DWT.PUSH ) )
		{
			setText( "..." );
			handleSelection( this, delegate( SelectionEvent e )
			{
				PrjProperty pThis = cast(PrjProperty)e.cData;
				
				scope dlg = new DirectoryDialog( pThis.getShell, DWT.OPEN );
				dlg.setFilterPath(Globals.recentDir);
				pThis.txtDMCPath.setText( dlg.open() );
			});
		}		

        tab4_Comp = new Composite( tabFolder, DWT.NONE );
        gridLayout = new GridLayout();
		tab4_Comp.setLayout( gridLayout );


		with( tableTool = new Table( tab4_Comp, DWT.BORDER | DWT.CHECK | DWT.V_SCROLL ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 12;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
			handleEvent( null, DWT.DefaultSelection, &onTableDefaultSelection );
			handleEvent( null, DWT.Selection, &onTableItemCheck );
		}
		
		for( int i = 0; i < 50; ++ i )
		{
			char[] 	beTransOptionName =  "pp3.o" ~ std.string.toString( i );
			char[] 	optionName = Globals.getTranslation( beTransOptionName );

			if( beTransOptionName == optionName ) break;

			bool 	bChecked;
			if( project !is null ) getOptionName( project.buildOptionTool, optionName, bChecked );

			with( new TableItem( tableTool, DWT.NULL ) )
			{
				setText( optionName );
				setChecked( bChecked );

				if( bChecked )
				{
					scope color = new Color( display, 0x99, 0xff, 0x66 );
					setBackground( 0, color );
				}
			}
		}		

		with( new Label( tab4_Comp, DWT.SEPARATOR | DWT.HORIZONTAL ) )
			setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 1, 1 ) );


		with( chkCombine = new Button( tab4_Comp, DWT.CHECK ) )
		{
			setSelection( false );
			setText( Globals.getTranslation( "pp3.combineoption" ) );
			setLayoutData( new GridData(GridData.BEGINNING, GridData.CENTER, true, false, 1, 1 ) );
		}

		with( chkNoFiles = new Button( tab4_Comp, DWT.CHECK ) )
		{
			setSelection( false );
			setText( Globals.getTranslation( "pp3.nofiles" ) );
			setLayoutData( new GridData(GridData.BEGINNING, GridData.CENTER, true, false, 1, 1 ) );
		}

		// horizontal line
		with( new Label( tab4_Comp, DWT.SEPARATOR | DWT.HORIZONTAL ) )
			setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 1, 1 ) );


		with( new Label( tab4_Comp, DWT.NONE ) )
		{
			setText( Globals.getTranslation( "pp3.extra" ) );
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );
		}
		
		with( txtExtraToolOption = new Text( tab4_Comp, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL | DWT.WRAP )) 
		{
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			setLayoutData( new GridData( GridData.FILL, GridData.FILL, true, true, 1, 1) );
		}


		Group toolEXEGroup = new Group( tab4_Comp, DWT.NONE );
		
		gridData = new GridData( GridData.FILL_HORIZONTAL );
		//gridData.horizontalSpan = 5;
		toolEXEGroup.setLayoutData( gridData );
				
		toolEXEGroup.setText( Globals.getTranslation( "pp3.path" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 3;
		toolEXEGroup.setLayout( gridLayout );

		// Tool's path
		with( new Label( toolEXEGroup, DWT.NONE ) )
		{
			setText( Globals.getTranslation("cp.build_path") );
		}

		with( txtBudTool = new Text( toolEXEGroup, DWT.BORDER ) )
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );

		// Bud tool button
		with( new Button( toolEXEGroup, DWT.PUSH ) )
		{
			setText( "..." );
			handleSelection( this, delegate( SelectionEvent e )
			{
				PrjProperty pThis = cast(PrjProperty)e.cData;
				
				scope dlg = new FileDialog( pThis.getShell, DWT.OPEN );
				dlg.setFilterPath( Globals.recentDir );
				dlg.setFilterExtensions( [ "*.exe", "*.*"]  );	
				pThis.txtBudTool.setText( dlg.open() );
			});
		}


		TabItem item1 = new TabItem( tabFolder, DWT.NONE );
		item1.setText( Globals.getTranslation( "pp.folder" ) );
		item1.setControl( tab1_Comp );

		TabItem item2 = new TabItem( tabFolder, DWT.NONE );
		item2.setText( Globals.getTranslation( "pp1.folder" ) );
		item2.setControl( tab2_Comp );

		TabItem item3 = new TabItem( tabFolder, DWT.NONE );
		item3.setText( Globals.getTranslation( "pp2.folder" ) );
		item3.setControl( tab3_Comp );


		TabItem item4 = new TabItem( tabFolder, DWT.NONE );
		item4.setText( Globals.getTranslation( "pp3.folder" ) );
		item4.setControl( tab4_Comp );

		// horizontal line
		with( new Label( shell, DWT.SEPARATOR | DWT.HORIZONTAL ) )
			setLayoutData( new GridData( GridData.FILL, GridData.FILL, true, false, 3, 1 ) );
		
		// the bottom buttton bar
		Button[] buts = createButtonBar( shell );
		btnOK = buts[0];
		btnOK.handleSelection( this, delegate( SelectionEvent e )
		{
			PrjProperty pThis = cast(PrjProperty)e.cData;
			pThis.onOK(e);
		} 
		);
		
		
		initData();
		
		shell.pack();
		Point pt = shell.getSize();
		pt.x = pt.y * 4 / 3;// * 3 / 2;
		shell.setSize(pt);
		shell.setMinimumSize(pt);

		return shell;
	}

	private bool getOptionName( char[] buildOption, inout char[] optionName, inout bool bChecked )
	{
		bChecked = false;
		
		if( !buildOption.length || !optionName.length ) return false;
		
		int 	openbracketPos	= std.string.rfind( optionName, "[" ) + 1;
		int 	closebracketPos	= std.string.rfind( optionName, "]" );

		if( closebracketPos > openbracketPos )
		{
			char[]	switchName		= optionName[openbracketPos..closebracketPos];
			int		ltPos			= std.string.rfind( optionName, "<" );
			int		gtPos			= std.string.rfind( optionName, ">" );
			int		equalPos		= std.string.rfind( optionName, "=" );

			if( ltPos > 0 )
			{
				if( gtPos > ltPos )
				{
					char[] caseName = optionName[ltPos..gtPos+1]; // get <...>
					
					if( equalPos > -1 )
						switchName = optionName[openbracketPos..equalPos];
					else
						switchName = optionName[openbracketPos..ltPos];

					int indexOption = std.string.find( buildOption, switchName );
					if( indexOption > -1 )
					{
						char[] 	dirName;
						int		switchNameLength = switchName.length;

						int end = std.string.find( buildOption[indexOption+switchNameLength..length], " " );
						dirName = buildOption[indexOption+switchNameLength..indexOption+switchNameLength+end];
						optionName = std.string.replace( optionName, caseName, dirName );
						bChecked = true;
						return true;						
					}
				}
			}
			else
			{
				int indexOption = std.string.find( buildOption, switchName ~ " " );
				if( indexOption > -1 )
				{
					bChecked = true;
					return true;
				}
			}
		}

		return false;
	}

	private void onTabFolderSelection( Event e ){ selectedList = null; }	

	private void onTableDefaultSelection( Event e )
	{
		TableItem 	item = cast(TableItem) e.item;
		Table		selectedTable = cast(Table) e.widget;

		if( item !is null )
		{
			char[] 	beTransOptionName;
			int		index = selectedTable.indexOf( item );
			
			if( selectedTable == tableTool )
				beTransOptionName =  "pp3.o" ~ std.string.toString( index );
			else if( selectedTable == tableLIB )
				beTransOptionName =  "pp2.lib_o" ~ std.string.toString( index );
			else if( selectedTable == tableImplib )
				beTransOptionName =  "pp2.implib_o" ~ std.string.toString( index );
			else if( selectedTable == tableDMD )
				beTransOptionName =  "pp2.o" ~ std.string.toString( index );
			
			char[] 	optionName = Globals.getTranslation( beTransOptionName );
			char[]	result;
			int		ltPos			= std.string.rfind( optionName, "<" );
			int		gtPos			= std.string.rfind( optionName, ">" );

			if( gtPos > ltPos )
			{
				char[] caseName = optionName[ltPos..gtPos+1]; // get <...>
				switch( caseName )
				{
					case "<path>":
						scope dlg = new EditDlg( sShell, 0, null, "Set directory", "" );
						result = std.string.strip( dlg.open() );
						break;
					case "<name>":
						scope dlg = new AskStringDlg( sShell, "Set Name", "" );
						dlg.setText( "Name" );
						result = std.string.strip( dlg.open() );
						break;
					case "<file>":
						scope dlg = new EditDlg( sShell, 1, null, "Set File", "" );
						result = std.string.strip( dlg.open() );
						break;
						/*
						scope dlg = new AskStringDlg( sShell, "Set File Name", "" );
						dlg.setText( "File Name" );
						result = std.string.strip( dlg.open() );
						break;
						*/
					case "<option>":
						scope dlg = new AskStringDlg( sShell, "Set Options", "" );
						dlg.setText( "Option" );
						result = std.string.strip( dlg.open() );
						break;
					case "<nnn>":
						scope dlg = new AskStringDlg( sShell, "Set Page Size", null );
						dlg.setText( "PAGE SIZE" );

						result = std.string.strip( dlg.open() );
						int 	ret = std.string.atoi( result );

						if( ret >= 2 )
						{
							if( ( ret & ( ret - 1 ) ) ) result = "";
						}
						else
							result = "";

						break;
					case "<yes/no>":
						scope dlg = new EditDlg( sShell, 0, null, "Enable/Disable", "", 3 );
						result = std.string.strip( dlg.open() );
						if( result != "yes" && result != "no" ) return;
						break;
					default:
				}

				if( result.length )	item.setText( std.string.replace( optionName, caseName, result ) );
			}
		}
	}

	private void onTableItemCheck( Event e )
	{
		TableItem 	item = cast(TableItem) e.item;

		if( item !is null )
		{
			with( item )
			{
				if( getChecked() )
				{
					scope color = new Color( display, 0x99, 0xff, 0x66 );
					setBackground( 0, color );
				}
				else
					setBackground( 0, null );
			}
		}
	}
	
	private void onCoBuildType( Event e )
	{
		if( cobBuildType.getSelectionIndex() == 0 )
		{
			if( libTabItem !is null )
			{
				libTabItem.dispose();
				delete libTabItem;
			}
		}
		else if( cobBuildType.getSelectionIndex() == 1 )
		{
			createLibOption();
			tableLIB.setEnabled( true );
			tableImplib.setEnabled( false );

			chkUseImpilb.setEnabled( false );
			chkMap.setEnabled( false );
			chkGCstub.setEnabled( false );
		}
		else
		{
			createLibOption();
			tableLIB.setEnabled( false );
			tableImplib.setEnabled( true );

			chkUseImpilb.setEnabled( true );
			chkMap.setEnabled( true );
			chkGCstub.setEnabled( true );
		}
	}

	// only when create new project
	private void onBrowseDir(Event e) {
		scope wc = new WaitCursor(shell);
		scope dlg = new DirectoryDialog(shell, DWT.OPEN);
		dlg.setFilterPath(Globals.recentDir);
		char[] fullpath = dlg.open();
		if( fullpath )
		{
			if( sGUI.packageExp.isProjectOpened( fullpath ) ) 
			{
				MessageBox.showMessage(Globals.getTranslation("mb.prj_already_opened"), Globals.getTranslation( "INFORMATION"), 
					getShell(), DWT.ICON_WARNING);
				return;
			}
			
			char[] file = std.path.join(fullpath, Project.EXT);
			if(std.file.exists(file))
			{
				int result = MessageBox.showMessage(Globals.getTranslation("mb.choose_prj_file_exist"), Globals.getTranslation("mb.file_exists"), 
					getShell(), DWT.ICON_QUESTION | DWT.YES | DWT.NO | DWT.CANCEL);
				if(result == DWT.YES){
					this.project = Project.loadProject(fullpath);
					initData();
					// 
					createNew = true;
				}else if(result == DWT.NO){
					txtDir.setText(fullpath);
				}
				// DWT.CANCEL do nothing
				
			}else{
				txtDir.setText(fullpath);
			}
		}
	}
	
	private void onBrowseMainFile(Event e) {
		// nested class
		class _Dlg : GeneralDialog
		{
			private import poseidon.controller.packageexplorer;
			
			List 	list;
			char[] 	dir;
			Button 	btnOK, btnCancel;

			this( Shell parent, char[] dir )
			{
				super(parent);
				this.dir = dir;
			}
			
			protected Shell createShell(Shell parent)
			{
				Shell shell = new Shell(parent, DWT.RESIZE | DWT.DIALOG_TRIM | DWT.APPLICATION_MODAL);				
				shell.setText("Select the main file");
				shell.setLayout(new GridLayout(2,false));
				list = new List(shell, DWT.V_SCROLL | DWT.BORDER | DWT.SINGLE);
				list.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 2, 1));
				// Note, the event is different from btnOK's onOK(Event e)
				list.handleEvent(null, DWT.DefaultSelection, &onOK);

				scope dfiles = new CFindAllFile( dir, "*.d" );

				char[][] listDFile = dfiles.getFiles();
				foreach( char[] s; listDFile )
				{
					char[] path = MiscUtil.relativePath( s, dir );
					list.add(path);
				}

				// btns[0] is OK button, btns[1] is Cancel button
				Button[] btns = createButtonBar(shell);
				shell.setDefaultButton(btns[0]);
				btns[0].handleEvent(null, DWT.Selection, &onOK);
				
				shell.pack();
				Point pt = shell.getSize();
				shell.setSize(pt.x + 20, pt.x);

				return shell;
			}
			protected void onOK(Event e) {
				int sel = list.getSelectionIndex();
				if(sel >= 0){
					result = list.getItem(sel);
				}				
				getShell().close();
			}
		}
		char[] dir = std.string.strip( txtDir.getText() );
		scope dlg = new _Dlg(getShell(), dir);
		char[] result = dlg.open();
		if(result)
			txtMainFile.setText(result);
	}

	private char[] getFullPath( char[] filename )
	{
		char[] dirName		= std.string.strip( std.path.getDirName( filename ) );
		char[] driveName 	= std.string.strip( std.path.getDrive( filename ) );

		if( driveName.length > 0 )
			return filename;
		else
			return std.string.strip( txtDir.getText() ) ~ "\\" ~ filename;
	}
		
	
	protected void onOK(SelectionEvent e) {
		char[] dir = txtDir.getText();
		
		// Windows system will remove any space at the both end of the dir
		dir = std.string.strip(dir);
		txtDir.setText(dir);
		
		if(!Project.checkDir(dir)){
			MessageBox.showMessage(Globals.getTranslation("mb.root_as_prjdir"));
			return;
		}
		if(createNew && sGUI.packageExp.isProjectOpened(dir)) {
			MessageBox.showMessage(Globals.getTranslation("mb.prj_already_opened"), Globals.getTranslation("INFORMATION"), 
				getShell(), DWT.ICON_WARNING);
			return;
		}

		
		boolean save = true;
		bool bNewProject = false;
		if( project is null )
		{
			// create new project
			project = new Project( dir );
			bNewProject = true;
		}
		else
		{
			// the project is opened as dir not opened from project file,
			// prompt to save
			char[] path = std.path.join( project.projectDir, Project.EXT );
			if(!std.file.exists(path)){
				char[] s = Globals.getTranslation("mb.prompt _save_prj");
				int result = MessageBox.showMessage(s, Globals.getTranslation("QUESTION"),
					getShell(), DWT.YES | DWT.NO | DWT.CANCEL | DWT.ICON_QUESTION);
				if(DWT.CANCEL == result)	
					return;
				if(DWT.YES != result)
					save = false;				
			}
		}

		if( btnByPath.getSelection() ) project.style = 1;else project.style = 0;
		project.projectName 		= std.string.strip( txtName.getText() );
		project.projectBuildType 	= cobBuildType.getSelectionIndex();
		project.projectTargetName 	= std.string.strip( txtExeName.getText() );
		project.projectEXEArgs		= std.string.strip( txtExeArgs.getText() );
		project.comment				= std.string.strip( txtComment.getText() );
		
		project.setFileFilter( txtFilter.getText() );
		project.showEmptyFolder = chkEmtyFolder.getSelection();
		project.mergeOption = chkCombine.getSelection();
		project.nonFiles = chkNoFiles.getSelection();
		project.mainFile = txtMainFile.getText();

		project.DMDPath = std.string.strip( txtDMDPath.getText() );
		project.DMCPath = std.string.strip( txtDMCPath.getText() );
		project.BudExe = std.string.strip( txtBudTool.getText() );

		project.buildOptionDMD = project.buildOptionTool = project.projectExtraCompilerOption = project.projectExtraToolOption =
		project.buildOptionLIB = project.buildOptionIMPLIB = "";

		foreach( TableItem ti; tableDMD.getItems() )
		{
			if( ti.getChecked() )
				project.buildOptionDMD ~= ( project.getBracketText( ti.getText( 0 ) ) ~ " " );
		}
		if( project.buildOptionDMD.length ) project.buildOptionDMD = " " ~ project.buildOptionDMD;

		foreach( TableItem ti; tableTool.getItems() )
		{
			if( ti.getChecked() )
				project.buildOptionTool ~= ( project.getBracketText( ti.getText( 0 ) ) ~ " " );
		}
		if( project.buildOptionTool.length ) project.buildOptionTool = " " ~ project.buildOptionTool;

		if( project.projectBuildType > 0 && libTabItem !is null )
		{
			project.useImplib = chkUseImpilb.getSelection();
			project.mapFile = chkMap.getSelection();
			project.useGcstub = chkGCstub.getSelection();
			foreach( TableItem ti; tableLIB.getItems() )
			{
				if( ti.getChecked() )
					project.buildOptionLIB ~= ( project.getBracketText( ti.getText( 0 ) ) ~ " " );
			}
			if( project.buildOptionLIB.length ) project.buildOptionLIB = " " ~ project.buildOptionLIB;

			foreach( TableItem ti; tableImplib.getItems() )
			{
				if( ti.getChecked() )
					project.buildOptionIMPLIB ~= ( project.getBracketText( ti.getText( 0 ) ) ~ " " );
			}
			if( project.buildOptionIMPLIB.length ) project.buildOptionIMPLIB = " " ~ project.buildOptionIMPLIB;			
		}
		
		project.projectExtraCompilerOption 	= std.string.strip( txtExtraCompilerOption.getText() );
		project.projectExtraToolOption 		= std.string.strip( txtExtraToolOption.getText() );

		project.projectFiles.length = project.projectInterfaces.length = project.projectResources.length =
		project.projectOthers.length = project.projectIncludePaths.length = project.projectLibs.length = 
		project.projectImportExpressions.length = 0;//project.projectIgnoreModules.length = 0;

		// all files
		foreach( char[] s; listFiles.getItems() )
		{
			if( std.string.tolower( std.path.getExt( s ) ) == "d" )
				project.projectFiles ~= getFullPath( s );
			else if( std.string.tolower( std.path.getExt( s ) ) == "di" )
				project.projectInterfaces ~= getFullPath( s );
			else if( std.string.tolower( std.path.getExt( s ) ) == "res" )
				project.projectResources ~= getFullPath( s );
			else
				project.projectOthers ~= getFullPath( s );
		}

		// include path
		foreach( char[] s; listIncludePaths.getItems() )
			project.projectIncludePaths ~= std.string.strip( s );//getFullPath( s );

		if( sAutoComplete !is null )
		{
			if( project.projectDir in sAutoComplete.projectImportParsers )
			{
				sAutoComplete.projectImportParsers[project.projectDir].createBaseDirs( project.projectDir ~ project.scINIImportPath ~ project.projectIncludePaths);
			}
			else
			{
				auto IParser = new ImportComplete( project.projectDir ~ project.scINIImportPath ~ project.projectIncludePaths );
				sAutoComplete.projectImportParsers[project.projectDir] = IParser;				
			}
		}
		

		// link libraries
		foreach( char[] s; listLinkLibs.getItems() )
			project.projectLibs ~= std.string.strip( s );//getFullPath( s );

		// link ImportExpressions
		foreach( char[] s; listJ.getItems() )
			project.projectImportExpressions ~= std.string.strip( s );//getFullPath( s );

		if( bNewProject && project.projectBuildType == 2 )
		{
			char[] defFullPath = project.projectDir ~ "\\" ~ project.projectName ~ ".def";

			auto file = new BufferedFile( defFullPath, FileMode.OutNew );
			file.writefln( "LIBRARY				" ~ std.string.toupper( project.projectName ) );
			file.writefln( "DESCRIPTION			'" ~ std.string.toupper( project.projectName ) ~ ".DLL'" );
			file.writefln( "EXETYPE				NT" );
			file.writefln( "CODE				PRELOAD DISCARDABLE" );
			file.writefln( "DATA				PRELOAD SINGLE" );
			file.close();
			
			project.projectOthersDMD ~= defFullPath;
		}

		/+
		// IgnoreModules
		foreach( char[] s; listIgnoreModules.getItems() )
			project.projectIgnoreModules ~= s;
		+/
	
		// save to file
		if( save ) 
		{
			char[][]  files = listFiles.getItems();
			if( ( Globals.useCodeCompletion | Globals.showOnlyClassBrowser ) & bRefreshParser ) 
			{
				/*if( Globals.backLoadParser )
				{
					FileArguments a = new FileArguments( files );
					ThreadEx thread = new ThreadEx( a, &_parseProjectFiles );
					thread.start();
				}
				else
				{*/
					sAutoComplete.refreshFileParser( files );
					sGUI.outputPanel.appendLine( "ReLoad Project[ " ~ project.projectName ~ " ] Parsers Is Done.\n" );
				/*}*/
			}
			
			project.save();
		}
		
		result = "OK";
		// close the dialog
		getShell().close();
	}

	private int _parseProjectFiles( Object args )
	{
		
		try 
		{		
			FileArguments a = cast(FileArguments) args;
			Display display = Display.getDefault();

			void _end( Object args )
			{
				if( !sGUI.outputPanel.isDisposed() )
				{
					sGUI.outputPanel.setBusy( false );
					sGUI.outputPanel.appendString( "ReLoad Project Parsers Is Done.\n" );
					sGUI.statusBar.setString( "" );

					foreach( char[] s ;sGUI.editor.getFileNames() )
					{
						foreach( char[] ss; a.data )
						{
							if( std.string.tolower( s ) == std.string.tolower( ss ) )
							{
								EditItem ei = sGUI.editor.findEditItem( s );
								if( ei !is null )
								{
									sGUI.outline.singleFileToProjectFile( ei );
								}
								sGUI.fileList.changeImage( s );
								break;
							}
						}
					}
				}
			}

			//sAutoComplete.addProjectParser( a.data );
			sAutoComplete.refreshFileParser( a.data );
			display.asyncExec( args , &_end );
		}
		catch ( Exception e )
		{ 
		
		}


		return 1;
	}
	
	private void onValidate(Event e) {
		boolean bName = false;
		boolean bDir = true;
		
		char[] str;
		str = txtName.getText();
		bName = (std.string.strip(str).length != 0);
			
		str = txtDir.getText();
		if( !std.file.exists(str) || !std.file.isdir(str))
			bDir = false;
		
		btnOK.setEnabled(bName && bDir);
		btnMainFile.setEnabled(bDir);		
	}

	private bool getSelectedListArgs( int editAction, inout int browserType, inout char[][] fileExtension, inout char[] winTitle, inout char[] existFile )
	{
		if( selectedList == listFiles )
		{
			browserType = 1;
			fileExtension = ["*.d;*.di;*.di;*.res","*.d","*.di","*.res","*.*"];

			if( editAction == 0 ) 
				winTitle = Globals.getTranslation( "diag.title0" );
			else
			{
				winTitle = Globals.getTranslation( "diag.title0_1" );
				existFile = selectedList.getItem( selectedList.getFocusIndex() );
			}
		
			bRefreshParser = true;
			return true;
		}
		else if( selectedList == listIncludePaths )
		{
			browserType = 0;
			fileExtension = null;
			if( editAction == 0 ) 
				winTitle = Globals.getTranslation( "diag.title1" );
			else
			{
				winTitle = Globals.getTranslation( "diag.title1_1" );
				existFile = selectedList.getItem( selectedList.getFocusIndex() );
			}
			return true;
		}
		else if( selectedList == listLinkLibs )
		{
			browserType = 1;
			fileExtension = ["*.lib","*.*"];
			if( editAction == 0 ) 
				winTitle = Globals.getTranslation( "diag.title2" );
			else
			{
				winTitle = Globals.getTranslation( "diag.title2_1" );
				existFile = selectedList.getItem( selectedList.getFocusIndex() );
			}
			return true;
		}
		else if( selectedList == listJ )
		{
			browserType = 0;
			fileExtension = null;
			if( editAction == 0 ) 
				winTitle = Globals.getTranslation( "diag.title7" );
			else
			{
				winTitle = Globals.getTranslation( "diag.title7_1" );
				existFile = selectedList.getItem( selectedList.getFocusIndex() );
			}
			return true;
		}

		return false;
	}
	
	private void swapListItem( List activeList, int a, int b )
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

	private bool hasSelect( List activeList )
	{
		if( activeList.getItemCount() == 0 ) return false;
		if( activeList.getFocusIndex() == -1 ) return false;
		if( activeList.getSelectionCount == 0 ) return false;

		return true;
	}

	private void touchAdd( List activeList, char[] str )
	{
		if( !str.length || ( activeList is null ) ) return;

		char[][] files = std.string.split( str, ";" );
		foreach( char[] s; files )
			activeList.add( s );
			
		activeList.setTopIndex( activeList.getItemCount());
		activeList.deselectAll();
		activeList.select( activeList.getItemCount() - files.length ,activeList.getItemCount() - 1 );		
	}

	private void touchDel( List activeList )
	{
		if( activeList is null ) return;
		
		if( hasSelect( activeList ) )
		{
			activeList.remove( activeList.getSelectionIndices() );
			if( activeList == listFiles ) bRefreshParser = true;
		}
	}

	private void touchEdit( List activeList, char[] str )
	{
		if( !str.length || ( activeList is null ) ) return;

		int index = activeList.getFocusIndex();
		activeList.setItem( index, str );
		activeList.deselectAll();
		activeList.select( index );
	}
	
	private void onAdd( Event e )
	{
		char[] 		winTitle, existFile;
		int 		browserType;
		char[][]	fileExtension;

		if( getSelectedListArgs( 0, browserType, fileExtension, winTitle, existFile ) )
		{
			scope dlg = new EditDlg( getShell(), browserType, fileExtension, winTitle );
			touchAdd( selectedList, dlg.open() );
		}
	}

	private void onDel( Event e ){ touchDel( selectedList ); }

	private void onEdit( Event e )
	{
		if( hasSelect( selectedList ) )
		{
			char[] 		winTitle, existFile;
			int 		browserType;
			char[][]	fileExtension;

			if( getSelectedListArgs( 2, browserType, fileExtension, winTitle, existFile ) )
			{
				scope dlg = new EditDlg( getShell(), browserType, fileExtension, winTitle, existFile );
				touchEdit( selectedList, dlg.open() );
			}
		}
	}
	
	private void onUp( Event e )
	{
		with( selectedList )
		{
			if( getItemCount() == 0 ) return;
			if( getFocusIndex() == -1 ) return;
			if( getSelectionCount() == 0 ) return;
			
			int index = getSelectionIndex();
			if( index <= 0 )
				return;
			else
				swapListItem( selectedList, index, index - 1 );
		}
	}

	private void onDown( Event e )
	{
		with( selectedList )
		{
			if( getItemCount() == 0 ) return;
			if( getFocusIndex() == -1 ) return;
			if( getSelectionCount() == 0 ) return;
			
			int index = getSelectionIndex();
			if( getItemCount() <= index )
				return;
			else
				swapListItem( selectedList, index, index + 1 );
		}
	}

	private void onImportFiles( Event e )
	{
		char[] dir;
		
		if( project )
			dir = project.projectDir;
		else
		{
			try
			{
				dir = std.string.strip( txtDir.getText() );
				if( !std.file.isdir( dir ) ) return;
			}
			catch
			{
				return;
			}
		}

		listFiles.removeAll();

		char[][] filefilters;
		char[][] filters = std.string.split( std.string.strip( txtFilter.getText() ), ";" );
		if( !filters.length ) return;

		foreach( char[] s; filters )
			filefilters ~= std.string.strip( s );
		

		char[][] files = sGUI.packageExp.getAllFilesInProjectDir( dir, filefilters );
		foreach( char[] s; files )
			listFiles.add( s );

		listFiles.selectAll();
		bRefreshParser = true;
	}

	private void createLibOption()
	{
		// ********************************************************************
		// TabItem 5( Library Options ):
		if( libTabItem is null )
		{
			tab5_Comp = new Composite( tabFolder, DWT.NONE );

			libTabItem =  new TabItem( tabFolder, DWT.NONE );
			libTabItem.setText( Globals.getTranslation( "pp2.libfolder" ) );
			libTabItem.setControl( tab5_Comp );

			GridLayout gridLayout = new GridLayout();
			//gridLayout.numColumns = 2;
			//gridLayout.makeColumnsEqualWidth = true;
			tab5_Comp.setLayout( gridLayout );

			with( new Label( tab5_Comp, DWT.NONE ) )
			{
				setText( Globals.getTranslation( "pp2.lib_static" ) );
				setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );
			}

			with( tableLIB = new Table( tab5_Comp, DWT.BORDER | DWT.CHECK ) )
			{
				GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
				scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
				setFont( font );
				
				int ListHeight = getItemHeight() * 2;
				Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
				innergridData.heightHint = trim.height;
				setLayoutData( innergridData );
				setEnabled( false );
				handleEvent( null, DWT.DefaultSelection, &onTableDefaultSelection );
				handleEvent( null, DWT.Selection, &onTableItemCheck );
			}

			for( int i = 0; i < 50; ++ i )
			{
				char[] 	beTransOptionName =  "pp2.lib_o" ~ std.string.toString( i );
				char[] 	optionName = Globals.getTranslation( beTransOptionName );

				if( beTransOptionName == optionName ) break;

				bool 	bChecked;
				if( project !is null ) getOptionName( project.buildOptionLIB, optionName, bChecked );

				with( new TableItem( tableLIB, DWT.NULL ) )
				{
					setText( optionName );
					setChecked( bChecked );

					if( bChecked )
					{
						scope color = new Color( display, 0x99, 0xff, 0x66 );
						setBackground( 0, color );
					}
				}
			}


			// horizontal line
			with( new Label( tab5_Comp, DWT.SEPARATOR | DWT.HORIZONTAL ) )
				setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 1, 1 ) );	

		
			with( new Label( tab5_Comp, DWT.NONE ) )
			{
				setText( Globals.getTranslation( "pp2.lib_dynamic" ) );
				setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );
			}

			with( chkGCstub = new Button( tab5_Comp, DWT.CHECK ) )
			{
				setSelection( false );
				setText( Globals.getTranslation( "pp2.gcstub" ) );
				setLayoutData( new GridData(GridData.BEGINNING, GridData.CENTER, true, false, 1, 1 ) );
			}		

			with( chkMap = new Button( tab5_Comp, DWT.CHECK ) )
			{
				setSelection( false );
				setText( Globals.getTranslation( "pp2.map" ) );
				setLayoutData( new GridData(GridData.BEGINNING, GridData.CENTER, true, false, 1, 1 ) );
			}		

			with( chkUseImpilb = new Button( tab5_Comp, DWT.CHECK ) )
			{
				setSelection( false );
				setText( Globals.getTranslation( "pp2.useimplib" ) );
				setLayoutData( new GridData(GridData.BEGINNING, GridData.CENTER, true, false, 1, 1 ) );
			}		

			with( tableImplib = new Table( tab5_Comp, DWT.BORDER | DWT.CHECK ) )
			{
				GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
				scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
				setFont( font );
				
				int ListHeight = getItemHeight() * 3;
				Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
				innergridData.heightHint = trim.height;
				setLayoutData( innergridData );
				setEnabled( false );
				handleEvent( null, DWT.DefaultSelection, &onTableDefaultSelection );
				handleEvent( null, DWT.Selection, &onTableItemCheck );
			}

			for( int i = 0; i < 50; ++ i )
			{
				char[] 	beTransOptionName =  "pp2.implib_o" ~ std.string.toString( i );
				char[] 	optionName = Globals.getTranslation( beTransOptionName );

				if( beTransOptionName == optionName ) break;

				bool 	bChecked;
				if( project !is null ) getOptionName( project.buildOptionIMPLIB, optionName, bChecked );

				with( new TableItem( tableImplib, DWT.NULL ) )
				{
					setText( optionName );
					setChecked( bChecked );

					if( bChecked )
					{
						scope color = new Color( display, 0x99, 0xff, 0x66 );
						setBackground( 0, color );
					}
				}
			}
		}

		if( project !is null )
		{
			chkUseImpilb.setSelection( project.useImplib );
			chkMap.setSelection( project.mapFile );
			chkGCstub.setSelection( project.useGcstub );
		}
	}
}