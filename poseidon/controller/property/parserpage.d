module poseidon.controller.property.parserpage;

private
{
	import dwt.all;
	import poseidon.globals;
	import poseidon.controller.gui;
	import poseidon.i18n.itranslatable;
	import poseidon.util.layoutshop;
	import poseidon.util.miscutil;
	import poseidon.controller.property.ipropertypage;
	import poseidon.controller.dialog.generaldialog;
	import poseidon.util.waitcursor;
	import poseidon.model.project;
}


class ParserPage : AbstractPage
{
	private import CodeAnalyzer.syntax.nodeHsu;
	/*
	private Button 	chkUseCodeCompletion, chkOnlyClassBorwser, chkAutoImport, chkAutoAll, chkShowAllMember, 
					chkUseDefaultParser, chkShowType, chkJumpTop, chkCaseSensitive, chkBackgroundLoad, chkUpdateParserLive, chkUpdateParserLiveFull;
	*/
	private Shell 			shell;
	private List  			listDefaultParsers;
	private Text  			txtLetters, txtMakeDefaultParser;
	private TableItem[15] 	items;
	Button					btnV1, btnV2;

	this( Composite parent, IPropertyPage parentPage, void delegate(bool) dirtyListener )
	{
		super( parent, parentPage, dirtyListener );
		shell = parent.getShell();
		initGUI();
	}

	public void applyChanges()
	{
		if( btnV1.getSelection )
			Globals.parserDMDversion = compilerVersion = 1;
		else
			Globals.parserDMDversion = compilerVersion = 2;
		
		Globals.useCodeCompletion = items[0].getChecked();
		Globals.showOnlyClassBrowser = items[1].getChecked();
		Globals.parseImported = items[2].getChecked();
		Globals.parseAllModule = items[3].getChecked();
		Globals.updateParseLive = items[4].getChecked();
		//Globals.updateParseLiveFull = items[5].getChecked();
		Globals.updateParseLiveFull = 0;
		items[5].setChecked( false );
		Globals.showAllMember = items[6].getChecked();
		Globals.showType = items[7].getChecked();
		Globals.jumpTop = items[8].getChecked();
		Globals.parserCaseSensitive = items[9].getChecked();
		Globals.useDefaultParser = items[10].getChecked();
		Globals.backLoadParser = items[11].getChecked();
		Globals.showAutomatically = items[12].getChecked();

		if( !Globals.useCodeCompletion )
		{
			Globals.parseAllModule = 0;
			Globals.parseImported = 0;
			items[3].setChecked( false );
			Globals.updateParseLive = 0;
			items[4].setChecked( false );
			Globals.updateParseLiveFull = 0;
			items[5].setChecked( false );
			Globals.useDefaultParser = 0;
			items[10].setChecked( false );
			items[12].setChecked( false );
		}
		
		
		
		/*
		Globals.useCodeCompletion = chkUseCodeCompletion.getSelection();
		if( !Globals.useCodeCompletion )
		{
			Globals.parseAllModule = 0;
			Globals.parseImported = 0;
			chkAutoAll.setSelection( false );
			Globals.updateParseLive = 0;
			chkUpdateParserLive.setSelection( false );
			chkUpdateParserLiveFull.setSelection( false );
			Globals.useDefaultParser = 0;
			chkUseDefaultParser.setSelection( false );
		}
		else
		{
			Globals.parseAllModule = chkAutoAll.getSelection();
			Globals.parseImported = chkAutoImport.getSelection();
			Globals.updateParseLive = chkUpdateParserLive.getSelection();
			Globals.updateParseLiveFull = chkUpdateParserLiveFull.getSelection();
			Globals.useDefaultParser = chkUseDefaultParser.getSelection();
		}
		*/

		int count = std.string.atoi( std.string.strip( txtLetters.getText() ) );
		if( count < 2 )
			count = 2;
		else if( count > 20 )
			count = 20;
		Globals.lanchLetterCount = count;

		/*
		Globals.jumpTop = chkJumpTop.getSelection();
		Globals.showOnlyClassBrowser = chkOnlyClassBorwser.getSelection();
		Globals.backLoadParser = chkBackgroundLoad.getSelection();
		Globals.parserCaseSensitive = chkCaseSensitive.getSelection();
		Globals.showAllMember = chkShowAllMember.getSelection();
		Globals.showType = chkShowType.getSelection();
		*/

		setDirty( false );

		if( Globals.useCodeCompletion )
		{
			Project[] projects = sGUI.packageExp.getProjects();
			foreach( Project project; projects )
			{
				if( !( project.projectName in sAutoComplete.projectParsers ) )
				{
					sGUI.outputPanel.bringToFront();
					sGUI.outputPanel.setForeColor( 0, 0, 0 );
					sGUI.outputPanel.setString( "Project[ " ~ project.projectName ~ " ] Parser Updating......\n" );
					sGUI.statusBar.setString( "" );
					sGUI.outputPanel.setBusy( true );
					
					char[][] filesName = sGUI.packageExp.getProjectFiles( project, true );
					sAutoComplete.addProjectParser( filesName );
					
					sGUI.outputPanel.setBusy( false );
					sGUI.outputPanel.appendString( "Project[ " ~ project.projectName ~ " ] Parser Updated Finish.\n\n" );
				}
			}
		}

		Globals.defaultParserPaths = listDefaultParsers.getItems();
	}

	public char[] getTitle()
	{
		return Globals.getTranslation( "pref.parser" );
	}

	private void initGUI()
	{
		setLayout( LayoutShop.createGridLayout( 1 ) );

		// Load version
		auto versionGroup = new Group( this, DWT.NONE );
		versionGroup.setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
		GridLayout gridLayout = new GridLayout();
 		gridLayout.numColumns = 2;
 		versionGroup.setLayout( gridLayout );

		with( btnV1 = new Button( versionGroup, DWT.RADIO ) )
		{
			setText( Globals.getTranslation( "pap.v1" ) );
			if( Globals.parserDMDversion < 2 ) setSelection( true );
			handleEvent( null, DWT.Selection, &onAction );
		}
		
		with( btnV2 = new Button( versionGroup, DWT.RADIO ) )
		{
			setText( Globals.getTranslation( "pap.v2" ) );
			if( Globals.parserDMDversion > 1 ) setSelection( true );
			handleEvent( null, DWT.Selection, &onAction );
		}

		
		Table		tableParser;
		with( tableParser = new Table( this, DWT.BORDER | DWT.CHECK ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 10;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
			//handleEvent( null, DWT.DefaultSelection, &onTableDefaultSelection );
			handleEvent( null, DWT.Selection, &onAction );
		}

		for( int i = 0; i < 15; ++ i )
		{
			char[] 	beTransOptionName =  "pap.o" ~ std.string.toString( i );
			char[] 	optionName = Globals.getTranslation( beTransOptionName );

			if( beTransOptionName == optionName ) break;
			
			with( items[i] = new TableItem( tableParser, DWT.NULL ) )
			{
				setText( optionName );
			}
			
		}
		loadOptions();

		/+
		with( chkUseCodeCompletion = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.use" );
			setSelection( Globals.useCodeCompletion );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}

		with( chkOnlyClassBorwser = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.only" );
			setSelection( Globals.showOnlyClassBrowser );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}

		with( chkAutoImport = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.import" );
			setSelection( Globals.parseImported );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}
		
		with( chkAutoAll = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.all" );
			setSelection( Globals.parseAllModule );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}

		with( chkUpdateParserLive = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.update" );
			setSelection( Globals.updateParseLive );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}		

		with( chkUpdateParserLiveFull = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.updatefull" );
			setSelection( Globals.updateParseLiveFull );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}	
		
		with( chkShowAllMember = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.show" );
			setSelection( Globals.showAllMember );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}

		with( chkShowType = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.showlisttype" );
			setSelection( Globals.showType );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}

		with( chkJumpTop = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.jumptop" );
			setSelection( Globals.jumpTop );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}	

		with( chkCaseSensitive = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.case" );
			setSelection( Globals.parserCaseSensitive );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}		

		with( chkUseDefaultParser = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.load_default" );
			setSelection( Globals.useDefaultParser );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}

		with( chkBackgroundLoad = new Button( this, DWT.CHECK ) )
		{
			setData( LANG_ID, "pap.thread" );
			setSelection( Globals.backLoadParser );
			//setLayoutData( LayoutDataShop.createGridData( GridData.GRAB_HORIZONTAL, 1 ) );
			handleEvent(null, DWT.Selection, &onAction);
		}
		+/
		auto letterGroup = new Group( this, DWT.NONE );
		letterGroup.setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
		//GridLayout gridLayout = new GridLayout();
 		gridLayout.numColumns = 2;
 		letterGroup.setLayout( gridLayout );
		
		with( new Label( letterGroup, DWT.NONE ) )
		{
			setText( Globals.getTranslation("pap.letter") );
		}

		char[] _count = std.string.toString( Globals.lanchLetterCount );
		with( txtLetters = new Text( letterGroup, DWT.BORDER ) )
		{
			handleEvent(null, DWT.KeyDown, &onAction);
			if( Globals.lanchLetterCount > 0 ) setText( _count );
			setLayoutData( new GridData( GridData.FILL, GridData.CENTER, true, false, 1, 1 ) );	
		}

		// Directory
		Group directoryGroup = new Group( this, DWT.NONE );
		directoryGroup.setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
				
		directoryGroup.setText( Globals.getTranslation( "pap.default" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 2;
		directoryGroup.setLayout( gridLayout );

		with( listDefaultParsers = new List( directoryGroup, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 5 );
			Font font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 4;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
		}
		if( Globals.defaultParserPaths.length )
			listDefaultParsers.setItems( Globals.defaultParserPaths );

		with( new Button( directoryGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("add_obj") );
			setToolTipText( Globals.getTranslation( "pp.add" ) );
			handleEvent( null, DWT.Selection, &onEdit1_0 );
		}

		with( new Button( directoryGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("delete_obj") );
			setToolTipText( Globals.getTranslation( "pp.delete" ) );
			handleEvent( null, DWT.Selection, &onEdit1_1 );
		}

		/+
		with( new Button( directoryGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("write_obj") );
			setToolTipText( Globals.getTranslation( "pp.edit" ) );
			handleEvent( null, DWT.Selection, &onEdit1_2 );
		}
		+/
		// Make
		Group makeGroup = new Group( this, DWT.NONE );
		makeGroup.setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
				
		makeGroup.setText( Globals.getTranslation( "pap.make_default" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 3;
		makeGroup.setLayout( gridLayout );		

		with( txtMakeDefaultParser = new Text( makeGroup, DWT.BORDER ) )
		{
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ));
		}

		// DMD's path button
		with( new Button( makeGroup, DWT.PUSH ) ) 
		{
			setText( "..." );
			handleEvent( null, DWT.Selection, &onBrowseDirParser );
		}

		with( new Button( makeGroup, DWT.PUSH ) )
		{
			setData( LANG_ID, "pap.make" );
			handleEvent( null, DWT.Selection, &onMakeParser );
		}
	}

	private void loadOptions()
	{
		items[0].setChecked = Globals.useCodeCompletion;
		items[1].setChecked = Globals.showOnlyClassBrowser;
		items[2].setChecked = Globals.parseImported;
		items[3].setChecked = Globals.parseAllModule;
		items[4].setChecked = Globals.updateParseLive;
		items[5].setChecked = Globals.updateParseLiveFull = 0;
		items[6].setChecked = Globals.showAllMember;
		items[7].setChecked = Globals.showType;
		items[8].setChecked = Globals.jumpTop;
		items[9].setChecked = Globals.parserCaseSensitive;
		items[10].setChecked = Globals.useDefaultParser;
		items[11].setChecked = Globals.backLoadParser;
		items[12].setChecked = Globals.showAutomatically;
	}


	public void restoreDefaults()
	{
		btnV1.setSelection = 1;
		
		items[0].setChecked = 1;
		items[1].setChecked = 0;
		items[2].setChecked = 0;
		items[3].setChecked = 1;
		items[4].setChecked = 1;
		items[5].setChecked = 0;
		items[6].setChecked = 0;
		items[7].setChecked = 1;
		items[8].setChecked = 0;
		items[9].setChecked = 0;
		items[10].setChecked = 0;
		items[11].setChecked = 1;
		items[12].setChecked = 1;
		/*
		chkUseCodeCompletion.setSelection( true );
		chkAutoAll.setSelection( false );
		chkOnlyClassBorwser.setSelection( false );
		chkUpdateParserLive.setSelection( false );
		chkUpdateParserLiveFull.setSelection( false );
		chkAutoAll.setSelection( false );
		chkShowAllMember.setSelection( true );
		chkShowType.setSelection( false );
		chkUseDefaultParser.setSelection( true );
		chkBackgroundLoad.setSelection( false );
		chkJumpTop.setSelection( false );
		chkCaseSensitive.setSelection( false );
		*/
		txtLetters.setText( "2" );
		listDefaultParsers.add( "std" );
		
		setDirty( true );
	}

	
	private void onAction( Event e )
	{
		setDirty( true );
		//if( chkUpdateParserLive.getSelection() ) chkUpdateParserLiveFull.setSelection( false );
		//if( chkUpdateParserLiveFull.getSelection() ) chkUpdateParserLive.setSelection( false );
	}

	private void onEdit1_0( Event e )
	{
		class _Dlg : GeneralDialog 
		{
			List 	list;
			Button 	btnOK, btnCancel;
			
			this( Shell parent )
			{
				super( parent );
			}

			private char[][] findAnaPath( char[] BaseRootDir )
			{
				char[][] paths;
				
				foreach( char[] pathName;  std.file.listdir( BaseRootDir ) )
					if( std.file.isdir( BaseRootDir ~ "\\" ~ pathName ) ) paths ~= pathName;

				return paths;
			}
			
			
			protected Shell createShell(Shell parent)
			{
				Shell shell = new Shell( parent, DWT.RESIZE | DWT.DIALOG_TRIM | DWT.APPLICATION_MODAL );				
				shell.setText( Globals.getTranslation( "diag.title4" ) );
				shell.setLayout(new GridLayout(2,false));
				list = new List(shell, DWT.V_SCROLL | DWT.BORDER | DWT.SINGLE);
				list.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 2, 1));
				// Note, the event is different from btnOK's onOK(Event e)
				list.handleEvent( null, DWT.DefaultSelection, &onOK );

				char[][] listDFile = findAnaPath( Globals.appDir ~ "\\ana" );
				foreach( char[] s; listDFile )
					list.add( s );

				// btns[0] is OK button, btns[1] is Cancel button
				Button[] btns = createButtonBar(shell);
				shell.setDefaultButton(btns[0]);
				btns[0].handleEvent(null, DWT.Selection, &onOK);
				
				shell.pack();
				Point pt = shell.getSize();
				shell.setSize(pt.x + 20, pt.x);

				return shell;
			}
			
			protected void onOK( Event e )
			{
				int sel = list.getSelectionIndex();
				if( sel >= 0 ) result = list.getItem( sel );

				getShell().close();
			}
		}

		scope _Dlg dlg = new _Dlg( getShell() );
		touchAdd( listDefaultParsers, dlg.open() );

		setDirty( true );
	}

	private void onEdit1_1( Event e )
	{ 
		touchDel( listDefaultParsers );
		setDirty( true );
	}

	/+
	private void onEdit1_2( Event e )
	{
		if( hasSelect( listDefaultParsers ) )
		{
			scope dlg = new _editDlg( getShell(), 0, 0, Globals.getTranslation( "diag.title4_1" ), listDefaultParsers.getItem( listDefaultParsers.getFocusIndex() ) );
			touchEdit( listDefaultParsers, dlg.open() ); 
			setDirty( true );
		}
	}
	+/

	private bool hasSelect( List activeList )
	{
		if( activeList.getItemCount() == 0 ) return false;
		if( activeList.getFocusIndex() == -1 ) return false;
		if( activeList.getSelectionCount == 0 ) return false;

		return true;
	}
	
	private void touchAdd( List activeList, char[] str )
	{
		if( !str.length ) return;

		char[][] files = std.string.split( str, ";" );
		foreach( char[] s; files )
			activeList.add( s );
			
		activeList.setTopIndex( activeList.getItemCount());
		activeList.deselectAll();
		activeList.select( activeList.getItemCount() - files.length ,activeList.getItemCount() - 1 );		
	}

	private void touchDel( List activeList )
	{
		if( hasSelect( activeList ) )
			activeList.remove( activeList.getSelectionIndices() );
	}

	/+
	private void touchEdit( List activeList, char[] str )
	{
		if( !str.length ) return;

		int index = activeList.getFocusIndex();
		activeList.setItem( index, str );
		activeList.deselectAll();
		activeList.select( index );
	}
	+/

	private void onBrowseDirParser( Event e )
	{
		scope wc = new WaitCursor(shell);
		
		scope dlg = new DirectoryDialog( shell, DWT.OPEN );
		dlg.setFilterPath( Globals.recentDir );
		char[] fullpath = std.string.strip( dlg.open() );
		if( fullpath ) txtMakeDefaultParser.setText( fullpath );
	}

	private void onMakeParser( Event e )
	{
		try
		{
			if( std.file.isdir( txtMakeDefaultParser.getText() ) > 0 )
			{
				scope dlg = new EditDlg( getShell(), 0, ["*.d","*.*"], Globals.getTranslation( "diag.title6" ), txtMakeDefaultParser.getText(), 1 );
				dlg.open();
			}
		}
		catch
		{
			txtMakeDefaultParser.setText( "" );
			return;
		}
	}
}
