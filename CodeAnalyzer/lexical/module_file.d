module CodeAnalyzer.lexical.module_file;

class Module
{
	private
	{
		import std.file;
		import poseidon.util.fileutil;
		dchar[] text;
	}
	
	public
	{
		this(){}
		
		this( char[] fileName )
		{
			if( exists( fileName ) )
			{
				// Kuan Hsu
				int bom;
				char[] tempText;
				FileReader.read( fileName, tempText, bom );
				text = std.utf.toUTF32( tempText );
				// End of Kuan Hsu
			}
			else
			{
				throw new Exception( "NoExist" );
			}
		}

		dchar[] getText()
		{
			return text;
		}

		void setText( dchar[] _text ){ text = _text; } // Kuan Hsu
		
	}
}