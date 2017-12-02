module CodeAnalyzer.syntax.templates; 
import CodeAnalyzer.syntax.core;

class TemplateDeclaration : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateDeclaration:
            template TemplateIdentifier TemplateParameters DeclDefBlock
     */
    public void parse()
    {
        parseTerminal( TOK.Ttemplate );
		parseR!(TemplateIdentifier);

		char[] ident = globalIdentifier; // Kuan Hsu
		
		parseR!(TemplateParameters); 

		activeNode = activeNode.addLeaf( globalProt, D_TEMPLATE, ident, null, ts.peek().lineNumber, globalParams ); // Kuan Hsu
		globalParams = null; // Kuan Hsu
		globalIdentifier = ident; // Kuan Hsu
		
        parseR!(DeclDefBlock);

		// check if Implicit Template
		// Kuan Hsu
		if( activeNode.getLeafCount() == 1 )
			if( activeNode.getLeaf(0).identifier == activeNode.identifier )
			{
				if( activeNode.getLeaf(0).DType & ( D_CLASS | D_STRUCT | D_UNION | D_INTERFACE ) )
					activeNode.baseClass = "c";
				else
					activeNode.baseClass = "i";
			}
			
		activeNode = activeNode.getRoot();
		// End of Kuan Hsu
    }
}

class TemplateParameters : ParseRule
{
    public  this(TokenScanner ts) { super(ts); }

    /**
        TemplateParameters:
            ( TemplateParmaterList )
            ( )
     */
    public void parse()
    {
		globalParams = null; // Kuan Hsu
		
        parseTerminal( TOK.Openparen );
        if( !ts.next( TOK.Closeparen ) )
        {
            parseR!(TemplateParameterList);
        }
        parseTerminal( TOK.Closeparen );
		parseR!( TemplateConstraints ); // D 2.0
    }

    
}

class TemplateIdentifier : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateIdentifier:
            Identifier
     */
    public void parse()
    {
		tokenText = null; // Kuan Hsu
       	parseR!(Identifier);
		globalIdentifier = tokenText; // Kuan Hsu
    }
}

class TemplateParameterList : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateParameterList
            TemplateParameter
            TemplateParameter , TemplateParameterList
     */
    public void parse()
    {
        while( true )
        {
			if( ts.next( TOK.Closeparen ) ) break;
			
            parseR!(TemplateParameter);
			
			// Kuan Hsu
            if( !ts.next( TOK.Comma ) )
				break;
			else
				globalParams ~= ", ";
			// End of Kuan Hsu
			
            //if( !ts.next( TOK.Comma ) ) break;
            parseTerminal();
        }
    }
}

// D2.0
class TemplateConstraints : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
		Constraint:
			if ( ConstraintExpression )

		ConstraintExpression:
			Expression
    */
	
    public void parse()
    {
		if( compilerVersion > 1 ) // D 2.0
			if( ts.next( TOK.Tif ) )
			{
				char[] prevParams = globalParams;
				//parseTerminal( TOK.Closeparen );
				parseTerminal( TOK.Tif );
				parseTerminal( TOK.Openparen );
				parseR!( Expression );
				parseTerminal( TOK.Closeparen );
				globalParams = prevParams;
			}
    }
}

class TemplateParameter : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateParameter:
            TemplateTypeParameter
            TemplateValueParameter
            TemplateAliasParameter
			TemplateTupleParameter

			// D 2.0
			TemplateThisParameter:
     */
    public void parse()
    {
        if( ts.next( TOK.Talias ) )
        {
			//globalParams ~= "alias ";
            parseR!(TemplateAliasParameter);
        }
		else if( ts.next( TOK.Tthis ) )
		{
			if( compilerVersion > 1 ) parseR!(TemplateTypeParameter);
		}
		else if( ts.next( TOK.Identifier, TOK.Tdotdotdot ) )
		{
			parseR!(TemplateTupleParameter);
		}		
        else if( ts.next( TOK.Identifier ) )
        {
            switch( ts.peektype(2) )
            {
                case TOK.Colon, TOK.Tassign, TOK.Comma, TOK.Closeparen:
                    parseR!(TemplateTypeParameter);
                    break;
                default:
                    parseR!(TemplateValueParameter);
                    break;
            }
        }
        else
        {
            parseR!(TemplateValueParameter);
        }
    }
}

class TemplateTypeParameter : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateTypeParameter:
            Identifier
            Identifier TemplateTypeParameterSpecialization
            Identifier TemplateTypeParameterDefault
            Identifier TemplateTypeParameterSpecialization TemplateTypeParameterDefault
     */
    public void parse()
    {
		tokenText = null; // Kuan Hsu
        parseR!(Identifier);
		globalParams ~= tokenText; // Kuan Hsu
		
        if( ts.next( TOK.Colon ) )
        {
            parseR!(TemplateTypeParameterSpecialization);
        }
        if( ts.next( TOK.Tassign ) )
        {
            parseR!(TemplateTypeParameterDefault);
        }
    }
}

class TemplateTypeParameterSpecialization : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateTypeParameterSpecialization:
             : Type
     */
    public void parse()
    {
        parseTerminal( TOK.Colon );
		globalParams ~= ":"; // Kuan Hsu
		tokenText = ""; // Kuan Hsu
        parseR!(Type);
		globalParams ~= globalTypeIdentifier; // Kuan Hsu
    }
}

class TemplateTypeParameterDefault : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateTypeParameterDefault:
             = Type
     */
    public void parse()
    {
        parseTerminal( TOK.Tassign );
		globalParams ~= "="; // Kuan Hsu
		tokenText = ""; // Kuan Hsu
        parseR!(Type);
		globalParams ~= globalTypeIdentifier; // Kuan Hsu
    }
}

class TemplateAliasParameter : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateAliasParameter:
            alias Identifier
            alias Identifier TemplateAliasParameterSpecialization
            alias Identifier TemplateAliasParameterDefault
            alias Identifier TemplateAliasParameterSpecialization TemplateAliasParameterDefault
     */
    public void parse()
    {
        parseTerminal( TOK.Talias );
		globalParams ~= "alias "; // Kuan Hsu

		tokenText = null; // Kuan Hsu
        parseR!(Identifier);
		globalParams ~= tokenText; // Kuan Hsu

        if( ts.next( TOK.Colon ) )
        {
            parseR!(TemplateAliasParameterSpecialization);
        }
        if( ts.next( TOK.Tassign ) )
        {
            parseR!(TemplateAliasParameterDefault);
        }
    }
}

class TemplateAliasParameterSpecialization : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateAliasParameterSpecialization:
            : Type
     */
    public void parse()
    {
        parseTerminal( TOK.Colon );
		globalParams ~= ":"; // Kuan Hsu
		tokenText = ""; // Kuan Hsu
        parseR!(Type);
		globalParams ~= globalTypeIdentifier; // Kuan Hsu
    }
}

class TemplateAliasParameterDefault : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateAliasParameterDefault:
            = Type
     */
    public void parse()
    {
        parseTerminal( TOK.Tassign );
		//globalParams ~= "="; // Kuan Hsu
		tokenText = ""; // Kuan Hsu
        //parseR!(Type); // ?????
		parseR!(AssignExpression);
		//globalParams ~= globalTypeIdentifier; // Kuan Hsu
    }
}

class TemplateValueParameter : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateValueParameter:
            Type Declarator
            Type Declarator TemplateValueParameterSpecialization
            Type Declarator TemplateValueParameterDefault
            Type Declarator TemplateValueParameterSpecialization TemplateValueParameterDefault
     */
    public void parse()
    {
		tokenText = ""; // Kuan Hsu
        parseR!(Type);
		globalParams ~= ( globalTypeIdentifier ~ " " ); // Kuan Hsu

		tokenText = ""; // Kuan Hsu
        parseR!(Declarator);
		globalParams ~= globalIdentifier; // Kuan Hsu
		
        if( ts.next( TOK.Colon ) )
        {
            parseR!(TemplateValueParameterSpecialization);
        }
        if( ts.next( TOK.Tassign ) )
        {
            parseR!(TemplateValueParameterDefault);
        }
    }
}

class TemplateValueParameterSpecialization : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateValueParameterSpecialization:
             : ConditionalExpression
     */
    public void parse()
    {
        parseTerminal( TOK.Colon );
		globalParams ~= ":"; // Kuan Hsu

		tokenText = null; // Kuan Hsu
        parseR!(ConditionalExpression);
		globalParams ~= tokenText; // Kuan Hsu
		
    }
}

class TemplateValueParameterDefault : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateValueParameterDefault:
             = ConditionalExpression
     */
    public void parse()
    {
        parseTerminal( TOK.Tassign );
		globalParams ~= "="; // Kuan Hsu

		tokenText = null; // Kuan Hsu
        parseR!(ConditionalExpression);
		globalParams ~= tokenText; // Kuan Hsu
    }
}

class TemplateTupleParameter : ParseRule
{
	public this( TokenScanner ts )
	{
		super(ts);
	}

	/**
		TemplateTupleParameter:
			Identifier ...
	 */
	public void parse()
	{
		tokenText = null; // Kuan Hsu
		parseR!(Identifier);
		globalParams ~= tokenText; // Kuan Hsu
		parseTerminal(TOK.Tdotdotdot);
		globalParams ~= "..."; // Kuan Hsu
	}

}

class TemplateMixin : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TemplateMixin:
            mixin IdentifierSequence ;
            mixin IdentifierSequence MixinIdentifier ;
     */
    public void parse()
    {
		int lineNum = ts.peek().lineNumber; // Kuan Hsu
		
        parseTerminal( TOK.Tmixin );
		
		if( ts.next( TOK.Openparen ) )
		{
			parseR!(MixinExpression);
		}
		else
		{
			tokenText = null; // Kuan Hsu
			parseR!(IdentifierSequence);

			int notPos = std.string.find( tokenText, "!(" );
			char[] ident = tokenText, params;
			
			if( notPos > -1 )
			{
				ident = tokenText[0..notPos];
				if( tokenText.length > notPos + 2 ) params = tokenText[notPos+2..length-1];
			}

			activeNode.addLeaf( globalProt, D_MIXIN, ident, null, lineNum, params ); // Kuan Hsu
			
			if( ts.next( TOK.Identifier ) )
			{
				tokenText = null; // Kuan Hsu
				parseR!(MixinIdentifier);
				activeNode.getLeaf( activeNode.getLeafCount() - 1 ).typeIdentifier = tokenText; // Kuan Hsu
			}
		}
		parseTerminal( TOK.Semicolon );
    }
}

class MixinIdentifier : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        MixinIdentifier:
            Identifier    
     */
    public void parse()
    {
        parseR!(Identifier);
    }
}
