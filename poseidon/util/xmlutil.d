module poseidon.util.xmlutil;

private import ak.xml.coreXML;



class XMLUtil
{
	private import std.string;

	
	static char[] getAttrib(XMLnode node, char[] attribName, char[] defaultValue = null)
	{
		assert(node);
		XMLattrib attrib = node.getAttrib(attribName);
		if(attrib)
			return attrib.GetValue();
		return defaultValue;
	}
	
	static int getAttribInt(XMLnode node, char[] attribName, int defaultValue = 0 )
	{
		char[] value = getAttrib(node, attribName, null);
		if(value)
			return cast(int)std.string.atoi(value);
		return defaultValue;
	}

	static double getAttribDouble(XMLnode node, char[] attribName, double defaultValue = 0 )
	{
		char[] value = getAttrib(node, attribName, null);
		if(value)
			return std.string.atof(value);
		return defaultValue;
	}
}