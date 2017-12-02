/**
 * Ini File loader/saver
 *
 * Author: Shawn Liu, shawn666.liu@gmail.com
 *
 * License: use freely for any purpose
 *
 * History:
 *	2005.12.24 Initial version
 */ 
 
module poseidon.util.iniloader;

private import poseidon.util.fileutil;

private import dwt.all;

class IniLoader
{

private import std.string;
private import std.stream;

class Section 
{
	char[] name;
	char[][char[]] items;

	this(char[] name)
	{ 
		this.name = name; 
	}

	int count() 
	{ 
		return items.length; 
	}
}

int ibom = -1;
private char[] filename;
private Section[] sections;

static char[] CRLF = "\r\n";

public this(){}	

public ~this() { clear(); }	

public bool load(char[] filename)
{
	clear();
	char[] buffer;

	this.filename = filename;
	
	// use FileReader to convert any format of file to UTF string buffer	
	try{
		FileReader.read(filename, buffer, ibom);
	}catch(Exception e){
		Util.trace(e.toString());
		return false;
	}

	MemoryStream mms = new MemoryStream(buffer);
	Section current = null;
	while(! mms.eof())
	{
		char[] line = mms.readLine();
		line = std.string.strip(line);
		if(line.length > 0 && line[0] != ';' && line[0] != '#')
		{
			if(line[0] =='[' && line[--$] == ']')
			{
				current = new Section(line[1..--$]);
				sections ~= current;
				Util.trace(current.name);
			}
			else if(current !is null)
			{	
				int firstEqualPos = std.string.find( line, "=" );
				if( firstEqualPos > 0 )
				{
					char[] item = std.string.strip( line[0..firstEqualPos] );
					char[] value = std.string.strip( line[firstEqualPos+1..length] );
					current.items[item] = value; 
				}
				/*
				char[][] array = std.string.split(line, "=");
				if(array.length >= 2)
				{
					char[] item = std.string.strip(array[0]);
					char[] value = std.string.strip(array[1]);
					current.items[item] = value; 
				}
				*/
			}
		}
	}

	return true;
}

/**
 * <Shawn Liu> be careful: the current implementation strips any comment and blank line
 * Can make it better
 */
public bool save(char[] filename = null) 
{
	if(filename is null)
		filename = this.filename;

	char[] buffer;

	foreach(Section sc; sections)
	{	
		buffer ~= "[" ~ sc.name ~ "]" ~ CRLF;
		char[][] keys = sc.items.keys;
		foreach(char[] key; keys)
		{
			char[] line = key ~ " = " ~ sc.items[key] ~ CRLF;
			buffer ~= line;
		}
	}
	
	try{
		FileSaver.save(filename, buffer, ibom);
	}catch(Exception e){
		Util.trace(e.toString());
		return false;
	}
	
	return true;
}

public void clear() 
{
	sections = null;
}

public Section getSection(int index)
{
	if(index >=0 && index < sections.length)
		return sections[index];
	return null;
}

public Section getSection(char[] name)
{
	foreach(Section sc; sections)
	{
		if(sc.name == name)
			return sc;
	}
	return null;
}

public int getSectionCount()
{
	return sections.length;
}

int getItemCount(char[] section)
{
	Section sc = getSection(section);
	if(sc)
		return sc.count;
	return 0;
}

int getItemCount(int sectionIndex)
{
	if(sectionIndex >=0 && sectionIndex < sections.length)
	{
		Section sc = sections[sectionIndex];
		return sc.count;
	}
	return 0;
}

public char[] getValue(char[] section, char[] item)
{
	Section sc = getSection(section);
	if(sc && item in sc.items)
	{
		return sc.items[item];
	}
	return null;
}

public void removeSection(char[] section)
{
	Section sc = getSection(section);
	if(sc)
	{
		TVector!(Section).remove(sections, sc);
	}
}

public void setValue(char[] section, char[] item, char[] value)
{
	Section sc = getSection(section);
	if(sc)
	{
		sc.items[item] = value;
	}
	else
	{
		sc = new Section(section);
		sc.items[item] = value;
		sections ~= sc;
	}
}

}

//unittest {
//	IniLoader ini = new IniLoader;
//	if(ini.load(`c:\test.ini`))
//	{
//		char[] BUTTON_EXTTOOL = ini.getValue("Translations", "BUTTON_EXTTOOL");
//		Util.trace(BUTTON_EXTTOOL);
//	}
//
//	ini.setValue("admin", "name", "hello");
//	ini.setValue("Translations", "name", "past");
//	ini.setValue("Translations", "BUTTON_EXTTOOL", "unittest");
//
//	ini.save();
//}