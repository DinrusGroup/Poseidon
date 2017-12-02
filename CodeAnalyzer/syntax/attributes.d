module CodeAnalyzer.syntax.attributes;
import CodeAnalyzer.syntax.core;

class AttributeDeclaration : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        AttributeDeclaration
            Attribute DeclDefBlock
            Attribute :
     */
    public void parse()
    {
		// For D 2.0 const() or invariant() or immutable()
		if( compilerVersion > 1 ) // D 2.0
			if( ts.next( TOK.Tconst, TOK.Openparen ) || ts.next( TOK.Tinvariant, TOK.Openparen ) ||
						ts.next( TOK.Timmutable, TOK.Openparen ) )
			{
				parseR!(Declaration);
				return;
			}
		
        parseR!(Attribute);
        if( ts.next( TOK.Colon ) )
        {
            parseTerminal();
			bAttributeDeclarationColon = true;
            return;
        }
        else 
        {
            parseR!(DeclDefBlock);
        }
    }
}

class Attribute : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Attribute:
            ProtectionAttribute
            StorageClass
            AlignAttribute
            LinkageAttribute
     */
    public void parse()
    {
        ParseDelegate attrib;
        TOK t = ts.peek().type;
        if( handle.handles(t) )
        {
            attrib = handle[t];
            parseWith( attrib );
        }
        else
        {
            throw new ParserException( ts, "Can't Parse Attribute" );
        }
    }
}

class ProtectionAttribute : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ProtectionAttribute:
            public
            private
            protected
            export
            package
     */
    public void parse()
    {
        if( !prot(ts) )
        {
            throw new ParserException(ts, "Expected a protection attribute");
        }
        parseTerminal();
    }

    bool prot(TokenScanner ts)
    {
        switch( ts.peek().type )
        {
			// Kuan Hsu
			case TOK.Tpublic:
				globalProt = globalProt & ( D_Attribute - D_Prot ) | D_Public;
				return true;

			case TOK.Tprivate:
				globalProt = globalProt & ( D_Attribute - D_Prot ) | D_Private;
				return true;

			case TOK.Tprotected:
				globalProt = globalProt & ( D_Attribute - D_Prot ) | D_Protected;
				return true;

			case TOK.Tpackage:
				globalProt = globalProt & ( D_Attribute - D_Prot ) | D_Package;
				return true;
				
			case TOK.Texport:
				globalProt = globalProt & ( D_Attribute - D_Prot ) | D_Export;
				return true;

						
            //case TOK.Tpublic, TOK.Tprivate, TOK.Tprotected, TOK.Tpackage, TOK.Texport: return true;
			// End of Kuan Hsu
            default: return false;
        }
    }
}

class StorageClass : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        StorageClass:
            deprecated
            override
            abstract
            const
            auto
            static
            final
            scope
			invariant

			// D2.0
			pure
			nothrow
			ref
			__gshared
     */
    public void parse()
    {
        assert( stc(ts) );
        parseTerminal();
    }
    
    bool stc(TokenScanner ts)
    {
        return StorageClass.isStorageClass( ts.peek().type );
    }

    public static bool isStorageClass( TOK t )
    {
        switch( t )
        {
			// Kuan Hsu
			case TOK.Tdeprecated:
				globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Deprecated;
				return true;

			case TOK.Toverride:
				globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Override;
				return true;

			case TOK.Tabstract:
				globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Abstract;
				return true;

			case TOK.Tconst:
				globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Const;
				return true;
				
			case TOK.Tauto:
				globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Auto;
				return true;

			case TOK.Tstatic:
				globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Static;
				return true;

			case TOK.Tfinal:
				globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Final;
				return true;

			case TOK.Tsynchronized:
				//globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Synchronized;
				return true;

			case TOK.Tscope:
				globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Scope;
				return true;

			case TOK.Tinvariant:
				globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Invariant;
				return true;

			case TOK.Tpure:
				if( compilerVersion > 1 ) // D 2.0
				{
					globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Pure;
					return true;
				}
				else
					return false;

			case TOK.Tnothrow:
				if( compilerVersion > 1 ) // D 2.0
				{
					globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Nothrow;
					return true;
				}
				else
					return false;

			case TOK.Tshared:
				if( compilerVersion > 1 ) // D 2.0
				{
					globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Shared;
					return true;
				}
				else
					return false;
					
			case TOK.T__gshared:
				if( compilerVersion > 1 ) // D 2.0
				{
					globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Gshared;
					return true;
				}
				else
					return false;
					

			case TOK.Tref:
				if( compilerVersion > 1 ) // D 2.0
				{
					globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Ref;
					return true;
				}
				else
					return false;

			case TOK.Timmutable:
				if( compilerVersion > 1 ) // D 2.0
				{
					globalProt = globalProt & ( D_Attribute - D_Storage ) | D_Immutable;
					return true;
				}
				else
					return false;
			// End of Kuan Hsu

			/*
            case TOK.Tdeprecated, TOK.Toverride, TOK.Tabstract, TOK.Tconst,
            TOK.Tauto, TOK.Tstatic, TOK.Tfinal, TOK.Tsynchronized, TOK.Tscope: return true;
			*/
            default: return false;
        }
    }
}

class AlignAttribute : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        AlignAttribute:
            align
            align( Number )
     */
    public void parse()
    {
        parseTerminal( TOK.Talign );
        if( ts.next( TOK.Openparen ) )
        {
            parseTerminal();
            parseR!(Number);
            parseTerminal( TOK.Closeparen );
        }
		globalProt = globalProt | D_Align; // Kuan Hsu
    }
}

class LinkageAttribute : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        LinkageAttribute:
            extern
            extern ( LinkageType )
     */
    public void parse()
    {
        parseTerminal( TOK.Textern );
        if( ts.next( TOK.Openparen ) )
        {
            parseTerminal();
            parseR!(LinkageType);
            parseTerminal( TOK.Closeparen );
        }
		globalProt = globalProt | D_Extern; // Kuan Hsu
    }
}

class LinkageType : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        LinkageType:
            C
            C++
            D
            Windows
            Pascal
     */
    public void parse()
    {
        parseR!(Identifier);
        if( ts.next( TOK.Tplusplus ) )
        {
            parseTerminal();
        }
    }
}

class Pragma : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Pragma:
            pragma ( Identifier )
            pragma ( Identifier , Expression )

     */
    public void parse()
    {
        parseTerminal( TOK.Tpragma );
        parseTerminal( TOK.Openparen );
        parseR!(Identifier);
        if( !ts.next( TOK.Closeparen ) )
        {
            parseTerminal( TOK.Comma );
            parseR!(Expression);
        }
        parseTerminal( TOK.Closeparen );
		globalProt = globalProt | D_Pragma; // Kuan Hsu
    }
}

private AttributeHandler handle;

static this()
{
    handle = new AttributeHandler;
}

class AttributeHandler : AbstractParseHandler
{
    public:
    this()
    {
        initializeHandler();
    }

    void initializeHandler()
    {
        assign!(ProtectionAttribute).toParse(TOK.Tpublic);
        assign!(ProtectionAttribute).toParse(TOK.Tprivate);
        assign!(ProtectionAttribute).toParse(TOK.Tprotected);
        assign!(ProtectionAttribute).toParse(TOK.Tpackage);
        assign!(ProtectionAttribute).toParse(TOK.Texport);
        assign!(LinkageAttribute).toParse(TOK.Textern);
        assign!(AlignAttribute).toParse(TOK.Talign);
        assign!(StorageClass).toParse(TOK.Tfinal);
        assign!(StorageClass).toParse(TOK.Tsynchronized);
        assign!(StorageClass).toParse(TOK.Tdeprecated);
        assign!(StorageClass).toParse(TOK.Toverride);
        assign!(StorageClass).toParse(TOK.Tabstract);
        assign!(StorageClass).toParse(TOK.Tconst);
        assign!(StorageClass).toParse(TOK.Tauto);
        assign!(StorageClass).toParse(TOK.Tscope);
		assign!(StorageClass).toParse(TOK.Tinvariant); // For D 2.0
		assign!(StorageClass).toParse(TOK.Tpure); // For D 2.0
		assign!(StorageClass).toParse(TOK.Tnothrow); // For D 2.0
		assign!(StorageClass).toParse(TOK.T__gshared); // For D 2.0
		assign!(StorageClass).toParse(TOK.Tshared); // For D 2.0
		assign!(StorageClass).toParse(TOK.Tref); // For D 2.0
		assign!(StorageClass).toParse(TOK.Timmutable); // For D 2.0
				 
        assign!(StorageClass).toParse(TOK.Tstatic);
        assign!(Pragma).toParse(TOK.Tpragma);
    }
}


