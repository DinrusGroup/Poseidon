module poseidon.globals;
 

private import dwt.all;
private import poseidon.controller.gui;
private import poseidon.model.misc;
private import poseidon.model.project;
private import poseidon.i18n.translation;
private import ak.xml.coreXML;
private import poseidon.controller.editor;
private import poseidon.model.editorsettings;


const char[] LANG_ID = "language-id";

class Globals : Object
{
	private import std.path;
	private import std.file;
	private import poseidon.util.miscutil;
	private import CodeAnalyzer.syntax.nodeHsu;
	
	static public boolean showSplash = true;
	static public boolean loadWorkSpaceAtStart = true;
	static public boolean isShellMaximized = true;
	static public Rectangle shellBounds = null;

	static public char[][]	fileArgs;

	static public char[]  	DMDPath;
	static public char[]  	DMCPath;
	static public char[]	BudExe;
	static public char[]	DebuggerExe;
	static public char[]	RCExe;
	static public char[][]	DDcoumentDir;
	static public int		backBuild = 1;
	static public int	  	outputWRAP = 64;

	static public int[]		ExplorerWeight;
	static public int[] 	BottomPanelWeight;
	static public int[] 	BottomPanelLastWeight;
	static public char[][]	SplitedExplorerFilter;

	static public char[][]	debuggerSearchPath;
	static public int		sendAbsoluteFullpath = 1;

	static public int		parserDMDversion = 1;
	static public int 		useCodeCompletion = 1;
	static public int		parseImported;
	static public int		parseAllModule = 1;
	static public int		updateParseLive = 1;
	static public int		updateParseLiveFull = 0;
	static public int		showAllMember;
	static public int		showType;
	static public int 		jumpTop;
	static public int		useDefaultParser;
	static public int		parserCaseSensitive;
	static public int		lanchLetterCount = 3;
	static public int		showOnlyClassBrowser;
	static public int		showAutomatically = 1;
	static public char[][] 	defaultParserPaths;
	static public int		backLoadParser = 1;
	static public int		edDebug;
	static public int		elDebug;

	static public bool		bOutputStop;
	
	static private Image[char[]] images;

	static public char[] appPath;
	static public char[] appDir;
	static public char[] imageDir;
	static public char[] recentDir;
	static public char[] i18nDir;
	static public char[] lexerDir;	// Syntax lexer file dir

	// MRU involved
	public static PrjPair[] recentPrjs = null;
	const int MAX_RECENT_PRJ = 8;

	// i18n involved 
	private static Translation i18n;
	public static char[][char[]] languages = null;	// filename[language_name]
	public static char[] curLang;	// current language name

	
	public static ToolEntry[]	toolEntries;
	public static _ShortCut[]	hotkeys;


	public static void prepareDir()
	{
		appPath = Util.getExePathName(0, false);
		appDir = std.path.getDirName(appPath);
		imageDir = std.path.join(appDir, "images");
		i18nDir = std.path.join(appDir, "nls");
		lexerDir = std.path.join(appDir, "lexer");
		checkDir(imageDir);
		checkDir(i18nDir);
		checkDir(lexerDir);
	}

	/**
	 * check whether the dir exists or not, create it if not exists
	 */
	public static void checkDir(char[] dir)
	{
		if(!std.file.exists(dir))
			std.file.mkdir(dir);
	}

	public static char[] getVersionS() { return "0.221"; }
	public static float  getVersion() { return 0.221f; }
	
	public static void initIcons(Shell shell)
	{
		// make sure display has been created, and register shell as resource user
		assert(shell);
		DWTResourceManager.registerResourceUser(shell);
		std.file.chdir(imageDir);
		
		images["build"]		 	= DWTResourceManager.getImage("build.gif");
		images["build_dis"]	 	= DWTResourceManager.getImage("build_dis.gif");
		images["clear"]		 	= DWTResourceManager.getImage("clear.gif");
		images["clear_dis"]		= DWTResourceManager.getImage("clear_dis.gif");
		images["close_view"] 	= DWTResourceManager.getImage("close_view.gif");
		images["collapseall"]	= DWTResourceManager.getImage("collapseall.gif");
		images["console_view"]	= DWTResourceManager.getImage("console_view.gif");
		images["d"] 			= DWTResourceManager.getImage("d.gif");
		images["di"] 			= DWTResourceManager.getImage("di.gif");
		images["project_file"]	= DWTResourceManager.getImage("project_file.gif");
		images["res"] 			= DWTResourceManager.getImage("res.gif");
		images["d-icon"] 		= DWTResourceManager.getImage("d-icon.gif");
		images["e_back"] 		= DWTResourceManager.getImage("e_back.gif");
		images["e_forward"] 	= DWTResourceManager.getImage("e_forward.gif");
		images["e_back_dis"] 	= DWTResourceManager.getImage("e_back_dis.gif");
		images["e_forward_dis"] = DWTResourceManager.getImage("e_forward_dis.gif");
		images["e_search_results_view"]	= DWTResourceManager.getImage("e_search_results_view.gif");
		images["external_tools"]= DWTResourceManager.getImage("external_tools.gif");
		images["file_obj"] 		= DWTResourceManager.getImage("file_obj.gif");
		images["file_addcompiler_obj"] = DWTResourceManager.getImage("file_addcompiler_obj.gif");
		images["mark_clear"] 	= DWTResourceManager.getImage("mark_clear.gif");
		images["mark_clear_dis"]= DWTResourceManager.getImage("mark_clear_dis.gif");
		images["mark_next"] 	= DWTResourceManager.getImage("mark_next.gif");
		images["mark_next_dis"] = DWTResourceManager.getImage("mark_next_dis.gif");
		images["mark_prev"] 	= DWTResourceManager.getImage("mark_prev.gif");
		images["mark_prev_dis"] = DWTResourceManager.getImage("mark_prev_dis.gif");
		images["mark_toggle"] 	= DWTResourceManager.getImage("mark_toggle.gif");
		images["mark_toggle_dis"]	= DWTResourceManager.getImage("mark_toggle_dis.gif");
		images["module_obj"] 	= DWTResourceManager.getImage("module_obj.gif");
		images["newprj_wiz"] 	= DWTResourceManager.getImage("newprj_wiz.gif");
		images["outline_co"] 	= DWTResourceManager.getImage("outline_co.gif");
		images["package"] 		= DWTResourceManager.getImage("package.gif");
		images["progress_rem"] 	= DWTResourceManager.getImage("progress_rem.gif");	// delete_obj_dis
		images["progress_stop"]	= DWTResourceManager.getImage("progress_stop.gif");
		images["progress_stop_dis"]	= DWTResourceManager.getImage("progress_stop_dis.gif");
		images["prop_ps"]	 	= DWTResourceManager.getImage("prop_ps.gif");
		images["project_obj"] 	= DWTResourceManager.getImage("project_obj.gif");
		images["redo"] 			= DWTResourceManager.getImage("redo.gif");
		images["sample"]		= DWTResourceManager.getImage("sample.gif");
		images["save"] 			= DWTResourceManager.getImage("save.gif");
		images["save_all"] 		= DWTResourceManager.getImage("save_all.gif");
		images["save_all_dis"] 		= DWTResourceManager.getImage("save_all_dis.gif");
		images["save_as"] 		= DWTResourceManager.getImage("saveas.gif");
		images["save_dis"]		= DWTResourceManager.getImage("save_dis.gif");
		images["shift_l_edit"] 	= DWTResourceManager.getImage("shift_l_edit.gif");

		images["fldr"]			= DWTResourceManager.getImage("fldr_obj.gif");

		images["show_params"] 	= DWTResourceManager.getImage("show_params.gif");
		images["show_rettype"] 	= DWTResourceManager.getImage("show_rettype.gif");
		images["show_none"] 	= DWTResourceManager.getImage("show_nopr.gif");
		images["show_all"] 		= DWTResourceManager.getImage("show_pr.gif");
		
		images["sort"] 			= DWTResourceManager.getImage("sort.gif");		
		images["synced"]		= DWTResourceManager.getImage("synced.gif");
		images["xml"]	 		= DWTResourceManager.getImage("xml.gif");
		images["undo"]	 		= DWTResourceManager.getImage("undo.gif");
		images["uninstall_wiz"]	= DWTResourceManager.getImage("uninstall_wiz.gif");
		images["uninstall_wiz_dis"]	= DWTResourceManager.getImage("uninstall_wiz_dis.gif");
		images["unknown"]		= DWTResourceManager.getImage("unknown_obj.gif");

		images["refresh"]		= DWTResourceManager.getImage("nav_refresh.gif");
		images["refresh_dis"]	= DWTResourceManager.getImage("nav_refresh_dis.gif");
		images["link"]			= DWTResourceManager.getImage("link_obj.gif");


		images["zip"]			= DWTResourceManager.getImage("zip.gif");
		images["importfile"]	= DWTResourceManager.getImage("importfile_obj.gif");

		images["find"]			= DWTResourceManager.getImage("find_replace.gif");
		images["search"]		= DWTResourceManager.getImage("find_replace_files.gif");
		images["goto"]			= DWTResourceManager.getImage("goto.gif");

		images["gmail"]			= DWTResourceManager.getImage("GMAIL", "GIFFILE");

		images["undo_dis"]	 	= DWTResourceManager.getImage("undo_dis.gif");
		images["redo_dis"]	 	= DWTResourceManager.getImage("redo_dis.gif");
			
		images["cut"]	 		= DWTResourceManager.getImage("cut.gif");
		images["cut_dis"]		= DWTResourceManager.getImage("cut_dis.gif");			
		images["copy"]	 		= DWTResourceManager.getImage("copy.gif");
		images["copy_dis"]		= DWTResourceManager.getImage("copy_dis.gif");			
		images["paste"]	 		= DWTResourceManager.getImage("paste.gif");
		images["paste_dis"]	 	= DWTResourceManager.getImage("paste_dis.gif");

		images["compile"]	 	= DWTResourceManager.getImage("compile.gif");
		images["compile_dis"]	= DWTResourceManager.getImage("compile_dis.gif");
		images["run"]	 		= DWTResourceManager.getImage("run.gif");
		images["run_dis"]	 	= DWTResourceManager.getImage("run_dis.gif");
		images["build_run"]		= DWTResourceManager.getImage("build_run.gif");
		images["build_run_dis"]	= DWTResourceManager.getImage("build_run_dis.gif");
		images["rebuild"] 		= DWTResourceManager.getImage("rebuild.gif");
		images["rebuild_dis"] 	= DWTResourceManager.getImage("rebuild_dis.gif");
		images["Bud"] 			= DWTResourceManager.getImage("Bud.gif");
		images["Bud_dis"] 		= DWTResourceManager.getImage("Bud_dis.gif");

		images["information"] 	= DWTResourceManager.getImage("information.gif");
		images["help_link"] 	= DWTResourceManager.getImage("linkto_help.gif");
		images["help_view"] 	= DWTResourceManager.getImage("help_view.gif");

		images["class_hi"]	 	= DWTResourceManager.getImage("class_hi.gif");
		images["add_obj"]	 	= DWTResourceManager.getImage("add_obj.gif");
		images["write_obj"]	 	= DWTResourceManager.getImage("write_obj.gif");
		images["prev_nav"]	 	= DWTResourceManager.getImage("prev_nav.gif");
		images["next_nav"]	 	= DWTResourceManager.getImage("next_nav.gif");
		images["delete_obj"] 	= DWTResourceManager.getImage("delete_obj.gif");
		images["delete_obj_dis"]= DWTResourceManager.getImage("delete_obj_dis.gif");


		images["property"]		= DWTResourceManager.getImage("property_obj.gif");

		images["newfile"]		= DWTResourceManager.getImage("newfile.gif");
		images["openfile"]		= DWTResourceManager.getImage("fldr_obj.gif");
		images["max_view"]	 	= DWTResourceManager.getImage("max_view.gif");
		images["min_view"] 		= DWTResourceManager.getImage("min_view.gif");

		images["repository"]	= DWTResourceManager.getImage("repository_rep.gif");

		// DEBUG
		images["debug_exc"]			= DWTResourceManager.getImage("debug/debug_exc.gif");
		images["debug_run"]			= DWTResourceManager.getImage("debug/rundebug.gif");
		images["debug_build"]			= DWTResourceManager.getImage("debug/debug_build.gif");

		images["debug_resume"]		= DWTResourceManager.getImage("debug/resume_co.gif");
		images["debug_suspend"]		= DWTResourceManager.getImage("debug/suspend_co.gif");
		images["debug_command"]		= DWTResourceManager.getImage("debug/debug_command.gif");
		images["debug_stepinto"]	= DWTResourceManager.getImage("debug/stepinto_co.gif");
		images["debug_stepover"]	= DWTResourceManager.getImage("debug/stepover_co.gif");
		images["debug_stepreturn"]	= DWTResourceManager.getImage("debug/stepreturn_co.gif");
		images["debug_varview"]		= DWTResourceManager.getImage("debug/variable_view.gif");
		images["debug_bpview"]		= DWTResourceManager.getImage("debug/breakpoint_view.gif");
		images["debug_bp"]			= DWTResourceManager.getImage("debug/breakpoint.gif");
		images["debug_register"]	= DWTResourceManager.getImage("debug/genericregister_obj.gif");
		images["debug_stack"]		= DWTResourceManager.getImage("debug/stack.gif");
		images["debug_dll"]			= DWTResourceManager.getImage("debug/links_obj.gif");
		images["debug_stackframe"]	= DWTResourceManager.getImage("debug/stckframe_obj.gif");
		images["debug_threads"]		= DWTResourceManager.getImage("debug/threads_obj.gif");
		images["debug_debugthreads"]= DWTResourceManager.getImage("debug/debugts_obj.gif");
		images["debug_misc"]		= DWTResourceManager.getImage("debug/defaultview_misc.gif");
		images["debug_disassembly"]	= DWTResourceManager.getImage("debug/disassembly.gif");
		

		images["debug_exc_dis"]		= DWTResourceManager.getImage("debug//debug_exc_dis.gif");
		images["debug_resume_dis"]		= DWTResourceManager.getImage("debug//resume_co_dis.gif");
		images["debug_suspend_dis"]		= DWTResourceManager.getImage("debug//suspend_co_dis.gif");
		images["debug_command_dis"]		= DWTResourceManager.getImage("debug//debug_command_dis.gif");
		images["debug_stepinto_dis"]	= DWTResourceManager.getImage("debug//stepinto_co_dis.gif");
		images["debug_stepover_dis"]	= DWTResourceManager.getImage("debug//stepover_co_dis.gif");
		images["debug_stepreturn_dis"]	= DWTResourceManager.getImage("debug//stepreturn_co_dis.gif");

		
		char[] dir = std.path.join(imageDir, "obj16");
		if(std.file.exists(dir)){
			std.file.chdir(dir);
			images["D_ALIAS"]				= DWTResourceManager.getImage("alias_obj.gif");
			images["D_CLASS"] 				= DWTResourceManager.getImage("class_obj.gif");
			images["D_CLASS-PRIVATE"] 		= DWTResourceManager.getImage("class_private_obj.gif");
			images["D_CLASS-PROTECTED"] 	= DWTResourceManager.getImage("class_protected_obj.gif");
			images["D_CTOR"] 				= DWTResourceManager.getImage("ctor_obj.gif");
			images["D_DTOR"] 				= DWTResourceManager.getImage("dtor_obj.gif");
			images["D_DEBUG"] 				= DWTResourceManager.getImage("debug_obj.gif"); 
			images["D_ENUM"] 				= DWTResourceManager.getImage("enum_obj.gif");
			images["D_ENUM-PRIVATE"] 		= DWTResourceManager.getImage("enum_private_obj.gif");
			images["D_ENUM-PROTECTED"] 		= DWTResourceManager.getImage("enum_protected_obj.gif");
			images["D_ENUMMEMBER"] 			= DWTResourceManager.getImage("enum_member_obj.gif");
			images["D_FUNCTION"]			= DWTResourceManager.getImage("function_public_obj.gif");
			images["D_FUNCTION-PRIVATE"] 	= DWTResourceManager.getImage("function_private_obj.gif");
			images["D_FUNCTION-PROTECTED"] 	= DWTResourceManager.getImage("function_protected_obj.gif");
			images["D_FUNLITERALS"]			= DWTResourceManager.getImage("functionliterals_obj.gif");
			images["D_FUNPOINTER"]			= DWTResourceManager.getImage("functionpointer_obj.gif");
			images["D_FUNPOINTER-PRIVATE"]	= DWTResourceManager.getImage("functionpointer_private_obj.gif");
			images["D_FUNPOINTER-PROTECTED"]= DWTResourceManager.getImage("functionpointer_protected_obj.gif");
			images["D_IMPORT"] 				= DWTResourceManager.getImage("import_obj.gif");
			images["D_IMPORT-PRIVATE"] 		= DWTResourceManager.getImage("import_private_obj.gif");
			images["D_INTERFACE"]			= DWTResourceManager.getImage("interface_obj.gif");
			images["D_INTERFACE-PRIVATE"]	= DWTResourceManager.getImage("interface_private_obj.gif");
			images["D_INTERFACE-PROTECTED"] = DWTResourceManager.getImage("interface_protected_obj.gif");
			images["D_MIXIN"] 				= DWTResourceManager.getImage("mixin_template_obj.gif");
			images["D_MODULE"] 				= DWTResourceManager.getImage("module_obj.gif");
			images["D_STATICCTOR"] 			= DWTResourceManager.getImage("static_ctor_obj.gif");
			images["D_STATICDTOR"] 			= DWTResourceManager.getImage("static_dtor_obj.gif");
			images["D_STRUCT"] 				= DWTResourceManager.getImage("struct_obj.gif");
			images["D_STRUCT-PRIVATE"] 		= DWTResourceManager.getImage("struct_private_obj.gif");
			images["D_STRUCT-PROTECTED"]	= DWTResourceManager.getImage("struct_protected_obj.gif");
			images["D_TEMPLATE"]			= DWTResourceManager.getImage("template_obj.gif");
			images["D_TYPEDEF"] 			= DWTResourceManager.getImage("typedef_obj.gif");
			images["D_UNION"] 				= DWTResourceManager.getImage("union_obj.gif");
			images["D_UNION-PRIVATE"]		= DWTResourceManager.getImage("union_private_obj.gif");
			images["D_UNION-PROTECTED"]		= DWTResourceManager.getImage("union_protected_obj.gif");
			images["D_UNITTEST"]			= DWTResourceManager.getImage("unittest_obj.gif");
			images["D_VARIABLE"]			= DWTResourceManager.getImage("variable_obj.gif");
			images["D_VARIABLE-PRIVATE"]	= DWTResourceManager.getImage("variable_private_obj.gif");
			images["D_VARIABLE-PROTECTED"]	= DWTResourceManager.getImage("variable_protected_obj.gif");
			images["D_VERSION"] 			= DWTResourceManager.getImage("version_obj.gif");
			images["D_WITH"] 				= DWTResourceManager.getImage("with_obj.gif");
			images["D_VERSIONSPEC"]			= DWTResourceManager.getImage("version_spec_obj.gif");
			images["D_DEBUGSPEC"] 			= DWTResourceManager.getImage("debug_spec_obj.gif");
			images["D_ANONYMOUSBLOCK"] 		= DWTResourceManager.getImage("anonymousblock_obj.gif");
		}

		// return to main path
		std.file.chdir(appDir);
	}

	static public Image getImageByExt(char[] ext)
	{
		if( !std.string.icmp( ext, "d" ) ) 		return images["d"];
		if( !std.string.icmp( ext, "di" ) )		return images["di"];
		if( !std.string.icmp( ext, "res" ) )	return images["res"];
		
		if( !std.string.icmp( ext, "xml" ) ) 	return images["xml"];
			
		return images["file_obj"];
	}

	static public Image getImage(char[] name)
	{
		if(name in images)
			return images[name];
		return null;
	}

	//private
	static void removeFromRecent(char[] dir)
	{
		if(recentPrjs.length == 0)	return;
		
		int index = -1;
		for(int i=0; i<recentPrjs.length; ++i){
			PrjPair pp = recentPrjs[i];
			if(pp.dir == dir){
				index = i;
				break;
			}
		}
		
		if(index >= 0){
			TVector!(PrjPair).remove(recentPrjs, index);
		}
	}

	public static void addRecentPrj(Project prj) {
		// remove the path if it exists already
		removeFromRecent(prj.projectDir);

		// add the path 
		char[] name = prj.serialized ? prj.projectName : null;
		PrjPair pp = new PrjPair(prj.projectDir, name);
		recentPrjs ~= pp;
		if(recentPrjs.length > MAX_RECENT_PRJ){
			TVector!(PrjPair).remove(recentPrjs, 0);
		}
	}
	
	public static ToolEntry findTool(char[] name) {
		foreach(ToolEntry entry; toolEntries) {
			if(entry.name == name)
				return entry;
		}
		return null;
	}

	/**
	 * 1) search lang dir to enum all languages
	 * 2) load the language previous used (stored in xml)
	 */
	public static void initI18N()
	{
		languages = Translation.enumLanguages(i18nDir);
	}

	public static char[] getConfigFileName() {
		return 	std.path.join(appDir, "config.xml");
	}

	public static bool loadConfig()
	{
		XML xml = new XML();
		if(xml.Open(getConfigFileName()) < 0 )
			return false; // failed
		XMLnode root = xml.m_root.getChildEx("config", null);
		
		// load external tool entries
		_updateToolEntries(root, false);
		
		// load hot key settings
		_updateHotKeys(root, false);
		
		// load recently projects
		_updateRecentPrjs(root, false);

		_updateIDESettings(root, false);

		// load editor settings
		Editor.settings._updateEditorSettings(root, false);

		XMLnode child = root.getChild("recentdir");
		if(child){
			XMLattrib at = child.getAttrib("name");
			if(at && at.GetValue().length > 0)
				recentDir = at.GetValue();
		}

		// default to english
		curLang = "english";
		child = root.getChild("language");
		if(child){
			XMLattrib at = child.getAttrib("value");
			if(at && at.GetValue().length > 0)
				curLang = at.GetValue();
		}

		XMLnode compilerChild = root.getChild("compilersetting");

		if( compilerChild )
		{
			child = compilerChild.getChild("DMD");
			if( child )
			{
				XMLattrib at = child.getAttrib("path");
				if( at && at.GetValue().length > 0 ) DMDPath = at.GetValue();
			}

			child = compilerChild.getChild("DMC");
			if( child )
			{
				XMLattrib at = child.getAttrib("path");
				if( at && at.GetValue().length > 0 ) DMCPath = at.GetValue();
			}

			child = compilerChild.getChild( "BUD" );
			if( child )
			{
				XMLattrib at = child.getAttrib( "path" );
				if( at && at.GetValue().length > 0 ) BudExe = at.GetValue();
			}

			child = compilerChild.getChild("DEBUGGER");
			if( child )
			{
				XMLattrib at = child.getAttrib("path");
				if( at && at.GetValue().length > 0 ) DebuggerExe = at.GetValue();
			}

			child = compilerChild.getChild("BUILDTYPE");
			if( child )
			{
				XMLattrib at = child.getAttrib("thread");
				if( at && at.GetValue().length > 0 ) backBuild = std.string.atoi( at.GetValue() );
			}
			
			child = compilerChild.getChild("output");
			if( child )
			{
				XMLattrib at = child.getAttrib("wrap");
				if( at && at.GetValue().length > 0 ) outputWRAP = std.string.atoi( at.GetValue() );
			}

			child = compilerChild.getChild("debuggerSearch");
			if( child )
			{
				XMLattrib at = child.getAttrib("path");
				if( at && at.GetValue().length > 0 )
				{
					char[] path = at.GetValue();
					if( path.length )
						debuggerSearchPath = std.string.split( path, ";" );
				}
			}				
		}

		XMLnode parserChild = root.getChild("parsersetting");

		if( parserChild )
		{
			child = parserChild.getChild("codecompletion");
			if( child )
			{
				XMLattrib at = child.getAttrib("use");
				if( at && at.GetValue().length > 0 ) useCodeCompletion = std.string.atoi( at.GetValue() );

				at = child.getAttrib("onlybrowser");
				if( at && at.GetValue().length > 0 ) showOnlyClassBrowser = std.string.atoi( at.GetValue() );

				at = child.getAttrib("auto");
				if( at && at.GetValue().length > 0 ) parseImported = std.string.atoi( at.GetValue() );
				
				at = child.getAttrib("all");
				if( at && at.GetValue().length > 0 ) parseAllModule = std.string.atoi( at.GetValue() );

				at = child.getAttrib("live");
				if( at && at.GetValue().length > 0 ) updateParseLive = std.string.atoi( at.GetValue() );

				at = child.getAttrib("livefull");
				if( at && at.GetValue().length > 0 ) updateParseLiveFull = std.string.atoi( at.GetValue() );

				at = child.getAttrib("member");
				if( at && at.GetValue().length > 0 ) showAllMember = std.string.atoi( at.GetValue() );

				at = child.getAttrib("showtype");
				if( at && at.GetValue().length > 0 ) showType = std.string.atoi( at.GetValue() );

				at = child.getAttrib("jumptop");
				if( at && at.GetValue().length > 0 ) jumpTop = std.string.atoi( at.GetValue() );				

				at = child.getAttrib("casesensitive");
				if( at && at.GetValue().length > 0 ) parserCaseSensitive = std.string.atoi( at.GetValue() );

				at = child.getAttrib("lettercount");
				if( at && at.GetValue().length > 0 ) lanchLetterCount = std.string.atoi( at.GetValue() );
				
				at = child.getAttrib("defaultparser");
				if( at && at.GetValue().length > 0 ) useDefaultParser = std.string.atoi( at.GetValue() );

				at = child.getAttrib("backgroundload");
				if( at && at.GetValue().length > 0 ) backLoadParser = std.string.atoi( at.GetValue() );

				at = child.getAttrib("autoshow");
				if( at && at.GetValue().length > 0 ) showAutomatically = std.string.atoi( at.GetValue() );

				at = child.getAttrib("ed");
				if( at && at.GetValue().length > 0 ) edDebug = std.string.atoi( at.GetValue() );

				at = child.getAttrib("el");
				if( at && at.GetValue().length > 0 ) elDebug = std.string.atoi( at.GetValue() );

				at = child.getAttrib("version");
				if( at && at.GetValue().length > 0 ) parserDMDversion = compilerVersion = std.string.atoi( at.GetValue() );
			}

			child = parserChild.getChild( "defaultparserpaths" );
			if( child )
			{
				int count = child.getChildCount();
				for( int i=0; i < count; ++i )
				{
					XMLnode node = child.getChild( i );
					defaultParserPaths ~= node.getValue();
				}
			}
		}

		delete xml; // auto close
		
		return true;
	}

	public static boolean loadWorkSpace(out char[][] openedPrjs, out char[][] openedFiles)
	{
		char[] filename = std.path.join(appDir, "workspace.xml");
		XML xml = new XML();
		if(xml.Open(filename) < 0 )
			return false; // failed
		XMLnode root = xml.m_root.getChildEx("config", null);
		XMLnode child = root.getChild("openedprjs");
		if(child){
			int count = child.getChildCount();
			for(int i=0; i<count; ++i) {
				char[] path = XMLUtil.getAttrib(child.getChild(i), "path", null);
				if(path)
					openedPrjs ~= path;
			}
			
		}

		child = root.getChild("openedfiles");
		if(child){
			int count = child.getChildCount();
			for(int i=0; i<count; ++i) {
				char[] path = XMLUtil.getAttrib(child.getChild(i), "path", null);
				if(path)
					openedFiles ~= path;
			}
		}
		
		delete xml; // auto close
		return true;
	}
	

	public static void saveConfig()
	{
		XML xml = new XML();
		{
			xml.m_attributes ~= new XMLattrib("version", "1.0");
			xml.m_attributes ~= new XMLattrib("encoding", "UTF-8");
		}
		
		XMLnode root = xml.m_root.getChildEx("config", null);
		
		// save external tool entries
		_updateToolEntries(root, true);
		
		// load hot key settings
		_updateHotKeys(root, true);
		
		_updateRecentPrjs(root, true);

		// load editor settings
		Editor.settings._updateEditorSettings(root, true);

		_updateIDESettings(root, true);

		XMLnode node = root.addNode("recentdir", null);
		node.addAttrib("name", recentDir);

		node = root.addNode("language", null);
		node.addAttrib("value", curLang);

		XMLnode compiler_node = root.addNode("compilersetting", null);
			node = compiler_node.addNode( "DMD" , null);
			node.addAttrib( "path", DMDPath );

			node = compiler_node.addNode( "DMC" , null);
			node.addAttrib( "path", DMCPath );

			node = compiler_node.addNode( "BUD" , null);
			node.addAttrib( "path", BudExe );

			node = compiler_node.addNode( "DEBUGGER" , null);
			node.addAttrib( "path", DebuggerExe );

			node = compiler_node.addNode( "BUILDTYPE" , null);
			node.addAttrib( "thread", std.string.toString( backBuild ) );	
			
			node = compiler_node.addNode( "output" , null);
			node.addAttrib( "wrap", std.string.toString( outputWRAP ) );

			node = compiler_node.addNode( "debuggerSearch", null );
			node.addAttrib( "path", std.string.join( debuggerSearchPath, ";" ) );
		
		XMLnode parser_node = root.addNode("parsersetting", null);
			node = parser_node.addNode( "codecompletion" , null);
			node.addAttrib( "use", std.string.toString( useCodeCompletion ) );
			node.addAttrib( "onlybrowser", std.string.toString( showOnlyClassBrowser ) );
			node.addAttrib( "auto", std.string.toString( parseImported ) );
			node.addAttrib( "all", std.string.toString( parseAllModule ) );
			node.addAttrib( "live", std.string.toString( updateParseLive ) );
			node.addAttrib( "livefull", std.string.toString( updateParseLiveFull ) );
			node.addAttrib( "member", std.string.toString( showAllMember ) );
			node.addAttrib( "showtype", std.string.toString( showType ) );
			node.addAttrib( "jumptop", std.string.toString( jumpTop ) );
			node.addAttrib( "casesensitive", std.string.toString( parserCaseSensitive ) );
			node.addAttrib( "lettercount", std.string.toString( lanchLetterCount ) );
			node.addAttrib( "defaultparser", std.string.toString( useDefaultParser ) );
			node.addAttrib( "backgroundload", std.string.toString( backLoadParser ) );
			node.addAttrib( "autoshow", std.string.toString( showAutomatically ) );
			node.addAttrib( "ed", std.string.toString( edDebug ) );
			node.addAttrib( "el", std.string.toString( elDebug ) );
			node.addAttrib( "version", std.string.toString( parserDMDversion ) );

			node = parser_node.addNode( "defaultparserpaths", null );
			foreach( char[] s; defaultParserPaths )
				XMLnode subNode = node.addNode( "path", s );
		
		xml.Save(getConfigFileName());
		
		delete xml; // auto close
	}

	public static void saveWorkSpace(char[][] openedPrjs, char[][] openedFiles)
	{
		char[] filename = std.path.join(appDir, "workspace.xml");

		if(std.file.exists(filename)){
			try{ 
				std.file.remove(filename);
			}catch(Object o){
			}
		}

		XML xml = new XML();
		{
			xml.m_attributes ~= new XMLattrib("version", "1.0");
			xml.m_attributes ~= new XMLattrib("encoding", "UTF-8");
		}
		
		XMLnode root = xml.m_root.getChildEx("config", null);
		
		XMLnode child = root.getChildEx("openedprjs", null);
		foreach(char[] path; openedPrjs){
			XMLnode node = child.addNode(`prj`, null);
			node.addAttrib(`path`, path);
		}

		child = root.getChildEx("openedfiles", null);
		foreach(char[] path; openedFiles){
			XMLnode node = child.addNode(`file`, null);
			node.addAttrib(`path`, path);
		}
		
		xml.Save(filename);
		
		delete xml; // auto close
	}
	
	/**
	 * dynamically load language file when user change the lang setting
	 */
	public static void loadI18N(char[] lang)
	{
		i18n = new Translation(lang);
	}

	public static char[] getTranslation(char[] key)
	{
		if(i18n)
			return i18n.getTranslation(key);
		return key;
	}

	public static void _updateHotKeys(XMLnode root, boolean save) {
		assert(root);
		if(save){
			// save hot keys
			XMLnode child = root.getChildEx("hotkeys", null);
			int count = child.getChildCount();
			for(int i=count-1; i>=0; --i)
				child.deleteNode(i);
			foreach(_ShortCut key; hotkeys) {
				key.save(child.addNode("key", null));
			}
		}else{
			// load hot keys
			XMLnode child = root.getChild("hotkeys");
			if(child){
				hotkeys = null;
				int count = child.getChildCount();
				for(int i=0; i<count; ++i) {
					_ShortCut key = new _ShortCut();
					key.load(child.getChild(i));
					hotkeys ~= key;
				}
			}
		}
	}
	
	public static void _updateToolEntries(XMLnode root, boolean save) {
		assert(root);
		if(save) {
			// save ToolEntries
			XMLnode child = root.getChildEx("customtools", null);
			int count = child.getChildCount();
			for(int i=count-1; i>=0; --i)
				child.deleteNode(i);
			foreach(ToolEntry entry; toolEntries) {
				entry.save(child.addNode("tool", null));
			}
			// save last used tool name
			XMLattrib attrib = child.getAttribEx("last", "");
			char[] name = "";
			if(ToolEntry.lastTool)
				name = ToolEntry.lastTool.name;
			attrib.SetValue(name);
		}else{
			// load ToolEntries
			XMLnode child = root.getChild("customtools");
			if(child) {
				toolEntries = null;
				int count = child.getChildCount();	// int count = child.m_children.length;
				for(int i=0; i<count; ++i) {
					ToolEntry entry = new ToolEntry();
					entry.load(child.getChild(i));
					toolEntries ~= entry;
				}
				// load last used tool name
				XMLattrib attrib = child.getAttribEx("last", "");
				char[] lastToolName = attrib.GetValue();
				ToolEntry.lastTool = findTool(lastToolName);
			}
		}
	}

	public static void _updateIDESettings(XMLnode root, boolean save)
	{
		// nested function
		char[] _encodeRect(Rectangle rect) {
			if(rect is null) return "";
			char[] text = std.string.toString(rect.x) ~ " ";
			text ~= std.string.toString(rect.y) ~ " ";
			text ~= std.string.toString(rect.width) ~ " ";
			text ~= std.string.toString(rect.height);
			return text;
		}
		Rectangle _parseRect(char[] text) {
			if(text.length == 0) return null;
			int[] ints = new int[4];
			char[][] array = std.string.split(text, " ");
			for(int i=0; i<array.length && i<ints.length; ++i) {
				ints[i] = cast(int)std.string.atoi(array[i]);
			}
			return new Rectangle(ints[0], ints[1], ints[2], ints[3]);
		}

		// code start here
		assert(root);
		if(save) {
			// remove old data
			// remove it first
			int index = root.getChildIndex("ide");
			if(index >= 0)
				root.deleteNode(index);
			
			XMLnode node = root.addNode("ide", null);
			node.addAttrib("showsplash", std.string.toString(showSplash));
			node.addAttrib("loadworkspaceatstart", std.string.toString(loadWorkSpaceAtStart));
			node.addAttrib("isshellmaximized", std.string.toString(isShellMaximized));
			node.addAttrib("shellbounds", _encodeRect(shellBounds));

			ExplorerWeight = sGUI.topSash.getWeights();
			BottomPanelWeight = sGUI.mainSash.getWeights();
			if( BottomPanelLastWeight[0] != 0 ) BottomPanelWeight[] = 0;
			char[] desktop = std.string.toString( ExplorerWeight[0] ) ~ " " ~
							 std.string.toString( ExplorerWeight[1] ) ~ " " ~
							 std.string.toString( BottomPanelWeight[0] ) ~ " " ~
							 std.string.toString( BottomPanelWeight[1] ) ~ " " ~
							 std.string.toString( BottomPanelLastWeight[0] ) ~ " " ~
							 std.string.toString( BottomPanelLastWeight[1] );

			node.addAttrib("desktopweight", desktop );
			node.addAttrib("sendabspath", std.string.toString(sendAbsoluteFullpath) );
			node.addAttrib( "document", std.string.join( DDcoumentDir, ";" ) );			

			char[] filter = poseidon.util.miscutil.MiscUtil.getFilter( SplitedExplorerFilter );
			node.addAttrib("explorerfilters", filter );
		}else{
			XMLnode node = root.getChild("ide");
			if(node) 
			{
				showSplash = XMLUtil.getAttribInt(node, "showsplash", showSplash);
				loadWorkSpaceAtStart = XMLUtil.getAttribInt(node, "loadworkspaceatstart", loadWorkSpaceAtStart);
				isShellMaximized = XMLUtil.getAttribInt(node, "isshellmaximized", isShellMaximized);
				char[] bounds = XMLUtil.getAttrib(node, "shellbounds", null);

				ExplorerWeight.length = BottomPanelWeight.length = BottomPanelLastWeight.length = 2;
				char[] text = XMLUtil.getAttrib( node, "desktopweight", null );
				if( text.length > 0 )
				{
					char[][] array = std.string.split( text, " " );
					ExplorerWeight[0] = std.string.atoi( array[0] );
					ExplorerWeight[1] = std.string.atoi( array[1] );
					BottomPanelWeight[0] = std.string.atoi( array[2] );
					BottomPanelWeight[1] = std.string.atoi( array[3] );
					BottomPanelLastWeight[0] = std.string.atoi( array[4] );
					BottomPanelLastWeight[1] = std.string.atoi( array[5] );
				}
				shellBounds = _parseRect(bounds);

				sendAbsoluteFullpath = XMLUtil.getAttribInt(node, "sendabspath", sendAbsoluteFullpath);
				char[] documentDir = XMLUtil.getAttrib( node, "document", null );
				DDcoumentDir = std.string.split( documentDir, ";" );
				
				char[] filter = XMLUtil.getAttrib( node, "explorerfilters", "*.c;*.cpp;*.h;*.xml;*.txt;*.def" );
				SplitedExplorerFilter = poseidon.util.miscutil.MiscUtil.getSplitFilter( filter );
				
			}
		}
	}
	
	public static void _updateRecentPrjs(XMLnode root, boolean save) {
		assert(root);
		
		if(save) {
			XMLnode child = root.getChildEx("recentprjs", null);
			int count = child.getChildCount();
			for(int i=count-1; i>=0; --i)
				child.deleteNode(i);
			foreach(PrjPair pp; recentPrjs){
				XMLnode node = child.addNode(`prj`, null);
				node.addAttrib(`dir`, pp.dir);
				if(pp.name.length > 0){
					node.addAttrib(`name`, pp.name);
				}
			}
		}else{
			recentPrjs = null;
			XMLnode child = root.getChild("recentprjs");
			if(child){
				int count = child.getChildCount();
				for(int i=0; i<count; ++i) {
					XMLnode node = child.getChild(i);
					XMLattrib attrib = node.getAttrib("dir");
					if(attrib && attrib.GetValue().length > 0)
					{
						char[] dir = attrib.GetValue();
						PrjPair pp = new PrjPair(dir, null);
						attrib = node.getAttrib("name");
						if(attrib){
							pp.name = attrib.GetValue();
						}
						recentPrjs ~= pp;
					}
				}
			}
		}
	}

	public static void resetHotKey() {
		foreach(_ShortCut sc; hotkeys){
			sc.reset();
		}
	}

	/**
	 * 
	 */
	public static _ShortCut isHotKeyOccupied(uint mask, uint code, _ShortCut theKey) {
		foreach(_ShortCut sc; hotkeys){
			if(sc !is theKey && sc.mask == mask && sc.code == code)
					return sc;
		}
		return null;
	}

	// ugly methods name
	
	// the first call before others, non-GUI involved
	public static void firstCall( char[][] args = null )
	{
		prepareDir();
		Editor.settings = new EditorSettings(); // reqired by Global.loadConfig()
		loadConfig();
		fileArgs = args;
	}

}
