module CodeAnalyzer.syntax.decldefs;
import CodeAnalyzer.syntax.core;

class DeclDefs : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        DeclDefs:
            DeclDef
            DeclDef DeclDefs    
     */
    public void parse()
    {
        while( !ts.reachedEnd() && !ts.next( TOK.Closecurly ) )
        {
            parseR!(DeclDef);
        }
    }
}

class DeclDef : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        DeclDef:
            ImportDeclaration
            AttributeDeclaration
            ConditionalCompilation
            ConditionalSpecification
            StaticAssert
            StaticConstructor
            StaticDestructor
            ClassDeclaration
            StructDeclaration
            UnionDeclaration
            EnumDeclaration
            Invariant
            Unittest
            Declaration
            Constructor
            Destructor
            TemplateMixin
            Allocator
            Dellocator
            ;
     */
    public void parse()
    {
        ParseDelegate nextDeclDef;
        TOK t = ts.peek().type;

		int prevAttribute = globalProt; // Kuan Hsu

        if( handle.handles(t) )
        {
            nextDeclDef = handle[t];
            parseWith( nextDeclDef );
        }
        else if( ts.next( TOK.Semicolon ) )
        {
            parseTerminal();
        }
        else
        {
            throw new ParserException( ts, "Can't Parse DeclDef" );
        }

		// Kuan Hsu
		if( t == TOK.Tpublic || t == TOK.Tprivate || t == TOK.Tprotected || t == TOK.Tpackage || t == TOK.Texport ||
			t == TOK.Textern || t == TOK.Talign )
		{
			if( !bAttributeDeclarationColon ) globalProt = prevAttribute;
		}
		else
		{
			globalProt = prevAttribute;
			bAttributeDeclarationColon = false;
		}
		// End of Kuan Hsu
    }
}

class DeclDefBlock : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        DeclDefBlock:
            { }
            { DeclDefs }
            DeclDef    
     */
    public void parse()
    {
        if( ts.next(TOK.Opencurly) )
        {
            parseTerminal();
            if( !ts.next(TOK.Closecurly) )
            {
                parseR!(DeclDefs);
            }
            parseTerminal( TOK.Closecurly );
        }
        else
        {
            parseR!(DeclDef);
        }
    }
}

class StaticConstructor : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        StaticConstructor:
            static this () FunctionBody
     */
    public void parse()
    {
        parseTerminal( TOK.Tstatic );
        parseTerminal( TOK.Tthis );
        parseTerminal( TOK.Openparen );
        parseTerminal( TOK.Closeparen );
		activeNode = activeNode.addLeaf( globalProt, D_STATICCTOR, "this", null, ts.peek().lineNumber ); // Kuan Hsu

		// Kuan Hsu
		// EX: static this();
		if( ts.peek().type == TOK.Semicolon )
		{
			activeNode = activeNode.getRoot();
			parseTerminal( TOK.Semicolon );
			return;
		}
		// End of Kuan Hsu
		
        parseR!(FunctionBody);
		activeNode = activeNode.getRoot(); // Kuan Hsu
    }
}

class StaticDestructor : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        StaticDestructor:
            static ~ this () FunctionBody

     */
    public void parse()
    {
        parseTerminal( TOK.Tstatic );
        parseTerminal( TOK.Ttilde );
        parseTerminal( TOK.Tthis );
        parseTerminal( TOK.Openparen );
        parseTerminal( TOK.Closeparen );
		activeNode = activeNode.addLeaf( globalProt, D_STATICDTOR, "~this", null, ts.peek().lineNumber ); // Kuan Hsu

		// Kuan Hsu
		// EX: static ~this();
		if( ts.peek().type == TOK.Semicolon )
		{
			activeNode = activeNode.getRoot();
			parseTerminal( TOK.Semicolon );
			return;
		}
		// End of Kuan Hsu
		
        parseR!(FunctionBody);
		activeNode = activeNode.getRoot(); // Kuan Hsu
    }
}

class Unittest : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Unittest
            unittest FunctionBody
     */
    public void parse()
    {
        parseTerminal( TOK.Tunittest );
		activeNode = activeNode.addLeaf( globalProt, D_UNITTEST, "unittest", null, ts.peek().lineNumber ); // Kuan Hsu
        parseR!(FunctionBody);
		activeNode = activeNode.getRoot(); // Kuan Hsu
    }
}


class Invariant : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Invariant:
            invariant FunctionBody
     */
    public void parse()
    {
        parseTerminal( TOK.Tinvariant );
		if( compilerVersion > 1 )
		{
			parseTerminal( TOK.Openparen );
			parseTerminal( TOK.Closeparen );
		}
		else
		{
			if( ts.next( TOK.Openparen, TOK.Closeparen ) )
			{
				parseTerminal( TOK.Openparen );
				parseTerminal( TOK.Closeparen );
			}
		}
		
		activeNode = activeNode.addLeaf( globalProt, D_INVARIANT, "invariant", null, ts.peek().lineNumber ); // Kuan Hsu
        parseR!(FunctionBody);
		activeNode = activeNode.getRoot(); // Kuan Hsu
    }
}

class Typedef : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Typedef:
            typdef DeclDef
            alias DeclDef
     */
    public void parse()
    {
        assert( ts.next( TOK.Ttypedef ) || ts.next( TOK.Talias ) );
		tokenText = null; // Kuan Hsu
        parseTerminal();

		/**
		AliasThis:
			alias Identifier this;
		*/
		if( compilerVersion  > 1 ) // D 2.0
		{
			if( activeNode.DType & ( D_STRUCT | D_CLASS ) )
				if( ts.next( TOK.Identifier, TOK.Tthis ) )
				{
					parseTerminal( TOK.Identifier );
					parseTerminal( TOK.Tthis );
					return;
				}
		}		

		// Kuan Hsu
		int prevGlobalDType = globalDType;

		if( tokenText == "typedef" )
			activeNode =  activeNode.addLeaf( globalProt, D_TYPEDEF, null, null, ts.peek().lineNumber ); // Kuan Hsu
		else
			activeNode =  activeNode.addLeaf( globalProt, D_ALIAS, null, null, ts.peek().lineNumber ); // Kuan Hsu

		//if( tokenText == "typedef" ) globalDType = D_TYPEDEF;else globalDType = D_ALIAS;  // Kuan Hsu

		// End of Kuan Hsu

		if( compilerVersion  > 1 ) // D 2.0
		{
			if( ts.next( TOK.Tconst, TOK.Openparen ) || ts.next( TOK.Tinvariant, TOK.Openparen ) ||
						ts.next( TOK.Timmutable, TOK.Openparen ) )
			{
				parseR!(Declaration);
				globalDType = prevGlobalDType;  // Kuan Hsu
				activeNode = activeNode.getRoot(); // Kuan Hsu
				return;
			}
		}

        parseR!(DeclDef);
		globalDType = prevGlobalDType;  // Kuan Hsu
		activeNode = activeNode.getRoot(); // Kuan Hsu
    }
}

private DeclDefHandler handle;

static this()
{
    handle = new DeclDefHandler();
}

class DeclDefHandler : AbstractParseHandler
{
    this() { super(); }

    void initializeHandler()
    {
        assign!(ImportDeclaration).toParse(TOK.Timport);
        
        assign!(Declaration).toParse(TOK.Identifier);
        assign!(Declaration).toParse(TOK.Tdot);
        assign!(Declaration).toParse(TOK.Ttypeof);
        
        assign!(Typedef).toParse(TOK.Ttypedef);
        assign!(Typedef).toParse(TOK.Talias);
        
        assign!(EnumDeclaration).toParse(TOK.Tenum);
        assign!(ClassDeclaration).toParse(TOK.Tclass);
        assign!(InterfaceDeclaration).toParse(TOK.Tinterface);
        assign!(StructDeclaration).toParse(TOK.Tstruct);
        assign!(UnionDeclaration).toParse(TOK.Tunion);
		//PLEASE NOTE 
		//the handleAttributeDeclaration function, don't just 
		//put attributes here, maybe they need special handling
        assign!(AttributeDeclaration).toParse(TOK.Tpublic);
        assign!(AttributeDeclaration).toParse(TOK.Tprivate);
        assign!(AttributeDeclaration).toParse(TOK.Tprotected);
        assign!(AttributeDeclaration).toParse(TOK.Tpackage);
        assign!(AttributeDeclaration).toParse(TOK.Texport);
        assign!(AttributeDeclaration).toParse(TOK.Textern);
        assign!(AttributeDeclaration).toParse(TOK.Talign);
        assign!(Allocator).toParse(TOK.Tnew);
        assign!(Dellocator).toParse(TOK.Tdelete);
        assign!(Pragma).toParse(TOK.Tpragma);

        assign!(Invariant).toParse(TOK.Tinvariant);
        assign!(Unittest).toParse(TOK.Tunittest);

        assign!(Constructor).toParse(TOK.Tthis);
        assign!(Destructor).toParse(TOK.Ttilde);

        assign!(TemplateDeclaration).toParse(TOK.Ttemplate);
        assign!(TemplateMixin).toParse(TOK.Tmixin);

        handle[TOK.Tversion] = &handleVersionDebug;
        handle[TOK.Tdebug] = &handleVersionDebug;
        handle[TOK.Tstatic] = &handleStatic;
        handle[TOK.Tauto] = &handleAttributeDeclaration;
        		handle[TOK.Tscope] = &handleAttributeDeclaration;
        handle[TOK.Tconst] = &handleAttributeDeclaration;
        handle[TOK.Tabstract] = &handleAttributeDeclaration;
        handle[TOK.Toverride] = &handleAttributeDeclaration;
        handle[TOK.Tdeprecated] = &handleAttributeDeclaration;
        handle[TOK.Tfinal] = &handleAttributeDeclaration;
        handle[TOK.Tsynchronized] = &handleAttributeDeclaration;
		handle[TOK.Tinvariant] = &handleAttributeDeclaration;
		handle[TOK.Timmutable] = &handleAttributeDeclaration; // D 2.0
		handle[TOK.Tpure] = &handleAttributeDeclaration; // D 2.0	
		handle[TOK.Tnothrow] = &handleAttributeDeclaration; // D 2.0
		handle[TOK.T__gshared] = &handleAttributeDeclaration; // D 2.0
		handle[TOK.Tshared] = &handleAttributeDeclaration; // D 2.0
		handle[TOK.Tref] = &handleAttributeDeclaration; // D 2.0
    }
    
    ParseNode handleStatic( TokenScanner ts )
    {
        expect( ts, TOK.Tstatic );
        switch( ts.peektype(2) )
        {
            
            case TOK.Tif: return parseRuleT!( ConditionalCompilation ).using( ts );
            case TOK.Tassert: return parseRuleT!( StaticAssert ).using( ts );
            case TOK.Tthis: return parseRuleT!( StaticConstructor ).using( ts );
            case TOK.Ttilde: return parseRuleT!( StaticDestructor ).using( ts );
            default: return handleAttributeDeclaration( ts );
        }
    }
    
    ParseNode handleVersionDebug( TokenScanner ts )
    {
        switch( ts.peektype(2) )
        {
            case TOK.Tassign: return parseRuleT!( ConditionalSpecification ).using(ts);
            default: return parseRuleT!( ConditionalCompilation ).using(ts);
        }
    }

    ParseNode handleAttributeDeclaration( TokenScanner ts )
    {
		if( compilerVersion > 1 ) // D 2.0
		{
			if( ts.next( TOK.Tinvariant, TOK.Openparen, TOK.Closeparen, TOK.Opencurly ))
				return parseRuleT!( Invariant ).using(ts);
		}
		else
		{
			if( ts.next( TOK.Tinvariant, TOK.Openparen, TOK.Closeparen, TOK.Opencurly ))
			{
				return parseRuleT!( Invariant ).using(ts);
			}
			else if( ts.next( TOK.Tinvariant, TOK.Opencurly ))
			{
				return parseRuleT!( Invariant ).using(ts);
			}
		}
		
        if( AutoDeclaration.isAutoDeclaration(ts) )
        {
            return parseRuleT!( AutoDeclaration ).using(ts);
        }
        else
        {
            return parseRuleT!( AttributeDeclaration ).using(ts);
        }
    }
}