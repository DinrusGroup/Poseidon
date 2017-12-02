module poseidon.controller.dialog.generaldialog;

private
{
	import dwt.all;
	import poseidon.globals;
	import poseidon.util.layoutshop;
}


/**
 *  General Dialog. if JFace is ported, we don't need to implement them at all
 */
class GeneralDialog : Dialog {
	protected char[] 	result = null;
	protected Shell 	shell;		/// Shell embeded in the dialog
	protected char[] 	iconString;
	
	this(Shell parent, int style = DWT.NONE){
		super(parent, style);		
	}
	
	public void close() {
		if(shell)
			shell.close();
	}	
	
	/// derived class override this method to initlize the shell
	protected Shell createShell(Shell parent){
		return new Shell(parent, DWT.DIALOG_TRIM|DWT.APPLICATION_MODAL);
	}
	
	/**
	 * In most case, there is a pair buttons "OK"/"Cancel" at the bottom of dialog, call this method to create the buttons and the their container.
	 * Params:
	 *		parent = the parent comosite or shell. It is assumed that the parent has a GridLayout as layout manager.
	 *		centered = whether the OK/Cancel buttons aligned in center, default false to align to end;
	 *		horizontalLine = indicate whether a separater line is created.
	 * Returns:
	 *		Button[] buttons; buttons[0] is OK button, buttons[1] is Cancel button. To get the button bar itself, use button[0].getParent();
	 */
	protected Button[] createButtonBar(Composite parent, bool centered = false, bool horizontalLine = false)
	{
		if(horizontalLine){
			with(new Label(parent, DWT.HORIZONTAL | DWT.SEPARATOR)){
				setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, 2, 1));
			}	
		}
		
		Composite btnBar = new Composite(parent, DWT.NONE);
		btnBar.setLayoutData(new GridData( centered ? GridData.CENTER : GridData.END, GridData.CENTER, true, false));
		btnBar.setLayout(LayoutShop.createGridLayout(2, 5, 5, 10, 10, true));
		
		// caller should handle OK button's Selection Event		
		Button btnok;
		with(btnok = new Button(btnBar, DWT.PUSH)){
			setText(Globals.getTranslation("OK"));
			setLayoutData(LayoutDataShop.createGridData(GridData.FILL_HORIZONTAL, 1, 1, 70));
		}
		
		// Action of Cancel Button is always set return value to null and close the dialog
		Button btncancel;
		with(btncancel = new Button(btnBar, DWT.PUSH)){
			setText(Globals.getTranslation("CANCEL"));
			setLayoutData(LayoutDataShop.createGridData(GridData.FILL_HORIZONTAL, 1, 1, 70));
			handleEvent(this, DWT.Selection, delegate(Event e){
				GeneralDialog pthis = cast(GeneralDialog)e.cData;
				pthis.result = null;
				pthis.getShell().close();
			});
		}
		
		Button[] result;
		result ~= btnok;
		result ~= btncancel;
		
		return result;  
	}
	
	/**
	 * Returns: The Shell embeded in the dialog. 
	 */
	public Shell getShell() {
		return shell;
	}
	
	public char[] open() {
		Shell parent = getParent();		
		this.shell = createShell(parent);
		assert(shell);

		if( iconString.length ) this.shell.setImage( Globals.getImage( iconString ) );
		
		if(shell.getText().length == 0)
			shell.setText(this.getText());
		shell.centerWindow(parent);
		shell.open();
		Display display = parent.getDisplay();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch()) display.sleep();
		}
		return result;
	}

	public void setText(char[] string){
		super.setText(string);
		if(shell)
			shell.setText(string);
	}

	public void setImageString( char[] iconstr )
	{
		this.iconString = iconstr;
		if( shell )
			shell.setImage( Globals.getImage( iconstr ) );
	}	
}

class AskStringDlg : GeneralDialog {
	private Text	txt;
	private char[] 	title;
	private char[] 	iniString;
	private boolean delegate(char[] str) _validate = null;
	private Button 	btnOK;
	
	public this (Shell parent, char[] title, char[] iniString) {
		super (parent); 
		this.title = title;
		this.iniString = iniString;
	}
	
	private void onOK() {
		char[] str = txt.getText();
		if(_validate && !_validate(str)){
			MessageBox.showMessage(Globals.getTranslation("mb.invalid_string"), Globals.getTranslation("ERROR"), getShell(), DWT.ICON_ERROR);
			return;
		}
		if(str.length == 0){
			// the caller may check the return value against null instead of its length
			str = null;
		}
		result = str;
		
		getShell().close();
	}
	
	private void onCancel() {
	}
	
	protected Shell createShell(Shell parent){		
		Shell shell = new Shell(parent, DWT.DIALOG_TRIM | DWT.APPLICATION_MODAL);		
		GridLayout layout = new GridLayout(2, true);
		shell.setLayout(layout);
		with(layout){
			// numColumns = 2;
			// marginLeft = 20;
			// marginRight = 20;
			// marginTop = 20;
			// marginBottom = 20;
			marginHeight = 16;
			marginWidth = 24;
			horizontalSpacing = 24;
			verticalSpacing  = 8;
		}
		
		Label label = new Label(shell, DWT.NONE);
		label.setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, 2, 1));
		label.setText(title);
		txt = new Text(shell, DWT.SINGLE | DWT.BORDER);
		txt.setLayoutData(new GridData(GridData.FILL, GridData.CENTER, true, false, 2, 1));
		txt.handleEvent(null, DWT.Modify, &onModify);
		
		btnOK = new Button(shell, DWT.PUSH);
		btnOK.setText(Globals.getTranslation("OK"));
		btnOK.setLayoutData(new GridData(60, DWT.DEFAULT));
		btnOK.handleSelection(this, delegate(SelectionEvent e){
			AskStringDlg pThis = cast(AskStringDlg)e.cData;
			pThis.onOK();
		});
		Button btn = new Button(shell, DWT.PUSH);
		btn.setText(Globals.getTranslation("CANCEL"));
		btn.setLayoutData(new GridData(60, DWT.DEFAULT));
		btn.handleSelection(this, delegate(SelectionEvent e){
			AskStringDlg pThis = cast(AskStringDlg)e.cData;
			pThis.getShell().close(); // don't use pThis.close()
		});
		
		if(iniString){
			txt.setText(iniString);
			txt.setSelection(0, iniString.length);
		}
		else if(_validate !is null){
			btnOK.setEnabled(false);
		}
		shell.setDefaultButton(btnOK);
		shell.pack();
		
		return shell;
	}
	
	public void setValidateDelegate(boolean delegate(char[]) func) {
		assert(func);
		_validate = func;
	}
	
	private void onModify(Event e){
		if(_validate)
			btnOK.setEnabled(_validate(txt.getText()));
	}	
}


class EditDlg : GeneralDialog
{
	private
	{
		import poseidon.util.waitcursor;
		import poseidon.controller.packageexplorer;
		import poseidon.controller.gui;
		import CodeAnalyzer.syntax.nodeHsu;
	
		Button 		btnBrowser, btnOK, btnCancel, btnYes, btnNo;
		Text    	txtEditDir;
		int			type, titleType;
		char[]		title, filename;
		char[][]	fileExt;
	}

	int zipAll;
	
	this( Shell parent, int browserType = 0, char[][] fileExtension = null, char[] winTitle = "", char[] existFile = "", int _titleType = 0 )
	{
		/*
		_titleTtype = 0 	default
		_titleTtype = 1 	title == "Set Parser Dir Name"
		_titleTtype = 2 	title == "Set Zip Directory..."
		_titleTtype = 3 	yes/no
		*/
		type	 = browserType;
		fileExt  = fileExtension;
		title    = winTitle;
		filename = existFile;
		titleType = _titleType;
		
		super( parent );
	}
			
					
	Shell createShell( Shell parent )
	{
		Shell shell = new Shell( parent , DWT.DIALOG_TRIM | DWT.APPLICATION_MODAL );				
		with( shell )
		{
			setText( title );
			setSize( 300, 100 ); 
			setLayout( new GridLayout( 2, false ) );
		}

		if( titleType == 3 )
		{
			Group groupYesOrNo = new Group( shell, DWT.NONE );

			with( groupYesOrNo )
			{
				setLayoutData( new GridData( GridData.FILL, GridData.CENTER, false, false ) );
				FillLayout f = new FillLayout( DWT.HORIZONTAL );
				setLayout( f );
			}

			GridData gridData = new GridData( GridData.FILL_HORIZONTAL );
			gridData.horizontalSpan = 2;
			groupYesOrNo.setLayoutData( gridData );			
					
			btnYes = new Button( groupYesOrNo, DWT.RADIO );
			btnYes.setText("Yes");
		
			btnNo = new Button( groupYesOrNo, DWT.RADIO );
			btnNo.setText("No");

			if( filename == "yes" )
				btnYes.setSelection( true );
			else if( filename == "no" )
				btnNo.setSelection( true );
		}
		else
		{
			with( txtEditDir = new Text( shell, DWT.BORDER ) )
			{
				setText( filename );
				selectAll();
				GridData gd = new GridData();
				gd.widthHint = 350;
				gd.horizontalAlignment  = GridData.HORIZONTAL_ALIGN_FILL;
				setLayoutData( gd );
			}

			if( titleType != 1 )
			{
				with( btnBrowser = new Button( shell, DWT.FLAT ) )
				{
					setText( "..." );
					setLayoutData( new GridData( GridData.HORIZONTAL_ALIGN_FILL ) );

					switch( type )
					{
						case -1:
							setEnabled( false ); break;
						case 0:
							handleEvent( null, DWT.Selection, &onEditBrowseDir ); break;
						case 1:
							handleEvent( null, DWT.Selection, &onEditBrowseFile ); break;
						case 2:
							handleEvent( null, DWT.Selection, &onEditBrowseFile ); break;					
					}
					
				}


				if( titleType == 2 )
				{
					shell.setImage( Globals.getImage( "zip" ) );
					Group groupZip = new Group( shell, DWT.NONE );

					with( groupZip )
					{
						setLayoutData( new GridData( GridData.FILL, GridData.CENTER, false, false ) );
						FillLayout f = new FillLayout( DWT.HORIZONTAL );
						setLayout( f );
					}

					GridData gridData = new GridData( GridData.FILL_HORIZONTAL );
					gridData.horizontalSpan = 2;
					groupZip.setLayoutData( gridData );			
					
					Button radio = new Button( groupZip, DWT.RADIO );
					with( radio )
					{
						setText( Globals.getTranslation( "zip.only" ) );
						setData( new Integer( 0 ) );
						setSelection( true );
						handleEvent( null, DWT.Selection, &onCompressChange );
					}

					Button radio1 = new Button( groupZip, DWT.RADIO );
					with( radio1 )
					{
						setText( Globals.getTranslation( "zip.all" ) );
						setData( new Integer( 1 ) );
						setSelection( false );
						handleEvent( null, DWT.Selection, &onCompressChange );
					}				
				}
			}
			else
			{
				txtEditDir.setText( std.path.getBaseName( filename ) );
			}
		}

		// btns[0] is OK button, btns[1] is Cancel button
		Button[] btns = createButtonBar( shell );
		shell.setDefaultButton( btns[0] );
		btns[0].handleEvent( null, DWT.Selection, &onOK );
						
		shell.pack();

		return shell;
	}


	private void onCompressChange( Event e )
	{
		Button radio = cast(Button) e.widget;

		if( !radio.getSelection() )	return;
		
		Integer ii = cast(Integer) radio.getData();
		assert( ii );
		zipAll = ii.intValue();
	}
	
	protected void onOK( Event e )
	{
		if( titleType == 3 )
		{
			if( btnYes.getSelection() )
				result = "yes"; 
			else if( btnNo.getSelection() )
				result = "no";
			else
				result = "";
		}
		else
		{
			result = std.string.strip( txtEditDir.getText() );

			if( titleType == 1 )
			{
				result = std.path.getBaseName( result );
				if( result.length )
				{
					char[] dirName = Globals.appDir ~ "\\ana\\" ~ std.path.getBaseName( result );

					if( !std.file.exists( Globals.appDir ~ "\\ana" ) ) 
						std.file.mkdir( Globals.appDir ~ "\\ana" );
					
					if( !std.file.exists( dirName ) ) 
					{
						std.file.mkdir( dirName );
					}
					else
					{
						scope dirFiles = new CFindAllFile( dirName );
						char[][] fs = dirFiles.getFiles();

						foreach( char[] s; fs )
							std.file.remove( s );
						
					}

					scope stdFiles = new CFindAllFile( filename, ["*.d","*.di"] );
					char[][] files = stdFiles.getFiles();

					sGUI.outputPanel.clear();
					sGUI.outputPanel.bringToFront();

					foreach( char[] s; files )
					{
						sGUI.outputPanel.appendString( "Parsing [ " ~ s ~ " ]..." );

						try
						{
							scope head = CodeAnalyzer.syntax.core.parseFileHSU( s );

							if( head is null )
							{
								sGUI.outputPanel.appendString( "...Error!!\n" );
							}
							else
							{
								/*
								char[] f = std.string.replace( s, filename, null );
								f = std.string.replace( f[0] == '\\' ? f[1..length] : f, "\\", "-" );
								syntax.nodeHsu.savenalyzerNode( dirName ~ "\\" ~ f, head );
								*/
								CodeAnalyzer.syntax.nodeHsu.savenalyzerNode( dirName, head, s );
								sGUI.outputPanel.appendString( "...Save Ok!!\n" );
							}
						}
						catch
						{
							sGUI.outputPanel.appendString( "...Error!!\n" );
						}
					}

					if( files.length )
						sGUI.outputPanel.appendString( "Make Default Parser [ " ~ std.path.getBaseName( result ) ~ " ] done.\n" );
					else
						sGUI.outputPanel.appendString( "Make Default Parser [ " ~ std.path.getBaseName( result ) ~ " ] Error.\n" );
					
				}
			}
		}
		
		getShell().close();
	}

	protected void onEditBrowseDir( Event e )
	{
		scope wc = new WaitCursor( shell );
		
		scope dlg = new DirectoryDialog(shell, DWT.OPEN);
		dlg.setFilterPath(Globals.recentDir);
		char[] fullpath = dlg.open();
		if( fullpath )
		{
			txtEditDir.setText( fullpath );
			Globals.recentDir = fullpath;
		}
	}

	protected void onEditBrowseFile( Event e )
	{
		scope wc = new WaitCursor( shell );
		scope FileDialog dlg;

		if( type == 2 )
			dlg = new FileDialog( shell, DWT.OPEN );
		else
			dlg = new FileDialog( shell, DWT.OPEN | DWT.MULTI );
		

		dlg.setFilterPath( Globals.recentDir );
		if( fileExt.length ) dlg.setFilterExtensions( fileExt );

		char[] activeDir = std.path.getDirName( dlg.open() );
		char[][] SelectedFiles = dlg.getFileNames();
		char[][] files;
		if( SelectedFiles.length )
		{
			foreach( char[] s; SelectedFiles )
				files ~= std.path.join( activeDir, s );
			
			char[] ret = std.string.join( files, ";" );
			txtEditDir.setText( ret );
			Globals.recentDir = activeDir;
		}
	}
}

