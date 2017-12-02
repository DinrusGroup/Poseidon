module poseidon.i18n.translation;

private import poseidon.util.iniloader;
private import poseidon.globals;
private import dwt.all;
private import std.path;



class Translation {

	protected char[][char[]] _translation;
	protected static Translation defaultI18N;

	
	private this() {}

	/**
	 * Param: filename the absolute file path;
	 */
	this(char[] lang)
	{
		loadI18N(lang);
	}

	public static char[][char[]] enumLanguages(char[] langdir)
	{
		char[][char[]] languages = null;

		char[][] listDir = std.file.listdir( langdir, "*.ini" );
		foreach( char[] s; listDir )
		{
			char[] fn = std.path.join( langdir, s );
			scope ini = new IniLoader();
			if(ini.load(fn))
			{
				char[] lang = ini.getValue("info", "name");
				if(lang) 
					languages[lang] = std.path.getName( s );
			}			
		}

		/*
		Search search = new Search(langdir, "*.ini", RECLS_FLAG.RECLS_F_RECURSIVE);
		foreach(Entry entry; search)
		{
			char[] fn = entry.Path();
			scope ini = new IniLoader();
			if(ini.load(fn))
			{
				char[] lang = ini.getValue("info", "name");
				if(lang) 
					languages[lang] = entry.FileName();
			}
		}
		*/

		return languages;
	}

	public static Translation getDefaultI18N() {
		if (defaultI18N is null)
			defaultI18N = new Translation("english");
		return defaultI18N;
	}
	
	public char[][char[]] translation() {
		return _translation;
	}

	/**
	 * Return the translated word for the given key or the english translation if no translation was found. If the
	 * english translation is missing too, return the key.
	 * 
	 * Param: key
	 *            unique key
	 * Return:
	 *			String translated word in the selected language
	 */	
	final char[] getTranslation(char[] key)
	out(result){
		Util.trace(result);
	}
	body{
		if(key in _translation)
			return _translation[key];
		else if( key in getDefaultI18N().translation){
			return getDefaultI18N().translation[key];
		}
		return key;
	}

	protected void loadI18N(char[] filename)
	{
		// clear current
		_translation = null;

		char[] dir = Globals.i18nDir;
		char[] fn = std.path.join(dir, filename ~ ".ini");
		
		IniLoader ini = new IniLoader();
		if(ini.load(fn))
		{
			int sectionCnt = ini.getSectionCount();
			for(int i=0; i<sectionCnt; ++i)
			{
				ini.Section sc = ini.getSection(i);
				char[][] keys = sc.items.keys;
				foreach(char[] key; keys)
				{
					// multiple line support here
					char[] value = std.string.replace(sc.items[key], `\n`, "\n");
					_translation[key] = value;
				}
			}
		}
	}	
}
