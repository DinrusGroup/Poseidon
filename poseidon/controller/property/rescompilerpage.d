module poseidon.controller.property.rescompilerpage;

private import poseidon.controller.dialog.generaldialog;


class CResourceCompilerDialog : GeneralDialog
{
private:
	import std.string;
	import dwt.all;
	import poseidon.globals;
	import poseidon.controller.gui;
	import poseidon.i18n.itranslatable;
	import poseidon.util.layoutshop;
	import poseidon.util.miscutil;
	import poseidon.model.project;
	
	

	Text	txtSource, txtDest, txtCommand;
	Table	tableOption;
	List	listImport;
	Button	btnOK;
	
	char[] 	title;
	char[] 	iniString;
	
	
	void onOK()
	{
		char[] command = std.string.strip( txtCommand.getText() );
		if( !command.length )
		{
			foreach( char[] s; listImport.getItems() )
				command ~= ( "-I " ~ std.string.strip( s ) );

			if( command.length) command ~= " ";

			foreach( TableItem ti; tableOption.getItems() )
			{
				if( ti.getChecked() )
					command ~= ( Project.getBracketText( ti.getText( 0 ) ) ~ " " );
			}

			if( command.length) command = "-r " ~ command ~ " ";

			command ~= ( std.string.strip( txtSource.getText ) ~ " " ~ std.string.strip( txtDest.getText ) );
		}

		result = command;
		getShell().close();
	}
	
	void onCancel(){}

	bool hasSelect( List activeList )
	{
		if( activeList.getItemCount() == 0 ) return false;
		if( activeList.getFocusIndex() == -1 ) return false;
		if( activeList.getSelectionCount == 0 ) return false;

		return true;
	}	

	void touchDel( Event e )
	{
		if( hasSelect( listImport ) ) listImport.remove( listImport.getSelectionIndices() );
	}

	void touchEdit( Event e )
	{
		if( hasSelect( listImport ) )
		{
			scope dlg = new EditDlg( getShell(), 0, null, Globals.getTranslation( "diag.title1_1" ), listImport.getItem( listImport.getFocusIndex() ) );
			char[] str = std.string.strip( dlg.open() );
			
			if( !str.length ) return;

			int index = listImport.getFocusIndex();
			listImport.setItem( index, str );
			listImport.deselectAll();
			listImport.select( index );
		}
	}
	
	void touchAdd( Event e )
	{
		scope dlg = new EditDlg( getShell(), 0, null, Globals.getTranslation( "diag.title1" ), null );
		char[] str = std.string.strip( dlg.open() );
		char[][] files = std.string.split( str, ";" );
		foreach( char[] s; files )
			listImport.add( s );
			
		listImport.setTopIndex( listImport.getItemCount());
		listImport.deselectAll();
		listImport.select( listImport.getItemCount() - files.length ,listImport.getItemCount() - 1 );	
	}

	void onUp( Event e )
	{
		with( listImport )
		{
			if( getItemCount() == 0 ) return;
			if( getFocusIndex() == -1 ) return;
			if( getSelectionCount() == 0 ) return;
			
			int index = getSelectionIndex();
			if( index <= 0 )
				return;
			else
				swapListItem( listImport, index, index - 1 );
		}
	}

	void onDown( Event e )
	{
		with( listImport )
		{
			if( getItemCount() == 0 ) return;
			if( getFocusIndex() == -1 ) return;
			if( getSelectionCount() == 0 ) return;
			
			int index = getSelectionIndex();
			if( getItemCount() <= index )
				return;
			else
				swapListItem( listImport, index, index + 1 );
		}
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

	
protected:
	Shell createShell(Shell parent)
	{		
		Shell shell = new Shell(parent, DWT.DIALOG_TRIM | DWT.APPLICATION_MODAL);
		GridLayout layout = new GridLayout(3, 0);
		shell.setLayout(layout);

		with( new Label(shell, DWT.NONE) )
		{
			setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, false, 3, 1));
			setText( "RC Compiler : " ~ Globals.DMCPath ~ "\\bin\\rc.exe"  );
		}


		Group resOptionsGroup = new Group( shell, DWT.NONE );
		resOptionsGroup.setText( Globals.getTranslation( "pp2.rcoptions" ) );
		auto gridLayout = new GridLayout();
		gridLayout.numColumns = 1;
		resOptionsGroup.setLayout( gridLayout );
		GridData gridData = new GridData( GridData.FILL_HORIZONTAL );
		gridData.horizontalSpan = 3;
		resOptionsGroup.setLayoutData( gridData );
		

		with( tableOption = new Table( resOptionsGroup, DWT.BORDER | DWT.CHECK ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 6;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
			handleEvent( null, DWT.Selection, delegate( Event e )
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
			);
		}

		for( int i = 0; i < 50; ++ i )
		{
			char[] 	beTransOptionName =  "pp2.rc_o" ~ std.string.toString( i );
			char[] 	optionName = Globals.getTranslation( beTransOptionName );

			if( beTransOptionName == optionName ) break;

			with( new TableItem( tableOption, DWT.NULL ) )
			{
				setText( optionName );
				/*
				setChecked( bChecked );

				if( bChecked )
				{
					scope color = new Color( display, 0x99, 0xff, 0x66 );
					setBackground( 0, color );
				}
				*/
			}
		}


		Group importGroup = new Group( shell, DWT.NONE );
		importGroup.setText( Globals.getTranslation( "pp1.directory" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 5;
		importGroup.setLayout( gridLayout );
		gridData = new GridData( GridData.FILL_HORIZONTAL );
		gridData.horizontalSpan = 3;
		importGroup.setLayoutData( gridData );
		
		with( listImport = new List( importGroup, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 5, 5 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			
			int ListHeight = getItemHeight() * 9;
			Rectangle trim = computeTrim( 0, 0, 0, ListHeight );
			innergridData.heightHint = trim.height;
			setLayoutData( innergridData );
		}
		
		// Buttons
		with( new Button( importGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("add_obj") );
			setToolTipText( Globals.getTranslation( "pp.add" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &touchAdd );
		}

		with( new Button( importGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("delete_obj") );
			setToolTipText( Globals.getTranslation( "pp.delete" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &touchDel );
		}

		with( new Button( importGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("write_obj") );
			setToolTipText( Globals.getTranslation( "pp.edit" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &touchEdit );
		}

		with( new Button( importGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("prev_nav") );
			setToolTipText( Globals.getTranslation( "pp.moveup" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &onUp );
		}

		with( new Button( importGroup, DWT.FLAT ) )
		{
			setImage( Globals.getImage("next_nav") );
			setToolTipText( Globals.getTranslation( "pp.movedown" ) );
			setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );
			handleEvent( null, DWT.Selection, &onDown );
		}

		Group textGroup = new Group( shell, DWT.NONE );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 3;
		textGroup.setLayout( gridLayout );
		gridData = new GridData( GridData.FILL_HORIZONTAL );
		gridData.horizontalSpan = 3;
		textGroup.setLayoutData( gridData );
		
		with( new Label( textGroup, DWT.NONE ) ) setText( "Source:" );

		with( txtSource = new Text( textGroup, DWT.SINGLE | DWT.BORDER ) )
		{
			setText( iniString );
			setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, 1, 1));
		}

		with( new Button( textGroup, DWT.PUSH ) )
		{
			setText("...");
			handleSelection( this, delegate( SelectionEvent e )
			{
				CResourceCompilerDialog pThis = cast(CResourceCompilerDialog) e.cData;
				
				scope dlg = new DirectoryDialog( pThis.shell, DWT.OPEN );
				dlg.setFilterPath(Globals.recentDir);
				pThis.txtSource.setText( strip( dlg.open() ) );
			}
			);
		}		
		
		with( new Label( textGroup, DWT.NONE ) ) setText( "Destination:" );

		with( txtDest = new Text(textGroup, DWT.SINGLE | DWT.BORDER) )
		{
			setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, false, 1, 1));
		}

		with( new Button( textGroup, DWT.PUSH ) )
		{
			setText("...");
			handleSelection( this, delegate( SelectionEvent e )
			{
				CResourceCompilerDialog pThis = cast(CResourceCompilerDialog) e.cData;
				
				scope dlg = new DirectoryDialog( pThis.shell, DWT.OPEN );
				dlg.setFilterPath(Globals.recentDir);
				pThis.txtDest.setText( strip( dlg.open() ) );
			}
			);
		}	

		Group consoleGroup = new Group( shell, DWT.NONE );
		consoleGroup.setText( Globals.getTranslation( "pp2.command" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 1;
		consoleGroup.setLayout( gridLayout );
		gridData = new GridData( GridData.FILL_HORIZONTAL );
		gridData.horizontalSpan = 3;
		consoleGroup.setLayoutData( gridData );

		with( txtCommand = new Text( consoleGroup, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL | DWT.WRAP ) )
		{
			GridData innergridData = new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 );
			scope font = new Font( display, "Verdana", 8, DWT.NORMAL );
			setFont( font );
			innergridData.heightHint = 32;
			setLayoutData( innergridData );
		}

		// the bottom buttton bar
		Button[] buts = createButtonBar( shell, false, true );
		btnOK = buts[0];
		btnOK.handleSelection( this, delegate( SelectionEvent e )
		{
			CResourceCompilerDialog pThis = cast(CResourceCompilerDialog)e.cData;
			pThis.onOK();
		} 
		);		
		
		shell.setDefaultButton(btnOK);
		shell.pack();

		Point pt = shell.getSize();
		pt.x = pt.y * 3 / 3;
		shell.setSize(pt);
		shell.setMinimumSize(pt);
		
		
		return shell;
	}

public:
	this( Shell parent, char[] title, char[] iniString )
	{
		super( parent );
		this.title = title;
		this.iniString = iniString;
	}
}