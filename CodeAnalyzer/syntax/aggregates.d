module CodeAnalyzer.syntax.aggregates;
import CodeAnalyzer.syntax.core;

class AggregateIdentifier : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        AggregateIdentifier:
            Identifier
            Identifier ( TemplateParameterList )
     */
    public void parse()
    {
        parseR!(Identifier);

		char[] ident = globalIdentifier = tokenText;	// Kuan Hsu
		
        if( ts.next( TOK.Openparen ) )
        {
            parseTerminal();
			globalParams = null; // Kuan Hsu
			
            parseR!(TemplateParameterList);
			activeNode = activeNode.addLeaf( globalProt, D_TEMPLATE, ident, null, ts.peek().lineNumber, globalParams, "c" ); // Kuan Hsu
			globalIdentifier = ident; // Kuan Hsu
			
            parseTerminal( TOK.Closeparen );
			bTemplateParameterList = true;
        }
		else
			bTemplateParameterList = false;
    }
}

class ClassDeclaration : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ClassDeclaration:
            class AggregateIdentifier ClassBody
            class AggregateIdentifier : BaseClassList ClassBody
     */
    public void parse()
    {
		int lineNum = ts.peek().lineNumber;
        parseTerminal( TOK.Tclass );
		
		tokenText = globalBaseClass = null; // Kuan Hsu
		
        parseR!(AggregateIdentifier);

		bool bClassTemplateDeclaration = bTemplateParameterList; // Kuan Hsu

        if( ts.next( TOK.Colon ) )
        {
            parseTerminal();
            parseR!(BaseClassList);
        }

		// Kuan Hsu
		int prevProt = globalProt;
		globalProt = 0;		
		activeNode = activeNode.addLeaf( globalProt, D_CLASS, globalIdentifier, null, lineNum, null, globalBaseClass );
		// End of Kuan Hsu

		// D 2.0
		if( compilerVersion > 1 && bClassTemplateDeclaration ) parseR!( TemplateConstraints );

		parseR!(ClassBody);

		// Kuan Hsu
		globalProt = prevProt;
		activeNode = activeNode.getRoot();
		if( bClassTemplateDeclaration ) activeNode = activeNode.getRoot();
		// End of Kuan Hsu
    }
}

class BaseClassList : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        BaseClassList:
            BaseClass
            BaseClass, BaseInterfaceList
     */
    public void parse()
    {
		tokenText = null; // Kuan Hsu
        parseR!(BaseClass);
		globalBaseClass ~= tokenText; // Kuan Hsu
		
        if( ts.next(TOK.Comma) )
        {
            parseTerminal();
			globalBaseClass ~= ","; // Kuan Hsu
            parseR!(BaseInterfaceList);
        }
    }
}

class BaseInterfaceList : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        BaseInterfaceList:
            BaseInterface
            BaseInterface, BaseInterfaces
     */
    public void parse()
    {
        while( true )
        {
			tokenText = null; // Kuan Hsu
            parseR!(BaseInterface);
			globalBaseClass ~= tokenText; // Kuan Hsu
			
            if( !ts.next(TOK.Comma) )
                break;
			else
				globalBaseClass ~= ","; // Kuan Hsu
            parseTerminal();
        }
    }
}

class BaseClass : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        BaseClass:
            IdentifierSequence
            Protection IdentifierSequence
     */
    public void parse()
    {
        if( nextprotection(ts) )
        {
            parseTerminal();
        }
        parseR!(IdentifierSequence);
    }

    bool nextprotection( TokenScanner ts )
    {
        switch( ts.peek().type )
        {
            case TOK.Tpublic, TOK.Tprivate, TOK.Tprotected, TOK.Tpackage: return true;
            default: return false;
        }
    }
}

class BaseInterface : BaseClass
{
    this(TokenScanner ts)
    {
        super(ts);
    }
}

class ClassBody : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ClassBody:
            { }
            { DeclDefs }
     */
    public void parse()
    {
        parseTerminal( TOK.Opencurly );
        if( !ts.next(TOK.Closecurly) )
        {
            parseR!(DeclDefs);
        }
        parseTerminal( TOK.Closecurly );
    }
}

class StructDeclaration : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        StructDeclaration:
            struct AggregateIdentifier StructBody
            struct AggregateIdentifier ;
            struct StructBody
     */
    public void parse()
    {
        parseTerminal( TOK.Tstruct );
		
		tokenText = null; // Kuan Hsu
		bool bClassTemplateDeclaration;  // Kuan Hsu
		
        if( ts.next( TOK.Identifier) )
        {
			globalIdentifier = tokenText;
            parseR!(AggregateIdentifier);
			bClassTemplateDeclaration = bTemplateParameterList; // Kuan Hsu
			
            if( ts.next( TOK.Semicolon ) )
            {
                parseTerminal();
                return;
            }
        }

		// Kuan Hsu
		int prevProt = globalProt;
		globalProt = 0;		
		activeNode = activeNode.addLeaf( globalProt, D_STRUCT, globalIdentifier, null, ts.peek().lineNumber );
		// End of Kuan Hsu

		if( compilerVersion > 1 && bClassTemplateDeclaration ) parseR!( TemplateConstraints );
		
        parseR!(StructBody);

		// Kuan Hsu
		globalProt = prevProt;
		activeNode = activeNode.getRoot();
		if( bClassTemplateDeclaration ) activeNode = activeNode.getRoot();
		// End of Kuan Hsu	
    }
}

class StructBody : ClassBody
{
    this(TokenScanner ts)
    {
        super(ts);
    }
}

class UnionDeclaration : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        UnionDeclaration:
            union Identifier UnionBody
            union Identifier ;
            union UnionBody
     */
    public void parse()
    {
        parseTerminal( TOK.Tunion );

		tokenText = null; // Kuan Hsu
		bool bClassTemplateDeclaration;  // Kuan Hsu		

		tokenText = null; // Kuan Hsu
		
        if( ts.next( TOK.Identifier) )
        {
            //parseR!(Identifier);
			globalIdentifier = tokenText;
            parseR!(AggregateIdentifier);
			bClassTemplateDeclaration = bTemplateParameterList; // Kuan Hsu
			
            if( ts.next( TOK.Semicolon ) )
            {
                parseTerminal();
                return;
            }
        }

		// Kuan Hsu
		int prevProt = globalProt;
		globalProt = 0;
		activeNode = activeNode.addLeaf( globalProt, D_UNION, globalIdentifier, null, ts.peek().lineNumber );
		// End of Kuan Hsu
		
		parseR!(UnionBody);

		// Kuan Hsu
		globalProt = prevProt;
		activeNode = activeNode.getRoot();
		if( bClassTemplateDeclaration ) activeNode = activeNode.getRoot();
		// End of Kuan Hsu
    }
}

class UnionBody : StructBody
{
    this(TokenScanner ts)
    {
        super(ts);
    }
}


class InterfaceDeclaration : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        InterfaceDeclaration:
            interface AggregateIdentifier InterfaceBody
            interface AggregateIdentifier : BaseInterfaceList InterfaceBody    
     */
    public void parse()
    {
        parseTerminal( TOK.Tinterface );

		tokenText = globalBaseClass = null; // Kuan Hsu
		
        parseR!(AggregateIdentifier);
		bool bClassTemplateDeclaration = bTemplateParameterList; // Kuan Hsu

        if( ts.next( TOK.Colon ) )
        {
            parseTerminal();
            parseR!(BaseInterfaceList);
        }

		// Kuan Hsu
		int prevProt = globalProt;
		globalProt = 0;
		activeNode = activeNode.addLeaf( globalProt, D_INTERFACE, globalIdentifier, null, ts.peek().lineNumber, null, globalBaseClass.length > 0 ? globalBaseClass[0..length - 2] : null );
		// End of Kuan Hsu
		
        parseR!(InterfaceBody);
		
		// Kuan Hsu
		globalProt = prevProt;
		activeNode = activeNode.getRoot();
		if( bClassTemplateDeclaration ) activeNode = activeNode.getRoot();
		// End of Kuan Hsu
    }
}

class InterfaceBody : ClassBody
{
    this(TokenScanner ts)
    {
        super(ts);
    }
}

class EnumDeclaration : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        EnumDeclaration:
            enum Identifier EnumBody
            enum EnumBody
            enum Identifier : EnumBaseType EnumBody
            enum : EnumBaseType EnumBody
     */
    public void parse()
    {
        parseTerminal( TOK.Tenum );

		// Kuan Hsu
		tokenText = globalBaseClass = globalIdentifier = null;
		char[] enumBaseTypeIdent;
		// End of Kuan Hsu

		if( compilerVersion > 1 ) // D 2.0
		{
			if( !ts.next( TOK.Identifier ) && !ts.next( TOK.Opencurly ) && !ts.next( TOK.Identifier, TOK.Colon ) &&
				!ts.next( TOK.Colon ) || ts.next( TOK.Identifier, TOK.Tassign ) )
			{
				activeNode = activeNode.addLeaf( globalProt, D_ENUM, "-anonymous-", null, ts.peek().lineNumber );
				parseR!(EnumMember);
				activeNode = activeNode.getRoot();
				if( ts.next( TOK.Semicolon ) ) parseTerminal( TOK.Semicolon );
				return;
			}
		}
		else
		{
			if( !ts.next( TOK.Identifier, TOK.Opencurly ) && !ts.next( TOK.Opencurly ) && !ts.next( TOK.Identifier, TOK.Colon ) &&
				!ts.next( TOK.Colon ) )
			{
				activeNode = activeNode.addLeaf( globalProt, D_ENUM, "-anonymous-", null, ts.peek().lineNumber );
				parseR!(EnumMember);
				// Kuan Hsu
				//globalProt = prevProt;
				activeNode = activeNode.getRoot();
				// Kuan Hsu	
				return;
			}
		}

		
        if( ts.next( TOK.Identifier ) )
        {
            parseR!(Identifier);

			globalIdentifier = tokenText;	// Kuan Hsu
			tokenText = "";
        }
        if( ts.next( TOK.Colon ) )
        {
            parseTerminal();
            parseR!(EnumBaseType);
			enumBaseTypeIdent = tokenText;
        }

		// Kuan Hsu
		int prevProt = globalProt;
		globalProt = 0;
		activeNode = activeNode.addLeaf( globalProt, D_ENUM, ( globalIdentifier.length > 0 ? globalIdentifier : "-anonymous-" ), enumBaseTypeIdent, ts.peek().lineNumber, null, globalBaseClass.length > 0 ? globalBaseClass[0..length - 2] : null );
		// End of Kuan Hsu
		
        parseR!(EnumBody);

		// Kuan Hsu
		globalProt = prevProt;
		activeNode = activeNode.getRoot();
		// Kuan Hsu
    }
}

class EnumBaseType : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        EnumBaseType:
            IdentifierSequence
     */
    public void parse()
    {
		tokenText = null; // Kuan Hsu
        parseR!(IdentifierSequence);
		globalBaseClass ~= tokenText; // Kuan Hsu
    }
}

class EnumBody : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        EnumBody:
            ;
            { EnumMembers }
     */
    public void parse()
    {
        if( ts.next( TOK.Opencurly ) )
        {
            parseTerminal();
            parseR!(EnumMembers);
            parseTerminal( TOK.Closecurly );
        }
		else
		{
			if( compilerVersion > 1 )
			{
				parseR!(EnumMembers);
				if( ts.next( TOK.Semicolon ) ) parseTerminal( TOK.Semicolon );
			}
		}
    }
}

class EnumMembers : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        EnumMembers:
            EnumMember
            EnumMember ,
            EnumMember , EnumMembers
     */
    public void parse()
    {
        while( true )
        {
            parseR!(EnumMember);
            if( !ts.next( TOK.Comma ) )
                break;
            parseTerminal();
            if( !ts.next( TOK.Identifier ) )
                break;
        }
    }
}

class EnumMember : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        EnumMember:
            Identifier
            Identifier = AssignExpression
			Type Identifier = AssignExpression // D2.0
     */
    public void parse()
    {
		tokenText = null; // Kuan Hsu

		parseR!(Type);
		
		char[] type = tokenText;

		if( ts.next( TOK.Identifier ) )
		{
			tokenText = null;
			parseR!(Identifier);
		}
		else
		{
			tokenText = type;
			type = null;
		}
        
		activeNode.addLeaf( globalProt, D_ENUMMEMBER, tokenText, type, ts.peek().lineNumber ); // Kuan Hsu
		
        if( ts.next( TOK.Tassign ) )
        {
            parseTerminal();
            parseR!(AssignExpression);
        }
    }
}