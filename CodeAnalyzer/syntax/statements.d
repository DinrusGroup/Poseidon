module CodeAnalyzer.syntax.statements;
import CodeAnalyzer.syntax.core;

class Statements : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Statements:
            Statement
            Statement Statements
     */
    public void parse()
    {
        while( !ts.next( TOK.Closecurly ) )
        {
            parseR!(Statement);
        }
    }
}

class Statement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        Statement:
            IfStatement								// Kuan Hsu
            WhileStatement							// Kuan Hsu
            DoWhileStatement						// Kuan Hsu
            ForStatement							// Kuan Hsu
            ForEachStatement						// Kuan Hsu
            StatementBlock
            ExpressionStatement
            DeclarationStatement
            StorageClassDeclarationStatement
            LabelStatement
            SwitchStatement							// Kuan Hsu
            GotoStatement    						// Kuan Hsu
            CaseStatement							// Kuan Hsu
            DefaultCaseStatement					// Kuan Hsu
            ContinueStatement						// Kuan Hsu
            BreakStatement							// Kuan Hsu
            ReturnStatement							// Kuan Hsu
            ConditionalCompilationStatement
            VolatileStatement
            TryStatement							// Kuan Hsu
            TemplateMixin		
            Pragma
			MixinStatement							// Kuan Hsu
            ;
     */
    public void parse()
    {
		int prevAttribute = globalProt; // Kuan Hsu
		
        ParseDelegate nextStatement;
        TOK t = ts.peek().type;
        if( handle.handles(t) )
        {
            nextStatement = handle[t];
            parseWith( nextStatement );
        }
        else
        {
            parseTerminal( TOK.Semicolon );
        }

		globalProt = prevAttribute; // Kuan Hsu
    }
}

class IfStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        IfStatement:
            if ( IfCondition ) Statement
            if ( IfCondition ) Statement else Statement
     */
    public void parse()
    {
        parseTerminal( TOK.Tif );

		activeNode = activeNode.addLeaf( 0, D_BLOCK, "if", "if", ts.peek().lineNumber, null, "if" ); // Kuan Hsu

        parseTerminal( TOK.Openparen );
        parseR!(IfCondition);
        parseTerminal( TOK.Closeparen );

		
        parseR!(Statement);

		//activeNode = activeNode.getRoot(); // Kuan Hsu
		
        if( ts.next( TOK.Telse ) )
        {
            parseTerminal();
			if( ts.next( TOK.Tif ) )
			{
				activeNode = activeNode.getRoot(); // Kuan Hsu
				parseR!(Statement);
			}
			else
			{
				activeNode = activeNode.getRoot(); // Kuan Hsu
				activeNode = activeNode.addLeaf( 0, D_BLOCK, "else", "else", ts.peek().lineNumber, null, "else" ); // Kuan Hsu
				parseR!(Statement);
				activeNode = activeNode.getRoot(); // Kuan Hsu
			}
        }
		else
		{
			activeNode = activeNode.getRoot(); // Kuan Hsu
		}
    }
}

class IfCondition : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        IfCondition:
            Expression
            Type Declarator
            auto Identifier = Expression    
     */
    public void parse()
    {
        if( ts.next( TOK.Tauto ) )
        {
            parseTerminal();
            parseR!(Identifier);
            parseTerminal( TOK.Tassign );
            parseR!(Expression);
        }
        else if( handle.isAssignDeclaration(ts) )
        {
			tokenText = ""; // Kuan Hsu
            parseR!(Type);
			tokenText = ""; // Kuan Hsu
            parseR!(Declarator);
        }
        else
        {
            parseR!(Expression);
        }
    }
}

class DeclarationStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        DeclarationStatement:
            Declaration
     */
    public void parse()
    {
        parseR!(Declaration);
    }
}

class ExpressionStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ExpressionStatement:
            Expression ;
     */
    public void parse()
    {
        parseR!(Expression);
        parseTerminal( TOK.Semicolon );
    }
}

class StorageClassDeclarationStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        StorageClassDeclarationStatement:
            StorageClass Statement
     */
    public void parse()
    {
        //consume possible multiple storage classes
        while( StorageClass.isStorageClass( ts.peek().type ) )
        {
			// EX: invariant(char[5])[int] aa;
			// Turn to parse Declaration
			if( compilerVersion > 1 ) // D 2.0
			{
				if( ts.next( TOK.Tconst, TOK.Openparen ) || ts.next( TOK.Tinvariant, TOK.Openparen ) ||
					ts.next( TOK.Timmutable, TOK.Openparen ) )
				{
					parseR!(Declaration);
					return;
				}
			}
			
            parseR!(StorageClass);
        }
        parseR!(Statement);
    }
}

class StatementBlock : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        StatementBlock:
            { Statements }
            { }
     */
    public void parse()
    {
		bool 	bAnonymous;
		int 	prevAttribute = globalProt; // Kuan Hsu

		TOK t = ts.peektype( 0 );

		if( t != TOK.Closeparen && t != TOK.Tdo && t != TOK.Telse && t != TOK.Ttry && t != TOK.Tcatch && 
			t != TOK.Tfinally && t != TOK.Tunittest && t != TOK.Tin && t != TOK.Tout && t != TOK.Tbody && t != TOK.Tsynchronized )
		{
			if( compilerVersion > 1 && ( t == TOK.Tconst || t == TOK.Tinvariant ) )
			{
			}
			else
			{
				bAnonymous = true;
				globalProt = D_Private;
				activeNode = activeNode.addLeaf( globalProt, D_ANONYMOUSBLOCK, null, null, ts.peek().lineNumber );
			}
		}
		
        parseTerminal( TOK.Opencurly );
        if( !ts.next( TOK.Closecurly ) )
        {
            parseR!(Statements);
        }
        parseTerminal( TOK.Closecurly );

		if( bAnonymous )
		{
			globalProt = prevAttribute;
			activeNode = activeNode.getRoot();
		}
    }
}

class DoWhileStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        DoWhileStatement:
            do Statement while( Expression )
     */
    public void parse()
    {
        parseTerminal( TOK.Tdo );

		activeNode = activeNode.addLeaf( 0, D_BLOCK, "do", "do", ts.peek().lineNumber, null, "do" ); // Kuan Hsu
        parseR!(Statement);
		activeNode = activeNode.getRoot(); // Kuan Hsu
		
        parseTerminal( TOK.Twhile );
        parseTerminal( TOK.Openparen );
        parseR!(Expression);
        parseTerminal( TOK.Closeparen );
    }
}

class WhileStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        WhileStatement:
            while ( Expression ) Statement
     */
    public void parse()
    {
        parseTerminal( TOK.Twhile );
        parseTerminal( TOK.Openparen );
        parseR!(Expression);
        parseTerminal( TOK.Closeparen );

		activeNode = activeNode.addLeaf( 0, D_BLOCK, "while", "while", ts.peek().lineNumber, null, "while" ); // Kuan Hsu
        parseR!(Statement);
		activeNode = activeNode.getRoot(); // Kuan Hsu
    }
}

class LabelStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        LabelStatement:
            Identifier :
     */
    public void parse()
    {
        parseR!(Identifier);
        parseTerminal( TOK.Colon );
    }
}

class ForStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ForStatement:
            for ( ForParameters ) Statement    
     */
    public void parse()
    {
        parseTerminal( TOK.Tfor );
        parseTerminal( TOK.Openparen );
		activeNode = activeNode.addLeaf( 0, D_BLOCK, "for", "for", ts.peek().lineNumber, null, "for" ); // Kuan Hsu
        parseR!(ForParameters);
        parseTerminal( TOK.Closeparen );
        parseR!(Statement);
		activeNode = activeNode.getRoot(); // Kuan Hsu
    }
}

class ForEachStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ForEachStatement:
            foreach ( ForEachParameters ) Statement
            foreach_reverse ( ForEachParameters ) Statement

		D 2.0
		ForeachRangeStatement:
			Foreach (ForeachType; LwrExpression .. UprExpression ) ScopeStatement

     */
    public void parse()
    {
        if( !ts.next( TOK.Tforeach ) && !ts.next( TOK.Tforeach_reverse ) )
        {
            expect( TOK.Tforeach ); //throw an exception ..
        }
        parseTerminal();
        parseTerminal( TOK.Openparen );
		activeNode = activeNode.addLeaf( 0, D_BLOCK, "foreach", "foreach", ts.peek().lineNumber, null, "foreach" ); // Kuan Hsu
        parseR!(ForEachParameters);
        parseTerminal( TOK.Closeparen );
        parseR!(Statement);
		activeNode = activeNode.getRoot(); // Kuan Hsu
    }
}


class ForEachParameters : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ForEachParameters:
            ForEachTypeList ; Expression
     */
    public void parse()
    {
        parseR!(ForEachTypeList);
        parseTerminal( TOK.Semicolon );
        parseR!(Expression);
		if( compilerVersion > 1 )
		{
			if( ts.next( TOK.Tslice ) )
			{
				parseTerminal( TOK.Tslice );
				parseR!(Expression);
			}
		}
    }
}

class ForEachTypeList : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ForEachTypeList:
            ForEachType
            ForEachType, ForEachTypeList
     */
    public void parse()
    {
        parseR!(ForEachType);
        if( ts.next( TOK.Comma ) )
        {
            parseTerminal();
            parse();
        }
    }
}

class ForEachType : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ForEachType:
            InOut Type Identifier
            InOut Identifier
            Type Identifier
            Identifier
     */
    public void parse()
    {
        if( nextinout(ts) )
        {
            parseR!(InOut);
        }
        
        if( ts.next( TOK.Identifier, TOK.Comma ) ||
            ts.next( TOK.Identifier, TOK.Semicolon ) )
        {
            parseR!(Identifier);
        }
        else
        {
			tokenText = ""; // Kuan Hsu
            parseR!(Type);
			globalTypeIdentifier = tokenText; // Kuan Hsu

			tokenText = null; // Kuan Hsu
            parseR!(Identifier);
			
			activeNode.addLeaf( 0, D_VARIABLE, tokenText, globalTypeIdentifier, ts.peek().lineNumber ); // Kuan Hsu
        }
    }
}


class ForParameters : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ForParameters:
            ForInit ForTest ForInc
            ForInit ForTest
     */
    public void parse()
    {
        parseR!(ForInit);
        parseR!(ForTest);
        if( !ts.next(TOK.Closeparen) )
        {
            parseR!(ForInc);
        }
    }
}

class ForInit : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ForInit:
            DeclarationStatement
            ExpressionStatement
            ;
     */
    public void parse()
    {
        if( ts.next( TOK.Semicolon ) )
        {
            parseTerminal();
            return;
        }
        else
        {
            if( handle.isDeclaration( ts ) )
            {
                parseR!( DeclarationStatement );
            }
            else
            {
                parseR!( ExpressionStatement );
            }
        }
    }
}

class ForTest : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ForTest:
            ExpressionStatement
            ;
     */
    public void parse()
    {
        if( ts.next( TOK.Semicolon ) )
        {
            parseTerminal();
            return;
        }
        parseR!(ExpressionStatement);
    }
}

class ForInc : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ForInc:
            Expression
     */
    public void parse()
    {
        parseR!(Expression);
    }
}

class SwitchStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        SwitchStatement:
            switch ( Expression ) StatementBlock
     */
    public void parse()
    {
		activeNode = activeNode.addLeaf( 0, D_BLOCK, "switch", "switch", ts.peek().lineNumber, null, "switch" ); // Kuan Hsu
        parseTerminal( TOK.Tswitch );
        parseTerminal( TOK.Openparen );
        parseR!(Expression);
        parseTerminal( TOK.Closeparen );
        parseR!(StatementBlock);
		
		// Kuan Hsu
		if( activeNode.DType & D_BLOCK )
			if( activeNode.baseClass == "case" ) activeNode = activeNode.getRoot();

		activeNode = activeNode.getRoot(); 
		// End of Kuan Hsu		
    }
}

class GotoStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        GotoStatement:
            goto Identifier ;
            goto default ;
            goto case ;
            goto case Expression ;
     */
    public void parse()
    {
        parseTerminal( TOK.Tgoto );
        if( ts.next( TOK.Identifier ) )
        {
            parseR!(Identifier);
        }
        else if( ts.next( TOK.Tdefault ) )
        {
            parseTerminal();
        }
        else
        {
            parseTerminal( TOK.Tcase );
            if( !ts.next(TOK.Semicolon) )
            {
                parseR!(Expression);
            }
        }
        
        parseTerminal( TOK.Semicolon );

		// Kuan Hsu
		if( activeNode.DType & D_BLOCK )
			if( activeNode.baseClass == "case" ) activeNode = activeNode.getRoot();
		// End of Kuan Hsu		
    }
}

class CaseStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        CaseStatement:
            case Expression :
     */
    public void parse()
    {
        parseTerminal( TOK.Tcase );

		int ln = ts.peek().lineNumber;
		
        parseR!(Expression);
        parseTerminal( TOK.Colon );

		// Kuan Hsu
		if( activeNode.DType & D_BLOCK )
		{
			if( activeNode.baseClass == "switch" )
				activeNode = activeNode.addLeaf( 0, D_BLOCK, "case", "case", ln, null, "case" );
			else
			{
				if( activeNode.baseClass == "case" )
				{
					activeNode = activeNode.getRoot();
					activeNode = activeNode.addLeaf( 0, D_BLOCK, "case", "case", ln, null, "case" );
				}
			}
		}
		// End of Kuan Hsu
    }
}

class DefaultCaseStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        DefaultCaseStatement:
            default :
     */
    public void parse()
    {
        parseTerminal( TOK.Tdefault );

		int ln = ts.peek().lineNumber;
		
        parseTerminal( TOK.Colon );

		// Kuan Hsu
		if( activeNode.DType & D_BLOCK )
		{
			if( activeNode.baseClass == "switch" )
				activeNode = activeNode.addLeaf( 0, D_BLOCK, "case", "case", ln, null, "case" );
			else
			{
				if( activeNode.baseClass == "case" )
				{
					activeNode = activeNode.getRoot();
					activeNode = activeNode.addLeaf( 0, D_BLOCK, "case", "case", ln, null, "case" );
				}
			}
		}
		// End of Kuan Hsu
    }
}

class ContinueStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ContinueStatement:
            continue ;
            continue Identifier ;
     */
    public void parse()
    {
        parseTerminal( TOK.Tcontinue );
        if( !ts.next(TOK.Semicolon) )
        {
            parseR!(Identifier);
        }
        parseTerminal( TOK.Semicolon );
		// Kuan Hsu
		if( activeNode.DType == D_BLOCK )
			if( activeNode.baseClass == "case" ) activeNode = activeNode.getRoot();
		// End of Kuan Hsu		
    }
}

class BreakStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        BreakStatement:
            break ;
            break Identifier ;
     */
    public void parse()
    {
        parseTerminal( TOK.Tbreak );
        if( !ts.next(TOK.Semicolon) )
        {
            parseR!(Identifier);
        }
        parseTerminal( TOK.Semicolon );

		// Kuan Hsu
		if( activeNode.DType == D_BLOCK )
			if( activeNode.baseClass == "case" ) activeNode = activeNode.getRoot();
		// End of Kuan Hsu
    }
}

class ReturnStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        ReturnStatement:
            return ;
            return Expression ;
     */
    public void parse()
    {
        parseTerminal( TOK.Treturn );
        if( !ts.next(TOK.Semicolon) )
        {
            parseR!(Expression);
        }
        parseTerminal( TOK.Semicolon );

		// Kuan Hsu
		if( activeNode.DType == D_BLOCK )
			if( activeNode.baseClass == "case" ) activeNode = activeNode.getRoot();
		// End of Kuan Hsu
    }
}

class ScopeStatement : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        ScopeStatement:
            scope ( Identifier ) Statement
     */
    public void parse()
    {
        parseTerminal( TOK.Tscope );
        parseTerminal( TOK.Openparen );
        parseR!(Identifier);
        parseTerminal( TOK.Closeparen );
        parseR!(Statement);
    }
}

class ThrowStatement : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        ThrowStatement:
            throw Expression ;
     */
	public void parse()
	{
		parseTerminal( TOK.Tthrow );
		parseR!(Expression);
		parseTerminal( TOK.Semicolon );

		// Kuan Hsu
		if( activeNode.DType == D_BLOCK )
		if( activeNode.baseClass == "case" ) activeNode = activeNode.getRoot();
		// End of Kuan Hsu		 
	}
}

class SynchronizeStatement : ParseRule
{
    this(TokenScanner ts)
    {
        super(ts);
    }
    /**
        SynchronizeStatement:
            synchronized Statement
            synchronized ( Expression ) Statement
     */
    public void parse()
    {
        parseTerminal( TOK.Tsynchronized );
		activeNode = activeNode.addLeaf( 0, D_BLOCK, "synchronized", "synchronized", ts.peek().lineNumber, null, "synchronized" ); // Kuan Hsu
		
        if( ts.next( TOK.Openparen ) )
        {
            parseTerminal();
            parseR!(Expression);
            parseTerminal( TOK.Closeparen );
        }
		
        parseR!(Statement);
		activeNode = activeNode.getRoot; // Kuan Hsu
    }
}

class TryStatement : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        TryStatement:
            try Statement Catches
            try Statement Catches FinallyStatement
            try Statement FinallyStatement
     */
    public void parse()
    {
        parseTerminal( TOK.Ttry );
		activeNode = activeNode.addLeaf( 0, D_BLOCK, "try", "try", ts.peek().lineNumber, null, "try" ); // Kuan Hsu
        parseR!(Statement);
		activeNode = activeNode.getRoot(); // Kuan Hsu
        if( ts.next( TOK.Tcatch ) )
        {
            parseR!(Catches);
        }
        if( ts.next( TOK.Tfinally ) )
        {
            parseR!(FinallyStatement);
        }
    }
}

class Catches : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        Catches:
            LastCatch
            Catch
            Catch Catches
     */
    public void parse()
    {
        //if catch is followed by a "(" then it's not a LastCatch
        ts.read();
        bool lastCatch =  !ts.next( TOK.Openparen );
        ts.unwind();

		activeNode = activeNode.addLeaf( 0, D_BLOCK, "catch", "catch", ts.peek().lineNumber, null, "catch" ); // Kuan Hsu

        if( lastCatch )
        {
            parseR!(LastCatch);
			activeNode = activeNode.getRoot(); // Kuan Hsu
            return;
        }
        else
        {
            parseR!(Catch);
			activeNode = activeNode.getRoot(); // Kuan Hsu
            if( ts.next( TOK.Tcatch ) )
            {
                parse(); //recursive
            }
        }
    }
}

class Catch : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        Catch:
            catch ( CatchParameter ) Statement
     */
    public void parse()
    {
        parseTerminal( TOK.Tcatch );
        parseTerminal( TOK.Openparen );
        parseR!(CatchParameter);
        parseTerminal( TOK.Closeparen );
        parseR!(Statement);
    }
}

class CatchParameter : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        CatchParameter:
            IdentifierSequence
            IdentifierSequence Identifier
            
     */
    public void parse()
    {
		// Kuan Hsu
		char[] typeIdent, ident;
		tokenText = null;
		// End of Kuan Hsu

		parseR!(IdentifierSequence);

		typeIdent = tokenText; // kuan Hsu
		
        if( ts.next( TOK.Identifier ) )
        {
			tokenText = null; // kuan Hsu

			parseR!(Identifier);

			ident = tokenText; // kuan Hsu
			activeNode.addLeaf( 0, D_PARAMETER, ident, typeIdent, ts.peek().lineNumber ); // kuan Hsu
        }
    }
}

class LastCatch : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        LastCatch:
            catch Statement
     */
    public void parse()
    {
        parseTerminal( TOK.Tcatch );
        parseR!(Statement);
    }
}

class FinallyStatement : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        FinallyStatement:
            finally Statement
     */
    public void parse()
    {
        parseTerminal( TOK.Tfinally );
		activeNode = activeNode.addLeaf( 0, D_BLOCK, "finally", "finally", ts.peek().lineNumber, null, "finally" ); // Kuan Hsu
        parseR!(Statement);
		activeNode = activeNode.getRoot(); // Kuan Hsu
    }
}

class VolatileStatement : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        VolatileStatement:
            volatile Statement
     */
    public void parse()
    {
        parseTerminal( TOK.Tvolatile );
        parseR!(Statement);
    }
}

class WithStatement : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        WithStatement:
            with ( Expression ) Statement
     */
    public void parse()
    {
        parseTerminal( TOK.Twith );
        parseTerminal( TOK.Openparen );

		// Kuan Hsu
		tokenText = "";
		//activeNode = activeNode.addLeaf( 0, D_WITH, "with", "with", ts.peek().lineNumber );
		activeNode = activeNode.addLeaf( 0, D_BLOCK, "with", "with", ts.peek().lineNumber, null, "with" );
		// End of Kuan Hsu
       
		parseR!(Expression);

		// Kuan Hsu
		char[] ident, typeIdent;
		
		char[][] nameAndType = std.string.split( tokenText, "new " );
		if( nameAndType.length == 1 )
		{
			ident = tokenText;
		}
		else
		{
			ident = nameAndType[0];
			if( nameAndType[0].length )
				if( nameAndType[0][length-1] == '=' ) ident = nameAndType[0][0..length-1];

			typeIdent = nameAndType[1];
			if( nameAndType[1].length )
			{
				int openparenPos = std.string.find( nameAndType[1], "(" );
				if( openparenPos > 0 ) typeIdent = nameAndType[1][0..openparenPos];
			}
		}

		activeNode.identifier = ident;
		activeNode.typeIdentifier = typeIdent;
		// End of Kuan Hsu

		//activeNode = activeNode.addLeaf( 0, D_WITH, tokenText, "with", ts.peek().lineNumber ); // Kuan Hsu
		
        parseTerminal( TOK.Closeparen );
        parseR!(Statement);

		// Kuan Hsu
		bool bNoLeaf;
		if( activeNode.getLeafCount == 0 ) bNoLeaf = true;
		activeNode = activeNode.getRoot(); // Kuan Hsu
		// End of Kuan
    }
}

class AsmStatement : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        AsmStatement:
            asm { }
            asm { AsmInstructionList }
     */
    public void parse()
    {
        parseTerminal( TOK.Tasm );
        parseTerminal( TOK.Opencurly );
        if( !ts.next( TOK.Closecurly ) )
        {
            parseR!(AsmInstructionList);
        }
        parseTerminal( TOK.Closecurly );
    }
}

class AsmInstructionList : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        AsmInstructionList:
            AsmInstruction
            AsmInstruction AsmInstructionList
     */
    public void parse()
    {
        while( !ts.next( TOK.Closecurly ) )
        {
            parseR!(AsmInstruction);
        }
    }
}

class AsmInstruction : ParseRule
{
    public this(TokenScanner ts)
    {
        super(ts);
    }

    /**
        AsmInstruction:
            any_squence_of_tokens ;
     */
    public void parse()
    {
        while( !ts.next( TOK.Semicolon ) )
        {
            parseTerminal();
        }
        parseTerminal();
    }
}

private StatementHandler handle;

static this()
{
    handle = new StatementHandler;
}

class StatementHandler : AbstractParseHandler
{
    this()
    {
        super();
    }
    void initializeHandler()
    {
        assign!(IfStatement).toParse(TOK.Tif);
        assign!(StatementBlock).toParse(TOK.Opencurly);
        assign!(WhileStatement).toParse(TOK.Twhile);
        assign!(DoWhileStatement).toParse(TOK.Tdo);
        assign!(ForStatement).toParse(TOK.Tfor);
        assign!(ForEachStatement).toParse(TOK.Tforeach);
        assign!(ForEachStatement).toParse(TOK.Tforeach_reverse);
        assign!(SwitchStatement).toParse(TOK.Tswitch);
        assign!(GotoStatement).toParse(TOK.Tgoto);
        assign!(CaseStatement).toParse(TOK.Tcase);
        assign!(DefaultCaseStatement).toParse(TOK.Tdefault);
        assign!(BreakStatement).toParse(TOK.Tbreak);
        assign!(ContinueStatement).toParse(TOK.Tcontinue);
        assign!(ReturnStatement).toParse(TOK.Treturn);
        assign!(ConditionalCompilationStatement).toParse(TOK.Tversion);
        assign!(ConditionalCompilationStatement).toParse(TOK.Tdebug);
        assign!(ThrowStatement).toParse(TOK.Tthrow);
        assign!(SynchronizeStatement).toParse(TOK.Tsynchronized);
        assign!(TryStatement).toParse(TOK.Ttry);
        assign!(VolatileStatement).toParse( TOK.Tvolatile );
        assign!(WithStatement).toParse( TOK.Twith );
        assign!(AsmStatement).toParse( TOK.Tasm );
		//assign!(MixinExpression).toParse( TOK.Tmixin );

        assign!(EnumDeclaration).toParse(TOK.Tenum);
        assign!(ClassDeclaration).toParse(TOK.Tclass);
        assign!(InterfaceDeclaration).toParse(TOK.Tinterface);
        assign!(StructDeclaration).toParse(TOK.Tstruct);
        assign!(UnionDeclaration).toParse(TOK.Tunion);
        
        assign!(Pragma).toParse(TOK.Tpragma);

        assign!(ExpressionStatement).toParse(TOK.Tnew);
        assign!(ExpressionStatement).toParse(TOK.Tdelete);
        assign!(ExpressionStatement).toParse(TOK.Tand);
        assign!(ExpressionStatement).toParse(TOK.Tmul);
        assign!(ExpressionStatement).toParse(TOK.Tplusplus);
        assign!(ExpressionStatement).toParse(TOK.Tminusminus);
        assign!(ExpressionStatement).toParse(TOK.Tmin);
        assign!(ExpressionStatement).toParse(TOK.Tadd);
        assign!(ExpressionStatement).toParse(TOK.Tnot);
        assign!(ExpressionStatement).toParse(TOK.Ttilde);
        assign!(ExpressionStatement).toParse(TOK.Tassert);
        assign!(ExpressionStatement).toParse(TOK.Tcast);
        assign!(ExpressionStatement).toParse(TOK.Openparen); //TEMP!!
        assign!(ExpressionStatement).toParse(TOK.Tthis); //TEMP

        assign!(TemplateMixin).toParse(TOK.Tmixin);
        assign!(Declaration).toParse(TOK.Ttypeof);
        assign!(Typedef).toParse(TOK.Ttypedef);
        assign!(Typedef).toParse(TOK.Talias);
        
        
        handle[TOK.Identifier] = &handleIdentifierSequence;
        handle[TOK.Tdot] = &handleIdentifierSequence;
        
        handle[TOK.Tstatic] = &handleStatic;
        handle[TOK.Tauto] = &handleStorageClass;
        handle[TOK.Tconst] = &handleStorageClass;
        handle[TOK.Tabstract] = &handleStorageClass;
        handle[TOK.Toverride] = &handleStorageClass;
        handle[TOK.Tfinal] = &handleStorageClass;
        handle[TOK.Tdeprecated] = &handleStorageClass;
		handle[TOK.T__gshared] = &handleStorageClass;
		handle[TOK.Tshared] = &handleStorageClass;
        		handle[TOK.Tscope] = &handleScope;
				handle[TOK.Tinvariant] = &handleStorageClass;
				handle[TOK.Timmutable] = &handleStorageClass;
    }



    /**
        Resolve / disambiguate decalrations from expression statements from labels
     */
    ParseNode handleIdentifierSequence( TokenScanner ts )
    {
        if( isLabel(ts) )
        {
            return parseRuleT!( LabelStatement ).using(ts);
        }
        else if( isDeclaration(ts) )
        {
            return parseRuleT!( DeclarationStatement ).using(ts);
        }
        else
        {
            return parseRuleT!( ExpressionStatement ).using(ts);
        }
        
    }

    ParseNode handleStatic( TokenScanner ts )
    {
        expect( ts, TOK.Tstatic );
        switch( ts.peektype(2) )
        {
            
            case TOK.Tif: return parseRuleT!(ConditionalCompilationStatement).using(ts);
            case TOK.Tassert: return parseRuleT!(StaticAssert).using(ts);
            default: return handleStorageClass( ts );
        }
    }

		ParseNode handleScope( TokenScanner ts ) 
		{ 
			if( ts.next( TOK.Tscope, TOK.Openparen ) ) // scope( 
			{ 
				return parseRuleT!(ScopeStatement).using(ts); 
			} 
			else 
			{ 
				return handleStorageClass(ts); 
			} 
		}
		
    ParseNode handleStorageClass( TokenScanner ts )
    {
        if( AutoDeclaration.isAutoDeclaration(ts) )
        {
            return parseRuleT!(AutoDeclaration).using(ts);
        }
        else
        {
            return parseRuleT!(StorageClassDeclarationStatement).using(ts);
        }
    }

    /**
        Check whether or not this is a declaration with assignment, i.e.
        type var = expression

        with our grammar, this should produce a parse tree that looks like this:

             [declaration]
               /       \
              /         \
         [type]      [declarator]
                      /  |   \
                     /   |    \
         [declarator]    =     [initializer]
         
     */
    bool isAssignDeclaration( TokenScanner ts )
    {
        if( !isDeclaration(ts) )
        {
            return false;
        }
        int c = ts.cursor;
        scope(exit)
        {
            ts.setCursor(c);
        }

        try
        {
            parseRuleT!( Type ).using(ts);
            auto dcltr = parseRuleT!( Declarator ).using(ts);
            auto ch = dcltr.getChildren();
            if( ch.length >= 3 )
            {
                if( isLeaf(ch[1]) )
                {
                    if( (cast(Terminal)ch[1]).getToken().type == TOK.Tassign )
                    {
                        return true;
                    }
                }
            }
            return false;
        }
        catch( Object e )
        {
            return false;
        }
        
    }

    /**
        Check whether this is a declaration or not

        Params:
            ts: the token scanner that we want to check on

        //TODO: this is ugly, once it works, try to rewrite it nicely 
                while making sure it still works        
     */
    bool isDeclaration( TokenScanner ts )
    {
        //record the cursor so we can restore it
        int c = ts.cursor;
        scope(exit)
        {
            ts.setCursor( c ); //restore original cursor
        }

        if( AutoDeclaration.isAutoDeclaration(ts) )
            return true;
        if( !isIdentifierSequence(ts) )
            return false;
        
        parseRuleT!( IdentifierSequence ).using(ts);
        if( ts.next( TOK.Identifier ) )    //type followed by declarator or
        {
            return true;
        }
        else if( ts.next( TOK.Tmul ) //pointer specification
                || ts.next( TOK.Tfunction ) || ts.next( TOK.Tdelegate ) // function pointer
                )
        {
            return true;
        }
        else if( ts.next( TOK.Openbracket ) ) //could be an array declaration or an array access
        {
            //consume all successive [...]
            while( ts.next( TOK.Openbracket ) )
            {
                ts.skipBrackets();
            }
            if( // Kuan Hsu ts.next( TOK.Openparen ) || //if followed by an identifier, it's a declarator
                ts.next( TOK.Identifier ) || //if by a parenthesis, it's probably a c-style declaration
                ts.next( TOK.Tdelegate ) || //if by a delegate or a function, it's a function pointer
                ts.next( TOK.Tfunction )
            )
            {
                return true;
            }
            else        //otherwise it can't be a declaration (I think!!)
            {
                return false;
            }
            
        }
        //identifierSequence followed by a ( *
        //this could be a function call or a c-style declaration
        else if( ts.next( TOK.Openparen, TOK.Tmul ) )
        {
            //check for c-style declaration
            //    IdentifierSequence ( * ...) (...)     is a c-style function pointer
            //    IdentifierSequence ( * ...) [...]     is a c-style array //really?! this maybe wrong    TODO:investigate this
            
            ts.skipParens();    //skip first parenthesis block (recursively)
            if( ts.next( TOK.Openparen ) ||
                ts.next( TOK.Openbracket ) ) //c-style declaration
            {
                return true;
            }
            else //not a declaration
            {
                return false;
            }
        }
        else
        {
            //not a declaration
            return false;
        }
    }

    bool isLabel( TokenScanner ts )
    {
        return ts.next( TOK.Identifier, TOK.Colon );
    }

    bool isIdentifierSequence( TokenScanner ts )
    {
        return ts.next( TOK.Tdot ) || ts.next( TOK.Identifier ) || ts.next( TOK.Tthis );
    }
}
