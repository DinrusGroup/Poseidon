module CodeAnalyzer.syntax.declarations;

import CodeAnalyzer.syntax.core;
import std.stdio;

class Declaration : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Declaration:
            Type Declarator ;
            Type Declarator , DeclIdentifierList ;
            Type Declarator Parameters ;
            Type Declarator Parameters FunctionBody
            AutoDeclaration        
     */
    public void parse()
    {
        if( AutoDeclaration.isAutoDeclaration(ts) )
        {
			parseR!(AutoDeclaration);
			return;	
        }

		int prevType = globalDType; // Kuan Hsu

		tokenText = ""; // Kuan Hsu
		parseR!(Type);

		char[] _typeIdentifier = globalTypeIdentifier;

		int lineNumber = ts.peek().lineNumber; // Kuan Hsu

		tokenText = ""; // Kuan Hsu
        parseR!(Declarator);

        if( ts.next( TOK.Semicolon ) )
        {
			// Kuan Hsu
			if( activeNode.DType & ( D_ALIAS | D_TYPEDEF ) )
			{
				activeNode.identifier = globalIdentifier;
				activeNode.typeIdentifier = _typeIdentifier;
			}
			else
			{
				int posDelegate = std.string.find( _typeIdentifier, " delegate" );
				int posFunction = std.string.find( _typeIdentifier, " function" );

				if( posDelegate > -1 || posFunction > -1 )
				{
					char[] typeIdent, params, baseClass;
								
					if( posDelegate > -1 ) typeIdent = _typeIdentifier[0..posDelegate];
					if( posFunction > -1 ) typeIdent = _typeIdentifier[0..posFunction];

					int posOpenParen = std.string.find( _typeIdentifier, "(" );
					int posCloseParen = std.string.rfind( _typeIdentifier, ")" );
					if( posCloseParen > posOpenParen && posOpenParen > -1 && posCloseParen > 0 )
					{
						params = _typeIdentifier[posOpenParen+1..posCloseParen];
						if( posCloseParen < _typeIdentifier.length - 1 ) baseClass = _typeIdentifier[posCloseParen+1..length];

						activeNode.addLeaf( globalProt, D_FUNLITERALS, globalIdentifier, typeIdent, lineNumber, params, baseClass ); // Kuan Hsu
						parseTerminal();
						return;
					}
				}

				activeNode.addLeaf( globalProt, D_VARIABLE, globalIdentifier, _typeIdentifier, lineNumber ); // Kuan Hsu
			}
			// End of Kuan Hsu
			
            parseTerminal();
        }
        else if( ts.next( TOK.Comma ) )
        {
			activeNode.addLeaf( globalProt, D_VARIABLE, globalIdentifier, _typeIdentifier, lineNumber ); // Kuan Hsu
			
            parseTerminal();
            parseR!(DeclIdentifierList);
            parseTerminal( TOK.Semicolon );
        }
        else
        {
			// Kuan Hsu
			int funProt = globalProt, funLN = lineNumber;
			char[] funIdent = globalIdentifier, funTypeIdent = globalTypeIdentifier;
			// activeNode = activeNode.addLeaf( globalProt, D_FUNCTION, globalIdentifier, globalTypeIdentifier, lineNumber );
			// End of Kuan Hsu

            parseR!(Parameters);

			bool bFunctionTemplateDeclaration = bFunctionTemplate; // Kuan Hsu

			// C_style function point
			bool bFUNLITERALS;

			if( funIdent.length > 2 )
				if( funIdent[0] == '(' && funIdent[length-1] == ')' )
				{
					bFUNLITERALS = true;
					char[] arrayString;
					
					funIdent = funIdent[2..length-1]; // erase (* and  )

					if( globalParams.length )
						if( globalParams[length - 1] == ' ' )  globalParams.length = globalParams.length - 1;

					int posOpenbracket = std.string.rfind( funIdent, ']' ) + 1;
					if( posOpenbracket > 1 )
					{
						arrayString = funIdent[0..posOpenbracket];
						funIdent = funIdent[posOpenbracket..length];
					}

					if( activeNode.DType & ( D_ALIAS | D_TYPEDEF ) )
					{
						/*
						example:  alias int (*[] sd)(char); --> 
						type = int
						ident = sd
						parameterstring = char
						baseClass = []
						*/
						activeNode.identifier = funIdent;
						activeNode.typeIdentifier = funTypeIdent ~ " function(" ~ globalParams ~ ")" ~ arrayString;
					}
					else
						activeNode.addLeaf( funProt, D_FUNLITERALS, funIdent, funTypeIdent, lineNumber, globalParams, arrayString ); // Kuan Hsu
				}
				
			if( !bFUNLITERALS )
			{
				activeNode = activeNode.addLeaf( funProt, D_FUNCTION, funIdent, funTypeIdent, lineNumber, globalParams ); // Kuan Hsu


				if( globalParams.length )
				{
					char[][] params;

					int 	countParen;
					char[]  string;
					
					foreach( char c; std.string.strip( globalParams ) )
					{
						string ~= c;
						
						switch( c )
						{
							case '(': countParen ++; break;
							case ')': countParen --; break;
							case ',':
								if( countParen == 0 )
								{
									params ~= string[0..length - 1];
									string = null;
								}
								
								break;
							default: break;
						}
					}

					if( string.length )	params ~= string;

					foreach( char[] s; params )
					{
						char[] paramString = std.string.strip( s );
						int posAssign = std.string.rfind( paramString, "=" );
						if( posAssign > 2 )	paramString = paramString[0..posAssign];
						
						int spacePos = std.string.rfind( paramString, " " );
						if( spacePos > 0 )
							if( spacePos < paramString.length - 1 )
							{
								char[] ident = paramString[spacePos + 1..length];
								char[] typeIdent = paramString[0..spacePos];
								
								paramString = paramString[0..spacePos];
								spacePos = std.string.rfind( paramString, " " );
								if( spacePos > 0 ) typeIdent = paramString[spacePos+1..length]; // include inout.....

								activeNode.addLeaf( 0, D_PARAMETER, ident, typeIdent, lineNumber );
							}
					}
				}
			
				//activeNode.parameterString = globalParams; // Kuan Hsu
				
				
				if( ts.next( TOK.Semicolon ) )
				{
					parseTerminal();
				}
				else
				{
					globalProt = 0;
					// D 2.0
					if( compilerVersion > 1 )
						if( ts.next( TOK.Tconst ) || ts.next( TOK.Tinvariant ) ) parseTerminal( TOK.Tconst );
						
					parseR!(FunctionBody);
				}

				// Kuan Hsu
				activeNode = activeNode.getRoot();
				if( bFunctionTemplateDeclaration ) activeNode = activeNode.getRoot();
				// End of Kuan Hsu
			}
        }
    }
}

class Parameters : ParseRule
{
    public this(TokenScanner ts) { super(ts); }

    /**
        Parameters:
            TemplateParameters FunctionParameters
            FunctionParameters
     */

    public void parse()
    {
		globalParams = null; // Kuan Hsu
		
        expect( TOK.Openparen );
        auto cursor = ts.cursor();
        ts.skipParens();
        bool isTemplate = ts.next( TOK.Openparen ); // (...)(...)
        ts.setCursor( cursor );

        if( isTemplate )
        {
			// Kuan Hsu
			int lineNumber = ts.peek().lineNumber; 
			activeNode = activeNode.addLeaf( 0, D_TEMPLATE, globalIdentifier, null, lineNumber );
			// End of Kuan Hsu

            parseR!(TemplateParameters);

			// Kuan Hsu
			activeNode.parameterString = globalParams;
			bFunctionTemplate = true;
			activeNode.baseClass = "i"; // set Implicit Template
			// End of Kuan Hsu
			
            parseR!(FunctionParameters);

			parseR!( TemplateConstraints );
        }
        else
        {
			bFunctionTemplate = false; // Kuan Hsu
            parseR!(FunctionParameters);
        }
    }
}

class AutoDeclaration : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        AutoDeclaration:
            StorageClass Identifier = Expression ;
            StorageClass AutoDeclaration
     */
    public void parse()
    {
		/*
		if( compilerVersion > 1 ) // D 2.0
		{
			if( ts.next( TOK.Tconst, TOK.Openparen ) || ts.next( TOK.Tinvariant, TOK.Openparen ) ||
						ts.next( TOK.Timmutable, TOK.Openparen ) )
			{
				return;
			}
		}
		*/
        while( StorageClass.isStorageClass(ts.peek().type) )
        {
            parseTerminal();
        }

		if( compilerVersion > 1 ) // D 2.0
			if( ts.next( TOK.Identifier, TOK.Openparen ) )
			{
				parseR!( AutoFunction );
				return;
			}
		
		tokenText = null; // Kuan Hsu
        parseR!(Identifier);
		char[] ident = tokenText; // Kuan Hsu

        parseTerminal( TOK.Tassign );

		// Kuan Hsu
		tokenText = "";

		bool bAnonymousClass;
		if( ts.next( TOK.Tnew, TOK.Tclass ) ) // AnonymousClass
		{
			bAnonymousClass = true;
		}

        parseR!(Expression);
		if( bAnonymousClass )
		{
			parseTerminal( TOK.Semicolon );
			return;
		}

		char[] typeIdent;
		if( tokenText.length ) // template
		{
			bool bCast;
			if( tokenText.length > 4 )
			{
				if( tokenText[0..5] == "cast(" ) bCast = true;
			}

			if( tokenText.length > 6 )
				if( tokenText[0..7] == "import(" )
				{
					activeNode.addLeaf( globalProt, D_VARIABLE, ident, "char[]", ts.peek().lineNumber );
					
					parseTerminal( TOK.Semicolon );
					return;
				}


			int indexDot		= std.string.rfind( tokenText, "." );
			int indexNot 		= std.string.find( tokenText, "!" );
			int indexOpenparen	= std.string.find( tokenText, "(" );
			int indexCloseparen	= std.string.rfind( tokenText, ")" );
			
			int countOpenparen = 1;

			if( bCast )
			{
				for( int endPosition = 5; endPosition < tokenText.length; ++ endPosition )
				{
					if( tokenText[endPosition] == '(' )
						countOpenparen ++;
					else if( tokenText[endPosition] == ')' )
						countOpenparen --;

					if( countOpenparen == 0 )
					{
						typeIdent = tokenText[5..endPosition];
						break;
					}
				}
			}
			else if( indexDot > indexCloseparen )
			{
				typeIdent = tokenText;
			}
			else if( indexNot > -1 )
			{
				if( indexOpenparen == indexNot + 1 )
				{
					for( int endPosition = indexOpenparen + 1; endPosition < tokenText.length; ++ endPosition )
					{
						if( tokenText[endPosition] == '(' )
							countOpenparen ++;
						else if( tokenText[endPosition] == ')' )
							countOpenparen --;

						if( countOpenparen == 0 )
						{
							typeIdent = tokenText[0..endPosition+1];
							break;
						}
					}
				}
			}
			else if( indexOpenparen > -1 ) // class
				typeIdent = tokenText[0..indexOpenparen]; 
			else
				typeIdent = tokenText;
		}

		activeNode.addLeaf( globalProt, D_VARIABLE, ident, typeIdent, ts.peek().lineNumber );
		// End of Kuan Hsu
		
        parseTerminal( TOK.Semicolon );
    }

    public static bool isAutoDeclaration(TokenScanner ts)
    {
        int originalPlace = ts.cursor;
        bool stc()
        {
            return StorageClass.isStorageClass(ts.peek().type);
        }
        scope(exit)
        {
            ts.setCursor(originalPlace);
        }

        if( !stc() ) return false;

        while( stc() )
        {
			if( compilerVersion > 1 ) // D 2.0
			{
				if( ts.next( TOK.Tconst, TOK.Openparen ) || ts.next( TOK.Tinvariant, TOK.Openparen ) ||
								ts.next( TOK.Timmutable, TOK.Openparen ) )
				{
					return false;
				}
			}
			
			if( ts.next( TOK.Tauto, TOK.Identifier, TOK.Openparen ) )
			{
		        ts.read();
				return true;
			}
			ts.read();
        }
        if( !ts.next( TOK.Identifier ) )
        {
            return false;
        }
        ts.read();
        if( !ts.next( TOK.Tassign ) )
        {
            return false;
        }
        return true;
    }
}

class Type : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Type:
            IdentifierSequence
            IdentifierSequence TypeSuffixes
            typeof
     */
    public void parse()
    {
        if( ts.next( TOK.Ttypeof ) )
        {
			parseR!(Typeof);

			//if( ts.next( TOK.Openbracket ) ) 
			//	parseR!(TypeSuffixes); // Kuan Hsu
			//else

			if( ts.next( TOK.Tdot ) ) parseR!( IdentifierSequence );
			
			//{
			//	globalDType = D_TYPEOF;
			//}

            if( isTypeSuffixStart( ts ) )
            {
                parseR!(TypeSuffixes);
            }			
		} 
		else 
		{
			if( compilerVersion > 1 ) // D 2.0
			{
				if( !ts.next( TOK.Tconst ) && !ts.next( TOK.Tinvariant ) && !ts.next( TOK.Timmutable ) )
					parseR!(IdentifierSequence);
				else
				{
					if( ts.peektype(2) == TOK.Closeparen ) parseTerminal();
				}
			}
			else
				parseR!(IdentifierSequence);

            if( isTypeSuffixStart( ts ) )
            {
                parseR!(TypeSuffixes);
            }
        }

		globalTypeIdentifier = tokenText; // Kuan Hsu
    }
}

/**
    returns whether or not this can be the start of a typesuffix
    *
    [
    function
    delegate
    
    but of course, not all '[' are type suffixes, so this is not perfect.
    use with care!
 */
bool isTypeSuffixStart( TokenScanner ts )
{
	if( compilerVersion > 1 ) // D 2.0
	{
		return ( ts.next( TOK.Tmul ) || ts.next( TOK.Openbracket ) || ts.next( TOK.Tfunction ) || ts.next( TOK.Tdelegate )
				|| ts.next( TOK.Tconst ) || ts.next( TOK.Tinvariant ) || ts.next( TOK.Timmutable ) );
	}
	else
		return ( ts.next( TOK.Tmul ) || ts.next( TOK.Openbracket ) || ts.next( TOK.Tfunction ) || ts.next( TOK.Tdelegate ) );
}

class TypeSuffixes : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        TypeSuffixes:
            TypeSuffix
            TypeSuffix TypeSuffixes
     */
    public void parse()
    {
        parseR!(TypeSuffix);
        if( isTypeSuffixStart( ts ) )
        {
            parseR!(TypeSuffixes);
        }
    }
}

class TypeSuffix : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        TypeSuffix:
            Pointer
            Array
            FunctionPointer
            Delegate

			C 2.0
			Const
			Invariant
			TOK.Timmutable
     */
    public void parse()
    {
		if( compilerVersion > 1 ) // D 2.0
		{
			if( ts.next( TOK.Tconst ) || ts.next( TOK.Tinvariant ) || ts.next( TOK.Timmutable ) )
			{
				int countOpenparen;
				
				parseTerminal();
				if( ts.next( TOK.Openparen ) )
				{
					parseTerminal( TOK.Openparen );
					countOpenparen ++;
				}
				else
					tokenText = tokenText ~ " ";

				parseR!( Type );

				if( ts.next( TOK.Closeparen ) )
					if( countOpenparen > 0 ) parseTerminal( TOK.Closeparen );
					
				return;
			}
		}

        if( ts.next( TOK.Tmul ) )
        {
            parseR!(Pointer);
        }
        else if( ts.next( TOK.Openbracket ) )
        {
			//if( globalDType & ( D_ALIAS | D_TYPEDEF ) ) // Kuan Hsu
			if( activeNode.DType & ( D_ALIAS | D_TYPEDEF ) )
				parseR!(ArrayIndex); // Kuan Hsu
			else
				parseR!(Array);
        }
        else if( ts.next( TOK.Tfunction ) )
        {
            parseR!(FunctionPointer);
        }
        else
        {
            parseR!(Delegate);
        }
    }
}

class Pointer : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Pointer:
            *
     */
    public void parse()
    {
        parseTerminal( TOK.Tmul );
    }
}

class Array : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Array:
            []
            [ ExprType ]
     */
    public void parse()
    {
        parseTerminal( TOK.Openbracket );
        if( !ts.next( TOK.Closebracket ) )
        {
            parseR!(ExprType);
        }
        parseTerminal( TOK.Closebracket );
    }
}

class Typeof : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Typeof:
            typeof ( Expression )
     */
    public void parse()
    {
        parseTerminal( TOK.Ttypeof );
        parseTerminal( TOK.Openparen );
		
		if( compilerVersion > 1 ) // D 2.0
		{
			if( ts.next( TOK.Treturn ) )
			{
				parseTerminal( TOK.Treturn );
				tokenText ~= "return";
				parseTerminal( TOK.Closeparen );
				return;
			}
		}
		
        parseR!(Expression);
        parseTerminal( TOK.Closeparen );
    }
}

class ExprType : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ExprType:
            AssignExpression
            AssignExpression TypeSuffixes
            Typeof
     */
    public void parse()
    {
        if( ts.next( TOK.Ttypeof ) )
        {
            parseR!(Typeof);
            return;
        }
        else
        {
			if( compilerVersion > 1 ) // d 2.0
			{
				if( ts.next( TOK.Tconst ) || ts.next( TOK.Tinvariant ) || ts.next( TOK.Timmutable ) )
				{
			        if( isTypeSuffixStart(ts) ) parseR!(TypeSuffixes);
					return;
				}
			}
			
            parseR!(AssignExpression);
            if( isTypeSuffixStart(ts) )
            {
                parseR!(TypeSuffixes);
            }
        }
    }
}

class FunctionPointer : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        FunctionPointer:
            function FunctionParameters
     */
    public void parse()
    {
		parseTerminal( TOK.Tfunction );

		// Kuan Hsu
		char[] typeIdent = tokenText;
		if( tokenText.length >= 8 )
			typeIdent = std.string.insert( tokenText, tokenText.length - 8, " " );
		// End of Kuan Hsu
			
		parseR!(FunctionParameters);

		// Kuan Hsu
		if( globalParams.length )
			if( globalParams[length - 1] == ' ' )  globalParams.length = globalParams.length - 1;
			
		tokenText = typeIdent ~ "(" ~ globalParams ~ ")";
		// End of Kuan Hsu
	}
}

class Delegate : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Delegate:
            delegate FunctionParameters
     */
    public void parse()
    {
		parseTerminal( TOK.Tdelegate );

		// Kuan Hsu
		char[] typeIdent = tokenText;
		if( tokenText.length >= 8 )
			typeIdent = std.string.insert( tokenText, tokenText.length - 8, " " );
		// End of Kuan Hsu
			
		parseR!(FunctionParameters);

		// Kuan Hsu
		if( globalParams.length )
			if( globalParams[length - 1] == ' ' )  globalParams.length = globalParams.length - 1;
		
		tokenText = typeIdent ~ "(" ~ globalParams ~ ")";
		// End of Kuan Hsu
	}
}

bool isDeclaratorStart( TokenScanner ts )
{
    return (ts.next( TOK.Identifier ) || ts.next( TOK.Openparen ));
}

class Declarator : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Declarator:
            Identifier
            Declarator CTypeSuffixes
            Declarator = Initializer
            ( Declarator )
            ( TypeSuffixes Declarator )
            ( TypeSuffixes )
    */
    public void parse()
    {
        if( ts.next( TOK.Identifier ) )
        {
			//tokenText = null; // Kuan Hsu
            parseR!(Identifier);
        }
        else
        {
            parseTerminal( TOK.Openparen );
            if( isTypeSuffixStart( ts ) )
            {
                parseR!(TypeSuffixes);
                if( ts.next( TOK.Closeparen ) )
                {
                    parseTerminal();
                    return;
                }
            }
            parseR!(Declarator);
            parseTerminal( TOK.Closeparen );
        }

        if( ts.next( TOK.Openbracket ) )
        {
            parseR!(CTypeSuffixes);
        }

		globalIdentifier = tokenText; // Kuan Hsu

        if( ts.next( TOK.Tassign ) )
        {
            parseTerminal();
            parseR!(Initializer);
        }
    }
}

class DeclIdentifierList : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        DeclIdentifierList:
            DeclIdentifier
            DeclIdentifier, DeclIdentifierList
     */
    public void parse()
    {
        parseR!(DeclIdentifier);
		activeNode.addLeaf( globalProt, D_VARIABLE, globalIdentifier, globalTypeIdentifier, ts.peek().lineNumber ); // Kuan Hsu
        if( ts.next( TOK.Comma ) )
        {
            parseTerminal();
            parse();
        }
    }
}

class DeclIdentifier : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        DeclIdentifier:
            Identifier
            Identifier = Initializer
     */
    public void parse()
    {
		tokenText = null;
        parseR!(Identifier);
		globalIdentifier = tokenText;
        if( ts.next( TOK.Tassign ) )
        {
            parseTerminal();
            parseR!(Initializer);
        }
    }
}

class CTypeSuffixes : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        CTypeSuffixes:
            Array
            Array CTypeSuffixes    
     */
    public void parse()
    {
        parseR!(Array);
        if( ts.next( TOK.Openbracket ) )
        {
            parseR!(CTypeSuffixes);
        }
    }
}

class FunctionParameters : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        FunctionParameters:
            ( )
            ( FunctionParameterList )
     */
    public void parse()
    {
		globalParams = null; // Kuan Hsu
        parseTerminal( TOK.Openparen );

        if( !ts.next( TOK.Closeparen ) )
        {
            parseR!(FunctionParameterList);
        }
        parseTerminal( TOK.Closeparen );
    }
}

class FunctionParameterList : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        FunctionParameterList:
            Paremeter
            FunctionParameter, FunctionParameterList
            FunctionParameter ...
            ...
     */
    public void parse()
    {
        if( ts.next( TOK.Tdotdotdot ) )
        {
            parseTerminal();
			globalParams ~= "..."; // Kuan Hsu
            return;
        }
        
        parseR!(FunctionParameter);
        if( ts.next( TOK.Tdotdotdot ) )
        {
            parseTerminal();
			globalParams ~= "..."; // Kuan Hsu
            return;
        }
        if( ts.next( TOK.Comma ) )
        {
            parseTerminal();
			globalParams ~= ", "; // Kuan Hsu
            parse();
        }
    }
}

class FunctionParameter : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        FunctionParameter:
            Type
            Type Declarator
            Type Declarator FunctionParameters             
            Type Declarator = Initializer
            InOut FunctionParameter
     */
    public void parse()
    {
		if( ts.next( TOK.Tconst, TOK.Openparen ) )
		{
		}
		else if( nextinout(ts) )
        {
            parseR!(InOut);
        }

		char[] prevParamText = globalParams; // Kuan Hsu
		tokenText = ""; // Kuan Hsu
        parseR!(Type);
		globalParams = prevParamText ~ globalTypeIdentifier ~ " "; // Kuan Hsu
		
        if( isDeclaratorStart( ts ) )
        {
			tokenText = ""; // Kuan Hsu
            parseR!(Declarator);

			globalParams ~= tokenText; // Kuan Hsu
			
            if( ts.next( TOK.Tassign ) )
            {
                parseTerminal();
                parseR!(Initializer);
				
            }
            else if( ts.next( TOK.Openparen ) )
            {
                parseR!(FunctionParameters);
            }
        }

		/*
		// Kuan Hsu
		if( activeNode.DType & D_FUNCTION )
			activeNode.addLeaf( 0, D_PARAMETER, globalIdentifier, globalTypeIdentifier, ts.peek().lineNumber );
		// End of Kuan Hsu
		*/
    }
}

class InOut : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        InOut:
            in
            out
            inout
			ref
            lazy
     */
    public void parse()
    {
        if( nextinout(ts) )
        {
			tokenText = null; //Kuan Hsu
            parseTerminal();
			globalParams ~= ( tokenText ~ " " );
        }
        else
        {
            throw new ParserException( ts, "Expecting in/out/ref/lazy" );
        }
    }
}

bool nextinout(TokenScanner ts)
{
    switch( ts.peek().type )
    {
        case    
            TOK.Tin,
            TOK.Tout, 
            TOK.Tinout,
			TOK.Tref,
            TOK.Tlazy:
                return true;
		case
			TOK.Tconst,
			TOK.Tscope:
				if( compilerVersion > 1 ) return true; // D 2.0
			
        default: 
                return false;
    }
}

class FunctionBody : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        FunctionBody:
            StatementBlock
            body StatementBlock
            FunctionContracts body StatementBlock
     */
    public void parse()
    {
        if( ts.next( TOK.Tin ) || ts.next( TOK.Tout ) )
        {
            parseR!(FunctionContracts);
            parseTerminal( TOK.Tbody );
        }
        else if( ts.next( TOK.Tbody ) )
        {
            parseTerminal();
        }
        parseR!(StatementBlock);
    }
}

class FunctionContracts : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        FunctionContracts:
            InContract
            OutContract
            InContract OutContract
            OutContract InContract
     */
    public void parse()
    {
        bool incon = false;
        if( ts.next( TOK.Tin ) )
        {
            incon = true;
            parseR!(InContract);
        }
        if( ts.next( TOK.Tout ) )
        {
            parseR!(OutContract);
        }
        if( !incon )
        {
            if( ts.next( TOK.Tin ) )
            {
                incon = true;
                parseR!(InContract);
            }
        }
    }
}

class InContract : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        InContract:
            in StatementBlock
     */
    public void parse()
    {
        parseTerminal( TOK.Tin );
        parseR!(StatementBlock);
    }
}

class OutContract : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        OutContract:
            out StatementBlock
            out ( Identifier ) StatementBlock
     */
    public void parse()
    {
        parseTerminal( TOK.Tout );
        if( ts.next( TOK.Openparen ) )
        {
            parseTerminal();
            parseR!(Identifier);
            parseTerminal( TOK.Closeparen );
        }
        parseR!(StatementBlock);
    }
}

class Constructor : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        Constructor:
            this FunctionParameters FunctionBody
            this FunctionParameters ;
     */
    public void parse()
    {
		parseTerminal( TOK.Tthis );

		parseR!(Parameters);

		int 	lineNumber = ts.peek().lineNumber;
		bool	isTemplate;
		
		if( bFunctionTemplate )
		{
			if( activeNode.DType & D_TEMPLATE )
			{
				lineNumber = activeNode.lineNumber;
				activeNode.identifier = "this";
				isTemplate = true;
			}
		}

		activeNode = activeNode.addLeaf( globalProt, D_CTOR, "this", null, lineNumber, globalParams ); // Kuan Hsu
        if( ts.next( TOK.Semicolon ) )
        {
            parseTerminal();
        }
        else
        {
			globalProt = 0;
            parseR!(FunctionBody);
        }

		activeNode = activeNode.getRoot(); // Kuan Hsu
		if( isTemplate ) activeNode = activeNode.getRoot(); // Kuan Hsu	
    }
}

class Destructor : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        Destructor:
            ~ this ( ) FunctionBody
            ~ this ( ) ;
     */
    public void parse()
    {
        parseTerminal( TOK.Ttilde );
        parseTerminal( TOK.Tthis );

		activeNode = activeNode.addLeaf( globalProt, D_DTOR, "~this", null, ts.peek().lineNumber ); // Kuan Hsu
		
        parseTerminal( TOK.Openparen );
        parseTerminal( TOK.Closeparen );
        if( ts.next( TOK.Semicolon ) )
        {
            parseTerminal();
        }
        else
        {
			globalProt = 0;
            parseR!(FunctionBody);
        }

		activeNode = activeNode.getRoot(); // Kuan Hsu
    }
}

class Allocator : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        Allocator:
            new FunctionParameters FunctionBody
            new FunctionParameters ;
     */
    public void parse()
    {
        parseTerminal( TOK.Tnew );
        parseR!(FunctionParameters);
        if( ts.next( TOK.Semicolon ) )
        {
            parseTerminal();
        }
        else
        {
            parseR!(FunctionBody);
        }
    }
}

class Dellocator : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        Dellocator:
            delete FunctionParameters FunctionBody
            delete FunctionParameters ;
     */
    public void parse()
    {
        parseTerminal( TOK.Tdelete );
        parseR!(FunctionParameters);
        if( ts.next( TOK.Semicolon ) )
        {
            parseTerminal();
        }
        else
        {
            parseR!(FunctionBody);
        }
    }
}

class AutoFunction : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }

    public void parse()
    {
		int prevType = globalDType; // Kuan Hsu
		tokenText = ""; // Kuan Hsu

		char[] _typeIdentifier = globalTypeIdentifier;

		int lineNumber = ts.peek().lineNumber; // Kuan Hsu

		tokenText = ""; // Kuan Hsu
        parseR!(Declarator);

        if( ts.next( TOK.Semicolon ) )
        {
			// Kuan Hsu
			if( activeNode.DType & ( D_ALIAS | D_TYPEDEF ) )
			{
				activeNode.identifier = globalIdentifier;
				activeNode.typeIdentifier = _typeIdentifier;
			}
			else
			{
				int posDelegate = std.string.find( _typeIdentifier, " delegate" );
				int posFunction = std.string.find( _typeIdentifier, " function" );

				if( posDelegate > -1 || posFunction > -1 )
				{
					char[] typeIdent, params, baseClass;
								
					if( posDelegate > -1 ) typeIdent = _typeIdentifier[0..posDelegate];
					if( posFunction > -1 ) typeIdent = _typeIdentifier[0..posFunction];

					int posOpenParen = std.string.find( _typeIdentifier, "(" );
					int posCloseParen = std.string.rfind( _typeIdentifier, ")" );
					if( posCloseParen > posOpenParen && posOpenParen > -1 && posCloseParen > 0 )
					{
						params = _typeIdentifier[posOpenParen+1..posCloseParen];
						if( posCloseParen < _typeIdentifier.length - 1 ) baseClass = _typeIdentifier[posCloseParen+1..length];

						activeNode.addLeaf( globalProt, D_FUNLITERALS, globalIdentifier, typeIdent, lineNumber, params, baseClass ); // Kuan Hsu
						parseTerminal();
						return;
					}
				}

				activeNode.addLeaf( globalProt, D_VARIABLE, globalIdentifier, _typeIdentifier, lineNumber ); // Kuan Hsu
			}
			// End of Kuan Hsu
			
            parseTerminal();
        }
        else if( ts.next( TOK.Comma ) )
        {
			activeNode.addLeaf( globalProt, D_VARIABLE, globalIdentifier, _typeIdentifier, lineNumber ); // Kuan Hsu
			
            parseTerminal();
            parseR!(DeclIdentifierList);
            parseTerminal( TOK.Semicolon );
        }
        else
        {
			// Kuan Hsu
			int funProt = globalProt, funLN = lineNumber;
			char[] funIdent = globalIdentifier, funTypeIdent = globalTypeIdentifier;
			// activeNode = activeNode.addLeaf( globalProt, D_FUNCTION, globalIdentifier, globalTypeIdentifier, lineNumber );
			// End of Kuan Hsu

            parseR!(Parameters);

			bool bFunctionTemplateDeclaration = bFunctionTemplate; // Kuan Hsu

			// C_style function point
			bool bFUNLITERALS;

			if( funIdent.length > 2 )
				if( funIdent[0] == '(' && funIdent[length-1] == ')' )
				{
					bFUNLITERALS = true;
					char[] arrayString;
					
					funIdent = funIdent[2..length-1]; // erase (* and  )

					if( globalParams.length )
						if( globalParams[length - 1] == ' ' )  globalParams.length = globalParams.length - 1;

					int posOpenbracket = std.string.rfind( funIdent, ']' ) + 1;
					if( posOpenbracket > 1 )
					{
						arrayString = funIdent[0..posOpenbracket];
						funIdent = funIdent[posOpenbracket..length];
					}

					if( activeNode.DType & ( D_ALIAS | D_TYPEDEF ) )
					{
						/*
						example:  alias int (*[] sd)(char); --> 
						type = int
						ident = sd
						parameterstring = char
						baseClass = []
						*/
						activeNode.identifier = funIdent;
						activeNode.typeIdentifier = funTypeIdent ~ " function(" ~ globalParams ~ ")" ~ arrayString;
					}
					else
						activeNode.addLeaf( funProt, D_FUNLITERALS, funIdent, funTypeIdent, lineNumber, globalParams, arrayString ); // Kuan Hsu
				}
				
			if( !bFUNLITERALS )
			{
				activeNode = activeNode.addLeaf( funProt, D_FUNCTION, funIdent, null, lineNumber, globalParams ); // Kuan Hsu


				if( globalParams.length )
				{
					char[][] params;

					int 	countParen;
					char[]  string;
					
					foreach( char c; std.string.strip( globalParams ) )
					{
						string ~= c;
						
						switch( c )
						{
							case '(': countParen ++; break;
							case ')': countParen --; break;
							case ',':
								if( countParen == 0 )
								{
									params ~= string[0..length - 1];
									string = null;
								}
								
								break;
							default: break;
						}
					}

					if( string.length )	params ~= string;

					foreach( char[] s; params )
					{
						char[] paramString = std.string.strip( s );
						int posAssign = std.string.rfind( paramString, "=" );
						if( posAssign > 2 )	paramString = paramString[0..posAssign];
						
						int spacePos = std.string.rfind( paramString, " " );
						if( spacePos > 0 )
							if( spacePos < paramString.length - 1 )
							{
								char[] ident = paramString[spacePos + 1..length];
								char[] typeIdent = paramString[0..spacePos];
								
								paramString = paramString[0..spacePos];
								spacePos = std.string.rfind( paramString, " " );
								if( spacePos > 0 ) typeIdent = paramString[spacePos+1..length]; // include inout.....

								activeNode.addLeaf( 0, D_PARAMETER, ident, typeIdent, lineNumber );
							}
					}
				}
			
				//activeNode.parameterString = globalParams; // Kuan Hsu
				
				
				if( ts.next( TOK.Semicolon ) )
				{
					parseTerminal();
				}
				else
				{
					globalProt = 0;
					if( ts.next( TOK.Tconst ) ) parseTerminal( TOK.Tconst );
					parseR!(FunctionBody);
				}

				// Kuan Hsu
				activeNode = activeNode.getRoot();
				if( bFunctionTemplateDeclaration ) activeNode = activeNode.getRoot();
				// End of Kuan Hsu
			}
        }
    }
}