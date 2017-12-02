module poseidon.controller.edititem;

private import dwt.all;
private import dwt.extra.all;
private import dwt.internal.converter; 
 
private import poseidon.controller.editor;
private import poseidon.controller.bottompanel;
private import poseidon.controller.dialog.askreloaddlg;
private import poseidon.controller.dialog.finddlg;
private import poseidon.controller.dialog.generaldialog;
private import poseidon.controller.dialog.searchdlg;
private import poseidon.controller.gui;
private import poseidon.controller.packageexplorer;
private import poseidon.controller.scintillaex;
private import poseidon.globals;
private import poseidon.i18n.itranslatable;
private import poseidon.model.misc;
private import poseidon.model.navcache;
private import poseidon.model.project;
private import poseidon.util.fileutil;
private import poseidon.util.waitcursor;
private import poseidon.model.editorsettings;

private import CodeAnalyzer.syntax.core;
import std.stdio;

private import std.stream;
private import std.c.windows.windows;

extern (Windows) 
{
	BOOL GetFileTime
	(
		HANDLE hFile,                 // handle to the file
		LPFILETIME lpCreationTime,    // address of creation time
		LPFILETIME lpLastAccessTime,  // address of last access time
		LPFILETIME lpLastWriteTime    // address of last write time
	);
}

class EditItem : CTabItem 
{
	private import poseidon.controller.debugcontrol.debugparser;
	private import poseidon.controller.ddoc.ddocparser;
	
	Editor 				_parent;
	ScintillaEx 		scintilla;
	ItemInfo			iteminfo;
	FILETIME			filetime;		// monitor the file change externally
	private int 		lastGoto = -1;		// the last goto line number
	CAnalyzerTreeNode	fileParser;	


	/**
	* ItemInfo can be null, when a file is not in any opened projects.
	* If ItemInfo argument is valid, the fullPathName must be equal.
	*/
	this( Editor parent, ItemInfo iteminfo, char[] fullPathName )
	{
		super( parent, DWT.None );
		
		debug
		{
			if( iteminfo ) assert( iteminfo.getFileName == fullPathName );
		}
		
		this._parent = parent;
		this.iteminfo = iteminfo;

		scintilla = new ScintillaEx( parent, DWT.NONE );
		char[] ext = std.path.getExt( fullPathName );
		this.setImage( Globals.getImageByExt( ext ) );
		this.setControl( scintilla );	
		
		this.handleEvent(null, DWT.Dispose, &onDispose);

		scintilla.defineMarker( Editor.MARK_SYMBOLE, Scintilla.SC_MARK_CIRCLE, 0x000000FF, 0x0000FFFF );
		scintilla.defineMarker( Editor.MARK_DEBUGSYMBOLE, Scintilla.SC_MARK_SMALLRECT, 0x0000FFFF, 0x00FF0000 );
		scintilla.defineMarker( Editor.MARK_DEBUGRUNSYMBOLE, Scintilla.SC_MARK_ARROW, 0x00FFFF00, 0x000000FF );
		scintilla.defineMarker( Editor.MARK_DEBUGRUNLINE, Scintilla.SC_MARK_ARROW, 0x00FFFF00, 0x000000FF );

		
		scintilla.handleEvent( null, DWT.KeyDown, &onKeyDown );
		scintilla.handleEvent( null, DWT.MouseDown, &onMouseDown );
		scintilla.handleNotify( null, Scintilla.SCN_DOUBLECLICK, &onDoubleClick );
		scintilla.handleNotify( null, Scintilla.SCN_MODIFYATTEMPTRO, &onModifyAttemptRo );
		scintilla.handleNotify( this, Scintilla.SCN_SAVEPOINTREACHED, &onSavePointChanged );
		scintilla.handleNotify( this, Scintilla.SCN_SAVEPOINTLEFT, &onSavePointChanged );
		scintilla.handleNotify( this, Scintilla.SCN_DWELLSTART,&onMouseDwellStart );
		scintilla.handleNotify( this, Scintilla.SCN_DWELLEND,&onMouseDwellEnd );
		scintilla.handleNotify( this, Scintilla.SCN_MARGINCLICK, delegate(SCNotifyEvent e)
		{
			if( e.margin == 1 ) 
			{
				EditItem pthis = cast(EditItem) e.cData;
				int lineNumber = pthis.scintilla.lineFromPosition( e.position );
				
				if( e.modifiers == Scintilla.SCMOD_CTRL )
					pthis.toggleDebugMarker( lineNumber );
				else
					pthis.toggleMarker( lineNumber );
			}
		});

		Editor.settings.applySettings( scintilla, std.path.getExt( fullPathName ) );

		scintilla.autoCSetSeparator( '^' );

		loadFile( fullPathName );
	}


	this( Editor parent, ItemInfo iteminfo, char[] fullPathName, ScintillaEx _scintilla, CAnalyzerTreeNode _fileParser, FILETIME _filetime, int index )
	{
		super( parent, DWT.None, index );
		
		debug
		{
			if( iteminfo ) assert( iteminfo.getFileName == fullPathName );
		}
		
		this._parent = parent;
		this.iteminfo = iteminfo;

		if( _scintilla !is null ) scintilla = _scintilla;
		this.filetime = _filetime;
		this.fileParser = _fileParser;

		
		// scintilla = new ScintillaEx( parent, DWT.NONE );
		char[] ext = std.path.getExt( fullPathName );
		this.setImage( Globals.getImageByExt( ext ) );
		//this.setText( std.path.getBaseName( fullPathName ) );
		//setControl( _scintilla );	

		
		this.handleEvent(null, DWT.Dispose, &onDispose);
		/+
		scintilla.defineMarker( Editor.MARK_SYMBOLE, Scintilla.SC_MARK_CIRCLE, 0x000000FF, 0x0000FFFF );
		scintilla.defineMarker( Editor.MARK_DEBUGSYMBOLE, Scintilla.SC_MARK_SMALLRECT, 0x0000FFFF, 0x00FF0000 );
		scintilla.defineMarker( Editor.MARK_DEBUGRUNSYMBOLE, Scintilla.SC_MARK_ARROW, 0x00FFFF00, 0x000000FF );
		scintilla.defineMarker( Editor.MARK_DEBUGRUNLINE, Scintilla.SC_MARK_ARROW, 0x00FFFF00, 0x000000FF );

		
		scintilla.handleEvent( null, DWT.KeyDown, &onKeyDown );
		scintilla.handleEvent( null, DWT.MouseDown, &onMouseDown );
		scintilla.handleNotify( null, Scintilla.SCN_DOUBLECLICK, &onDoubleClick );
		scintilla.handleNotify( null, Scintilla.SCN_MODIFYATTEMPTRO, &onModifyAttemptRo );
		scintilla.handleNotify( this, Scintilla.SCN_SAVEPOINTREACHED, &onSavePointChanged );
		scintilla.handleNotify( this, Scintilla.SCN_SAVEPOINTLEFT, &onSavePointChanged );
		scintilla.handleNotify( this, Scintilla.SCN_DWELLSTART,&onMouseDwellStart );
		scintilla.handleNotify( this, Scintilla.SCN_DWELLEND,&onMouseDwellEnd );
		scintilla.handleNotify( this, Scintilla.SCN_MARGINCLICK, delegate(SCNotifyEvent e)
		{
			if( e.margin == 1 ) 
			{
				EditItem pthis = cast(EditItem) e.cData;
				int lineNumber = pthis.scintilla.lineFromPosition( e.position );
				
				if( e.modifiers == Scintilla.SCMOD_CTRL )
					pthis.toggleDebugMarker( lineNumber );
				else
					pthis.toggleMarker( lineNumber );
			}
		});
		
		Editor.settings.applySettings( scintilla, std.path.getExt( fullPathName ) );
		
		scintilla.autoCSetSeparator( '^' );

		
		loadFile( fullPathName );
		+/
	}

	private _ShortCut[] hotkeys(){ return Globals.hotkeys; }
	private FindDlg findDlg(){ return _parent.findDlg; }
	
	private void adjustFindDialogPosition()
	{
		assert(_parent.findDlg);
		if( _parent.findDlg.isVisible() == false ) return;
		
		
		Scintilla sc = this.scintilla;
		int nStart = sc.getSelectionStart();
		int x = sc.pointXFromPosition(nStart);
		int y = sc.pointYFromPosition(nStart);
		
		Point point = sc.toDisplay(x, y);

		Rectangle rectDlg = _parent.findDlg.getBounds();
		
		if( rectDlg.contains( point ) )
		{
			if( point.y > rectDlg.height )
				rectDlg.y += point.y - (rectDlg.y + rectDlg.height) - 20;
			else
			{
				int nVertExt = this.getDisplay().getBounds().height;
				if( point.y + rectDlg.height < nVertExt )
				rectDlg.y += 40 + point.y - rectDlg.y;
			}
			_parent.findDlg.setBounds(rectDlg);
		}
	}

	private bool saveUntitled( bool bClose )
	{
		char[] fileName = getFileName();
		
		if( !std.path.getExt( fileName ) )
		{
			if( fileName.length >= 9 )
			{
				if( fileName[0..8] == "Untitled" ) 
				{
					scope dlg = new FileDialog( _parent.getShell, DWT.SAVE );
					dlg.setFilterPath( Globals.recentDir );
					dlg.setFileName( fileName );

					char[] result = std.string.strip( dlg.open() );
					if( result.length )
					{
						if( scintilla.saveFile( result , bClose ) )
						{
							try
							{
								std.file.remove( fileName );
								if( !bClose ) // Save | Save As
								{
									scintilla.loadFile( result ) ;

									char[] ext = std.path.getExt( result );
									this.setImage( Globals.getImageByExt( ext ) );
									Editor.settings.applySettings( scintilla, ext );
									sGUI.fileList.refresh();
								}
							}
							catch
							{
								MessageBox.showMessage( "Remove Untitled File: " ~ fileName ~ " Error!!" );
							}
						}
					}
					return true;
				}
			}
		}

		return false;
	}
	
	/**
	* If file closed successfully (saved or not), return true;
	* If file not closed (User choosed Cancel), return false, 
	* and keep CTabItem unclosed
	*/
	public boolean close( boolean checkModified = true ) 
	{
		boolean _closeSave()
		{
			// force to save
			if( scintilla.getModify() )
			{
				if( !saveUntitled( true ) )
				{
					char[] fn = getFileName();
					boolean result = scintilla.saveFile( fn , true );
					return result;
				}
			}
			return true;
		}
		
		// save before close
		if(checkModified && scintilla.getModify() )
		{
			// auto set/reset modifyChecking flag
			scope amp =  new AutoModifyProtect(_parent);

			char[] fileName = getFileName();
			
			switch( promptToSave( fileName ) )
			{
				case DWT.YES:
					try
					{
						updateFileParser( fileName );
					}
					catch
					{
					}
					
					_closeSave();
					break;
				/*
				case DWT.NO:
					this.dispose();
					return true;
					break;
				*/
				case DWT.CANCEL:
					return false;
					break;
				default : break;
			}
		}

		int newLine = scintilla.markerNext( 1, 1 << Editor.MARK_DEBUGSYMBOLE );
		while( newLine >= 0 )
		{
			sGUI.debuggerDMD.delBP_editor( getFileName(), newLine + 1 );
			newLine = scintilla.markerNext( newLine + 1, 1 << Editor.MARK_DEBUGSYMBOLE );
		}
		
		scintilla.markerDeleteAll( -1 );
		//if( fileParser ) delete fileParser;
		
		this.dispose();
		if( scintilla !is null ) delete scintilla;
		return true;
	}
	
	public int countAll()
	{
		FindOption fop = findDlg.fop.clone();
		fop._scope = SS_CURFILE;
			
		int result = Editor.processAll( fop, SearchDlg.COUNT_ALL, this.scintilla, false );
			
		// may return -1 in error
		if(result >= 0)	{
		  char[] s = "Marked " ~ std.string.toString( result ) ~ " matched";
		  findDlg.setStatus( s );
		}
			
		return result;
	}
	
	private int findAndSelect( int dwFlags, TextToFind* ft )
	{
		int index = scintilla.findText( dwFlags, ft );
		if( index != -1 ) // i.e. we found something
			scintilla.setSel(ft.startFound, ft.endFound);

		return index;
	}
	
	public void findText(char[] strFind, boolean bForward) 
	{
		if( strFind.length == 0 )
		{
			strFind = _parent.findDlg.fop.strFind;
			if( strFind.length == 0 ) return;
		}

		char[] temp = strFind;
		
		if( std.string.cmp( strFind, _parent.findDlg.fop.strFind ) != 0)
		{
			// to avoid select too much characters in to findDlg, multipline is ignored,
			// eg. user press F3/F4 with all document selected by accident
			int pos = std.string.find(strFind, Eofline());
			if( pos > 0 ) temp = strFind[0..pos];
			
			_parent.findDlg.addToCache( temp );
			_parent.findDlg.fop.strFind = temp;
		}
		
		if( findTextSimple( strFind, bForward ) )
		{
			adjustFindDialogPosition();
			int line = scintilla.getCurrentLineNumber();
			sActionMan.navCache.add( getFileName(), line );
		}else
		{
			_parent.findDlg.setStatus( `"` ~ strFind ~ `" not found` );
		}
	}
	
	private boolean findTextSimple( char[] s2find, boolean bForward )
	{
		void swap( inout int a, inout int b )
		{
			int temp = b;
			b = a;
			a = temp;
		}
		
		int cpMin = scintilla.getSelectionStart();
		int cpMax = scintilla.getSelectionEnd();
		TextToFind ft = TextToFind(s2find, cpMin, cpMax);
		
		if( cpMin != cpMax )
		{
			if( bForward ) ft.start++;else ft.end = ft.start - 1;
		}
		
		int nLength = scintilla.getLength();
		if( bForward ) ft.end = nLength;else ft.start = 0;
 	  
		int dwFlags = findDlg.fop.bCase ? Scintilla.SCFIND_MATCHCASE : 0;
		dwFlags |= findDlg.fop.bWord ? Scintilla.SCFIND_WHOLEWORD : 0;
		dwFlags |= findDlg.fop.bRegexp ? Scintilla.SCFIND_REGEXP | Scintilla.SCFIND_POSIX : 0;

		if( !bForward )
		{
			//Swap the start and end positions which Scintilla uses to flag backward searches
			swap( ft.start, ft.end );
		}
  		
		// if we find the text return TRUE
		boolean result = ( findAndSelect( dwFlags, &ft ) != -1 );
		if( !result && findDlg.fop.bWrap )
		{
			if( bForward )
			{
				ft.start = 0;
				ft.end = nLength;
			}else
			{
				ft.start = nLength;
				ft.end = 0;
			}
			result = ( findAndSelect( dwFlags, &ft ) != -1 );
		} 
		return result;
	}
	
	
	char[] getFileName()
	{
		if( iteminfo ) return iteminfo.getFileName();else return scintilla.getFileName();
	}
	
	/**
	* return whether the file modified externally
	* return value 
	* 0 : nothing happened
	* 1 : file is modified externally
	* -1 : file is deleted
	*/
	public int getExternalModify()
	{
		char[] fn = getFileName();
		if( !std.file.exists( fn ) || !std.file.isfile( fn ) ) return -1; 

		FILETIME ftCreate, ftAccess, ftWrite;
	
		try
		{
			scope file = new File(fn);
			GetFileTime( file.handle(), &ftCreate, &ftAccess, &ftWrite );
		}
		catch( Object o )
		{
			Util.trace( o.toString() );
			return 1;
		}
		
		if( std.c.windows.windows.CompareFileTime( &ftWrite, &filetime ) == 0 ) return 0;

		return 1;
	}
	
	/**
	* Load file when created or file modified externally
	*/
	public void loadFile( char[] fn )
	{
		try
		{
			scintilla.loadFile( fn );
		}
		catch( Exception e )
		{
			MessageBox.showMessage( e.toString(), Globals.getTranslation( "EXCEPTION" ), _parent.getShell() );
		}
	}
	
	public int markAll()
	{
		FindOption fop = findDlg.fop.clone();
		fop._scope = SS_CURFILE;
		
		int result = Editor.processAll( fop, SearchDlg.MARK_ALL, this.scintilla, false );
		
		// may return -1 in error
		if( result >= 0 )
		{
			char[] s = "Marked " ~ std.string.toString(result) ~ " matched";
			findDlg.setStatus( s );
		}
		
		return result;
	}
	
	boolean modified(){ return scintilla.getModify(); }

	public void toolbarDirectlyHSU( int cases )
	{
		switch( cases )
		{
			case 0: // Undo
				_undo(); break;
			case 1: // Redo
				_redo(); break;
			case 2: // Cut
				_cut(); break;
			case 3: // Copy
				_copy(); break;
			case 4: // Paste
				_paste(); break;
			case 5: // Select All
				_select_all(); break;
			case 6: // Toggle Commet
				_toggle_comment(); break;
			case 7: // Stream commet
				_streamComment(); break;
			case 8: // box commet
				_boxComment(); break;
			case 9: // Find
				_find(); break;
			case 10:
				doStreamComment( true ); break;
		}
	}
	
	private void onDispose( Event e )
	{
		_parent.fireEditorEvent( Editor.EEV_ITEM_DISPOSE, this );
		
		Control ctl = this.getControl();
		if( ctl ) ctl.dispose();

		// check whether this is the last edit item in the editor
		if( _parent.getItemCount() == 0 ) _parent.fireEditorEvent( Editor.EEV_ALL_CLOSED, null );
	}
	
	private void onDoubleClick( SCNotifyEvent e )
	{
		int line = scintilla.getCurrentLineNumber();
		sActionMan.navCache.add( getFileName(), line );
		sGUI.statusBar.updateStatusBar();
	}
	
	private void onKeyDown( Event e ) 
	{
		uint mask = cast(uint) e.stateMask;
		int temp = e.stateMask;
		uint code = cast(uint) e.keyCode;


		void delegate() func = translateKeys( mask, code );
		
		if( func )
		{
			e.doit = false;
			func();
		}else if( e.stateMask & DWT.CTRL )
		{
			// if CTRL Key pressed, discard some unused operation
			// switch(e.keyCode){
			// case 'w','q','e','r','p','n','b','\t':
			//				if(e.keyCode >= 'a' && e.keyCode <= 'z')
			//					e.doit = false; 
			// break;
			// default :break;	
			//}
		}
		/** 		else if(e.stateMask == DWT.SHIFT) {
		* 			// the default SHIFT+TAB of DWT is switch to other control
		* 			// instead of decreasing indent the selected text,
		* 			switch(e.keyCode){
		* 			case DWT.TAB:
		* 				e.doit = false; 
		* 				break;
		* 			default :break;
		* 			}
		* 		}
		*/
		sGUI.statusBar.updateStatusBar();
	}
	
	private void onModifyAttemptRo( SCNotifyEvent e )
	{
		if( DWT.YES == MessageBox.showMessage( Globals.getTranslation("mb.modify_attempt_readonly"), Globals.getTranslation("mb.readonly_file"), 
						_parent.getShell(), DWT.YES | DWT.NO | DWT.ICON_QUESTION ) )

			scintilla.setReadOnly(false);
	}
	
	/**
	* Save the navigation point when left mouse button down
	*/
	private void onMouseDown( Event e )
	{
		if( e.button == 1 )
		{
			int line = scintilla.getCurrentLineNumber();
			sActionMan.navCache.add( getFileName(), line );
			sGUI.statusBar.updateStatusBar();
		}
	}

	private void onMouseDwellStart( SCNotifyEvent e )
	{
		//if( !sGUI.debuggerDMD.isRunning() ) return;
		//if( !sGUI.packageExp.isFileInProjects( scintilla.getFileName() ) ) return;

		//if( iteminfo !is null )
			//if( iteminfo.project.projectDir != sGUI.debuggerDMD.projectDir ) return;
		
		try
		{
			//if( scintilla.callTipActive() ) return;
			
			int pos = scintilla.positionFromPointClose( e.x, e.y );
			if( pos < 1 ) return;
			
			char[] varName = DStyle.readHoverWord( scintilla, pos );

			//sc.positionFromPoint( callTipX, currentY )

			if( varName.length )
			{
				if( sGUI.debuggerDMD.isRunning() )
				{
					if( iteminfo !is null )
						if( iteminfo.project.projectDir != sGUI.debuggerDMD.projectDir ) return;
						
					char[] tempVarName = varName;
					char[] type = CDebugParser.getType( tempVarName );

					if( !type.length )
					{
						type = CDebugParser.getType( "this." ~ tempVarName );
						if( type.length ) tempVarName = "this." ~ tempVarName;else return;
					}
					
					char[] value = CDebugParser.getValue( tempVarName, type, false, true );

					if( value.length > 3 )
					{
						if( value.length > 15 )
						{
							if( value[0..15] == "Unknown symbol " ) return;
							if( value[0..15] == "invalid string:" ) return; 
							if( value[0..15] == "Parser: Invalid" ) return;
							if( value[0..15] == "array cast misa" ) return;
						}

						scintilla.callTipSetBack( 0x99ffff );
						scintilla.callTipSetFore( 0x993300 );
							
						scintilla.callTipShow( pos, type ~ " " ~ varName ~ ( value.length? " = " ~ value[0..length-3] : "" ) );
					}
				}
				else
				{
					if( scintilla.getSelText.length ) return;
					
					char[] 				fileFullPath, moduleName;
					int					lineNum;
					CAnalyzerTreeNode 	resultNode;

					DStyle dStyle = cast(DStyle) StyleFactory.getStyleKeeper( DStyle.SCLEX_D );
					if( dStyle is null ) return;// dStyle = new DStyle;
					dStyle.performJumpToDefintion( scintilla, pos, fileFullPath, moduleName, lineNum, resultNode );

					if( resultNode !is null )
						CDDocParser.showTip( scintilla, pos, CDDocParser.getText( resultNode ), 0x993300, 0x99ffff );
				}
			}
		}
		catch( Exception e )
		{
			//MessageBox.showMessage( "Scintilla MouseDwell Error!! \n" ~ e.toString  );
		}
	}

	private void onMouseDwellEnd( SCNotifyEvent e )
	{
		scintilla.callTipCancel();
	}		

	void updateFileParser( char[] filePath )
	{
		if( Globals.useCodeCompletion || Globals.showOnlyClassBrowser )
		{
			try
			{
				//if( fileParser !is null ) delete fileParser;
				fileParser = CodeAnalyzer.syntax.core.parseTextHSU( scintilla.getText(), filePath );
				//fileParser = parsing.core.parseFileHSU( filePath );
				sAutoComplete.updateProjectParser( fileParser, filePath );
				if( sGUI.editor.getSelectedFileName == filePath ) sAutoComplete.setFileParser( fileParser );
				//if( sAutoComplete.getFileParserPath() == filePath ) sAutoComplete.setFileParser( fileParser );

				if( Globals.parseAllModule || Globals.parseImported )
				{
					if( fileParser !is null )
					{
						if( Globals.backLoadParser )
						{
							Thread th = new Thread( &_addMoudule );
							th.start();
						}
						else
							sAutoComplete.setAdditionImportModules( fileParser );
					}
				}
			}
			catch( Exception e )
			{
				fileParser = null;
				sAutoComplete.updateProjectParser( fileParser, filePath );
				if( sGUI.editor.getSelectedFileName == filePath ) sAutoComplete.setFileParser( fileParser );
				//if( sAutoComplete.getFileParserPath() == filePath ) sAutoComplete.setFileParser( fileParser );
				throw e;
			}
		}
	}

	void updateFileParser2()
	{
		if( Globals.useCodeCompletion || Globals.showOnlyClassBrowser )
		{
			try
			{
				char[] filePath = sGUI.editor.getSelectedFileName();
				fileParser = CodeAnalyzer.syntax.core.parseTextHSU( scintilla.getText(), filePath );
				sAutoComplete.updateProjectParser( fileParser, filePath );
				if( sGUI.editor.getSelectedFileName == filePath ) sAutoComplete.setFileParser( fileParser );

				if( Globals.parseAllModule || Globals.parseImported )
				{
					if( fileParser !is null )
					{
						if( Globals.backLoadParser )
						{
							Thread th = new Thread( &_addMoudule );
							th.start();
						}
						else
							sAutoComplete.setAdditionImportModules( fileParser );
					}
				}
			}
			catch( Exception e )
			{
				/*
				fileParser = null;
				sAutoComplete.updateProjectParser( fileParser, filePath );
				if( sGUI.editor.getSelectedFileName == filePath ) sAutoComplete.setFileParser( fileParser );
				//if( sAutoComplete.getFileParserPath() == filePath ) sAutoComplete.setFileParser( fileParser );*/
				throw e;
			}
		}
	}
	
	private int _addMoudule()
	{
		sAutoComplete.setAdditionImportModules( fileParser );
		return 0;
	}
	
	private void onSavePointChanged( SCNotifyEvent e )
	{
		boolean changed;

		EditItem ei = sGUI.editor.findEditItem( getFileName() );
		if( ei is null ) ei = this;

		if( e.code == Scintilla.SCN_SAVEPOINTREACHED )
		{
			changed = false;
			ei.updateFileTime();
		}
		else
		{
			// SCN_SAVEPOINTLEFT
			changed = true;
		}

		ei.setTitleModified( changed );

		_parent.fireEditorEvent( Editor.EEV_SAVE_STATE, ei );
	}

	
	void reportErrors()
	{
		//    MessageBox.showMessage("funk power");
		try
		{
			sGUI.statusBar.setString("" );
		}
		catch( Exception ) {} 
	}

	
	private int promptToSave( char[] filename )
	{
		return MessageBox.showMessage(`"` ~ filename ~ "\" " ~ Globals.getTranslation("mb.prompt_to_save"),
				Globals.getTranslation("QUESTION"), _parent.getShell(), DWT.YES | DWT.NO | DWT.CANCEL | DWT.ICON_QUESTION);
	}
	
	public void rename( char[] newname )
	{
		// file name in iteminfo will be updated by package explorer
		char[] shortname = std.path.getBaseName( newname );
		char[] oldname = getFileName();

		char[] name = std.path.join( std.path.getDirName( oldname ), shortname );
		scintilla.setFileName( name );			

		this.setTitleModified( modified() );
	}
	
	/**
	 * Replace the selection
	 */
	void replaceSel( boolean moveToNext )
	{
		if( findDlg.fop.strFind.length == 0 ) return;
		
		if( !sameAsSelected( findDlg.fop ) )
		{
			if( !moveToNext ) return;

			if( findTextSimple( findDlg.fop.strFind, findDlg.fop.bForward ) )
				adjustFindDialogPosition();
			else
				findDlg.setStatus( `"` ~ findDlg.fop.strFind ~ `" not found` );
				
			return;
		}
		
		int nSelStart = scintilla.getSelectionStart();
		int nSelEnd = scintilla.getSelectionEnd();
		
		if( findDlg.fop.bRegexp )
		{
			scintilla.setTargetStart( nSelStart );
			scintilla.setTargetEnd( nSelEnd );
			scintilla.replaceTargetRE( findDlg.fop.strReplace );
		}else
		{
			scintilla.replaceSel( findDlg.fop.strReplace );
		}
		
		if( moveToNext )
		{
			if( findTextSimple( findDlg.fop.strFind, findDlg.fop.bForward ) )
				adjustFindDialogPosition();
			else
				findDlg.setStatus( `No more "` ~ findDlg.fop.strFind ~ `" found` );
				
		}else
		{
			// select the replaced text
			scintilla.setSelectionStart( nSelStart );
			nSelStart += findDlg.fop.strReplace.length;
			scintilla.setSelectionEnd( nSelStart );	
		}
	}
	
	/**
	 * Replace all
	 */
	public void replaceAll()
	{
		if( findDlg.fop.strFind.length == 0 ) return;

		
			if( scintilla.getReadOnly() ) return;

			int nbReplaced;
			int docLength = scintilla.getLength();
			int endPosition = docLength;
			int startPosition;

			int dwFlags = findDlg.fop.bCase ? Scintilla.SCFIND_MATCHCASE : 0;
			dwFlags |= findDlg.fop.bWord ? Scintilla.SCFIND_WHOLEWORD : 0;
			dwFlags |= findDlg.fop.bRegexp ? Scintilla.SCFIND_REGEXP | Scintilla.SCFIND_POSIX : 0;

			if( findDlg.fop.bWrap ) 
				startPosition = 0;
			else
			{
				startPosition = scintilla.getCurrentPos();
				if( !findDlg.fop.bForward )	
				{
					docLength = endPosition = startPosition;
					startPosition = 0;
				}
			}
			
			scintilla.setTargetStart( startPosition );
			scintilla.setTargetEnd( endPosition );
			scintilla.setSearchFlags( dwFlags );
		
			int posFind = scintilla.searchInTarget( findDlg.fop.strFind );

			while( posFind != -1 && !scintilla.isDisposed() )
			{		
				int posFindBefore = posFind;
				int start = scintilla.getTargetStart();
				int end = scintilla.getTargetEnd();
				int foundTextLen = (end >= start)?end - start : start - end;
		
				if( foundTextLen < 0 ) return;
				
				scintilla.setTargetStart( start );
				scintilla.setTargetEnd( end );

				int replacedLength;
				if( findDlg.fop.bRegexp )
					replacedLength = scintilla.replaceTargetRE( findDlg.fop.strReplace );
				else
					replacedLength = scintilla.replaceTarget( findDlg.fop.strReplace );

				if( foundTextLen == 0 )
				{
					startPosition = posFind + replacedLength;
					if( posFind >= docLength )
					{
						nbReplaced ++;
						break;
					}
					endPosition = docLength = docLength - foundTextLen + replacedLength;
				}
				else
				{
					startPosition = posFind + replacedLength;
					endPosition = docLength = docLength - foundTextLen + replacedLength;
				}

				scintilla.setTargetStart( startPosition );
				scintilla.setTargetEnd( endPosition );
		
				posFind = scintilla.searchInTarget( findDlg.fop.strFind );
				nbReplaced ++;
			}

			findDlg.setStatus( "Replaced " ~ std.string.toString( nbReplaced ) ~ " matched" );
			return;
		

		/+
		scope wc = new WaitCursor( _parent );
		if( !sameAsSelected( findDlg.fop ) || findDlg.fop.bRegexp )
		{
			if( !findTextSimple( findDlg.fop.strFind, findDlg.fop.bForward ) )
			{
				findDlg.setStatus( `"` ~ findDlg.fop.strFind ~ `" not found` );
				return;
			}
		}
		
		scintilla.hideSelection( true );
		int count = 0;
		do
		{
			int nSelStart = scintilla.getSelectionStart();
			int nSelEnd = scintilla.getSelectionEnd();
			
			if( findDlg.fop.bRegexp )
			{
				scintilla.setTargetStart( nSelStart );
				scintilla.setTargetEnd( nSelEnd );
				scintilla.replaceTargetRE( findDlg.fop.strReplace );
			}else
			{
				scintilla.replaceSel( findDlg.fop.strReplace );
			}
			
			++ count;
			
		}while( findTextSimple( findDlg.fop.strFind, findDlg.fop.bForward ) );
		
		findDlg.setStatus( "Replaced " ~ std.string.toString(count) ~ " matched" );
		scintilla.hideSelection( false );+/
	}

	boolean sameAsSelected( FindOption fop )
	{
		//if we are doing a regular expression Find / Replace, then it they match!!
		if( fop.bRegexp ) return true;
		
		// check length first
		int nLen = fop.strFind.length;
		int nStartChar = scintilla.getSelectionStart();
		int nEndChar = scintilla.getSelectionEnd();

		if( nLen != ( nEndChar - nStartChar ) ) return false;
		
		// length is the same, check contents
		char[] strSelect = scintilla.getSelText();
		return ( fop.bCase && strSelect == fop.strFind ) || ( !fop.bCase && std.string.icmp( fop.strFind, strSelect ) == 0 );
	}
	
 	public boolean save( boolean force = false )
	{
		// force to save
		if( scintilla.getModify() || force )
		{
			if( !saveUntitled( false ) )
			{
				char[] fn = getFileName();
				
				boolean result = scintilla.saveFile( fn );
				return result;
			}
		}
		return true;
	}

 	public bool saveAs()
	{
		if( !saveUntitled( false ) )
		{
			char[] fileName = getFileName();

			scope dlg = new FileDialog( _parent.getShell, DWT.SAVE );
			dlg.setFilterPath( Globals.recentDir );
			dlg.setFileName( fileName );

			char[] result = std.string.strip( dlg.open() );
			if( result.length )
			{
				if( !sGUI.packageExp.isFileInProjects( fileName ) )
				{
					scintilla.saveFile( result , true );
					scintilla.loadFile( result ) ;

					char[] ext = std.path.getExt( result );
					this.setImage( Globals.getImageByExt( ext ) );
					Editor.settings.applySettings( scintilla, ext );

					sGUI.fileList.refresh();
				}
				else
				{
					FileSaver.save( result, scintilla.getText(), scintilla.ibom );
				}
			}
		}
		return true;
	}
	
	public void setTitleModified( boolean modified )
	{
		this.setToolTipText( getFileName() );
		if( modified )
			this.setText( "*" ~ std.path.getBaseName( getFileName() ) );
		else
			this.setText( std.path.getBaseName( getFileName() ) );
	}	
	
	public void setSelection(int line = -1) 
	{
		if( line >= 0 )
		{
			sActionMan.navCache.add( this.getFileName(), line );
			scintilla.gotoLine( line );
			sGUI.statusBar.updateStatusBar();
		}
	}
	
	public void showGotoLine()
	{
		char[] lastLine;
		if( lastGoto != -1 ) lastLine = std.string.toString( lastGoto );
		
		char[] str = std.string.format( Globals.getTranslation( "gotodlg.detail" ), scintilla.getLineCount() );
		AskStringDlg dlg = new AskStringDlg( _parent.getShell(), str, lastLine );
		dlg.setText( Globals.getTranslation( "gotodlg.title" ) );
		dlg.setImageString( "goto" );
		
		char[] result = dlg.open();
		if( result.length > 0 )
		{
			lastGoto = cast(int) std.string.atoi( result );
			scintilla.call( scintilla.SCI_ENSUREVISIBLEENFORCEPOLICY, lastGoto - 1 );
			scintilla.gotoLine( lastGoto - 1 );
			sActionMan.navCache.add( getFileName(), lastGoto - 1 );
			sGUI.statusBar.updateStatusBar();
		}
	}

	void toggleMarker(int lineNumber)
	{
		uint state = scintilla.markerGet( lineNumber );
		if( state & ( 1 << Editor.MARK_SYMBOLE ) )
			scintilla.markerDelete( lineNumber, Editor.MARK_SYMBOLE );
		else
			scintilla.markerAdd( lineNumber, Editor.MARK_SYMBOLE );
	}

	void toggleDebugMarker( int lineNumber )
	{
		if( std.string.icmp( std.path.getExt( getFileName() ), "d" ) ) return;
		
		uint state = scintilla.markerGet( lineNumber );
		if( state & ( 1 << Editor.MARK_DEBUGSYMBOLE  ) )
		{
			sGUI.debuggerDMD.delBP_editor( getFileName(), lineNumber + 1 );
			scintilla.markerDelete( lineNumber, Editor.MARK_DEBUGSYMBOLE );
		}
		else
		{
			sGUI.debuggerDMD.addBP_editor( getFileName(), lineNumber + 1, sGUI.packageExp.getActiveProjectDir );
			scintilla.markerAdd( lineNumber, Editor.MARK_DEBUGSYMBOLE );
		}
	}

	void deleteAllDebugMarker(){ scintilla.markerDeleteAll(  Editor.MARK_DEBUGSYMBOLE ); }	

	void deleteAllDebugRunMarker()
	{
		scintilla.markerDeleteAll(  Editor.MARK_DEBUGRUNSYMBOLE );
		scintilla.markerDeleteAll(  Editor.MARK_DEBUGRUNLINE );		
	}

	void toggleDebugRunMarker( int lineNumber )
	{
		if( std.string.icmp( std.path.getExt( getFileName() ), "d" ) ) return;
		
		uint state = scintilla.markerGet( lineNumber );

		deleteAllDebugRunMarker();
		
		scintilla.markerAdd( lineNumber, Editor.MARK_DEBUGRUNSYMBOLE );
		scintilla.markerAdd( lineNumber, Editor.MARK_DEBUGRUNLINE );
		

		/+
		if( state & ( 1 << Editor.MARK_DEBUGRUNSYMBOLE  ) )
		{
			scintilla.markerDelete( lineNumber, Editor.MARK_DEBUGRUNSYMBOLE );
			scintilla.markerDelete( lineNumber, Editor.MARK_DEBUGRUNLINE );
		}
		else
		{
			scintilla.markerAdd( lineNumber, Editor.MARK_DEBUGRUNSYMBOLE );
			scintilla.markerAdd( lineNumber, Editor.MARK_DEBUGRUNLINE );
		}
		+/
	}
	
	
	void delegate() translateKeys( uint mask, uint code )
	{
		_ShortCut _shortcut = null;
		foreach( _ShortCut t; hotkeys )
		{
			if( t.match( mask, code ) )
			{
				_shortcut = t;
				break;
			}
		}

		if( _shortcut is null )	return null;

		Util.trace( _shortcut.keyname() );
		Util.trace( _shortcut.getFuncKey() );
		Util.trace( _shortcut.name );
		
		void delegate() func = null;
		switch( _shortcut.name )
		{
			case "save"					:	return &_save;
			case "save_allfiles"		:	return &_save_allfiles;
			case "close_file"			:	return &_closeCurrentFile;

			case "undo"           		:	return &_undo;
			case "redo"           		:	return &_redo;
			case "cut"            		:	return &_cut;
			case "copy"           		:	return &_copy;
			case "paste"          		:	return &_paste;
			case "select_all"     		:	return &_select_all;
			case "toggle_comment" 		:	return &_toggle_comment;
			case "stream_comment"		:	return &_streamComment;
			case "box_comment"			:	return &_boxComment;
			case "nest_comment"			:	return &_nestComment;

			case "find"           		:	return &_find;
			case "search"        		:	return &_search;
			case "goto_line"			:	return &_goto_line;

			case "compile"				:	return &_compile;
			case "run_project"			:	return &_runCurrentProject;
			case "build_project"		:	return &_buildCurrentProject;
			case "build_run_project"	:	return &_buildRunCurrentProject;
			case "rebuild_project"		:	return &_rebuildCurrentProject;
			case "buildtool"			:	return &_buildtoolCurrentProject;

			case "debug_project"		:	return &_debugCurrentProject;
			case "debug_build_project"	:	return &_debugbuildCurrentProject;
			case "debug_run"			:	return &_debug_run;
			case "debug_in"				:	return &_debug_in;
			case "debug_over"			:	return &_debug_over;
			case "debug_return"			:	return &_debug_return;
			case "debug_stop"			:	return &_debug_stop;
			case "debug_clean_bps"		:	return &_debug_cleanbps;

			case "document0"			:	return &_document0;
			case "document1"			:	return &_document1;
			case "document2"			:	return &_document2;
			case "document3"			:	return &_document3;
			case "document4"			:	return &_document4;

			// others
			case "find_back"      		:	return &_find_back;
			case "find_forward"   		:	return &_find_forward;
			case "line_copy"      		:	return &_line_copy;
			case "line_cut"       		:	return &_line_cut;
			case "line_del"       		:	return &_line_del;
			case "line_dup"       		:	return &_line_dup;
			case "line_swap"       		:	return &_line_swap;
			case "lowercase"			:	return &_lowerCase;
			case "uppercase"			:	return &_upperCase;
			case "nav_back"				:	return &_navback;
			case "nav_forward"			:	return &_navforward;
			case "mark_prev"			:	return &markerPrevious;
			case "mark_next"			:	return &markerNext;
			case "mark_toggle"			:	return &markerToggle;
			case "force_complete"		:	return &_forceAutoComplete;
			case "jump_to_defintion"	:	return &_jumpToDefintion;
			default : break;
		}
		
		return null;
	}

	private void _jumpToDefintion()
	{
		DStyle dStyle = cast(DStyle) StyleFactory.getStyleKeeper( DStyle.SCLEX_D );
		if( dStyle is null ) return;

		char[] 				fileFullPath, moduleName;
		int					lineNum;
		CAnalyzerTreeNode 	resultNode;
		
		dStyle.performJumpToDefintion( scintilla, -1, fileFullPath, moduleName, lineNum, resultNode );

		//MessageBox.showMessage( "name = " ~ fileFullPath ~ "\n" ~ std.string.toString( lineNum ) );
		if( fileFullPath.length && lineNum > -1 )
		{
			if( fileFullPath.length > 5 )
			{
				if( fileFullPath[0..5] == "<ana>" ) fileFullPath = fileFullPath[5..length];
			}

			if( std.file.exists( fileFullPath ) )
				sGUI.packageExp.openFile( fileFullPath, lineNum - 1, true );
			else
			{
				// Maybe fileFullPath in default parser not exist, check import paths...
				if( sGUI.packageExp.activeProject !is null && moduleName.length )
				{
					foreach( char[] path; sGUI.packageExp.activeProject().projectIncludePaths ~ sGUI.packageExp.activeProject().scINIImportPath )
					{
						char[] name = std.string.replace( moduleName, ".", "\\" );
						name = std.path.join( path, name );// ~".d";

						if( std.file.exists( name ~ ".di" ) )
						{
							sGUI.packageExp.openFile( name ~ ".di", lineNum - 1, true );
							break;
						}
						else if( std.file.exists( name ~ ".d" ) )
						{
							sGUI.packageExp.openFile( name ~ ".d", lineNum - 1, true );
							break;
						}
					}
				}
			}
		}

		/+
		char[] word = DStyle.readHoverWord(scintilla);
		CAnalyzerTreeNode[] listings = sAutoComplete.search( word );
		//TODO : make this smarter
		if ( listings.length )
		{
			CAnalyzerTreeNode l = listings[0];

			char[] moduleName, fileFullPath;
			sAutoComplete.getModuleNames( l, moduleName, fileFullPath );
			sGUI.packageExp.openFile( fileFullPath, l.lineNumber - 1, true );
		}
		+/
	}

	private void _forceAutoComplete()
	{
		DStyle dStyle = cast(DStyle) StyleFactory.getStyleKeeper( DStyle.SCLEX_D );
		if( dStyle is null ) return;

		dStyle.forceComplete( scintilla );
	}

	public void updateFileTime()
	{
		try
		{
			scope file = new File( getFileName() );
			FILETIME ftCreate, ftAccess;
			GetFileTime( file.handle(), &ftCreate, &ftAccess, &filetime );
			// _deleted = false;
		}
		catch( Object o )
		{
			// do nothing
		}
	}
	
	/**
	 * Hot Key methods
	 */
	private void _copy()
	{
		// when scintillaex.d import std.file, the compiler complains that
		// "function std.file.copy (char[],char[]) does not match argument types ()"
		(cast(Scintilla)scintilla).copy();
	}

	
	private void _cut(){ scintilla.cut(); }
	
	private void _find()
	{ 
		FindDlg findDlg = _parent.findDlg;
		
		assert( findDlg );
		
		char[] selText = scintilla.getSelText();

		int pos = std.string.find( selText, Eofline() );
		if( pos > 0 ) selText = selText[0 .. pos];
		
		if( !findDlg.opened )
		{
			findDlg.centerWindow( _parent );
			findDlg.open();
			findDlg.setTextToFind( selText );
		}else
		{
			findDlg.setTextToFind( selText );
			findDlg.setVisible( true );
		}
	}

	private void _compile(){ sActionMan.actionDefaultCompile( null ); }

	private void _buildCurrentProject(){ sActionMan.actionDefaultBuildHSU( null ); }

	private void _rebuildCurrentProject(){ sActionMan.actionDefaultBuild( null ); }

	private void _runCurrentProject(){ sActionMan.actionDefaultRun( null ); }

	private void _buildRunCurrentProject(){ sActionMan.actionDefaultBuild_RunHSU( null ); }

	private void _buildtoolCurrentProject(){ sActionMan.actionBud( null ); }

	private void _debugCurrentProject(){ sActionMan.actionDebug( false ); }

	private void _debugbuildCurrentProject(){ sActionMan.actionDebug( true ); }

	private void _debug_run(){ sActionMan.actionDebugExec( null ); }

	private void _debug_in(){ sActionMan.actionDebugStepInto( null ); }

	private void _debug_over(){ sActionMan.actionDebugStepOver( null ); }
	
	private void _debug_return(){ sActionMan.actionDebugStepReturn( null ); }
	
	private void _debug_stop(){ sActionMan.actionDebugStop( null ); }

	private void _debug_cleanbps(){ sActionMan.actionCleanAllBreakPoints( null ); }

	private void _closeCurrentFile(){ this.close( true ); }

	private void _document0(){ sActionMan.actionDDocumentFile( 0 ); }

	private void _document1(){ sActionMan.actionDDocumentFile( 1 ); }

	private void _document2(){ sActionMan.actionDDocumentFile( 2 ); }

	private void _document3(){ sActionMan.actionDDocumentFile( 3 ); }

	private void _document4(){ sActionMan.actionDDocumentFile( 4 ); }
	
	private char Eofline()
	{
		char endline;
		
		int eolMode = scintilla.getEOLMode();
		
		if ( eolMode == Scintilla.SC_EOL_CRLF || eolMode == Scintilla.SC_EOL_CR ) endline = '\r';
		if ( eolMode == Scintilla.SC_EOL_LF ) endline = '\n';

		return endline;
	}


	private void _find_back()
	{
		char[] strFind = null;

		if( !_parent.findDlg.fop.bRegexp ) strFind = scintilla.getSelText();
		findText( strFind, false );
	}
	
	private void _find_forward()
	{
		char[] strFind = null;
		
		if( !_parent.findDlg.fop.bRegexp ){	strFind = scintilla.getSelText(); }
		findText( strFind, true );
	}
	private void _goto_line(){ showGotoLine();	}

	private void _line_copy(){ scintilla.lineCopy(); }

	private void _line_cut(){ scintilla.lineCut(); }

	private void _line_del(){ scintilla.lineDelete(); }

	private void _line_dup(){ scintilla.lineDuplicate(); }

	public void markerNext()
	{
		int line = scintilla.getCurrentLineNumber() + 1;
		int newLine = scintilla.markerNext( line, 1<<Editor.MARK_SYMBOLE );
		if( newLine >= 0 ) 
			scintilla.gotoLine( newLine );
		else if( ( newLine = scintilla.markerNext( 0, 1<<Editor.MARK_SYMBOLE ) ) >=0 )
			scintilla.gotoLine( newLine );
	}
	
	public void markerPrevious()
	{
		int line = scintilla.getCurrentLineNumber() - 1;
		int newLine = scintilla.markerPrevious( line, 1<<Editor.MARK_SYMBOLE );
		if( newLine >= 0 ) 
			scintilla.gotoLine( newLine );
		else
		{
			int count = scintilla.getLineCount();
			if((newLine = scintilla.markerPrevious( count, 1 << Editor.MARK_SYMBOLE ) )>=0 )
				scintilla.gotoLine( newLine );
		}
	}
	
	void markerClear(){ scintilla.markerDeleteAll(  Editor.MARK_SYMBOLE ); }

	public void markerToggle()
	{
		int line = scintilla.getCurrentLineNumber();
		toggleMarker( line );
	}
	
	private void _navback(){ sActionMan.navCache.navBack();	}

	private void _navforward(){	sActionMan.navCache.navForward(); }

	private void _paste()
	{
		scintilla.paste();
		scintilla.resetLineNumWidth();
	}
	
	private void _redo(){ scintilla.redo(); }

	private void _search(){	_parent.showSearchDlg(); }

	private void _save() { save(); }

	private void _save_allfiles() { sActionMan.actionSaveAll( null ); }
	
	private void _select_all(){ scintilla.selectAll(); }

	private void _toggle_comment(){	doBlockComment(); }

	private void _undo(){ scintilla.undo();	}

	private void _line_swap(){ scintilla.lineTranspose(); }

	private void _upperCase(){ scintilla.upperCase(); }

	private void _lowerCase(){ scintilla.lowerCase(); }
	
	private void _streamComment(){ doStreamComment(); }

	private void _nestComment(){ doStreamComment( true ); }

	private void _boxComment(){	doBoxComment();	}

	private boolean doBlockComment()
	{
		char[] comment = `//`;
		comment ~= " ";
		char[] long_comment = comment;
		
		char[] linebuf;//[1000];
		int comment_length = comment.length;
		int selectionStart = scintilla.getSelectionStart();
		int selectionEnd = scintilla.getSelectionEnd();
		int caretPosition = scintilla.getCurrentPos();
		// checking if caret is located in _beginning_ of selected block
		boolean move_caret = caretPosition < selectionEnd;
		int selStartLine = scintilla.lineFromPosition(selectionStart);
		int selEndLine = scintilla.lineFromPosition(selectionEnd);
		int lines = selEndLine - selStartLine;
		int firstSelLineStart = scintilla.positionFromLine(selStartLine);
		// "caret return" is part of the last selected line
		if ((lines > 0) && (selectionEnd == (scintilla.positionFromLine(selEndLine))))
			selEndLine--;
		scintilla.beginUndoAction();
		for (int i = selStartLine; i <= selEndLine; i++) 
		{
			int lineStart = scintilla.positionFromLine(i);
			int lineIndent = lineStart;
			int lineEnd = scintilla.getLineEndPosition(i);
//			if ((lineEnd - lineIndent) >= (sizeof(linebuf)))        // Avoid buffer size problems
//					continue;
			/*if (props.GetInt(comment_at_line_start.c_str())) {
					GetRange(wEditor, lineIndent, lineEnd, linebuf);
			} else*/
			{
				lineIndent = scintilla.getLineIndentPosition(i);
				linebuf = scintilla.getTextInRange(lineIndent, lineEnd);
			}
			// empty lines are not commented
			if (linebuf.length < 1)
				continue;
			if (linebuf.length >= comment_length && (linebuf[0..comment_length - 1] == comment[0..comment_length - 1]))
			{
				if (linebuf[0..comment_length] == long_comment[0..comment_length] )
				{
					// removing comment with space after it
					scintilla.setSel(lineIndent, lineIndent + comment_length);
					scintilla.replaceSel("");
					if (i == selStartLine) // is this the first selected line?
						selectionStart -= comment_length;
					selectionEnd -= comment_length; // every iteration
					continue;
				}
				else
				{
					// removing comment _without_ space
					scintilla.setSel(lineIndent, lineIndent + comment_length - 1);
					scintilla.replaceSel("");
					if (i == selStartLine) // is this the first selected line?
						selectionStart -= (comment_length - 1);
					selectionEnd -= (comment_length - 1); // every iteration
					continue;
				}
			}
			if (i == selStartLine) // is this the first selected line?
				selectionStart += comment_length;
			selectionEnd += comment_length; // every iteration
			scintilla.insertText(lineIndent, long_comment);
		}
		// after uncommenting selection may promote itself to the lines
		// before the first initially selected line;
		// another problem - if only comment symbol was selected;
		if (selectionStart < firstSelLineStart)
		{
			if (selectionStart >= selectionEnd - (comment_length - 1))
				selectionEnd = firstSelLineStart;
			selectionStart = firstSelLineStart;
		}
		if (move_caret) 
		{
			// moving caret to the beginning of selected block
			scintilla.gotoPos(selectionEnd);
			scintilla.setCurrentPos(selectionStart);
		}
		else 
		{
			scintilla.setSel(selectionStart, selectionEnd);
		}
		scintilla.endUndoAction();
		return true;
	}
	
	private boolean doStreamComment( bool bNested = false )
	{
		// const char *commentStart = _pEditView->getCurrentBuffer().getCommentStart();
		// if ((!commentStart) || (!commentStart[0]))
			// return false;
	
		// const char *commentEnd = _pEditView->getCurrentBuffer().getCommentEnd();
		// if ((!commentEnd) || (!commentEnd[0]))
			// return false;
	
		char[] start_comment = `/*`;
		char[] end_comment = `*/`;
		char[] white_space = " ";

		if( bNested )
		{
			start_comment = `/+`;
			end_comment = `+/`;
		}
	
		start_comment ~= white_space;
		white_space ~= end_comment;
		end_comment = white_space;
		int start_comment_length = start_comment.length;
		int selectionStart = scintilla.sendMessage(Scintilla.SCI_GETSELECTIONSTART);
		int selectionEnd = scintilla.sendMessage(Scintilla.SCI_GETSELECTIONEND);
		int caretPosition = scintilla.sendMessage(Scintilla.SCI_GETCURRENTPOS);
		// checking if caret is located in _beginning_ of selected block
		boolean move_caret = caretPosition < selectionEnd;
		// if there is no selection?
		if (selectionEnd - selectionStart <= 0)
		{
			int selLine = scintilla.sendMessage(Scintilla.SCI_LINEFROMPOSITION, selectionStart);
			int lineIndent = scintilla.sendMessage(Scintilla.SCI_GETLINEINDENTPOSITION, selLine);
			int lineEnd = scintilla.sendMessage(Scintilla.SCI_GETLINEENDPOSITION, selLine);
	
			char[] linebuf;//[1000];
			linebuf = scintilla.getTextInRange(lineIndent, lineEnd);
			
			int caret = scintilla.sendMessage(Scintilla.SCI_GETCURRENTPOS);
			int line = scintilla.sendMessage(Scintilla.SCI_LINEFROMPOSITION, caret);
			int lineStart = scintilla.sendMessage(Scintilla.SCI_POSITIONFROMLINE, line);
			int current = caret - lineStart;
			// checking if we are not inside a word
	
			int startword = current;
			int endword = current;
			int start_counter = 0;
			int end_counter = 0;
			while (startword > 0)// && wordCharacters.contains(linebuf[startword - 1]))
			{
				start_counter++;
				startword--;
			}
			// checking _beginning_ of the word
			if (startword == current) return true; // caret is located _before_ a word
			
			while( linebuf[endword + 1] != '\0' ) // && wordCharacters.contains(linebuf[endword + 1]))
			{
				end_counter ++;
				endword ++;
			}
			selectionStart -= start_counter;
			selectionEnd += ( end_counter + 1 );
		}
		scintilla.sendMessage(Scintilla.SCI_BEGINUNDOACTION);
		scintilla.insertText(selectionStart, start_comment);
		selectionEnd += start_comment_length;
		selectionStart += start_comment_length;
		scintilla.insertText(selectionEnd, end_comment);
		if( move_caret )
		{
			// moving caret to the beginning of selected block
			scintilla.sendMessage( Scintilla.SCI_GOTOPOS, selectionEnd );
			scintilla.sendMessage( Scintilla.SCI_SETCURRENTPOS, selectionStart );
		}
		else
		{
			scintilla.sendMessage( Scintilla.SCI_SETSEL, selectionStart, selectionEnd );
		}
		scintilla.sendMessage( Scintilla.SCI_ENDUNDOACTION );
		return true;
	}
		
	private boolean doBoxComment()
	{
		// Get start/middle/end comment strings from options file(s)
		// char[] fileNameForExtension = ExtensionFileName();
		// char[] language = props.GetNewExpand("lexer.", fileNameForExtension.c_str());
		// char[] start_base("comment.box.start.");
		// char[] middle_base("comment.box.middle.");
		// char[] end_base("comment.box.end.");
		 char[] white_space = (" ");
		// start_base += language;
		// middle_base += language;
		// end_base += language;
		char[] start_comment = "/**";
					   char[] middle_comment = "*";
					   char[] end_comment = "*/";
		
		// Note selection and cursor location so that we can reselect text and reposition cursor after we insert comment strings
		int selectionStart = scintilla.sendMessage(Scintilla.SCI_GETSELECTIONSTART);
		int selectionEnd = scintilla.sendMessage(Scintilla.SCI_GETSELECTIONEND);
		int caretPosition = scintilla.sendMessage(Scintilla.SCI_GETCURRENTPOS);
		boolean move_caret = caretPosition < selectionEnd;
		int selStartLine = scintilla.sendMessage(Scintilla.SCI_LINEFROMPOSITION, selectionStart);
		int selEndLine = scintilla.sendMessage(Scintilla.SCI_LINEFROMPOSITION, selectionEnd);
		int lines = selEndLine - selStartLine + 1;
	
		// If selection ends at start of last selected line, fake it so that selection goes to end of second-last selected line
		if(lines > 1 && selectionEnd == cast(int)( scintilla.sendMessage( Scintilla.SCI_POSITIONFROMLINE, selEndLine ) ) )
		{
			selEndLine--;
			lines--;
			selectionEnd = scintilla.sendMessage( Scintilla.SCI_GETLINEENDPOSITION, selEndLine );
		}
		
		// Pad comment strings with appropriate whitespace, then figure out their lengths (end_comment is a bit special-- see below)
		start_comment ~= white_space;
		middle_comment ~= white_space;
		int start_comment_length = start_comment.length;
		int middle_comment_length = middle_comment.length;
		int end_comment_length = end_comment.length;
		int whitespace_length = white_space.length;
	
		// Calculate the length of the longest comment string to be inserted, and allocate a null-terminated char buffer of equal size
		int maxCommentLength = start_comment_length;
		if (middle_comment_length > maxCommentLength)
			maxCommentLength = middle_comment_length;
		if (end_comment_length + whitespace_length > maxCommentLength)
			maxCommentLength = end_comment_length + whitespace_length;
		// char *tempString = new char[maxCommentLength + 1];
		char[] tempString;
	
		scintilla.sendMessage(Scintilla.SCI_BEGINUNDOACTION);
	
		// Insert start_comment if needed
		int lineStart = scintilla.sendMessage(Scintilla.SCI_POSITIONFROMLINE, selStartLine);
		// GetRange(wEditor, lineStart, lineStart + start_comment_length, tempString);
		tempString = scintilla.getTextInRange(lineStart, lineStart + start_comment_length);
		// tempString[start_comment_length] = '\0';
		if (start_comment != tempString) {
			scintilla.insertText(lineStart, start_comment);
			selectionStart += start_comment_length;
			selectionEnd += start_comment_length;
		}
	
		if( lines <= 1 )
		{
			// Only a single line was selected, so just append whitespace + end-comment at end of line if needed
			int lineEnd = scintilla.sendMessage(Scintilla.SCI_GETLINEENDPOSITION, selEndLine);
			// GetRange(wEditor, lineEnd - end_comment_length, lineEnd, tempString);
			tempString = scintilla.getTextInRange(lineEnd - end_comment_length, lineEnd);
			// tempString[end_comment_length] = '\0';
			if (end_comment != tempString) {
				// end_comment.insert(0, white_space);
				end_comment = white_space ~ end_comment;
				scintilla.insertText(lineEnd, end_comment);
			}
		}else
		{
			// More than one line selected, so insert middle_comments where needed
			for (int i = selStartLine + 1; i < selEndLine; i++) {
				lineStart = scintilla.sendMessage(Scintilla.SCI_POSITIONFROMLINE, i);
				// GetRange(wEditor, lineStart, lineStart + middle_comment_length, tempString);
				tempString = scintilla.getTextInRange(lineStart, lineStart + middle_comment_length);
				// tempString[middle_comment_length] = '\0';
				if (middle_comment != tempString) {
					// SendEditorString(SCI_INSERTTEXT, lineStart, middle_comment.c_str());
					scintilla.insertText(lineStart, middle_comment);
					selectionEnd += middle_comment_length;
				}
			}
	
			// If last selected line is not middle-comment or end-comment, we need to insert
			// a middle-comment at the start of last selected line and possibly still insert
			// and end-comment tag after the last line (extra logic is necessary to
			// deal with the case that user selected the end-comment tag)
			lineStart = scintilla.sendMessage(Scintilla.SCI_POSITIONFROMLINE, selEndLine);
			// GetRange(wEditor, lineStart, lineStart + end_comment_length, tempString);
			tempString = scintilla.getTextInRange(lineStart, lineStart + end_comment_length);
			// tempString[end_comment_length] = '\0';
			if (end_comment != tempString) {
				// GetRange(wEditor, lineStart, lineStart + middle_comment_length, tempString);
				tempString = scintilla.getTextInRange(lineStart, lineStart + middle_comment_length);
				// tempString[middle_comment_length] = '\0';
				if (middle_comment != tempString) {
					// SendEditorString(SCI_INSERTTEXT, lineStart, middle_comment.c_str());
					scintilla.insertText(lineStart, middle_comment);
					selectionEnd += middle_comment_length;
				}
	
				// And since we didn't find the end-comment string yet, we need to check the *next* line
				//  to see if it's necessary to insert an end-comment string and a linefeed there....
				lineStart = scintilla.sendMessage(Scintilla.SCI_POSITIONFROMLINE, selEndLine + 1);
				// GetRange(wEditor, lineStart, lineStart + cast(int) end_comment_length, tempString);
				tempString = scintilla.getTextInRange(lineStart, lineStart + end_comment_length);
				// tempString[end_comment_length] = '\0';
				if (end_comment != tempString) {
					// end_comment.append("\n");
					end_comment ~= "\n";
					// SendEditorString(SCI_INSERTTEXT, lineStart, end_comment.c_str());
					scintilla.insertText(lineStart, end_comment);
				}
			}
		}
	
		if( move_caret )
		{
			// moving caret to the beginning of selected block
			scintilla.sendMessage( Scintilla.SCI_GOTOPOS, selectionEnd );
			scintilla.sendMessage( Scintilla.SCI_SETCURRENTPOS, selectionStart );
		}else
		{
			scintilla.sendMessage( Scintilla.SCI_SETSEL, selectionStart, selectionEnd );
		}
	
		scintilla.sendMessage( Scintilla.SCI_ENDUNDOACTION );
	
		return true; 
	}
}
