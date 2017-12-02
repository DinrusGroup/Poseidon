module CodeAnalyzer.utilCA.textScanner;

import CodeAnalyzer.lexical.module_file,
	   CodeAnalyzer.lexical.coreLex;
import CodeAnalyzer.utilCA.scanner,
       CodeAnalyzer.utilCA.string;

class TextScanner : Scanner!(dchar)
{
    private
    {
        int lineNumber = 1;
    }
    
    public
    {
        this( Module m )
        {
            this( m.getText() );
        }
        this( dchar[] text )
        {
            super(text);
        }

        dchar get( int index )
        {
            if( index >= text.length )
            {
                return 0;
            }
            else return super.get( index );
        }
        
        dchar[] text()
        {
            return getArray();
        }

        alias Scanner!(dchar).peek peek; // .. overloading peek
        bool peek( dchar[] str )
        {
            return peek( str.length ) == str;
        }
        
        void readToLineEnd()
        {
            while( peek() != '\n' && peek() != '\r' && !reachedEnd() )
            {
                read();
            }
        }
        
        void readUntil(dchar c, char[] msg = "")
        {
            while( peek() != c )
            {
                read();
				if( reachedEnd() )
				{
					throw new LexerException("Found EOF when looking for [" ~ msg ~ "]", this);
				}
            }
            assert( peek() == c );
        }
        //WARNING: duplicate code with above method...
        void readUntil(dchar[] s, char[] msg)
        {
            int length = s.length;
            while( peek(length) != s )
            {
                read();
				if( reachedEnd() )
				{
					throw new LexerException("Found EOF when looking for [" ~ msg ~ "]", this);
				}			
            }
            assert( peek(length) == s );
        }

        dchar invalid() { return dchar.init; } 
        
        dchar read()
        {
            dchar r = super.read();
            if( r == '\n' ) lineNumber++;
            return r;
        }

        dchar[] read(int length)
        {
            dchar[] str = super.read(length);

            foreach( c; str )
            {
                if( c == '\n' ) lineNumber++;
            }

            return str;
        }
        
        int getLineNumber()
        {
            return lineNumber;
        }
    }
}

//for convenience .. mostly needed when throwing exceptions.
char[] cutf8( dchar dc )
{
    return ( ""d ~ dc ).utf8();
}
