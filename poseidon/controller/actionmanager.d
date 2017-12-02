module poseidon.controller.actionmanager;

private import dwt.all;
private import poseidon.controller.gui;
private import poseidon.controller.menumanager;
private import poseidon.globals;
private import poseidon.model.project;
private import poseidon.model.misc;
private import poseidon.model.executer;
private import poseidon.controller.property.prjproperty;
private import poseidon.util.waitcursor;
private import poseidon.controller.dialog.customtool;
private import poseidon.controller.packageexplorer;
private import poseidon.controller.property.preference;
private import poseidon.controller.dialog.aboutbox;
private import poseidon.controller.toolbarmanager;
private import poseidon.controller.edititem;
private import poseidon.model.navcache;

class ActionManager
{
	private import std.string;
	private import std.process, std.stream;
	private import poseidon.util.registerutil;

	alias ArbitraryObj!(char[][]) FileArguments;

	
	// static properties
	private static MenuManager menuMan() { return sGUI.menuMan; };
	private static ToolBarManager toolMan() { return sGUI.toolMan; };
	private static ActionManager  pthis;

	public NavCache 	navCache;

	
	public this()
	{
		navCache = new NavCache();
	}

	public void actionExit(Event e)
	{
		// do save and close doc
		sGUI.onClose(e);

		/** Only dispose if is closing */
		if (GUI.isClosing)
			sShell.dispose();
	}

	public void actionNewFile( Event e )
	{
		sGUI.packageExp.createUntitleFile();
	}	

	public void actionOpenFile( Event e )
	{
		scope FileDialog dlg = new FileDialog( sShell, DWT.OPEN );
		char[][] filter;
		filter ~= "*.d";
		filter ~= "*.*";
		dlg.setFilterExtensions( filter );
		dlg.setFilterPath( Globals.recentDir );
		char[] fullpath = std.string.strip( dlg.open() );

		if( fullpath.length )
		{
			Globals.recentDir = std.path.getDirName( fullpath );
			sGUI.packageExp.openFile( fullpath, 1, true );
		}
	}	

	public void actionCloseFile( Event e )
	{
		sGUI.editor.closeFile( sGUI.editor.getSelectedFileName() );
	}	

	public void actionNewProject(Event e)
	{
		scope dlg = new PrjProperty(sShell, null);
		if(dlg.open() == "OK"){
			if(dlg.createNew && dlg.project)
			{
				// create the new project
				sGUI.packageExp.addProject(dlg.project);
				toolMan.updateToolBar();
			}
		}
	}

	public void actionOpenProject(Event e)
	{
		scope DirectoryDialog dlg = new DirectoryDialog(sShell, DWT.OPEN);
		dlg.setFilterPath(Globals.recentDir);
		char[] fullpath = dlg.open();
		if(fullpath) {
			if(!Project.checkDir(fullpath)){
				MessageBox.showMessage(Globals.getTranslation("mb.root_as_prjdir"));
				return;
			}
			
			char[] file = std.path.join(fullpath, Project.EXT);
			if(!std.file.exists(file)){
				if(DWT.YES != MessageBox.showMessage(Globals.getTranslation("mb.open_plain_prj"), 
					Globals.getTranslation("QUESTION"), sShell, DWT.ICON_QUESTION | DWT.YES | DWT.NO))
				return;
			}

			sGUI.packageExp.loadProject(fullpath);
			toolMan.updateToolBar();
		}
	}

	public void actionSave(Event e)
	{
		sGUI.editor.save();
		toolMan.updateToolBar();
	}
	
	public void actionSaveAll(Event e)
	{
		sGUI.editor.saveAll();
		toolMan.updateToolBar();
	}

	public void actionSaveAs(Event e)
	{
		sGUI.editor.saveAs();
		toolMan.updateToolBar();
	}

	public void actionUndo( Event e )
	{
		EditItem ei = sGUI.editor.getSelectedEditItemHSU();
		if( ei ) ei.toolbarDirectlyHSU( 0 );
		toolMan.updateToolBar();
	}

	public void actionRedo( Event e )
	{
		EditItem ei = sGUI.editor.getSelectedEditItemHSU();
		if( ei ) ei.toolbarDirectlyHSU( 1 );
		toolMan.updateToolBar();
	}

	public void actionCut( Event e )
	{
		EditItem ei = sGUI.editor.getSelectedEditItemHSU();
		if( ei ) ei.toolbarDirectlyHSU( 2 );
		toolMan.updateToolBar();
	}

	public void actionCopy( Event e )
	{
		EditItem ei = sGUI.editor.getSelectedEditItemHSU();
		if( ei ) ei.toolbarDirectlyHSU( 3 );
		toolMan.updateToolBar();
	}

	public void actionPaste( Event e )
	{
		EditItem ei = sGUI.editor.getSelectedEditItemHSU();
		if( ei ) ei.toolbarDirectlyHSU( 4 );
		toolMan.updateToolBar();
	}
	
	public void actionNavigate(Event e)
	{
		NavPoint pt;
		Integer ii = cast(Integer)e.cData;
		if(ii.intValue() == 0){
			// back
			pt = navCache.navBack();
		}else{
			// forward
			pt = navCache.navForward();
		}
	}
	
	public void actionClearNavCache(Event e)
	{
		navCache.clear();
	}
	
	/**
	 * invoke when use click the external tools menu item
	 */
	public void actionExtTool(Event e) {
		MenuItem mi = cast(MenuItem)e.widget;
		assert(mi);
		ToolEntry entry = cast(ToolEntry)mi.getData();
		
		/** 
		 * set the most recently operation to the toolItem, 
		 */
		// save the last tool name
		ToolEntry.lastTool = entry;
		toolMan.updateExtToolInfo();
		
		execExtTool(entry);
	}
	
	/**
	 * invoke when use click the external tools in toolbar
	 */
	public void actionTbarExtTools(Event event) {
		/**
		 * A selection event will be fired when a drop down tool
		 * item is selected in the main area and in the drop
		 * down arrow.  Examine the event detail to determine
		 * where the widget was selected.
		 */		
		if (event.detail == DWT.ARROW) {
			/*
			 * The drop down arrow was selected.
			 */
			
			// Position the menu below and vertically aligned with the the drop down tool button.
			ToolItem toolItem = cast(ToolItem) event.widget;
			ToolBar  toolBar = toolItem.getParent();
			
			Rectangle toolItemBounds = toolItem.getBounds();
			Point point = toolBar.toDisplay(toolItemBounds.x, toolItemBounds.y);
			Menu menu = menuMan.getExtToolMenu();
			menu.setLocation(point.x, point.y + toolItemBounds.height);
			menu.setVisible(true);
		} else {
			/*
			 * Main area of drop down tool item selected.
			 * An application would invoke the code to perform the action for the tool item.
			 */
			if(ToolEntry.lastTool) 
				execExtTool(ToolEntry.lastTool);
		}
	}


	// COMPILER 
	private bool checkCmdExist()
	{
		sGUI.outputPanel.setForeColor( 255, 0, 0 );
		
		if( !std.file.exists( Globals.DMDPath ~ "\\bin\\dmd.exe" ) )
		{
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setString( " ERROR >>> Wrong DMD Path!!\n" );
			return false;
		}

		ItemInfo itemInfo;
		if( sGUI.editor.getItemCount()> 0 )
			itemInfo = sGUI.editor.getSelectedItemInfoHSU();
		else
			itemInfo = sGUI.packageExp.getSelection();

		if( itemInfo ) 
		{
			Project prj 	= itemInfo.getProject();
			
			if( prj.projectBuildType > 0 )
				if( !std.file.exists( Globals.DMCPath ~ "\\bin\\lib.exe" ) )
				{
					sGUI.outputPanel.bringToFront();
					sGUI.outputPanel.setString( " ERROR >>> Wrong DMC Path!!\n" );
					return false;
				}
		}

		return true;
	}	

	// Clean
	public void actionCleanSourceRunning( Event e )
	{
		if( !sGUI.editor ) return;

		Project prj;
		if( sGUI.editor.getItemCount()> 0 )
			prj = sGUI.editor.getSelectedProjectHSU();
		else
			prj = sGUI.packageExp.activeProject();

		sGUI.outputPanel.bringToFront();
		sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );
		sGUI.outputPanel.setString( "Command >>> Clean Project: " ~ prj.projectName );
		sGUI.outputPanel.appendString( "\nClean all files created during compiling: " );

		char[][] d_running_files = std.file.listdir( prj.projectDir, "*.map" );
		foreach( char[] d; d_running_files ) std.file.remove( d );

		d_running_files = std.file.listdir( prj.projectDir, "*.rsp" );
		foreach( char[] d; d_running_files ) std.file.remove( d );

		d_running_files = std.file.listdir( prj.projectDir, "*.ksp" );
		foreach( char[] d; d_running_files ) std.file.remove( d );

		d_running_files = std.file.listdir( prj.projectDir, "*.lsp" );
		foreach( char[] d; d_running_files ) std.file.remove( d );

		d_running_files = std.file.listdir( prj.projectDir, "*.def" );
		foreach( char[] d; d_running_files ) std.file.remove( d );

		d_running_files = std.file.listdir( prj.projectDir, "*.lst" );
		foreach( char[] d; d_running_files ) std.file.remove( d );

		d_running_files = std.file.listdir( prj.projectDir, "*.obj" );
		foreach( char[] d; d_running_files ) std.file.remove( d );
			

		/*
		char[] exeName;
		if( prj.projectTargetName.length == 0 )
			exeName = prj.projectDir ~ "\\" ~ prj.projectName ~ ".exe";
		else
			exeName = prj.projectDir ~ "\\" ~ prj.projectTargetName ~ ".exe";
			
		if( std.file.exists( exeName ) ) std.file.remove( exeName );
		*/
		/*
		char[] objDir;
		if( prj.projectObjDir.length > 0 ) objDir = prj.projectDir ~ "\\" ~ prj.projectObjDir; else objDir = prj.projectDir;
		d_running_files = std.file.listdir( objDir, "*.obj" );
		foreach( char[] d; d_running_files ) std.file.remove( d );
		*/
		sGUI.outputPanel.appendString( "......OK!\n" );
	}
		
	// Compile
	public void actionDefaultCompile( Event e )
	{
		if( !checkCmdExist() ) return;

		if( sGUI.editor.getItemCount() < 1 )
		{
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
			sGUI.outputPanel.setString( "ERROR >>> Please Open A File To Compile!!!\n" );			
			return;
		}

		EditItem ei = sGUI.editor.getSelectedEditItemHSU();
		if( ei !is null )
		{
			char filename[] = ei.getFileName();
			ei.save();

			Project prj = sGUI.editor.getSelectedProjectHSU();
			ToolEntry entry = prj.generateCompileCmdHSU( filename );

			if( entry.name == "wrong -od path!" )
			{
				sGUI.outputPanel.bringToFront();
				sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
				sGUI.outputPanel.setString( "Command >>> Compiling File ......\n" );
				sGUI.outputPanel.appendString( " ERROR >>> Wrong OBJ Files Path!!!\n" );
				return;
			}

			sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );
			char[] title = "Command >>> Compiling File: " ~ filename ~ "......\n";			
			execExtToolHSU( entry, title, !Globals.backBuild );
		}
		else
		{
			sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setString( "Command >>> Compiling File ......\n" );
			sGUI.outputPanel.appendString( " ERROR >>> Not A D Source File!!!\n" );
		}
	}

	// Run
	public void actionDefaultRun( Event e )
	{
		Project prj;
		if( sGUI.editor.getItemCount()> 0 )
		{
			prj = sGUI.editor.getSelectedProjectHSU();
			if( prj is null ) prj = sGUI.packageExp.activeProject();
		}
		else
			prj = sGUI.packageExp.activeProject();
			
		if( prj.projectBuildType > 0 )
		{
			sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setString( "Command >>> Running Project: " ~ prj.projectName ~ "......\n" );
			sGUI.outputPanel.appendString( " ERROR >>> Can't Run Static/Dynamic Library!!!\n" );
			return;
		}
		
		ToolEntry entry = prj.generateRunCmdHSU();
		char[] title = "Command >>> Running Project: " ~ prj.projectName ~ "......\n";

		if( entry )
		{
			sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );
			execExtToolHSU( entry, title, !Globals.backBuild );
		}else
		{
			char[] exeFileName;
			if( prj.projectTargetName.length > 0 )
				exeFileName = prj.projectTargetName ~ ".exe";
			else
				exeFileName = prj.projectName ~ ".exe";
				
			sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setString( title );
			sGUI.outputPanel.appendLine( " ERROR >>> No " ~ exeFileName ~" Exist!!!" );
			sGUI.outputPanel.appendLine("\nFinished");
		}
	}		

	// Build
	public void actionDefaultBuildHSU( Event e )
	{
		if( !checkCmdExist() ) return;		

		Project prj;
		if( sGUI.editor.getItemCount()> 0 )
		{
			prj = sGUI.editor.getSelectedProjectHSU();
			if( prj is null ) prj = sGUI.packageExp.activeProject();
		}
		else
			prj = sGUI.packageExp.activeProject();
			
		sGUI.editor.saveProjectFile();

		ToolEntry entry = prj.generateBuildCmdHSU();
		char[] title = "Command >>> Building Project: " ~ prj.projectName ~ "......\n";
		
		if( !entry )
		{
			sGUI.outputPanel.setForeColor( 255, 107, 36 );
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setString( title );
			sGUI.outputPanel.appendLine( " WARING >>> It Isn't Necessary To Build Anything!!" );
			sGUI.outputPanel.appendLine("\nFinished");
		}else
		{
			if( entry.name == "wrong -od path!" )
			{
				sGUI.outputPanel.bringToFront();
				sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
				sGUI.outputPanel.setString( title );
				sGUI.outputPanel.appendString( " ERROR >>> Wrong OBJ Files Path!!!\n" );
				return;
			}
			
			sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );

			if( prj.projectBuildType > 0 )
				actionDefaultMakeLibHSU( entry, prj );
			else
				execExtToolHSU( entry, title, !Globals.backBuild );
		}
	}

	// Build and Run
	public void actionDefaultBuild_RunHSU( Event e )
	{
		sGUI.outputPanel.clear();
		if( !checkCmdExist() ) return;

		// Build & Run Single File
		if( sGUI.editor.getItemCount() >  0 )
		{
			if( !sGUI.editor.selectedIsProjectFile )
			{
				char[] singleFileName = sGUI.editor.getSelectedFileName();
				sGUI.editor.save();

				char[] title = "Command >>> Build and Run SingleFile: " ~ singleFileName ~ "......\n\n";

				ToolEntry entry = new ToolEntry();
				entry.cmd = Globals.DMDPath ~ "\\bin\\dmd.exe";
				entry.args = "-c " ~ singleFileName;
				entry.hideWnd = true;
				sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );
				execExtToolHSU( entry, title, true, true, false );


				char[] outResult = sGUI.outputPanel.getString();
				char[][] splitResult = std.string.split( outResult, "\n" );

				for( int i = 2; i < splitResult.length; ++ i )
				{
					if( splitResult[i].length > 1 )
					{
						sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
						return;
					}
				}

				/+
				if( std.file.exists( std.path.getName( singleFileName ) ~ ".obj" ) )
					std.file.remove( std.path.getName( singleFileName ) ~ ".obj" );
				+/
				
				entry.name = "Build & Run Single File";
				entry.hideWnd = false;
				entry.capture = false;

				entry.args = "-run " ~ singleFileName;

				execExtToolHSU( entry, title );
				return;
			}
		}
		

		Project prj;
		if( sGUI.editor.getItemCount()> 0 )
		{
			prj = sGUI.editor.getSelectedProjectHSU();
			if( prj is null ) prj = sGUI.packageExp.activeProject();
		}
		else
			prj = sGUI.packageExp.activeProject();

		sGUI.editor.saveProjectFile();

		ToolEntry entry = prj.generateBuildCmdHSU();

		char[] title = "Command >>> Running Project: " ~ prj.projectName ~ "......\n";
		if( !entry )
		{
			if( prj.projectBuildType > 0 )
			{
				sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
				sGUI.outputPanel.bringToFront();
				sGUI.outputPanel.setString( title );
				sGUI.outputPanel.appendString( " ERROR >>> Can't Run Static/Dynamic Library!!!\n" );
				return;
			}
				
			entry = prj.generateRunCmdHSU();
			sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );
			execExtToolHSU( entry, title, true );
		}else
		{
			if( entry.name == "wrong -od path!" )
			{
				sGUI.outputPanel.bringToFront();
				sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
				sGUI.outputPanel.setString( title );
				sGUI.outputPanel.appendString( " ERROR >>> Wrong OBJ Files Path!!!\n" );
				return;
			}
			// delete EXE
			
			char[] exeFileName;
			if( prj.projectTargetName.length > 0 )
				exeFileName = prj.projectDir ~ "\\" ~ prj.projectTargetName ~ ".exe";
			else
				exeFileName = prj.projectDir ~ "\\" ~ prj.projectName ~ ".exe";

			try
			{
				if( std.file.exists( exeFileName ) ) std.file.remove( exeFileName );
			}
			catch
			{
				sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
				sGUI.outputPanel.bringToFront();
				sGUI.outputPanel.setString( " ERROR >>> File Is Under Running!!!\n " );
				return;
			}
			
			title = "Command >>> Building Project: " ~ prj.projectName ~ "......\n";
			sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );
			execExtToolHSU( entry, title, true, true );

			title = "\nCommand >>> Running Project: " ~ prj.projectName ~ "......\n";
			if( prj.projectBuildType > 0 )
			{
				sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
				sGUI.outputPanel.bringToFront();
				sGUI.outputPanel.setString( title );
				sGUI.outputPanel.appendString( " ERROR >>> Can't Run Static/Dynamic Library!!!\n" );
				return;
			}

			entry = prj.generateRunCmdHSU();
			if( entry )	execExtToolHSU( entry, title, !Globals.backBuild, false );
		}
	}

	// ReBuild All
	public void actionDefaultBuild( Event e ) 
	{
		if( !checkCmdExist() ) return;
		
		Project prj;
		if( sGUI.editor.getItemCount()> 0 )
		{
			prj = sGUI.editor.getSelectedProjectHSU();
			if( prj is null ) prj = sGUI.packageExp.activeProject();
		}
		else
			prj = sGUI.packageExp.activeProject();
			
		sGUI.editor.saveProjectFile();

		ToolEntry entry = prj.generateBuildCmdHSU( true );
		char[] title = "Command >>> ReBuilding Project: " ~ prj.projectName ~ "......\n";

		if( entry.name == "wrong -od path!" )
		{
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
			sGUI.outputPanel.setString( title );
			sGUI.outputPanel.appendString( " ERROR >>> Wrong OBJ Files Path!!!\n" );
			return;
		}
		
		sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );
		if( prj.projectBuildType > 0 )
			actionDefaultMakeLibHSU( entry, prj );
		else
			execExtToolHSU( entry, title, !Globals.backBuild );
	}

	// Bud
	public void actionBud( Event e ) 
	{
		if( !checkCmdExist() ) return;

		if( !std.file.exists( Globals.BudExe ) )
		{
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setString( " ERROR >>> Wrong Extra Build Tool Path!!\n" );
			return;
		}
		
		Project prj;
		if( sGUI.editor.getItemCount()> 0 )
		{
			prj = sGUI.editor.getSelectedProjectHSU();
			if( prj is null ) prj = sGUI.packageExp.activeProject();
		}
		else
			prj = sGUI.packageExp.activeProject();

		char[] mainFile = std.string.strip( prj.mainFile );
		if( !mainFile.length )
		{
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
			sGUI.outputPanel.setString( "Command >>> Building The Project( Use Build Tool ): " ~ prj.projectName ~ "......\n" );
			sGUI.outputPanel.appendString( " ERROR >>> No Project Main File!!!\n" );
			return;
		}
			
		sGUI.editor.saveProjectFile();

		ToolEntry entry = prj.generateBUD();
		char[] title = "Command >>> Building The Project( Use Build Tool ): " ~ prj.projectName ~ "......\n";
		if( entry.name == "wrong -od path!" )
		{
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
			sGUI.outputPanel.setString( title );
			sGUI.outputPanel.appendString( " ERROR >>> Wrong OBJ Files Path!!!\n" );
			return;
		}

		sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );
		execExtToolHSU( entry, title, !Globals.backBuild );		
	}
	

	// Make Library
	private void actionDefaultMakeLibHSU( ToolEntry entry, Project prj )
	{
		if( !checkCmdExist() ) return;

		char[] title;
		sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );

		title = "Command >>> Compile All Files: " ~ prj.projectName ~ "......\n";
		execExtToolHSU( entry, title, true, true );

		char[] outResult = sGUI.outputPanel.getString();
		char[][] splitResult = std.string.split( outResult, "\n" );

		for( int i = 2; i < splitResult.length; ++ i )
		{
			if( splitResult[i].length > 1 )
			{
				sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
				sGUI.outputPanel.appendString( "Compile Error!!!!\n" );
				return;
			}
		}

		//prj.projectBuildType > 0
		if( prj.projectBuildType == 1 )
		{
			entry = prj.generateMakeLibCmdHSU();
			title = "Command >>> Make Library: " ~ prj.projectName ~ "......\n";
		}
		else
		{
			entry = prj.generateMakeDllCmdHSU();
			title = "Command >>> Make Dll: " ~ prj.projectName ~ "......\n";
			if( prj.useImplib )
			{
				execExtToolHSU( entry, title, true, false );

				entry = prj.generateImplib();
				if( entry !is null ) execExtToolHSU( entry, title, true, false );
				return;
			}
		}
		
		execExtToolHSU( entry, title, !Globals.backBuild, false );
	}


	public bool actionRCCompile( char[] fileName, char[] command )
	{
		if( !command.length )
		{
			sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setString( " ERROR >>> No Commands!!\n" );
			return false;
		}
		
		if( !std.file.exists( Globals.RCExe ) )
		{
			sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setString( " ERROR >>> Wrong RC Compiler EXE Path!!\n" );
			return false;
		}

		ToolEntry entry = new ToolEntry();

        entry.name = "RC Compiler";
		entry.cmd = Globals.RCExe;
		entry.args = command;
		entry.hideWnd = true;

		execExtToolHSU( entry, "Command >>> RC Compiler: " ~ fileName ~ "......\n", !Globals.backBuild, false );		

		return true;
	}


	public bool actionDDocumentFile( int index )
	{
		try
		{
			ToolEntry entry = new ToolEntry();
			entry.name = "Help Document " ~ std.string.toString( index );
			entry.cmd = Globals.DDcoumentDir[index];
			if( !std.file.exists( Globals.DDcoumentDir[index] ) ) return false;
			
			//entry.args = fileName;
			sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );

			execExtToolHSU( entry, "Open D Document......\n" );
		}
		catch
		{
			return false;
		}
		
		return true;
	}	

	public void actionDebug( bool bBuild = true ) 
	{
		if( !checkCmdExist() ) return;
		if( sGUI.debuggerDMD.isPipeCreate() ) 
		{
			MessageBox.showMessage( "Debugger had Already Created!" );
			return;
		}

		if( !std.file.exists( Globals.DebuggerExe ) )
		{
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setString( " ERROR >>> Wrong Debugger Path!!\n" );
			return;
		}

		Project prj;
		if( sGUI.editor.getItemCount()> 0 )
		{
			prj = sGUI.editor.getSelectedProjectHSU();
			if( prj is null ) prj = sGUI.packageExp.activeProject();
		}
		else
			prj = sGUI.packageExp.activeProject();

		if( bBuild )
		{
			sGUI.editor.saveProjectFile();

			char[] prevDMDOption = prj.buildOptionDMD;
			prj.buildOptionDMD = std.string.replace( prj.buildOptionDMD, " -O", "" );
			prj.buildOptionDMD = std.string.replace( prj.buildOptionDMD, " -inline", "" );
			prj.buildOptionDMD = std.string.replace( prj.buildOptionDMD, " -release", "" );

			prj.buildOptionDMD = prj.buildOptionDMD.length ? prj.buildOptionDMD ~ "-g -debug" : " -g -debug ";

		
			ToolEntry entry = prj.generateBuildCmdHSU( true );
			char[] title = "Command >>> ReBuilding Project( In Deubg Mode ): " ~ prj.projectName ~ "......\n";

			prj.buildOptionDMD = prevDMDOption;

			sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );

			execExtToolHSU( entry, title, true );

			char[] outResult = sGUI.outputPanel.getString();
			char[][] splitResult = std.string.split( outResult, "\n" );

			if( splitResult.length > 6 )
			{
				sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
				sGUI.outputPanel.appendString( "Make Error!!!!\n" );
				return;
			}		
			
			if( splitResult.length > 3 )
			{
				
				char[] reverseString = std.string.strip( splitResult[3].reverse );
				
				if( reverseString.length )
					if( reverseString[0] != ';' )
					{
						sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
						sGUI.outputPanel.appendString( "Make Error!!!!\n" );
						return;
					}
			}
		}

		//MessageBox.showMessage( "ffff" );

		ToolEntry entryDebug = new ToolEntry();

		if( !prj.projectTargetName.length )
			entryDebug.args = prj.projectDir ~ "\\" ~ prj.projectName ~ ".exe " ~ prj.projectEXEArgs;
		else
			entryDebug.args = prj.projectDir ~ "\\" ~ prj.projectTargetName ~ ".exe " ~ prj.projectEXEArgs;

		if( !std.file.exists( entryDebug.args ) )
		{
			sGUI.outputPanel.setForeColor( 0xff, 0, 0 );
			sGUI.outputPanel.appendString( "No EXE File Exist!!!!\n" );
			return;
		}

		sGUI.outputPanel.setForeColor( 0, 0x33, 0x66 );

		entryDebug.name = "Debugger";
		entryDebug.cmd = Globals.DebuggerExe;
		entryDebug.hideWnd = true;
		//entryDebug.args = "-cmd=" ~ "\"nc\"";
		if( entryDebug.dir.length == 0) entryDebug.dir = std.file.getcwd();

		if( !sGUI.debuggerDMD.execDebugger( entryDebug, prj.projectDir ) ) 
		{
			MessageBox.showMessage( "Debug Error!!\nTry compiling and linking with -g" );
			return;
		}

		sGUI.toolMan.updateToolBar();
		//sGUI.debugOutputPanel.bringToFront();
	}
	
	public void actionDebugExec( Event e ) 
	{
		sGUI.debuggerDMD.resume();
		sGUI.toolMan.updateToolBar();
	}

	public void actionDebugStop( Event e ) 
	{
		if( sGUI.debuggerDMD.isPipeCreate() ) 
		{
			sGUI.debuggerDMD.stop();
			sGUI.debuggerDMD.resetToolBar();
			sGUI.toolMan.updateToolBar();
		}
	}

	public void actionDebugStepInto( Event e ) 
	{
		sGUI.debuggerDMD.step( 0 );
	}

	public void actionDebugStepOver( Event e ) 
	{
		sGUI.debuggerDMD.step( 1 );
	}

	public void actionDebugStepReturn( Event e ) 
	{
		sGUI.debuggerDMD.step( 2 );
	}

	public void actionCleanAllBreakPoints( Event e )
	{
		if( sGUI.debuggerDMD !is null )	sGUI.debuggerDMD.topRightPanel.bpItem.cleanAllBps();
	}
	/+
	
	public void actionDebugDumpRegister( Event e ) 
	{
		sGUI.debuggerDMD.dumpRegister();
	}

	public void actionDebugDumpStack( Event e ) 
	{
		sGUI.debuggerDMD.dumpStack();
	}

	public void actionListDlls( Event e ) 
	{
		sGUI.debuggerDMD.dumpDll();
	}
	
	public void actionDebugListVariable( Event e ) 
	{
		sGUI.debuggerDMD.dumpVariables();
	}
	+/
	
	private void execExtToolHSU( ToolEntry entry, char[] title = "", bool bSoon = false, bool bCls = true, bool bShowCommand = true )
	{
		scope WaitCursor wc = new WaitCursor(sShell);
		
		// keep the old entry
		ToolEntry newEntry = entry.clone();
			
		//if(newEntry.savefirst) sGUI.editor.saveAll();

		if(newEntry.dir.length == 0) newEntry.dir = std.file.getcwd();
			
		// substitute envirenment variable
		envSubstitute( newEntry.cmd, true );
		envSubstitute( newEntry.args, true );
		// the dir doesn't need quotation added
		envSubstitute( newEntry.dir, false );
			
		std.file.chdir( newEntry.dir );
			
		sGUI.outputPanel.bringToFront();
		if( bCls )
			sGUI.outputPanel.setString( title );
		else
			sGUI.outputPanel.appendString( title );

		if( bShowCommand ) sGUI.outputPanel.appendString(newEntry.cmd ~" " ~ newEntry.args ~ "\n\n" );
		sGUI.outputPanel.setBusy( true );

		if( bSoon )
			_doExecExtTool( newEntry );
		else
		{
			ThreadEx thread = new ThreadEx( newEntry, &_doExecExtTool );
			thread.start();
		}
	}
	
	private void execExtTool(ToolEntry entry) {
		scope WaitCursor wc = new WaitCursor(sShell);
		
		// keep the old entry
		ToolEntry newEntry = entry.clone();
		
		if(newEntry.savefirst)
			sGUI.editor.saveAll();

		if(newEntry.dir.length == 0)
			newEntry.dir = std.file.getcwd();
		
		// substitute envirenment variable
		envSubstitute(newEntry.cmd, true);
		envSubstitute(newEntry.args, true);
		// the dir doesn't need quotation added
		envSubstitute(newEntry.dir, false);
		
		std.file.chdir(newEntry.dir);
		
		sGUI.outputPanel.bringToFront();
		sGUI.outputPanel.setString("cwd > " ~ newEntry.dir ~ "\n");

		sGUI.outputPanel.appendString(newEntry.cmd ~" " ~ newEntry.args ~ "\n\n" );
		sGUI.outputPanel.setBusy(true);

		ThreadEx thread = new ThreadEx(newEntry, &_doExecExtTool);
		thread.start();
	}

	int _doExecExtTool(Object args)
	{
		// nested functions
		void _echo(Object args)
		{
			if(!sGUI.outputPanel.isDisposed()){
				StringObj s = cast(StringObj)args;
				sGUI.outputPanel.appendLine(s.data);
			}
		}
		void _end(Object args)
		{
			if(!sGUI.outputPanel.isDisposed()){
				sGUI.outputPanel.setBusy(false);
				sGUI.outputPanel.appendLine("\nFinished");
			}
		}
		
		// code begin here
		/**
		 * since here is not in GUI thread, Display.getCurrent() just return
		 * null !!! use Display.getDefault() instead
		 */
		// Display display = Display.getCurrent();
		Display display = Display.getDefault();

		try{
			ToolEntry entry = cast(ToolEntry)args;
			Executer.run(entry, &_echo, display);
		}catch(Object o){
			Util.trace(o.toString());
		}finally{
			display.asyncExec(null, &_end);
		}
		return 0;
	}

	public void actionEditExtTool(Event e) 
	{
		CustToolEditor dlg = new CustToolEditor(sShell);
		dlg.open();
		dlg.handleEvent(dlg, DWT.Dispose, delegate(Event e) 
		{
			CustToolEditor dlg = cast(CustToolEditor)e.cData;
			if(dlg.returnValue) 
			{
				// save to xml file and rebuild custom menu
				Globals.saveConfig();
				menuMan.buildExtToolMenu();
			}
		});
	}

	void envSubstitute(inout char[] line, boolean addQuotation)
	{
		assert(line);
		
		// current selected item name
		char[] itempath = getItemPath();
		char[] quotation = `"`;
//		if(envSubstitute){
//			line = std.string.replace(line, `"$(ItemFileName)"`);
//			line = std.string.replace(line, `"$(ItemExt)"`);
//		}
		if(std.string.find(itempath, " ") >= 0 && addQuotation){
			line = std.string.replace(line, "$(ItemPath)", `"$(ItemPath)"`);
			line = std.string.replace(line, "$(ItemDir)", `"$(ItemDir)"`);
		}
		line = std.string.replace(line, "$(ItemPath)", itempath);
		line = std.string.replace(line, "$(ItemDir)", std.path.getDirName(itempath));
		line = std.string.replace(line, "$(ItemFileName)", std.path.getBaseName(itempath));
		line = std.string.replace(line, "$(ItemExt)", std.path.getExt(itempath));
		
		// Editor variable
		char[] row = "", col = "";
		int[] info = sGUI.editor.getLineInfo();
		if(info[0] != -1){
			row = std.string.toString(info[0]+1); // zero based index
			col = std.string.toString(info[1]);
		}
		char[] sel = sGUI.editor.getSelText();
		if(sel is null)	
			sel = "";
		line = std.string.replace(line, "$(CurLine)", row);
		line = std.string.replace(line, "$(CurCol)", col);
		line = std.string.replace(line, "$(CurText)", sel);
		
		// current project dir
		Project prj = sGUI.packageExp.activeProject;
		char[] ProjectName = prj ? prj.projectName : "";
		char[] ProjectDir = prj ? prj.projectDir : "";
		char[] mainFile = prj ? prj.mainFile : "";
		char[] all;

		if( prj )
		{
			if( std.string.find( line, "$(ProjectAll)" ) > -1 )
			{
				char[]	includePaths, exeName;
				
				if( !prj.projectTargetName.length ) exeName = " -of" ~ prj.projectName;else exeName = " -of" ~ prj.projectTargetName;
				
				for( int i = 0; i < prj.projectIncludePaths.length; i ++ )
				{
					if( i == 0 ) 
						includePaths = " -I" ~ prj.projectIncludePaths[i];
					else
						includePaths = includePaths ~ ";" ~ prj.projectIncludePaths[i];
				}
				
				
				for( int i = 0; i < prj.projectImportExpressions.length; i ++ )
				{
					if( i == 0 ) 
						includePaths = " -J" ~ prj.projectImportExpressions[i];
					else
						includePaths = includePaths ~ ";" ~ prj.projectImportExpressions[i];
				}
				if( !includePaths.length ) includePaths = " "; else includePaths ~= " ";
			
				all = std.string.join( prj.projectFiles, " " ) ~  " " ~ std.string.join( prj.projectResources, " " ) ~ includePaths
						~ std.string.join( prj.projectLibs, " " ) ~ prj.buildOptionDMD ~ " " ~ prj.projectExtraCompilerOption ~ exeName;
			}
		}

		line = std.string.replace(line, "$(ProjectDir)", ProjectDir);
		line = std.string.replace(line, "$(ProjectName)", ProjectName);
		line = std.string.replace(line, "$(ProjectMainFile)", mainFile);
		line = std.string.replace(line, "$(ProjectAll)", all);
	}

		/**
	 * Envirenment variable $ItemPath
	 * Get the current selected item full path, used by the env $ItemPath
	 */
	public char[] getItemPath()
	{
		char[] curname = sGUI.editor.getSelectedFileName();
		if(curname is null)
		{
			ItemInfo info = sGUI.packageExp.getSelection();
			if(info )
				curname = info.getFileName;
			else
				curname = "";				
		}
		return curname;
	}

	public void actionMarkerCmd(Event e)
	{
		StringObj o = cast(StringObj)e.widget.getData(LANG_ID);
		sGUI.editor.processMarkerCmd(o.data);
	}

	public void actionEncode(Event e)
	{
		MenuItem mi = cast(MenuItem)e.widget;
		EditItem ei = sGUI.editor.getSelectedEditItemHSU();

		if( ei !is null )
		{
			char[] text = mi.getText();
			int toBom;

			switch( text )
			{
				case "DEFAULT":
					toBom = -1;
					break;
				case "UTF8":
					toBom = -2;
					break;
				case "UTF8.BOM":
					toBom = BOM.UTF8;
					break;
				case "UTF16LE":
					toBom = BOM.UTF16LE;
					break;
				case "UTF16BE":
					toBom = BOM.UTF16BE;
					break;
				case "UTF32LE":
					toBom = BOM.UTF32LE;
					break;
				case "UTF32BE":
					toBom = BOM.UTF32BE;
					break;
				default:
					toBom = BOM.UTF8;
					break;			
			}

			int ibom = ei.scintilla.ibom;
			if( ibom == toBom ) return;

			ei.scintilla.ibom = toBom;

			int lineInfo[] = sGUI.editor.getLineInfo();
			lineInfo[3] = toBom;
			sGUI.statusBar.updateLineInfo( lineInfo );
			ei.save( true );
		}
	}

	public void actionRegister(Event e)
	{
		CRegister.unRegister( "d", "D.Document" );
		CRegister.register( "d", "D.Document", "D Programming Language File", Globals.appPath, "1" );

		CRegister.unRegister( "di", "DI.Document" );
		CRegister.register( "di", "DI.Document", "D Programming Language Interface File", Globals.appPath, "2" );
		
		CRegister.unRegister( "poseidon", "Poseidon.Document" );
		CRegister.register( "poseidon", "Poseidon.Document", "Poseidon Project File", Globals.appPath, "3" );

		CRegister.refreshIcon();
	}

	public void actionUnRegister(Event e)
	{
		CRegister.unRegister( "d", "D.Document" );
		CRegister.unRegister( "di", "DI.Document" );
		CRegister.unRegister( "poseidon", "Poseidon.Document" );

		CRegister.refreshIcon();		
	}

	public void actionEOL(Event e)
	{
		MenuItem mi = cast(MenuItem)e.widget;
		EditItem ei = sGUI.editor.getSelectedEditItemHSU();

		if( ei !is null )
		{
			char[] text = mi.getText();
			int mode = ei.scintilla.getEOLMode();

			switch( text )
			{
				case "Windows":
					if( mode == 0 )
						return;
					else
					{
						ei.scintilla.convertEOLs( 0 );
					}
					break;

				case "Unix":
					if( mode == 2 )
						return;
					else
						ei.scintilla.convertEOLs( 2 );

				case "Macintosh":
					if( mode == 1 )
						return;
					else
					{
						ei.scintilla.convertEOLs( 1 );
					}

				default:
			}
		}
	}	
	
	public void actionPreference(Event e)
	{
		Preference prf = new Preference(sShell);
		prf.open();
	}
	public void actionAboutBox(Event e)
	{
		(new AboutBox(sShell)).open();
	}

	public void actionShowPrjProperty(Event e)
	{
		sGUI.packageExp.showProjectProperty();
		//sAutoComplete.refreshFileParser( sGUI.packageExp.getActiveProjectFiles );
	}

	public void actionCloseProject(Event e){
		scope WaitCursor wc = new WaitCursor(sShell);
		sGUI.packageExp.closeProject();
		toolMan.updateToolBar();
	}

	public void actionCloseAllProject(Event e){
		scope WaitCursor wc = new WaitCursor(sShell);
		sGUI.packageExp.closeAllProject();
		toolMan.updateToolBar();
	}

	public void actionCompressProject(Event e){
		scope WaitCursor wc = new WaitCursor(sShell);
		sGUI.packageExp.compressProject();
		//toolMan.updateToolBar();
	}

	public void actionRefreshProject(Event e){
		scope WaitCursor wc = new WaitCursor(sShell);
		sGUI.packageExp.refreshProject();
	}
	
	public void actionLoadRecentProject(Event e)
	{
		MenuItem mi = cast(MenuItem)e.widget;
		char[] fullpath = (cast(StringObj)mi.getData()).data;
		
		if(Project.checkDir(fullpath))
		{
			// do project wizard here
			sGUI.packageExp.loadProject(fullpath);
			toolMan.updateToolBar();
			
		}else{
			// it seems that it is an invalid project path, remove it
			char[] msg = Globals.getTranslation("mb.invalid_prj_path");
			if(DWT.OK == MessageBox.showMessage(msg, Globals.getTranslation("QUESTION"), sShell, 
				DWT.ICON_QUESTION | DWT.OK | DWT.CANCEL)){
				Globals.removeFromRecent(fullpath);					
				menuMan.buildRecentPrjMenu();
			}
		}
	}

	void actionParseProject( char[][] files )
	{
		char[] projectName = sGUI.packageExp.getActiveProjectName();
		//foreach ( char [] f; a.data ) { str ~= "[ " ~ f ~ " ]\n"; }

		if( !sGUI.outputPanel.isDisposed() )
		{
			sGUI.outputPanel.bringToFront();
			sGUI.outputPanel.setForeColor( 0, 0, 0 );
			sGUI.outputPanel.setString( "Project[ " ~ projectName ~ " ] Parser Updating......\n" );
			sGUI.statusBar.setString( "Parsing project ... " );
			sGUI.outputPanel.setBusy( true );
		}
		
		try  
		{
			if( Globals.backLoadParser )
			{
				FileArguments a = new FileArguments(files);
				ThreadEx thread = new ThreadEx( a, &_parseProject );
				thread.start();
			}
			else
			{
				sAutoComplete.addProjectParser( files );

				foreach( char[] s ;sGUI.editor.getFileNames() )
				{
					foreach( char[] ss; files )
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
		catch( Exception e ) 
		{  
		}

		if( !Globals.backLoadParser )
		{
			if( !sGUI.outputPanel.isDisposed() )
			{
				sGUI.outputPanel.setBusy( false );
				sGUI.outputPanel.appendString( "Project[ " ~ projectName ~ " ] Parser Updated Finish.\n\n" );			
				sGUI.statusBar.setString( "" );
			}
		}
	}

	private int _parseProject( Object args )
	{
		FileArguments a = cast(FileArguments) args;
		Display display = Display.getDefault();

		void _end( Object args )
		{
			if( !sGUI.outputPanel.isDisposed() )
			{
				sGUI.outputPanel.setBusy( false );
				sGUI.outputPanel.appendString( "Project Parser Updated Finish.\n\n" );			
				sGUI.statusBar.setString( "" );

				FileArguments _a = cast(FileArguments) args;
				
				foreach( char[] s ;sGUI.editor.getFileNames() )
				{
					foreach( char[] ss; _a.data )
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
		
		try 
		{

			sAutoComplete.addProjectParser( a.data );
			display.asyncExec( args , &_end );
		}
		catch ( Exception e )
		{ 
		
		}


		return 1;
	}
}