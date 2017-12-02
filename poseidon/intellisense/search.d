module poseidon.intellisense.search;

private import std.string;
private import std.c.string;

void char_rootSearchR(int l , int r, in char[] root , in char[][] sortedItems, inout char[][] matches )
{
	if( l > r ) return;
		
	int m = ( l + r ) / 2; 					   // sortedItems 由中間開始搜尋,二分搜尋
		
	if( sortedItems[m].length >= root.length ) // 
	{
		if( sortedItems[m][0 .. root.length] == root ) 
		{
			matches ~= sortedItems[m];
			int temp = m - 1;
			
			if( temp >= 0 )
			{
				bool isMatched = true;
				while( isMatched )
				{
					isMatched = false;
					if( sortedItems[temp].length >= root.length ) 
					{
						if( sortedItems[temp][0 .. root.length] == root ) 
						{
							matches ~= sortedItems[temp];
							isMatched = true;
						}
					}
					
					temp--;
					if( temp < 0 ) break; 
				}
			}

			temp = m + 1;
			if( temp < sortedItems.length ) 
			{
				bool isMatched = true;
				while( isMatched )
				{
					isMatched = false;
					if( sortedItems[temp].length >= root.length )
					{
						if( sortedItems[temp][ 0 .. root.length ] == root )
						{
							matches ~= sortedItems[temp];
							isMatched = true;
						}

						temp++;
						if ( temp >= sortedItems.length) break; 
					}
				}
			}

			return; // match found, break out
	    }
	}

	if( root < sortedItems[m] )
		char_rootSearchR( l,m - 1, root, sortedItems, matches );
	else
		char_rootSearchR( m + 1, r, root, sortedItems, matches );
		
	return;
}


int icharCompare ( char[] x, char[] y )
{
    return std.string.tolower( x ) < std.string.tolower( y ) ? -1 : 0;
}

template TArray(_type)
{
	int sort (inout _type[] ar,int function(_type a,_type b) compareFunc)
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

	int sort (inout _type[] ar,int delegate(_type a,_type b) compareFunc)
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
	
	int remove( inout _type[] ar, int index, int len=1 )
	{
		if( index < 0 || index >= ar.length || index+len>ar.length )
			return 0;
		if( len == 0 )
			len=ar.length-index;
		if(len==ar.length)
		{
			ar.length=0;
			return 1;
		}
		int end=ar.length-len;
		int c2=0;
		int c3=0;
		int i=0;
		for(int c=index;c<end;c+=len)
		{
			c3=c+len;
			for(i=c;i<c3&&i<end;i++)
			{
				c2=i+len;
				ar[i]=ar[c2];
			}
		}
		ar.length=ar.length-len;
		return 1;
	}

	void shift( inout _type[] ar, _type ptr )
	{
		ar.length = ar.length + 1;
		if( ar.length > 1 )
	    	memmove( ar.ptr + 1, ar.ptr, ar.length * (_type*).sizeof );
	    ar[0] = ptr;
	}

	void insert( inout _type[] ar, uint index, inout _type[] a )
	{
	    if( a.length )
	    {
			uint d = a.length;
//			reserve(d);
			uint d0 = ar.length;

			ar.length = ar.length + a.length;
			if( index != d0 )
			{
//				_type[] tmp = ar[index..$-1].dup;
//			    memmove( ar.ptr + index + a.length, ar.ptr + index, (d0 - index) * (_type*).sizeof );
			    memmove( ar.ptr + index + a.length, ar.ptr + index, (d0 - index) * (_type*).sizeof );
			}
//			memcpy( ar.ptr + index, a.ptr, d * (_type*).sizeof);
			ar[index..index+a.length] = a[0..$-1];
//			dim += d;
	    }
	}


	bool array_contains ( _type [] array, _type element )
	{
		foreach ( _type t;array )
		{
			if ( t == element ) return true;
			
		}
		
		return false;
		
	}
	
	_type [] array_diff( _type [] one, _type [] two )
	{
		_type [] ret;
		
		foreach ( _type element;one )
		{
			if ( array_contains(two,element ) ) continue;
			else ret ~= element;
			
		}
		
		foreach ( _type element;two )
		{
			if ( array_contains(one,element ) ) continue;
			else ret ~= element;
			
		}
		
		return ret;
		
	}
	
	_type [] array_unique( _type [] one )
	{
		_type [] ret;
		
		foreach ( _type element;one )
		{
			if ( array_contains(ret,element ) ) continue;
			else ret ~= element;
			
		}
	
		
		return ret;
		
	}
}

abstract class CHeapSort( T )
{
protected:
	T[]		container;
	T		global_temp;
	int 	c_index;

	void down_heap( int parent_index, int last_heap_index )
	{
		int		p_index, last_parent_index;

		global_temp			= container[parent_index];
		p_index           	= parent_index;
		last_parent_index 	= ( last_heap_index - 1 ) >> 1;

		while( p_index <= last_parent_index )
		{
			c_index = ( p_index << 1 ) + 1;
			if( c_index < last_heap_index )
				if( compFunc1 ) c_index ++;
			if( compFunc2() )
			{
				container[p_index] = container[c_index];
				p_index = c_index;
			}
			else break;
		}
		if( p_index != parent_index ) container[p_index] = global_temp;
	}

	void heap_sort()
	{
		if( container.length < 2 ) return;

		int		last_parent_index, last_heap_index;
		T		temp;

		last_heap_index   = container.length - 1;
		last_parent_index = ( last_heap_index - 1 ) >> 1;

		for( int i = last_parent_index; i >= 0; i -- )
			down_heap( i, container.length - 1 );

		temp = container[0];
		container[0] = container[last_heap_index];
		container[last_heap_index] = temp;

		last_heap_index --;
		last_parent_index = ( last_heap_index - 1 ) >> 1;
		for( int i = container.length - 2; i > 0; i -- )
		{
			down_heap( 0, i );
			temp = container[0];
			container[0] = container[i];
			container[i] = temp;
		}
	}

	bool 	compFunc1();

	bool 	compFunc2();	

public:
	
	this( T[] elements )
	{ 
		container = elements;
		sort();
	}

	~this(){ container.length = 0; }

	T 		opIndex( int i ){ return container[i]; } // Overload []

	void 	push( T[] elements ){ container = elements; }

	void 	push( T elements ){ container ~= elements; }

	T[] 	pop(){	return container; }

	void 	sort(){ heap_sort(); }
		
	int 	size(){ return container.length; }

	void	clear(){ container.length = 0; }
}


class CCharsSort( T ) : CHeapSort!( T )
{
protected:

	bool compFunc1()
	{
		return ( std.string.tolower( container[c_index + 1] ) >= std.string.tolower( container[c_index] ) );
	}

	bool compFunc2()
	{
		return ( std.string.tolower( container[c_index] ) >= std.string.tolower( global_temp ) );
	}
	
public:
	
	this( T[] elements ){ super( elements ); }
}


class CDTypeSort( T ) : CHeapSort!( T )
{
protected:

	bool compFunc1(){ return ( container[c_index + 1].DType >= container[c_index].DType ); }

	bool compFunc2(){ return ( container[c_index].DType >= global_temp.DType ); }

public:
	
	this( T[] elements ){ super( elements ); }
}


class CIdentSort( T ) : CHeapSort!( T )
{
private:
	import poseidon.globals;
protected:

	bool compFunc1()
	{
		if( Globals.showType )
			return ( std.string.tolower( container[c_index + 1].identifier ~  container[c_index + 1].typeIdentifier ) >= std.string.tolower( container[c_index].identifier ~ container[c_index].typeIdentifier ) );

		return ( std.string.tolower( container[c_index + 1].identifier ) >= std.string.tolower( container[c_index].identifier ) );
	}

	bool compFunc2()
	{
		if( Globals.showType )
			return ( std.string.tolower( container[c_index].identifier ~  container[c_index].typeIdentifier ) >= std.string.tolower( global_temp.identifier ~ global_temp.typeIdentifier ) );

		return ( std.string.tolower( container[c_index].identifier ) >= std.string.tolower( global_temp.identifier ) );
	}
	
public:
	
	this( T[] elements ){ super( elements ); }

	T[]		scintillaPop()
	{
		T		prevT = container[0];
		T[]		newContainer;

		newContainer ~= container[0];

		for( int i = 1; i < container.length; ++ i )
		{
			bool bDifferent;
			if( Globals.showType )
			{
				if( container[i].identifier ~ ":" ~ container[i].typeIdentifier != prevT.identifier ~ ":" ~ prevT.typeIdentifier )
					bDifferent = true;
			}
			else
			{
				if( container[i].identifier != prevT.identifier ) bDifferent = true;
			}

			if( bDifferent )
			{
				prevT = container[i];
				newContainer ~= container[i];
			}
		}

		// move underline-head words to tail
		container = newContainer;
		int i;
		for( i = 0; i < container.length; ++ i )
		{
			if( container[i].identifier.length )
				if( container[i].identifier[0] != '_' ) break;
		}

		if( i > 0 && i < container.length )
			newContainer = container[i..length] ~ container[0..i];

		return newContainer;
	}		

}