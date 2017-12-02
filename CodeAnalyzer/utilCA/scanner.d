module CodeAnalyzer.utilCA.scanner;


/**
    The concept of a scanner is related to the traditional way of reading/scanning a text buffer using 
    a char* (pointer). The scanner object provides a modular way to scan an array of object T (this is
    a templated class), you can read and peek one or more elements from the array.
 */
class Scanner(T)
{
    private
    {
        T[] array;
        int mcursor = 0;
        
        void advanceCursor()
        {
            advanceCursor(1);
        }
        
        void advanceCursor( int p )
        {
            if( canRead(p) )
            {
                mcursor += p;
            }
            else
            {
				if( mcursor == array.length )
					throw new Exception( "Out of Tokens!!" ); // Kuan Hsu
				else
				{
					//just read to end
					mcursor = array.length;
				}
            }
        }

        /**
            returns whether c is inside array boundaries
        */
        bool inbound( int c )
        {
            int first() { return 0; }
            int last() { return array.length - 1; }
            
            return c >= first && c <= last;
        }
    }

    public
    {
        this( T[] buffer )
        {
            array = buffer;
        }
            
        T[] getArray()
        {
            return array;
        }

        abstract T invalid();
        
        T get( int c )
        {
            if( !inbound(c) )
            {
                return invalid();
            }
        
            return array[c];
        }

        void setCursor( int c )
        {
            if( inbound(c) )
            {
                mcursor = c;
            }
            else
            {
                throw new Exception("Scanner cursor has been set to an out of bounds value");
            }
        }
        
        T[] slice( int a, int b )
        {
            assert( b >= a );
            assert( a >= 0 );
            
            if( a >= array.length )
            {
                return null;
            }
            if( b >= array.length )
            {
                b = array.length;
            }
            return array[a..b];
        }
        
        bool reachedEnd()
        {
            return mcursor >= array.length;
        }
        
        bool canRead( int length )
        {
            return mcursor + length <= array.length;
        }
        
        int getRemainingLength()
        {
            return array.length - mcursor;
        }
        
        T peek()
        {
            return get(mcursor);
        }
        
        T read()
        {
            int p = mcursor;
            advanceCursor();
            return get(p);
        }

        void unwind()
        {
            if( mcursor > 1 )
            {
                mcursor--;
            }
        }
        
        T[] peek(int length)
        {
            assert( length > 0 );
            return slice(mcursor,mcursor+length);
        }
        
        T[] read(int length)
        {
            assert( length > 0 );
            int p = mcursor;
            advanceCursor( length );
            return slice(p,p+length);
        }
        
        void restart()
        {
            mcursor = 0;
        }
        
        //properties
        int length() { return array.length; }
        int cursor(){ return mcursor; }
        void cursor(int c) { setCursor(c); }
        
        /**
            Keeps reading tokens until it reaches a token where the 
            condition on it is met!
            The condition is supplied as a boolean delegate.
            
            Derived classes should probably try to wrap this in a nice
            way so that the user doesn't see or worry about the delegate.
         */
        int readUntil(bool delegate(T o) cond)
        {
            while( !cond(peek()) && !reachedEnd() )
            {
                read();
            }
            assert( cond(peek()) || reachedEnd() );
            
            if( reachedEnd() && !cond(peek()) ) //if we reached the end without finding an object where the condition applies, return -1 to indicate that we didn't find it!
            {
                return -1;
            }
            read(); //consume o
            return cursor;
        }
    }
    
    invariant
    {
        assert( mcursor >= 0 && mcursor <= array.length );
    }
}
