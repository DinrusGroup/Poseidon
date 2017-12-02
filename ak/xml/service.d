module ak.xml.service;

private import std.stream;
private import std.string;
private import ak.xml.coreXML;
//private import std.stdio;

extern (C) int strtol(char *,char **,int);

const int XML_STAG_NORMAL		=1;
const int XML_STAG_EMPTY		=2;
const int XML_STAG_PI			=3;
const int XML_STAG_CDATA		=4;
const int XML_STAG_COMMENT		=5;
const int XML_STAG_DOCTYPE		=6;
const int XML_STAG_ENTITY		=7;
const int XML_STAG_ELEMENT		=8;
const int XML_STAG_ATTLIST		=9;
const int XML_STAG_NOTATION		=10;
const int XML_STAG_IGNORE		=11;
const int XML_STAG_INCLUDE		=12;

const int XML_ENTITY_PE			=1;
const int XML_ENTITY_SYSTEM		=2;
const int XML_ENTITY_PUBLIC		=4;
const int XML_ENTITY_NDATA		=8;

int xml_iswhitespace(char r)
{
	if(r==0x20 || r==0x9 || r==0xD || r==0xA) return 1;
	else return 0;
}

int xml_isnamestartchar(char r)
{
	if((r>='a' && r<='z') || (r>='A' && r<='Z') || r=='_' || r==':' || (r>=0xC1 && r<=0xD6) || (r>=0xD8 && r<=0xF6) || (r>=0xF8 && r<=0x2FF) || (r>=0x370 && r<=0x37D) || (r>=0x37F && r<=0x1FFF) || (r>=0x200C && r<=0x200D) || (r>=0x2070 && r<=0x218F) || (r>=0x2C00 && r<=0x2FEF) || (r>=0x3001 && r<=0xD7FF) || (r>=0xF900 && r<=0xFDCF) || (r>=0xFDF0 && r<=0xFFFD) || (r>=0x10000 && r<=0xEFFFF)) return 1;
	else return 0;
}

int xml_isnamechar(char r)
{
	if(xml_isnamestartchar(r) || (r>='0' && r<='9') || r=='.' || r=='-' || r==0xB7 || (r>=0x0300 && r<=0x036F) || (r>=0x203F && r<=0x2040)) return 1;
	else return 0;
}

int xml_iseq(char r)
{
	if(r=='=') return 1;
	else return 0;
}

int xml_read_whitespace(char[] buffer)
{
	int c;
	for(;c<buffer.length;c++)
	{
		if(xml_iswhitespace(buffer[c])) continue;
		else break;
	}
	return ((c>0)?c:-1);
}

int xml_read_name(char[] buffer,inout char[] ret)
{
	if(buffer.length==0) return -1;
	if(!xml_isnamestartchar(buffer[0])) return -1;
	uint c=1;
	for(;c<buffer.length;c++)
	{
		if(xml_isnamechar(buffer[c])) continue;
		else break;
	}
	ret=buffer[0..c];
	return ret.length;
}

char[] xml_read_quoted(char[] buffer)
{
	if(!buffer.length) return null;
	if(buffer[0]!='\'' && buffer[0]!='"') return null;
	char[] ret;
	uint c=1;
	for(;c<buffer.length;c++) if(buffer[c]==buffer[0]) break;
	if(c<2) return ret;
	ret.length=c-1;
	ret[]=buffer[1..c];
	return ret;
}

int xml_read_attributes(XML parent,char[] buffer,inout XMLattrib[] ret)
{
	static int read_attribute(XML parent,char[] buffer,inout XMLattrib ret)
	{
		static int read_eq(char[] buffer)
		{
			int ret=xml_read_whitespace(buffer);
			if(ret<0) ret=0;
			if(xml_iseq(buffer[ret]))
			{
				int ret2=xml_read_whitespace(buffer[ret+1..buffer.length]);
				if(ret2>=0) return ret+ret2+1;
				else return ret+1;
			}
			return -1;
		}

		int len=-1,t;
		ret=new XMLattrib;
		if(xml_read_name(buffer,ret.m_name)>0)
		{
			int eq=read_eq(buffer[ret.m_name.length..buffer.length]);
			if(eq>0)
			{
				ret.m_value=xml_read_quoted(buffer[(ret.m_name.length+eq)..buffer.length]);
				int mv=ret.m_value.length;
				char[] smtp;
				xml_derefence(parent,null,ret.m_value,smtp);
				ret.m_value=smtp;
				len=ret.m_name.length+eq+mv+2;
			}
		}
		return len;
	}

	XMLattrib r;
	int len=0;
	int alllen=0;
	for(;;)
	{
		len=read_attribute(parent,buffer[alllen..buffer.length],r);
		if(len>=0)
		{
			alllen+=len;
			len=xml_read_whitespace(buffer[alllen..buffer.length]);
			if(len>=0) alllen+=len;
			ret~=r;
		}
		else
		{
			if(alllen==0) alllen=-1;
			break;
		}
	}
	return alllen;
}

int xml_find_notquoted(char[] buffer,char[] str)
{
	int ppp=0,lastshit=0,pp2=0,pp3=0,ppm=0,fl=0,end=0;
	for(;;)
	{
		ppp=find(buffer[lastshit..buffer.length],str);
		if(ppp<0) return -1;
		ppm=lastshit;
		end=lastshit+ppp;
		for(;;)
		{
			pp2=find(buffer[ppm..buffer.length],'"');
			pp3=find(buffer[ppm..buffer.length],'\'');
			if((pp2<0 || pp2+ppm>end) && (pp3<0 || pp3+ppm>end))
			{
				fl=1;
				lastshit=end;
				break;
			}
			else if(pp2<pp3 || pp3<0 || pp3+ppm>end)
			{
				ppm+=pp2+1;
				pp2=find(buffer[ppm..buffer.length],'"');
				if(pp2<0) return -1;
				ppm+=pp2+1;
				if(ppm>=end)
				{
					lastshit=ppm;
					break;
				}
			}
			else if(pp3<pp2 || pp2<0 || pp2+ppm>end)
			{
				ppm+=pp3+1;
				pp3=find(buffer[ppm..buffer.length],'\'');
				if(pp3<0) return -1;
				ppm+=pp3+1;
				if(ppm>=end)
				{
					lastshit=ppm;
					break;
				}
			}
		}
		if(fl) break;
	}
	return lastshit;
}

int xml_read_stag(char[] buffer,inout char[] ret,inout int type)
{
	type=0;
	if(buffer.length<2) return -1;
	if(buffer[0]=='<')
	{
		int ret2=find(buffer,'>');
		if(ret2<1) return -1;
		if(buffer[1]=='!')
		{
			int indent_comment(char[] buffer)
			{
				if(buffer.length<5) return 0;
				if(buffer[0..2]!="--") return 0;
				int ret=find(buffer[2..buffer.length],"-->");
				if(ret<0) return 0;
				else
				{
					type=XML_STAG_COMMENT;
					return ret+6;
				}
			}

			int indent_doctype(char[] buffer)
			{
				if(buffer.length<8) return 0;
				if(buffer[0..7]!="DOCTYPE") return 0;
				int lastshit=7;
				int ppp=xml_find_notquoted(buffer[lastshit..buffer.length],"[");
				if(ppp>=0)
				{
					lastshit+=ppp;
					ppp=xml_find_notquoted(buffer[lastshit..buffer.length],"]");
					if(ppp>=0) lastshit+=ppp;
					else return 0;
				}
				int ret=xml_find_notquoted(buffer[lastshit..buffer.length],">");
				if(ret<0) return 0;
				else
				{
					type=XML_STAG_DOCTYPE;
					return ret+lastshit+2;
				}
			}

			int indent_cdata(char[] buffer)
			{
				if(buffer.length<10) return 0;
				if(buffer[0..7]!="[CDATA[") return 0;
				int ret=find(buffer[8..buffer.length],"]]>");
				if(ret<0) return 0;
				else
				{
					type=XML_STAG_CDATA;
					return ret+12;
				}
			}

			int indent_entity(char[] buffer)
			{
				if(buffer.length<7) return 0;
				if(buffer[0..6]!="ENTITY") return 0;
				int ret=xml_find_notquoted(buffer[7..buffer.length],">");
				if(ret<0) return 0;
				else
				{
					type=XML_STAG_ENTITY;
					return ret+9;
				}
			}

			ret2=indent_comment(buffer[2..buffer.length]);
			if(!ret2) ret2=indent_doctype(buffer[2..buffer.length]);
			if(!ret2) ret2=indent_cdata(buffer[2..buffer.length]);
			if(!ret2) ret2=indent_entity(buffer[2..buffer.length]);
			/*if(!ret2) ret2=indent_element(buffer[2..buffer.length]);
			if(!ret2) ret2=indent_attlist(buffer[2..buffer.length]);
			if(!re2t) ret2=indent_notation(buffer[2..buffer.length]);
			if(!ret2) ret2=indent_ignore(buffer[2..buffer.length]);
			if(!ret2) ret2=indent_include(buffer[2..buffer.length]);*/
			if(!ret2) return -1;

			/*7<!---->
			9<!ENTITY>
			10<!DOCTYPE>
			10<!ELEMENT>
			10<!ATTLIST>
			11<!NOTATION>
			12<![CDATA[]]>
			13<![IGNORE[]]>
			14<![INCLUDE[]]>*/
		}
		else if(buffer[1]=='?')
		{
			if(buffer[ret2-1]=='?') type=XML_STAG_PI;
			else return -1;
		}
		else if(buffer[ret2-1]=='/') type=XML_STAG_EMPTY;
		else type=XML_STAG_NORMAL;
		ret=buffer[0..ret2+1];
		return ret2+1;
	}
	return -1;
}

int xml_read_etag(char[] buffer,char[] name,inout char[] ret)
{
	static int search_etag(char[] buffer,char[] name,inout char[] ret)
	{
		int l=0,l2=0,t=0,start=0;
		for(;start<buffer.length;)
		{
			l=find(buffer[start..buffer.length],name);
			if(l<0) return -1;
			else
			{
				start+=l;
				t=start+name.length;
				if(t>=buffer.length) return -1;
				if(buffer[t]=='>') l2=t+1;
				else 
				{
					l2=xml_read_whitespace(buffer[t..buffer.length]);
					if(l2<0) l2=0;
					if(buffer[t+l2]=='>') l2=t+l2+1;
					else
					{
						start=t+l2;
						continue;
					}
				}
				ret=buffer[start..l2];
				return start;
			}
		}
		return -1;
	}

	static int search_stag(char[] buffer,char[] name,inout char[] ret)
	{
		int l=0,l2=0,t=0,start=0;
		for(;start<buffer.length;)
		{
			l=find(buffer[start..buffer.length],name);
			if(l<0) return -1;
			start+=l;
			t=start+name.length;
			l=xml_read_whitespace(buffer[t..buffer.length]);
			if(l<0) l=0;
			if(l==0) {if(buffer[t+l]=='>') {l2=t+l; break;} else {start=t;continue;}}
			t+=l;
			l2=find(buffer[t..buffer.length],'>');
			if(l2<0) return -1;
			else if(buffer[t+l2-1]=='/')
			{
				start=t+l2;
				continue;
			}
			else
			{
				l2=t+l2;
				break;
			}
		}
		ret=buffer[start..l2+1];
		return start;
	}

	char[] name2="</"~name;
	char[] name1="<"~name;
	char[] rest1,rest2,m1,m2;
	rest2=buffer;
	rest1=buffer;
	int l1=0,l2=0;
	int ret2=0,ret1=0;
	for(;;)
	{
		l2=search_etag(rest2,name2,m2);
		if(l2>=0)
		{
			ret2+=l2;
			l1=search_stag(rest1,name1,m1);
			if(l1>=0)
			{
				ret1+=l1;
				if(ret1>ret2) break;
				else
				{
					ret2+=m2.length;
					ret1+=m1.length;
					rest1=rest1[l1+m1.length..rest1.length];
					rest2=rest2[l2+m2.length..rest2.length];
				}
			}
			else break;
		}
		else return -1;
	}
	ret=buffer[0..ret2];
	return m2.length;
}

int xml_read_unknown(XML parent,char[] buffer,inout XMLnode ret)
{
	int l=0;
	uint start=0;
	if(!ret) ret=new XMLnode;
	for(;;)
	{
		l=find(buffer[start..buffer.length],'<');
		if(l<0) l=buffer.length-start;
		if(l>0)
		{
			ret.m_value~=buffer[start..start+l];
			start+=l;
		}
		if(start<buffer.length)
		{
			XMLnode tmp;
			int type=0;
			l=xml_read_element(parent,buffer[start..buffer.length],tmp,type);
			if(l>=0)
			{
				if(tmp)
				{
					if((type==XML_STAG_NORMAL || type==XML_STAG_EMPTY))
					{
						tmp.m_parent=ret;
						char[] smtp;
						xml_derefence(parent,null,tmp.m_value,smtp);
						tmp.m_value=smtp;
						ret.m_children~=tmp;
					}
					else if(type==XML_STAG_CDATA && tmp.m_value.length) ret.m_value~=tmp.m_value;
				}
				start+=l;
			}
			else return -1;
		}
		else break;
	}
	return 1;
}

int xml_parse_entity(XML parent,char[] buffer)
{
	static int read_entity_value(char[] buffer,inout char[] ret)
	{
		ret=xml_read_quoted(buffer);
		if(!ret) return -1;
		else return ret.length+2;
	}

	static int read_entity_exteranlid(char[] buffer,inout XMLentity ntity)
	{
		static int read_system(char[] buffer,inout XMLentity ntity)
		{
			int r=-1;
			if(buffer.length<9) return -1;
			if(buffer[0..6]=="SYSTEM")
			{
				int t=xml_read_whitespace(buffer[6..buffer.length]);
				if(t<0) return -1;
				t+=6;
				ntity.m_systemliteral=xml_read_quoted(buffer[t..buffer.length]);
				if(!ntity.m_systemliteral) return -1;
				ntity.m_flags|=XML_ENTITY_SYSTEM;
				r=t+ntity.m_systemliteral.length+2;
			}
			return r;
		}

		if(buffer.length<8) return -1;
		int t;
		if(buffer[0..6]=="SYSTEM") return read_system(buffer,ntity);
		else if(buffer[0..6]=="PUBLIC")
		{
			t=xml_read_whitespace(buffer[6..buffer.length]);
			if(t<0) return -1;
			t+=6;
			ntity.m_pubidliteral=xml_read_quoted(buffer[t..buffer.length]);
			if(!ntity.m_pubidliteral) return -1;
			t+=ntity.m_pubidliteral.length+2;
			int t2=xml_read_whitespace(buffer[t..buffer.length]);
			if(t2<0) return -1;
			t+=t2;
			ntity.m_systemliteral=xml_read_quoted(buffer[t..buffer.length]);
			if(!ntity.m_systemliteral) return -1;
			ntity.m_flags|=XML_ENTITY_PUBLIC;
			return t+ntity.m_systemliteral.length+2;
		}
		return -1;
	}

	static int read_entity_ndata(char[] buffer,inout XMLentity ntity)
	{
		if(buffer.length<8) return 0;
		int t=xml_read_whitespace(buffer);
		if(t<0) return 0;
		int t6=t+5;
		if(t6>=buffer.length) return 0;
		if(buffer[t..t6]!="NDATA") return 0;
		t=xml_read_whitespace(buffer[t6..buffer.length]);
		if(t<0) return -1;
		t+=t6;
		if(xml_read_name(buffer[t..buffer.length],ntity.m_ndata)<0) return -1;
		t+=ntity.m_ndata.length;
		ntity.m_flags|=XML_ENTITY_NDATA;
		return t+ntity.m_ndata.length;
	}

	static int read_entitydef(char[] buffer,inout XMLentity ntity)
	{
		int ret=read_entity_value(buffer,ntity.m_ogvalue);
		if(ret<0)
		{
			ret=read_entity_exteranlid(buffer,ntity);
			if(ret>=0)
			{
				int t=read_entity_ndata(buffer[ret..buffer.length],ntity);
				if(t>=0) ret+=t;
				else ret=-1;
			}
		}
		return ret;
	}

	static int read_pedef(char[] buffer,inout XMLentity ntity)
	{
		int ret=read_entity_value(buffer,ntity.m_ogvalue);
		if(ret<0) return read_entity_exteranlid(buffer,ntity);
		return ret;
	}

	if(buffer.length<9) return -1;
	char[] buff=buffer[8..buffer.length-1];
	if(!buff.length) return -1;
	XMLentity entity=new XMLentity;
	int t=xml_read_whitespace(buff),s;
	if(t<0) return -1;
	s+=t;
	if(buff[s]=='%')
	{
		entity.m_flags|=XML_ENTITY_PE;
		s++;
		if(s>=buff.length) return -1;
		t=xml_read_whitespace(buff[s..buff.length]);
		if(t<0) return -1;
		s+=t;
	}
	if(xml_read_name(buff[s..buff.length],entity.m_name)<0) return -1;
	s+=entity.m_name.length;
	t=xml_read_whitespace(buff[s..buff.length]);
	if(t<0) return -1;
	s+=t;
	if(entity.m_flags&XML_ENTITY_PE) t=read_pedef(buff[s..buff.length],entity);
	else t=read_entitydef(buff[s..buff.length],entity);
	if(t<0) return -1;
	if(!(entity.m_flags&XML_ENTITY_PE)) if(xml_derefence(parent,entity.m_name,entity.m_ogvalue,entity.m_value)<0) return -1;
	parent.m_entities[entity.m_name]=entity;
	parent.m_entitiesorder~=entity.m_name;
	return 1;
}

int xml_parse_pi(XML parent,char[] buffer)
{
	if(buffer.length<5) return -1;
	int end=buffer.length-2;
	char[] name;
	if(xml_read_name(buffer[2..end],name)<0) return -1;
	int s=2+name.length;
	int l=xml_read_whitespace(buffer[s..end]);
	if(l<0) return -1;
	s+=l;
	char[] data=buffer[s..end];
	if(l==0 && data.length) return -1;
	return parent.OnPI(name,data);
}

int xml_read_element(XML parent,char[] buffer,inout XMLnode ret,inout int type)
{
	int total=0;
	char[] c;
	int l=xml_read_stag(buffer,c,type);
	if(l<=0) return -1;
	total+=l;
	if(type==XML_STAG_CDATA || type==XML_STAG_NORMAL || type==XML_STAG_EMPTY) if(!ret) ret=new XMLnode;
	if(type==XML_STAG_CDATA)
	{
		ret.m_value~=c;
		return total;
	}
	else if(type!=XML_STAG_PI && type!=XML_STAG_ENTITY && type>2)
	{
		parent.OnExclamation(c,type);
		return total;
	}
	else if(type==XML_STAG_PI)
	{
		if(xml_parse_pi(parent,c)<0) return -1;
		return total;
	}
	else if(type==XML_STAG_ENTITY)
	{
		if(xml_parse_entity(parent,c)<0) return -1;
		return total;
	}
	if(xml_read_name(c[1..c.length],ret.m_name)<0) return -1;
	l=xml_read_whitespace(c[ret.m_name.length+1..c.length]);
	if(l>0) l=xml_read_attributes(parent,c[l+ret.m_name.length+1..c.length],ret.m_attributes);
	if(type!=XML_STAG_EMPTY)
	{
		char[] content;
		l=xml_read_etag(buffer[c.length..buffer.length],ret.m_name,content);
		if(l>=0)
		{
			total+=l;
			if(content.length)
			{
				total+=content.length;
				l=xml_read_unknown(parent,content,ret);
				if(l<0) return -1;
			}
		}
		else return -1;
	}
	return total;
}

int xml_derefence(XML parent,char[] parentent,char[] buffer,inout char[] ret)
{
	int s,r,r2,sr;
	char[] Ref,deref;
	for(;;)
	{
		if(s>=buffer.length) break;
		r=find(buffer[s..buffer.length],'&');
		if(r<0)
		{
			ret~=buffer[s..buffer.length];
			break;
		}
		sr=s+r;
		r2=find(buffer[sr..buffer.length],';');
		if(r2<1) return -1;
		ret~=buffer[s..sr];
		s=sr+r2;
		sr++;
		Ref=buffer[sr..s];
		s++;
		//
		if(Ref[0]=='#')
		{
			deref=null;
			for(int chr;;)
			{
				if(Ref.length<2) return -1;
				if(Ref[1]=='x')
				{
					if(Ref.length<3) return -1;
					char[] refText = Ref[2..Ref.length];
					chr=strtol(refText.ptr,null,16);
				}
				else
				{
					char[] refText = Ref[1..Ref.length];
					chr=strtol(refText.ptr,null,10);
				}
				deref~=cast(char)chr;
				if(s>=buffer.length) break;
				if(buffer[s]=='#')
				{
					r=find(buffer[s..buffer.length],';');
					if(r>0)
					{
						sr=s+r;
						Ref=buffer[s..sr];
						s=sr+1;
					}
				}
				else break;
			}
		}
		else
		{
			if(parentent.length && deref==parentent) return -1;
			XMLentity *e=Ref in parent.m_entities;
			if(!e) return -1;
			deref=e.m_value;
		}
		ret~=deref;
	}
	return ret.length;
}

char[] xml_enreference(XML parent,char[] buffer)
{
	char[] ret=replace(buffer,"&","&amp;");
	ret=replace(ret,"<","&lt;");
	ret=replace(ret,">","&gt;");
	ret=replace(ret,"'","&apos;");
	return replace(ret,"\"","&quot;");
}