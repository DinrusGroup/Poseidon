module poseidon.util.fileutil;

private import dwt.all;
private import dwt.internal.converter;



class FileReader{
	
	private import std.stream;


	private static bool isUTF8WithouBOM( char[] data )
	{
		for( int i = 0; i < data.length; ++ i )
		{
			if( !data[i] )
			{
				return false;
			}
			else if( data[i] < 0x80 )
			{
				i ++;
			}
			else if( data[i] < ( 0x80 + 0x40 ) )
			{
				return true;
			}
			else if( data[i] < (0x80 + 0x40 + 0x20) )
			{
				if( i >= data.length - 1 ) return true;

				if( !( data[i] & 0x1F ) || ( data[i+1] & ( 0x80+0x40 ) ) != 0x80 ) break;

				i += 2;
			}
			else if( data[i] < ( 0x80 + 0x40 + 0x20 + 0x10 ) )
			{
				if( i >= data.length - 2 ) return true;
					
				if( !( data[i] & 0xF) || ( data[i+1] & (0x80+0x40) ) != 0x80 || ( data[i+2] &( 0x80+0x40 ) ) != 0x80 ) break;
				
				i += 3;
			}
			else
			{
				break;
			}
		}

		return false;
	}

	
	/**
	 * pass the buffer to receive file content, the return value indicate whether 
	 * the operation successful.
	 */
	public static bool read(char[] filename, out char[] buffer, out int bom){
	
		// reset receiver buffer
		buffer = null;
		
		File file;
		EndianStream f;
		bom = -1;
		
		try{
			file = new File(filename, FileMode.In);		
		}catch(Exception e){
			printf(e.toString());
			throw e;
		}
		
		if(file.size() == 0){
			file.close();
			return true;
		}

		try
		{
			size_t i = 0;
			
			f = new EndianStream(file);
			bom = f.readBOM();
			
			// Util.trace("file length %d, bom %d", file.size(), bom);
			
			switch(bom)
			{
				case -1:
					// ANSI/MBCS should be convert to UTF8 encoding
					scope char[] buf = new char[cast(int)f.size()];
					while(!f.eof())
					{
						buf[i++] = f.getc();
					}

					if( isUTF8WithouBOM( buf ) )
					{
						buffer = buf[0 .. i];
						bom = -2;
					}
					else
					{
						/**
						 * std.system.OS conflict with dwt.internal.win32.os.OS,
						 * use full package name
						 */
						int cp = dwt.internal.win32.os.OS.GetACP();
						char[] temp = Converter.MBCSzToStr(buf.ptr, buf.length, cp); 
						buffer = temp;
					}
					break;
				// UTF8
				case BOM.UTF8:
					// some time you get -1, set it to UTF8
					scope char[] buf = new char[cast(int)f.size()];
					while(!f.eof())
					{
						buf[i++] = f.getc();
					}
					buffer = buf[0 .. i];
					break;
				// UTF16
				case BOM.UTF16LE, BOM.UTF16BE:
					scope wchar[] wbuf = new wchar[cast(int)f.size() / wchar.sizeof];
					while(!f.eof())
					{
						wbuf[i++] = f.getcw();
					}
					buffer = std.utf.toUTF8(wbuf[0 .. i]);
					break;
				// UFT32
				case BOM.UTF32LE, BOM.UTF32BE:
					scope dchar[] dbuf = new dchar[cast(int)f.size() / dchar.sizeof];
					while(!f.eof())
					{
						dchar dch;
						f.read(dch);
						dbuf[i++] = dch;
					}
					buffer = std.utf.toUTF8(dbuf[0 .. i]);
					break;
				default : break;
			}
		}catch(Exception e){
			throw e;
		}
		finally
		{
			delete f;
			file.close();
			delete file;
		}
		
		return true;
	}
}

class FileSaver{

	private import std.stream;
	private import std.system;
	

	public this(){
	}
	/**
	 * the input buffer is in UTF8 format
	 */	
	public static bool save(char[] filename, char[] buffer, int bom = BOM.UTF8){
		int sz;
		Endian endian;
		
		// Util.trace("buffer length %d, bom %d", buffer.length, bom);
		
		switch(bom)
		{
			case -1:
				sz = char.sizeof;
				break;
			case BOM.UTF8:
			case -2: // UTF8 without BOM
				sz = char.sizeof;
				endian = std.system.endian;
				break;
			
			case BOM.UTF16LE:
				sz = wchar.sizeof;
				endian = Endian.LittleEndian;
				break;
			
			case BOM.UTF16BE:
				sz = wchar.sizeof;
				endian = Endian.BigEndian;
				break;
			
			case BOM.UTF32LE:
				sz = dchar.sizeof;
				endian = Endian.LittleEndian;
				break;
			
			case BOM.UTF32BE:
				sz = dchar.sizeof;
				endian = Endian.BigEndian;
				break;
			default : break;
		}
		
		File _f;
		EndianStream f;
		
		
		try
		{	
			// incase the file is read only
			_f = new File(filename, FileMode.OutNew);
			f = new EndianStream(_f, endian);
			if( bom > -1 )
				f.writeBOM(cast(BOM)bom);
			
			switch(sz)
			{
				case char.sizeof:
					if(bom == -1){
						// UTF8 ot ANSI/MBCS
						int cp = dwt.internal.win32.os.OS.GetACP();
						char[] cs = Converter.StrToMBCS(buffer, cp);
						f.writeExact(cs.ptr, cs.length);
					}else{
						// UTF8
						f.writeExact(buffer.ptr, buffer.length);
					}
					break;
				
				case wchar.sizeof:
					foreach(wchar ch; buffer)
					{	
						f.write(ch);
					}
					break;
				
				case dchar.sizeof:
					foreach(dchar ch; buffer)
					{
						f.write(ch);
					}
					break;
				default : break;
			}
		}catch(Exception e){
			Util.trace(e.toString());
			throw e;
		}
		finally
		{
			delete f;
			_f.close();
			delete _f;
		}
		
		return true;
	}
}

version( Windows )
{
	private
	{
		import std.c.windows.windows;
		import std.windows.charset;

		alias WORD FILEOP_FLAGS;

		struct SHFILEOPSTRUCTA
		{
			HWND            hwnd;
			UINT            wFunc;
			LPCSTR          pFrom;
			LPCSTR          pTo;
			FILEOP_FLAGS    fFlags;
			BOOL            fAnyOperationsAborted;
			LPVOID          hNameMappings;
			LPCSTR          lpszProgressTitle; // only used if FOF_SIMPLEPROGRESS
		}
		alias SHFILEOPSTRUCTA* LPSHFILEOPSTRUCTA;
			
		struct SHFILEOPSTRUCTW
		{
			HWND            hwnd;
			UINT            wFunc;
			LPCWSTR         pFrom;
			LPCWSTR         pTo;
			FILEOP_FLAGS    fFlags;
			BOOL            fAnyOperationsAborted;
			LPVOID          hNameMappings;
			LPCWSTR         lpszProgressTitle; // only used if FOF_SIMPLEPROGRESS
		}
		alias SHFILEOPSTRUCTW* LPSHFILEOPSTRUCTW;

		extern(Windows)
		{
			int SHFileOperationA( LPSHFILEOPSTRUCTA lpFileOp );
			int SHFileOperationW( LPSHFILEOPSTRUCTW lpFileOp );
		}


		UINT        FO_DELETE                         = 0x0003;
		UINT        FOF_ALLOWUNDO                     = 0x0040;
		UINT        FOF_NOCONFIRMATION                = 0x0010;		
	}

	bool delFileToTrashCan( char[] fileFullPath, bool bConfirmation = true )
	{
		SHFILEOPSTRUCTA op;
		op.wFunc = FO_DELETE;
		if( bConfirmation ) op.fFlags = FOF_ALLOWUNDO; else op.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION;
		
		if( std.path.isabs( fileFullPath ) )
		{
			op.pFrom = std.windows.charset.toMBSz( fileFullPath );
			if( SHFileOperationA(&op) == 0 ) return true;
		}
		return false;	
	}
}