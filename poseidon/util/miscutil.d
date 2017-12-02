module poseidon.util.miscutil;

private import std.regexp;
private import dwt.all;
private import poseidon.globals;

version(Win32){
	private import dwt.internal.win32.os;
}

class MiscUtil
{
	public static boolean isValidFileName(char[] shortName) {
		if(shortName.length == 0)	return false;
		if(shortName[--$] == '.')	return false;
		// \/:*?"<>|
		// can't contains any invalid char
		char[] invalid = `[\\/:*?"<>|]+`;
		// Util.trace(shortName);
		RegExp r = new RegExp(invalid, null);
		int pos = r.find(shortName); 
		return  pos == -1;
	}

	/**
	 * get the relative path, 
	 * For example, "d:\path\subdir", "d:\path" returns "subdir".
	 * any \ removed
	 */
	static char[] relativePath(char[] fullpath, char[] rootpath)
	{
		if( std.string.find(fullpath, rootpath) != 0)
			return null;
		char[] result = fullpath[rootpath.length..$];
		if(result.length > 0 && result[0] == std.path.sep[0])
			result = result[1..$];
		if(result.length > 0 && result[--$] == std.path.sep[0])
			result = result[0..--$];
		return result.length ? result : null;
	}

	static void sleep(uint dwMilliseconds){
		OS.Sleep(dwMilliseconds);
	}

	static bool inArray( T )( T v, T[] vs )
	{
		for( int i = 0; i < vs.length; ++ i )
		{
			if( v == vs[i] ) return true;
		}

		return false;
	}

	static char[][] getSplitFilter( char[] filter )
	{
		if( !std.string.strip( filter ).length ) return null;
		
		char[][] result;
		
		char[][] temp = std.string.split( filter, ";" );
		bool	 all = false;
		
		for( int i = 0; i < temp.length; ++i ) 
		{
			temp[i] = std.string.strip( temp[i]) ;
			if( temp[i].length > 2 && temp[i][0..2] == "*." )
			{
				char[] ext = temp[i][2..$];
				if( ext == "*" )
				{
					all = true;
					break;
				}
				else
				{
					result ~= ext;
				}
			}
		}
		
		if( all )
		{
			result.length = 1;
			result[0] = "*";
		}

		return result;
	}

	static char[] getFilter( char[][] splitFilters )
	{
		char[] result;

		foreach( char[] filter; splitFilters )
			result ~= "*." ~ filter ~ ";";

		if( result.length )
			result = result[0..--$]; //remove the last ;
		//else
			//result = "*.*";
			
		return result;
	}
}