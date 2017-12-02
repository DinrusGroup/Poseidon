module ak.xml.coreXML;
 
//private import ak.core.akobject;
//private import ak.core.array;
private import ak.xml.service;
private import std.file;
private import std.stream;
private import std.string;
private import std.c.windows.windows;

private import poseidon.util.fileutil;

debug{
private import std.stdio;
}

const int XML_RUN_ONSELF		=1;
const int XML_RUN_ONCHILDREN	=2;
const int XML_RUN_RECURSIVE		=4;
 
class akObject
{
	this(){_ak_thisid=++___ak_lastid;}
	uint _ak_thisid;
	private static uint ___ak_lastid;
}

class XMLentity
{
	this(){};
	this(char[] name,char[] value){m_name=name;m_value=value;}

	int Write(Stream outt)
	{
		int ret=0;
		if(outt.isOpen && outt.writeable)
		{
			ret=1;
			if(m_flags&XML_ENTITY_PE) outt.writef("<!ENTITY %% %s ",m_name);
			else outt.writef("<!ENTITY %s ",m_name);
			if(m_flags&XML_ENTITY_SYSTEM)
			{
				outt.writef("SYSTEM %s",m_systemliteral);
				if(m_flags&XML_ENTITY_NDATA|XML_ENTITY_PE) outt.writef(" NDATA %s",m_ndata);
			}
			else if(m_flags&XML_ENTITY_PUBLIC)
			{
				outt.writef("PUBLIC %s %s",m_pubidliteral,m_systemliteral);
				if(m_flags&XML_ENTITY_NDATA|XML_ENTITY_PE) outt.writef(" NDATA %s",m_ndata);
			}
			else outt.writef("\"%s\"",m_ogvalue);
			outt.writef(">\n");
		}
		return ret;
	}

	char[] m_name;
	char[] m_value;
	char[] m_ogvalue;
	char[] m_ndata;
	char[] m_systemliteral;
	char[] m_pubidliteral;
	int m_flags;
}

class XMLattrib
{
	this(){};
	this(char[] name,char[] value){SetName(name);SetValue(value);};

	char[] GetName(){return m_name;}
	char[] GetValue(){return m_value;}
	void SetName(char[] name){m_name=name;}
	void SetValue(char[] value){m_value=value;}

	char[] m_name;
	char[] m_value;
}

class XMLnode : akObject
{
	this(){};
	this(char[] name,char[] value){setName(name);setValue(value);};

	char[] getName(){return m_name;}
	char[] getValue(){return m_value;}
	void setName(char[] name){m_name=name;}
	void setValue(char[] value){m_value=value;}

	int Write(XML xmlparent,Stream outt,int indent=-1)
	{
		int ret=0;
		if(outt.isOpen && outt.writeable)
		{
			ret=1;
			int isempty=(!m_children.length && !m_value.length);
			if(m_name.length)
			{
				for(int c=0;c<indent;c++) outt.writef("\t");
				outt.writef("<%s",m_name);
				for(int c=0;c<m_attributes.length;c++) outt.writef(" %s=\"%s\"",m_attributes[c].m_name,xml_enreference(xmlparent,m_attributes[c].m_value));
				if(isempty) outt.writef(" /");
				outt.writef(">");
				if((!m_value.length && !isempty) || (isempty && ((m_parent && !m_parent.m_value) || !m_parent))) outt.writef("\n");
			}
			if(m_value.length) outt.writef("%s",xml_enreference(xmlparent,m_value));
			for(int c=0;c<m_children.length;c++) ret&=m_children[c].Write(xmlparent,outt,!m_value.length?indent+1:0);
			if(m_name.length && !isempty)
			{
				if(!m_value.length) for(int c=0;c<indent;c++) outt.writef("\t");
				outt.writef("</%s>\n",m_name);
			}
		}
		return ret;
	}

	int Run(int function(inout XMLnode v,void *args,TypeInfo[] argtypes) dg,int flags=XML_RUN_ONSELF,...) {return RunA(dg,flags,_argptr,_arguments);}

	int RunA(int function(inout XMLnode v,void *args,TypeInfo[] argtypes) dg,int flags,void *args,TypeInfo[] argtypes)
	{
		if(flags&XML_RUN_ONSELF) {if(!dg(this,args,argtypes)) return 0;}
		if(flags&XML_RUN_RECURSIVE) {for(int c=0;c<m_children.length;c++) if(!m_children[c].RunA(dg,flags,args,argtypes)) return 0;}
		else if(flags&XML_RUN_ONCHILDREN) {for(int c=0;c<m_children.length;c++) if(dg(m_children[c],args,argtypes)) return 0;}
		return 1;
	}

	int Clean(int recursive=0)
	{
		static int Clean_sub(inout XMLnode v,void *args,TypeInfo[] argtypes) {if(v.m_value.length && xml_read_whitespace(v.m_value)==v.m_value.length) v.m_value.length=0; return 1;}
		return Run(&Clean_sub,XML_RUN_ONSELF|(recursive?XML_RUN_RECURSIVE:XML_RUN_ONCHILDREN));
	}

	int Sort(int recursive=0,int function(XMLnode a,XMLnode b) dg=null)
	{
		static int Sort_sub(inout XMLnode v,void *args,TypeInfo[] argtypes)
		{
			int function(XMLnode a,XMLnode b) dg=*cast(int function(XMLnode a,XMLnode b)*)args;
			TArray!(XMLnode).Sort(v.m_children,dg);
			return 1;
		}
		static int cmp_node(XMLnode a,XMLnode b){return cmp(a.m_name,b.m_name);}
		if(!dg) dg=&cmp_node;
		return Run(&Sort_sub,XML_RUN_ONSELF|(recursive?XML_RUN_RECURSIVE:0),dg);
	}

	XMLattrib addAttrib(char[] name,char[] value)
	{
		m_attributes~=new XMLattrib(name,value);
		return m_attributes[m_attributes.length-1];
	}

	XMLattrib getAttribEx(char[] name,char[] value)
	{
		XMLattrib ret=getAttrib(name);
		if(!ret) ret=addAttrib(name,value);
		return ret;
	}

	XMLattrib changeAttrib(char[] name,char[] value)
	{
		XMLattrib ret=getAttrib(name);
		if(!ret) ret=addAttrib(name,value);
		ret.m_value=value;
		return ret;
	}

	XMLnode addNode(char[] name,char[] value)
	{
		int ret=m_children.length;
		m_children~=new XMLnode(name,value);
		m_children[ret].m_parent=this;
		return m_children[ret];
	}

	int deleteNode(int index) {return TArray!(XMLnode).DeleteItems(m_children,index,1);}

	int getChildIndex(char[] name)
	{
		for(int c=0;c<m_children.length;c++) if(m_children[c].m_name==name) return c;
		return -1;
	}

	XMLnode getChild(int index)
	{
		if(index>=m_children.length) return null;
		else return m_children[index];
	}
	
	int getChildCount() { return m_children.length; }

	XMLnode getChild(char[] name)
	{
		for(int c=0;c<m_children.length;c++) if(m_children[c].m_name==name) return m_children[c];
		return null;
	}

	XMLnode getChildEx(char[] name,char[] defvalue)
	{
		XMLnode ret=getChild(name);
		if(!ret) ret=addNode(name,defvalue);
		return ret;
	}

	XMLnode findChild(uint hash,int recursive=1)
	{
		static int findChild_hash_sub(inout XMLnode v,void *args,TypeInfo[] argtypes)
		{
			uint hash=*cast(uint*)args;
			XMLnode *ret=*cast(XMLnode**)(args+(uint).sizeof);
			if(v._ak_thisid==hash) (*ret)=v;
			if(*ret){return 0;}
			else return 1;
		}
		XMLnode ret;
		Run(&findChild_hash_sub,XML_RUN_ONSELF|(recursive?XML_RUN_RECURSIVE:XML_RUN_ONCHILDREN),hash,&ret);
		return ret;
	}

	XMLnode findChild(char[] name,int recursive=1)
	{
		static int findChild_name_sub(inout XMLnode v,void *args,TypeInfo[] argtypes)
		{
			char[] name=*cast(char[]*)args;
			XMLnode *ret=*cast(XMLnode**)(args+(char[]).sizeof);
			(*ret)=v.getChild(name);
			if(*ret){return 0;}
			else return 1;
		}
		XMLnode ret;
		Run(&findChild_name_sub,XML_RUN_ONSELF|(recursive?XML_RUN_RECURSIVE:XML_RUN_ONCHILDREN),name,&ret);
		return ret;
	}

	int getChild(XMLnode ch)
	{
		for(int c=0;c<m_children.length;c++) if(m_children[c] is ch) return c;
		return -1;
	}

	XMLnode getPath(char[] path,char[] deli="/",int function(XMLnode a,char[] b) compareFunc=null)
	{
		if(!path.length) return null;
		char[][] r=split(path,deli);
		if(!r.length) return null;
		static int def_cmp(XMLnode a,char[] b){return cmp(a.m_name,b);}
		if(!compareFunc) compareFunc=&def_cmp;
		
		static XMLnode findnode(inout XMLnode v,char[][] pyt,int level,int function(XMLnode a,char[] b) compareFunc)
		{
			XMLnode ret=null;
			for(int c=0;c<v.m_children.length;c++)
			{
				if(compareFunc(v.m_children[c],pyt[level])==0)
				{
					if(level<pyt.length-1) ret=findnode(v.m_children[c],pyt,level+1,compareFunc);
					else ret=v.m_children[c];
				}
				if(ret) break;
			}
			return ret;
		}
		return findnode(this,r,0,compareFunc);
	}

	XMLattrib getAttrib(int index)
	{
		if(index>=m_attributes.length) return null;
		else return m_attributes[index];
	}

	XMLattrib getAttrib(char[] name)
	{
		for(int c=0;c<m_attributes.length;c++) if(m_attributes[c].m_name==name) return m_attributes[c];
		return null;
	}

	char[] m_name;
	char[] m_value;
	XMLnode m_parent;
	XMLnode[] m_children;
	XMLattrib[] m_attributes;
}

class XML
{
	this(){predefineEntities();m_root=new XMLnode;}
	this(char[] s) {predefineEntities();Open(s);}
	// this(Stream s) {predefineEntities();Open(s);}
	~this(){Close();}

	void predefineEntities()
	{
		XMLentity e=new XMLentity("lt","<"); //"&#38;#60;"
		m_entities[e.m_name]=e;
		e=new XMLentity("gt",">"); //"&#62;"
		m_entities[e.m_name]=e;
		e=new XMLentity("amp","&"); //"&#38;#38;"
		m_entities[e.m_name]=e;
		e=new XMLentity("apos","'"); //"&#39;"
		m_entities[e.m_name]=e;
		e=new XMLentity("quot","\""); //"&#34;"
		m_entities[e.m_name]=e;
	}

	int Open(char[] filename)
	{
		if(!exists(filename) || !isfile(filename)) return -1;
		// File f=new File(filename,FileMode.In);
		// int ret = Open(f);
		// f.close();
		int bom;
		int ret;
		try{
			FileReader.read(filename, m_buffer, bom);
			ret = Parse(m_buffer);
		}catch(Object o){
			return -1;
		}
		
		return ret;
	}

/+ 	int Open(Stream s)
	{
		if(!s.isOpen() || !s.readable) return -1;
		try{m_buffer=s.readString(cast(uint)s.size());}
		catch(ReadException){return -1;}
		return Parse(m_buffer);
	} +/

	void Close()
	{
		m_buffer.length=0;
	}

	int Parse(char[] buffer)
	{
		if(!buffer.length) return -1;
		return xml_read_unknown(this,buffer,m_root);
	}

	int Save(char[] fn)
	{
		if(exists(fn) && isfile(fn) && getAttributes(fn)&FILE_ATTRIBUTE_READONLY) return -1;
		File file = new File(fn,FileMode.OutNew);		
		/**
		 * <shawn liu> modified here, save as UTF8 encoding
		 */
		EndianStream outt = new EndianStream(file, std.system.endian);
		
		outt.writeBOM(BOM.UTF8);
		
		outt.writef("<?xml ");
		for(int c=0;c<m_attributes.length;c++)
		{
			outt.writef("%s=\"%s\" ",m_attributes[c].m_name,m_attributes[c].m_value);
		}
		outt.writef("?>\n");
		if(m_doctype.length) outt.writef("%s\n",m_doctype);
		for(int c;c<m_entitiesorder.length;c++) m_entities[m_entitiesorder[c]].Write(outt);
		int ret=m_root.Write(this,outt);
		outt.close();
		file.close();
		
		return ret;
	}

	int OnPI(char[] name,char[] data)
	{
		if(icmp(name,"xml")==0)
		{
			int c=xml_read_whitespace(data);
			if(c<0) c=0;
			xml_read_attributes(this,data[c..data.length],m_attributes);
			return 1;
		}
		return 0;
	}

	int OnExclamation(char[] buffer,int type)
	{
		if(type==XML_STAG_DOCTYPE) m_doctype=buffer;
		return 0;
	}

	XMLnode m_root;
	XMLattrib[] m_attributes;
	XMLentity[char[]] m_entities;
	char[][] m_entitiesorder;
	char[] m_doctype;

	private char[] m_buffer;
}

//void main()
//{
//	XML xml=new XML;
//	if(xml.Open("programs.xml")>=0) writefln("parsed ok");
//	else writefln("parsed not ok");
//	xml.m_root.Clean(1);
////	writefln(xml.m_root.getPath("personnel/persong/name/family").m_value);
//	xml.Save("sss.xml");
//	delete xml;
//}

//void main() {
//	XML xtmp = new XML;
//	XMLnode root = xtmp.m_root.getChildEx("config", "default value");
//	XMLnode child = root.addNode("customtools", null);
//	for(int i=0; i<4; ++i){
//		XMLnode entry = child.addNode("tool", null);
//		entry.addAttrib("name", "explorer");
//		entry.addAttrib("cmd", "ShellExcute explorer %j");
//	}
//	xtmp.Save("macros.xml");
//}

template TArray(_type)
{
	int Sort(inout _type[] ar,int function(_type a,_type b) compareFunc)
	{
		if(!ar.length) return 0;
		_type tmp;
		byte notdone=1;
		int c=0,c2=0;
		for(;notdone;)
		{
			notdone=0;
			for(c=ar.length-1;c>0;c=c2)
			{
				c2=c-1;
				if(compareFunc(ar[c],ar[c2])<0)
				{
					tmp=ar[c2];
					ar[c2]=ar[c];
					ar[c]=tmp;
					notdone=1;
				}
			}
		}
		return 1;
	}

	int DeleteItems(inout _type[] ar,int index,int len=1)
	{
		if(index<0 || index>=ar.length || index+len>ar.length) return 0;
		if(len==0) return 1;
		if(len==ar.length)
		{
			ar.length=0;
			return 1;
		}
		ar=ar[0..index]~ar[index+len..ar.length];
		return 1;
	}
}

int icharCompare ( char[] x, char[] y )
{
    return std.string.tolower( x ) < std.string.tolower( y ) ? -1 : 0;
}