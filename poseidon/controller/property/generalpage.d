module poseidon.controller.property.generalpage;

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

class GeneralPage : AbstractPage
{
	private Button 	chkShowSplash, chkLoadWorkspace, chkUseOutputWrap, chkAbsoluteFullpath;
	private Text	txtExplorerFilters;
	private Text[5] txtDDocuments;
	private import std.string;


	this(Composite parent, IPropertyPage parentPage, void delegate(bool) dirtyListener)
	{
		super(parent, parentPage, dirtyListener);
		initGUI();
	}

	public void applyChanges() 
	{
		Globals.showSplash = chkShowSplash.getSelection();
		Globals.loadWorkSpaceAtStart = chkLoadWorkspace.getSelection();
		if( chkUseOutputWrap.getSelection() ) Globals.outputWRAP = DWT.WRAP; else Globals.outputWRAP = 0;
		Globals.sendAbsoluteFullpath = chkAbsoluteFullpath.getSelection();
		Globals.SplitedExplorerFilter = poseidon.util.miscutil.MiscUtil.getSplitFilter( std.string.strip( txtExplorerFilters.getText() ) );
		Globals.DDcoumentDir.length = 0;
		for( int i = 0; i < 5; ++ i )
			Globals.DDcoumentDir ~= txtDDocuments[i].getText();

		sGUI.menuMan.refreshDocumentHelp();

		setDirty(false);
	}

	private Button createCheckBox(char[] langId, int initVal = false)
	{
		Button button = new Button(this, DWT.CHECK);
		with(button) {
			setData(LANG_ID, langId);
			setSelection(initVal);
			setLayoutData(LayoutDataShop.createGridData(GridData.GRAB_HORIZONTAL, 2));
			handleEvent(null, DWT.Selection, &onAction);
		}
		return button;
	}

	public char[] getTitle() {
		return Globals.getTranslation("GENERAL");
	}

	private void initGUI()
	{
		setLayout(LayoutShop.createGridLayout( 1 ));
		chkShowSplash = createCheckBox("gp.sw_splash", Globals.showSplash);
		chkLoadWorkspace = createCheckBox("gp.ld_wspace", Globals.loadWorkSpaceAtStart);
		chkUseOutputWrap = createCheckBox("gp.wrap", Globals.outputWRAP );
		chkAbsoluteFullpath = createCheckBox("gp.absolute", Globals.sendAbsoluteFullpath );

		Group documentGroup = new Group( this, DWT.NONE );
		documentGroup.setText( Globals.getTranslation( "gp.doc_title" ) );
		auto gridLayout = new GridLayout();
		gridLayout.numColumns = 3;
		documentGroup.setLayout( gridLayout );
		documentGroup.setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );

		// D Document
		for( int i = 0; i < 5; ++ i )
		{
			char[] s = " #" ~ std.string.toString( i ) ~ ":";
			with( new Label( documentGroup, DWT.NONE ) ){ setText( Globals.getTranslation("gp.doc") ~ s ); }

			with( txtDDocuments[i] = new Text( documentGroup, DWT.BORDER ) )
			{
				setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ) );
				if( Globals.DDcoumentDir.length > i ) setText( Globals.DDcoumentDir[i] );
				handleEvent( null, DWT.Modify, &onAction );
			}

			// D Dcoument button
			with( new Button( documentGroup, DWT.PUSH ) ) 
			{
				setText( "..." );
				setData( txtDDocuments[i] );
				handleSelection( this, delegate( SelectionEvent e )
				{
					GeneralPage pThis 	= cast(GeneralPage)e.cData;
					Button 		pButton = cast(Button) e.widget;

					scope dlg = new FileDialog( pThis.getShell, DWT.OPEN );
					
					dlg.setFilterPath( Globals.recentDir );
					dlg.setFilterExtensions( ["*.*"] );	
					Text text = cast(Text) pButton.getData();
					
					text.setText( strip( dlg.open() ) );

					setDirty(true);
				});				
			}
		}

		Group explorerGroup = new Group( this, DWT.NONE );
		explorerGroup.setText( Globals.getTranslation( "gp.filter" ) );
		gridLayout = new GridLayout();
		gridLayout.numColumns = 1;
		explorerGroup.setLayout( gridLayout );
		explorerGroup.setLayoutData( new GridData( GridData.FILL_HORIZONTAL ) );

		with( txtExplorerFilters = new Text( explorerGroup, DWT.BORDER  ) )
		{
			setLayoutData( new GridData( GridData.FILL, GridData.BEGINNING, true, false, 1, 1 ));
			setText( poseidon.util.miscutil.MiscUtil.getFilter( Globals.SplitedExplorerFilter ) );
			handleEvent( null, DWT.Modify, &onAction );
		}		
	}

	private void onAction( Event e )
	{	
		setDirty(true);
	}

	public void restoreDefaults()
	{
		chkShowSplash.setSelection( true );
		chkLoadWorkspace.setSelection( true );
		chkUseOutputWrap.setSelection( true );
		chkAbsoluteFullpath.setSelection( false );
		for( int i = 0; i < 5; ++ i )
			txtDDocuments[i].setText( "" );
		
		txtExplorerFilters.setText( "*.c;*.cpp;*.h;*.xml;*.txt;*.def" );

		setDirty(true);
	}
}