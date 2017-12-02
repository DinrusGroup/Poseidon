module poseidon.model.project;

private import poseidon.model.misc;
private import dwt.all;
private import ak.xml.coreXML;

private import poseidon.globals;



class PrjPair
{
	char[] dir;
	char[] name;
	this(char[] dir, char[] name){
		this.dir = dir;
		this.name = name;
	}
}

class Project
{
	private import std.string, std.file, std.stream;
	private import poseidon.controller.gui;;
	private import poseidon.util.miscutil;

	int			style;
	char[] 		projectName;
	char[] 		projectDir;
	char[] 		projectOptions;
	char[][] 	fileFilter;
	char[] 		mainFile;
	char[] 		comment;

	char[][]	scINIImportPath;
	char[]		DMDPath;
	char[]  	DMCPath;
	char[]		BudExe;

	char[][]	projectFiles;
	char[][]	projectInterfaces;
	char[][]	projectResources;
	char[][]	projectOthersDMD;
	char[][]	projectOthers;
	
	char[][] 	projectIncludePaths;
	char[][] 	projectLibs;
	char[][]	projectImportExpressions;
	int			projectBuildType;
	char[]		projectExtraCompilerOption;
	char[]		projectExtraToolOption;
	char[]		projectEXEArgs;
	char[] 		projectTargetName;
	char[] 		buildOptionDMD;
	char[]		buildOptionTool;
	char[]		buildOptionLIB;
	char[]		buildOptionIMPLIB;

	int			mergeOption, nonFiles, mapFile, useImplib, useGcstub;


	boolean	showEmptyFolder = false;

	private boolean _serialized = false;
	
	const char[] EXT = ".poseidon";
	
	/**
	 * check whether the fullpath is a valid directory
	 * dir such as "d:", "d:\", "/", is not acceptable
	 */
	static boolean checkDir(char[] fullpath) 
	{
		if(!std.file.exists(fullpath) || !std.file.isdir(fullpath))
			return false;
		if(fullpath.length > 0 && fullpath[--$] == std.path.sep[0])
			fullpath = fullpath[0..--$];
		int pos = std.string.rfind(fullpath, std.path.sep);
		return pos > 0;
	}
	
	this( char[] fullpath )
	{
		projectDir = fullpath;
		int pos = std.string.rfind(fullpath, std.path.sep);
		projectName = fullpath[pos + 1..$];
		
		// the default filter
		fileFilter ~= "d";
		fileFilter ~= "di";
	}

	public ToolEntry generateCompileCmdHSU( char[] filename )
	{
		ToolEntry entry = new ToolEntry();
		entry.name = "Compile File";

		filename = getSentFileName( filename );

		if( this.DMDPath.length )
			entry.cmd = this.DMDPath ~ "\\bin\\dmd.exe";
		else
			entry.cmd = Globals.DMDPath ~ "\\bin\\dmd.exe";

		char[] includePaths, IPs;
				
		for( int i = 0; i < projectIncludePaths.length; i ++ )
		{
			if( i == 0 ) 
				includePaths = " -I" ~ projectIncludePaths[i];
			else
				includePaths = includePaths ~ ";" ~ projectIncludePaths[i];
		}

		for( int i = 0; i < projectImportExpressions.length; i ++ )
		{
			if( i == 0 ) 
				IPs = " -J" ~ projectImportExpressions[i];
			else
				IPs = IPs ~ ";" ~ projectImportExpressions[i];
		}

		entry.args = filename ~ includePaths ~ IPs ~ " -c" ~ buildOptionDMD ~ " " ~ projectExtraCompilerOption;

		entry.dir = projectDir;
		entry.hideWnd = true;
			
		return entry;
	}

	public ToolEntry generateRunCmdHSU()
	{
		ToolEntry entry = new ToolEntry();
		entry.name = "Run Project";

		char[] exeName;
		if( !projectTargetName.length )
			exeName = std.path.join( projectDir, projectName ~ ".exe" );
		else
			exeName = std.path.join( projectDir ,projectTargetName ~ ".exe" );

		if( std.file.exists( exeName ) )
		{
			entry.cmd = exeName;
			entry.dir = projectDir;
			entry.hideWnd = false;
			entry.capture = false;
			entry.args = projectEXEArgs;
			return entry;
		}else
		{
			return null;
		}
	}

		
	public ToolEntry generateBuildCmdHSU( bool bRebuild = false )
	{
		ToolEntry entry = new ToolEntry();

		entry.name = "Build Project";

		if( this.DMDPath.length )
			entry.cmd = this.DMDPath ~ "\\bin\\dmd.exe";
		else
			entry.cmd = Globals.DMDPath ~ "\\bin\\dmd.exe";
			

		char[] allFiles, includePaths, linkLibs, IPs, res;

		// No ReBuild
		if( !bRebuild )
			allFiles = getFileListDMD( false, false );
		else
			allFiles = getFileListDMD( true, false );


		for( int i = 0; i < projectLibs.length; i ++ )
			linkLibs = linkLibs ~ " " ~	projectLibs[i];

		for( int i = 0; i < projectIncludePaths.length; i ++ )
		{
			if( i == 0 ) 
				includePaths = " -I" ~ projectIncludePaths[i];
			else
				includePaths = includePaths ~ ";" ~ projectIncludePaths[i];
		}
		
		for( int i = 0; i < projectImportExpressions.length; i ++ )
		{
			if( i == 0 ) 
				IPs = " -J" ~ projectImportExpressions[i];
			else
				IPs = IPs ~ ";" ~ projectImportExpressions[i];
		}

		foreach( char[] s; projectResources ~ projectOthersDMD )
			res ~= ( " " ~ s );
			

		char[] exeName;
		if( projectTargetName == "" )
			exeName = " -of" ~ projectName;
		else
			exeName = " -of" ~ projectTargetName;

		if( projectBuildType > 0 ) 
			entry.args = " -c " ~ allFiles ~ " " ~ includePaths ~ IPs ~ buildOptionDMD ~ " " ~ projectExtraCompilerOption;
		else
			entry.args = allFiles ~ res ~ exeName ~ includePaths ~ IPs ~ linkLibs ~ buildOptionDMD ~ " " ~ projectExtraCompilerOption;

		entry.dir = projectDir;
		entry.hideWnd = true;

		//foreach( char[] j, int i; buildTarget )	buildTarget.remove( j );
			
		return entry;
	}

    public ToolEntry generateBUD()
    {
		ToolEntry entry = new ToolEntry();

        entry.name = "Build Project";

		if( this.BudExe.length )
			entry.cmd = this.BudExe;
		else
			entry.cmd = Globals.BudExe;

        char[] allFiles, objFiles, includePaths, IPs, linkLibs;//, ignoreModules;

		/*
		// Get Ignore Module name
		foreach( char[] s; projectIgnoreModules )
			ignoreModules = ignoreModules ~ " -X" ~ s;
		*/


		foreach( char[] s; projectLibs )
			linkLibs = linkLibs ~ " " ~ s;

		for( int i = 0; i < projectIncludePaths.length; i ++ )
		{
			if( i == 0 )
				includePaths = "-I" ~ projectIncludePaths[i];
			else
				includePaths = includePaths ~ ";" ~ projectIncludePaths[i];
		}

		for( int i = 0; i < projectImportExpressions.length; i ++ )
		{
			if( i == 0 ) 
				IPs = " -J" ~ projectImportExpressions[i];
			else
				IPs = IPs ~ ";" ~ projectImportExpressions[i];
		}		

		char[] exeName;
		//char[] binDMDPath = " -DCPATH" ~ Globals.DMDPath ~ "\\bin";

		char[] toolName = Globals.getTranslation( "pp3.toolname" );
		if( toolName == "bud" )
		{
			if( projectBuildType == 0 )
			{
				if( !projectTargetName.length )
					exeName = " -T" ~ projectName ~ ".exe ";
				else
					exeName = " -T" ~ projectTargetName ~ ".exe ";
			}
			else if( projectBuildType == 1 )
			{
				if( !projectTargetName.length )
					exeName = " -T" ~ projectName ~ ".lib ";
				else
					exeName = " -T" ~ projectTargetName ~ ".lib ";

				if( std.string.find( buildOptionTool, " -lib " ) < 0 ) exeName ~= " -lib";
			}
			else
			{
				if( !projectTargetName.length )
					exeName = " -T" ~ projectName ~ ".dll ";
				else
					exeName = " -T" ~ projectTargetName ~ ".dll ";

				if( std.string.find( buildOptionTool, " -dll " ) < 0 ) exeName ~= " -dll";
			}

			if( std.string.find( buildOptionTool, " -DCPATH" ) < 0 ) exeName ~=  ( "-DCPATH" ~ Globals.DMDPath ~ "\\bin" );
		}

		char[] options;
		if( mergeOption ) options = buildOptionDMD ~ buildOptionTool;else options = buildOptionTool;

		if( !options.length )
			options = projectExtraToolOption.length ? " " ~ projectExtraToolOption ~ " " : " ";
		else
			options ~= ( projectExtraToolOption.length ? projectExtraToolOption ~ " " : "" );

		if( std.string.find( options, " -gui " ) > -1 ) options = std.string.replace( options, " -L/SUBSYSTEM:windows:4", "" );	

		entry.args = ( nonFiles ? "" : mainFile ) ~ exeName ~ options ~ includePaths ~ IPs ~ linkLibs;

		entry.dir = projectDir;
		entry.hideWnd = true;

		return entry;
	}


	public ToolEntry generateMakeLibCmdHSU()
	{
		ToolEntry entry = new ToolEntry();

		entry.name = "Build Project";

		if( this.DMDPath.length )
			entry.cmd = this.DMCPath ~ "\\bin\\lib.exe";
		else
			entry.cmd = Globals.DMCPath ~ "\\bin\\lib.exe";
			
		char[] allFiles = getFileListDMD( false, true );
		char[] linkLibs;

		foreach( char[] s; projectLibs )
			linkLibs = linkLibs ~ " " ~	s;
			
		char[] libName;
		if( !projectTargetName.length )
			libName = projectName ~ ".lib";
		else
			libName = projectTargetName ~ ".lib";		

		entry.args = "-c " ~ buildOptionLIB ~ libName ~ allFiles ~ linkLibs;

		entry.dir = projectDir;
		entry.hideWnd = true;
			
		return entry;
	}

	public ToolEntry generateMakeDllCmdHSU()
	{
		ToolEntry entry = new ToolEntry();

		entry.name = "Build Project";

		if( this.DMDPath.length )
			entry.cmd = this.DMDPath ~ "\\bin\\dmd.exe";
		else
			entry.cmd = Globals.DMDPath ~ "\\bin\\dmd.exe";
			
		char[] allFiles = getFileListDMD( false, true );
		char[] linkLibs, res;

		foreach( char[] s; projectLibs )
			linkLibs = linkLibs ~ " " ~	s;

		char[] dllName;
		if( projectTargetName == "" )
			dllName = " -of" ~ projectName;
		else
			dllName = " -of" ~ projectTargetName;

		if( useGcstub )	dllName ~= " gcstub.obj";
		if( mapFile ) dllName ~= " -L/map";

		
		foreach( char[] s; projectResources ~ projectOthersDMD )
			res ~= ( " " ~ s );
			

		entry.args = allFiles ~ res ~ dllName ~ linkLibs ~ " " ~ buildOptionDMD ~ " " ~ projectExtraCompilerOption;

		entry.dir = projectDir;
		entry.hideWnd = true;
			
		return entry;
	}

	public ToolEntry generateImplib()
	{
		ToolEntry entry = new ToolEntry();

		entry.name = "Implib from DLL";

		if( this.DMDPath.length )
			entry.cmd = this.DMDPath ~ "\\bin\\implib.exe";
		else
			entry.cmd = Globals.DMDPath ~ "\\bin\\implib.exe";

		if( !std.file.exists( entry.cmd ) )
		{
			if( this.DMCPath.length )
				entry.cmd = this.DMCPath ~ "\\bin\\implib.exe";
			else
				entry.cmd = Globals.DMCPath ~ "\\bin\\implib.exe";	
		}
	
		char[] dllName;
		if( projectTargetName == "" )
			dllName = projectName ~ ".lib " ~ projectName ~ ".dll";
		else
			dllName = projectTargetName ~ ".lib " ~ projectTargetName ~ ".dll";


		entry.args = buildOptionIMPLIB ~ dllName;

		entry.dir = projectDir;
		entry.hideWnd = true;
			
		return entry;
	}		

	public static char[] getBracketText( char[] text )
	{
		int 	indexOpenbracket	= std.string.rfind( text, "[" ) + 1;
		int 	indexClosebracket 	= std.string.rfind( text, "]" );

		if( indexClosebracket > indexOpenbracket ) return text[indexOpenbracket..indexClosebracket];

		return null;
	}


	public void setFileFilter(char[] filter) {
		fileFilter = poseidon.util.miscutil.MiscUtil.getSplitFilter( filter );
		/*
		fileFilter = null;
		char[][] temp = std.string.split(filter, ";");
		boolean all = false;
		for(int i=0; i<temp.length; ++i) 
		{
			temp[i] = std.string.strip(temp[i]);
			if(temp[i].length > 2 && temp[i][0..2] == "*.")
			{
				char[] ext = temp[i][2..$];
				if(ext == "*"){
					all = true;
					break;
				}else{
					fileFilter ~= ext;
				}
			}
		}
		if(all)
		{
			fileFilter.length = 1;
			fileFilter[0] = "*";
		}
		*/
	}
	
	public boolean isFiltered( char[] ext )
	{
		if( fileFilter is null ) return false;

		if( fileFilter[0] == "*" ) return false;

		foreach( char[] filter; fileFilter )
		{
			if( std.string.icmp( filter, ext ) == 0 ) return false;
		}
		return true;
	}
	
	public char[] getFilter() {
		return poseidon.util.miscutil.MiscUtil.getFilter( fileFilter );
		/*
		char[] result;
		foreach(char[] filter; fileFilter) {
			result ~= "*." ~ filter ~ ";";
		}
		if(result.length) {
			result = result[0..--$]; //remove the last ;
		}else{
			result = "*.*";
		}
		return result;
		*/
	}
	
	/**
	 * static method to load project from a dir, with or without a config file
	 */
	static public Project loadProject( char[] dir )
	{
		if(!checkDir(dir))
			return null;
		
		Project prj = new Project(dir);
		char[] file = std.path.join(dir, Project.EXT);
		if(std.file.exists(file)){
			XML xml = new XML();
			if(xml.Open(file)){
				XMLnode root = xml.m_root.getChildEx("projectDescription", null);
				XMLnode child = root.getChild("style");
				if(child)
					prj.style = std.string.atoi(child.getValue() );

				child = root.getChild("name");
				if(child)	
					prj.projectName = child.getValue();

				child = root.getChild( "targetName");
				if(child)	
					prj.projectTargetName = child.getValue();
					
				child = root.getChild("comment");
				if(child)	
					prj.comment = child.getValue();
				child = root.getChild("filter");
				if(child)
					prj.setFileFilter(child.getValue());
				child = root.getChild("showemptyfolder");
				if(child)
					prj.showEmptyFolder = (std.string.atoi(child.getValue()) > 0);

				child = root.getChild("buildSpec");
				if(child) {
					XMLnode mf = child.getChild("mainFile");
					if(mf)
						prj.mainFile = mf.getValue();

					XMLnode ar = child.getChild("Args");
					if(ar)
						prj.projectEXEArgs = ar.getValue();
						
					XMLnode bo = child.getChild("buildType");
					if( bo )
						prj.projectBuildType = std.string.atoi( bo.getValue() );

					XMLnode tempNode;
					XMLnode op = child.getChild( "options" );
					if( op )
					{
						tempNode = op.getChild( "dmd" );
						if( tempNode ) prj.buildOptionDMD = tempNode.getValue();
						tempNode = op.getChild( "tool" );
						if( tempNode ) prj.buildOptionTool = tempNode.getValue();
						tempNode = op.getChild( "lib" );
						if( tempNode ) prj.buildOptionLIB = tempNode.getValue();
						tempNode = op.getChild( "implib" );
						if( tempNode ) prj.buildOptionIMPLIB = tempNode.getValue();
						tempNode = op.getChild( "extra" );
						if( tempNode ) prj.projectExtraCompilerOption = tempNode.getValue();
						tempNode = op.getChild( "toolextra" );
						if( tempNode ) prj.projectExtraToolOption = tempNode.getValue();
						tempNode = op.getChild( "merge" );
						if( tempNode ) prj.mergeOption = std.string.atoi( tempNode.getValue() );
						tempNode = op.getChild( "nonfiles" );
						if( tempNode ) prj.nonFiles = std.string.atoi( tempNode.getValue() );
						tempNode = op.getChild( "useimplib" );
						if( tempNode ) prj.useImplib = std.string.atoi( tempNode.getValue() );
						tempNode = op.getChild( "mapfile" );
						if( tempNode ) prj.mapFile = std.string.atoi( tempNode.getValue() );
						tempNode = op.getChild( "gcstub" );
						if( tempNode ) prj.useGcstub = std.string.atoi( tempNode.getValue() );
					}

					XMLnode dmd = child.getChild( "dmdpath" );
					if( dmd ) prj.DMDPath = dmd.getValue();
					XMLnode dmc = child.getChild( "dmcpath" );
					if( dmc ) prj.DMCPath = dmc.getValue();
					XMLnode bud = child.getChild( "buildtoolexe" );
					if( bud ) prj.BudExe = bud.getValue();


					if( prj.style == 1 )
					{
						prj.projectFiles = sGUI.packageExp.getAllFilesInProjectDir( prj.projectDir, ["*.d"] );
						prj.projectInterfaces = sGUI.packageExp.getAllFilesInProjectDir( prj.projectDir, ["*.di"] );
						prj.projectResources = sGUI.packageExp.getAllFilesInProjectDir( prj.projectDir, ["*.res"] );
					}
					else
					{
						// Load all file names of project
						XMLnode mfiles = child.getChild( "projectFiles" );
						if( mfiles )
						{
							XMLnode sourceNode = mfiles.getChild( "source" );
								if( sourceNode )
								{
									prj.projectFiles.length = sourceNode.getChildCount();
									for( int i = 0; i < prj.projectFiles.length; i ++ )
									{
										tempNode = sourceNode.getChild( i );
										prj.projectFiles[i] = tempNode.getValue();
										if( !std.path.isabs( prj.projectFiles[i] ) ) prj.projectFiles[i] = std.path.join( prj.projectDir, prj.projectFiles[i] );
									}
								}

							XMLnode interfaceNode = mfiles.getChild( "interface" );
								if( interfaceNode )
								{
									prj.projectInterfaces.length = interfaceNode.getChildCount();
									for( int i = 0; i < prj.projectInterfaces.length; i ++ )
									{
										tempNode = interfaceNode.getChild( i );
										prj.projectInterfaces[i] = tempNode.getValue();
										if( !std.path.isabs( prj.projectInterfaces[i] ) ) prj.projectInterfaces[i] = std.path.join( prj.projectDir, prj.projectInterfaces[i] );
									}
								}

							XMLnode resourceNode = mfiles.getChild( "resource" );
								if( resourceNode )
								{
									prj.projectResources.length = resourceNode.getChildCount();
									for( int i = 0; i < prj.projectResources.length; i ++ )
									{
										tempNode = resourceNode.getChild( i );
										prj.projectResources[i] = tempNode.getValue();
										if( !std.path.isabs( prj.projectResources[i] ) ) prj.projectResources[i] = std.path.join( prj.projectDir, prj.projectResources[i] );
									}
								}

							XMLnode othersDMDNode = mfiles.getChild( "othersDMD" );
								if( othersDMDNode )
								{
									prj.projectOthersDMD.length = othersDMDNode.getChildCount();
									for( int i = 0; i < prj.projectOthersDMD.length; i ++ )
									{
										tempNode = othersDMDNode.getChild( i );
										prj.projectOthersDMD[i] = tempNode.getValue();
										if( !std.path.isabs( prj.projectOthersDMD[i] ) ) prj.projectOthersDMD[i] = std.path.join( prj.projectDir, prj.projectOthersDMD[i] );
									}
								}								

							XMLnode othersNode = mfiles.getChild( "others" );
								if( othersNode )
								{
									prj.projectOthers.length = othersNode.getChildCount();
									for( int i = 0; i < prj.projectOthers.length; i ++ )
									{
										tempNode = othersNode.getChild( i );
										prj.projectOthers[i] = tempNode.getValue();
										if( !std.path.isabs( prj.projectOthers[i] ) ) prj.projectOthers[i] = std.path.join( prj.projectDir, prj.projectOthers[i] );
									}
								}							
						}
					}
					
					// Load all include path of project
					XMLnode iPaths = child.getChild("includePaths");
					if( iPaths )
					{
						prj.projectIncludePaths.length = iPaths.getChildCount();
						
						for( int i = 0; i < prj.projectIncludePaths.length; ++ i )
						{
							tempNode = iPaths.getChild( i );
							prj.projectIncludePaths[i] = tempNode.getValue();
						}
					}

					// Load all Libs of project
					XMLnode xLibs = child.getChild("linkLibrarys");
					if( xLibs )
					{
						prj.projectLibs.length = xLibs.getChildCount();

						for( int i = 0; i < prj.projectLibs.length; ++ i )
						{
							tempNode = xLibs.getChild( i );
							prj.projectLibs[i] = tempNode.getValue();
						}
					}

					// Load ImportExpression of project
					XMLnode IPs = child.getChild( "importExpressions" );
					if( IPs )
					{
						prj.projectImportExpressions.length = IPs.getChildCount();

						for( int i = 0; i < prj.projectImportExpressions.length; ++ i )
						{
							tempNode = IPs.getChild( i );
							prj.projectImportExpressions[i] = tempNode.getValue();
						}
					}

					/*
                    // Load all ignore modules of project
					XMLnode xMods = child.getChild("ignoreModules");
					if( xMods )
					{
						prj.projectIgnoreModules.length = xMods.getChildCount();

						for( int i = 0; i < prj.projectIgnoreModules.length; ++ i )
						{
							tempNode = xMods.getChild( i );
							prj.projectIgnoreModules[i] = tempNode.getValue();
						}
					}
					*/
				}
				// load sucessfully, set the flag
				prj._serialized = true;
			}
			delete xml; // auto close

			prj.loadSCINIImportModules();
		}

		return prj;
	
	}
	
	public void save()
	{
		XML xml = new XML();
		xml.m_attributes ~= new XMLattrib("version", "1.0");
		xml.m_attributes ~= new XMLattrib("encoding", "UTF-8");
		
		XMLnode root = xml.m_root.addNode("projectDescription", null);

		root.addNode( "style", std.string.toString( style ) );
		root.addNode("name", projectName);
		root.addNode( "targetName", projectTargetName );
		root.addNode("comment", comment);
		root.addNode("filter", getFilter());
		root.addNode("showemptyfolder", std.string.toString(showEmptyFolder));
	
		XMLnode buildSpec = root.addNode("buildSpec", null);
		buildSpec.addNode("buildType", std.string.toString( projectBuildType ) );
		buildSpec.addNode("mainFile", mainFile);
		buildSpec.addNode("Args", projectEXEArgs );
		//buildSpec.addNode("objPathName", projectObjDir );

		XMLnode op = buildSpec.addNode( "options", null );
			op.addNode( "dmd", buildOptionDMD );
			op.addNode( "tool", buildOptionTool );
			op.addNode( "lib", buildOptionLIB );
			op.addNode( "implib", buildOptionIMPLIB );
			op.addNode( "extra", projectExtraCompilerOption );
			op.addNode( "toolextra", projectExtraToolOption );
			op.addNode( "merge", std.string.toString( mergeOption ) );
			op.addNode( "nonfiles", std.string.toString( nonFiles ) );
			op.addNode( "useimplib", std.string.toString( useImplib ) );
			op.addNode( "mapfile", std.string.toString( mapFile ) );
			op.addNode( "gcstub", std.string.toString( useGcstub ) );

		buildSpec.addNode("dmdpath", DMDPath );
		buildSpec.addNode("dmcpath", DMCPath );
		buildSpec.addNode("buildtoolexe", BudExe );

		XMLnode pF = buildSpec.addNode( "projectFiles", null );
			XMLnode pSource = pF.addNode( "source", null );
			foreach( char[] s; projectFiles )
			{
				s = std.string.replace( s, projectDir ~ "\\", "" );
				pSource.addNode( "name", s );
			}

			XMLnode pInterface = pF.addNode( "interface", null );
			foreach( char[] s; projectInterfaces )
			{
				s = std.string.replace( s, projectDir ~ "\\", "" );
				pInterface.addNode( "name", s );
			}

			XMLnode pResource = pF.addNode( "resource", null );
			foreach( char[] s; projectResources )
			{
				s = std.string.replace( s, projectDir ~ "\\", "" );
				pResource.addNode( "name", s );
			}

			XMLnode pOthersDMD = pF.addNode( "othersDMD", null );
			foreach( char[] s; projectOthersDMD )
			{
				s = std.string.replace( s, projectDir ~ "\\", "" );
				pOthersDMD.addNode( "name", s );
			}
			
			XMLnode pOthers = pF.addNode( "others", null );
			foreach( char[] s; projectOthers )
			{
				s = std.string.replace( s, projectDir ~ "\\", "" );
				pOthers.addNode( "name", s );
			}

		XMLnode pI = buildSpec.addNode( "includePaths", null );
		foreach( char[] s; projectIncludePaths )
			pI.addNode( "name", s );

		XMLnode lL = buildSpec.addNode( "linkLibrarys", null );
		foreach( char[] s; projectLibs )
			lL.addNode( "name", s );

		XMLnode IL = buildSpec.addNode( "importExpressions", null );
		foreach( char[] s; projectImportExpressions )
			IL.addNode( "name", s );

		/*
		XMLnode iM = buildSpec.addNode( "ignoreModules", null );
		foreach( char[] s;projectIgnoreModules )
			iM.addNode( "name", s );
		*/

		try{
			xml.Save(std.path.join(projectDir, EXT));
			// save sucessfully, set the flag
			this._serialized = true;				
			delete xml; // auto close
		}catch(Exception e){
			MessageBox.showMessage(e.toString());
		}
	}

	public boolean serialized() { return _serialized; }

	public char[][] getVersionCondition()
	{
		char[][] result, splitVersionText = std.string.split( projectExtraCompilerOption, "-version" );

		void _setResult( char[][] splitedText )
		{
			for( int i = 1; i < splitedText.length; ++ i )
			{
				if( splitedText[i].length )
				{
					if( splitedText[i][0] == '=' )
					{
						int spacePos = std.string.find( splitedText[i], " " );
						if( spacePos < 0 ) result ~= splitedText[i][1..length]; else result ~= splitedText[i][1..spacePos];
					}
				}
			}
		}

		_setResult( splitVersionText );

		if( !result.length )
		{
			splitVersionText = std.string.split( projectExtraToolOption, "-version" );
			_setResult( splitVersionText );
		}

		version( Windows )
		{ 
			result ~= "Windows";
			result ~= "Win32";
		}		

		return result;
	}

	public char[][] getDebugCondition()
	{
		char[][] result, splitDebugText = std.string.split( projectExtraCompilerOption, "-debug" );

		bool bHasDebugOption, bHasDebugToolOption;
		
		if( std.string.find( buildOptionDMD, " -debug " ) > -1 ) bHasDebugOption = true;
		if( std.string.find( buildOptionTool, " -debug " ) > -1 ) bHasDebugToolOption = true;

		void _setResult( char[][] splitedText )
		{
			for( int i = 1; i < splitedText.length; ++ i )
			{
				if( splitedText[i].length )
				{
					if( splitedText[i][0] == '=' )
					{
						int spacePos = std.string.find( splitedText[i], " " );
						if( spacePos < 0 ) result ~= splitedText[i][1..length]; else result ~= splitedText[i][1..spacePos];
					}
					else if( splitedText[i][0] == ' ' )
					{
						result ~= "-anonymous-";
					}
				}
				else
					result ~= "-anonymous-"; // -debug at last
			}
		}

		_setResult( splitDebugText );
		char[] anonymous = "-anonymous-";
		if( !MiscUtil.inArray( anonymous, result ) )
			if( bHasDebugOption ) result ~= "-anonymous-";
		

		if( !result.length )
		{
			splitDebugText = std.string.split( projectExtraToolOption, "-debug" );
			_setResult( splitDebugText );

			if( !MiscUtil.inArray( anonymous, result ) )
				if( bHasDebugToolOption ) result ~= "-anonymous-";
		}

		

		return result;
	}

	public bool getDeprecated()
	{
		if( std.string.find( buildOptionDMD, "-d " ) > -1 ) return true;
		if( std.string.find( projectExtraCompilerOption, "-d " ) > -1 ) return true;
		if( std.string.find( buildOptionTool, "-d " ) > -1 ) return true;
		if( std.string.find( projectExtraToolOption, "-d " ) > -1 ) return true;

		return false;
	}

	private char[] getSentFileName( char[] fileName )
	{
		if( !Globals.sendAbsoluteFullpath )
		{
			if( std.path.isabs( fileName ) ) fileName = std.string.replace( fileName, projectDir ~ "\\", "" );
		}
		else
		{
			if( !std.path.isabs( fileName ) ) fileName = std.path.join( projectDir, fileName );
		}

		return fileName;
	}
	

	private char[] getFileListDMD( bool bReBuild, bool bMakeLib )
	{
		char[] 	result;
		int 	changeCount;
		char[] 	objDir = getObjDir();

		foreach( char[] f; projectFiles )
		{
			if( bMakeLib ) 
			{
				f = getSentFileName( f );
				
				char[] objFileName = std.path.getBaseName( std.path.getName( f ) ) ~ ".obj";
		
				if( objDir.length )
				{
					if( objDir == "-op" )
						result ~= ( " " ~ std.path.getName( f ) ~ ".obj" );
					else
						result ~= ( " " ~ objDir ~ "\\" ~ objFileName );
				}
				else // no -odxx and no -op
				{
					if( Globals.sendAbsoluteFullpath )
						result ~= ( " " ~ projectDir ~ "\\" ~ objFileName );
					else
						result ~= ( " " ~ objFileName );
						
				}
			}
			else
			{
				if( !bReBuild )
					result ~= ( " " ~ getSentFileName( getCompileTargetFileHSU( f ) ) );
				else
					result ~= ( " " ~ getSentFileName( f ) );
			}
		}

		return result;
	}
	
	private char[] getCompileTargetFileHSU( char[] filename )
	{
		char[] objFile, objDir = getObjDir();

		objFile = std.path.getBaseName( std.path.getName( filename ) );
		
		if( objDir.length )
		{
			if( objDir == "-op" )
				objFile = std.path.getName( filename ) ~ ".obj";
			else
				objFile = objDir ~ "\\" ~ objFile ~ ".obj";
		}
		else
			objFile = projectDir ~ "\\" ~ objFile ~ ".obj";

		if( !std.file.exists( objFile ) ) return filename;

		long creationTimeD, lastAccessTimeD, lastWriteTimeD;
		long creationTimeOBJ, lastAccessTimeOBJ, lastWriteTimeOBJ;

		std.file.getTimes( filename, creationTimeD, lastAccessTimeD, lastWriteTimeD );
		std.file.getTimes( objFile, creationTimeOBJ, lastAccessTimeOBJ, lastWriteTimeOBJ );

		if( lastWriteTimeD >= lastWriteTimeOBJ )
			return filename;
		else
			return objFile;
	}

	private char[] getObjDir()
	{
		// -op is greater than -odxxx
		char[] objDir;

		char[] checkOption = buildOptionDMD ~ projectExtraCompilerOption ~ " ";

		if( std.string.find( checkOption, "-op" ) < 0 ) // no include -op
		{
			int index = std.string.find( checkOption, "-od" );
			if( index > -1 )
			{
				int indexSpace = std.string.find( checkOption[index+3..length], " " );
				if( indexSpace > -1 ) objDir = checkOption[index+3..index+3+indexSpace];
			}
		}
		else
		{
			objDir = "-op"; // include -op
		}

		return objDir;
	}

	private void loadSCINIImportModules()
	{
		try
		{
			char[] myDMDPath;
			if( DMDPath.length ) myDMDPath = DMDPath; else myDMDPath = Globals.DMDPath;

			char[] ini = myDMDPath ~ "\\bin\\sc.ini";
			
			if( std.file.isfile( ini ) )
			{
				scope file = new File( ini, FileMode.In );
				while( !file.eof() )
				{
					char[] lineData = std.string.strip( file.readLine() );
					if( lineData.length > 5 )
					{
						if( lineData[0..6] == "DFLAGS" )
						{
							lineData = std.string.replace( lineData, "%@P%", myDMDPath ~ "\\bin" );
							
							int equalIndex = std.string.find( lineData, "=" );
							if( equalIndex >= 0 ) lineData = lineData[equalIndex+1..length];

							foreach( char[] s; std.string.split( lineData ) )
							{
								int Iindex = std.string.find( s, "-I" );
								if( Iindex > -1 )
								{
									s = s[Iindex+2..length];
									foreach( char[] ss; std.string.split( s, ";" ) )
									{
										if( ss.length )	scINIImportPath ~= std.string.removechars( ss, "\"" );
									}
								}
							}
						}
					}
				}

				file.close();
			}
		}
		catch
		{
			MessageBox.showMessage( "Load sc.ini Error!" );
		}
	}	
}