module poseidon.controller.debugcontrol.pipe;


class CPipe
{
private:
	import dwt.all;
	import poseidon.model.executer;
	import poseidon.model.misc;
	import poseidon.globals;
	import poseidon.controller.gui;

	import dwt.internal.win32.os;
	import std.c.windows.windows;
	import std.stream;

	import poseidon.controller.debugcontrol.debugger;
	import poseidon.controller.debugcontrol.debugparser;

	HANDLE						hReadPipe = null;
	HANDLE 						hWritePipe = null;
	PROCESS_INFORMATION 		pi;
	File 						fileIn, fileOut;
	bool						bPipeCreate;
	bool						bGetErrorMessage;

	void killProcess()
	{
		if( !bPipeCreate ) return;

		bPipeCreate = bGetErrorMessage = false;

		CloseHandle( hWritePipe );
		CloseHandle( hReadPipe );

		TerminateProcess( pi.hProcess, 0 );
		CloseHandle( pi.hThread );
		CloseHandle( pi.hProcess );		
	}

public:

	char[] outputBuffer;

	this( ToolEntry entry )
	{
		if( openConsole( entry ) )
		{
			sendCommand( "nc\n" );
			if( Globals.edDebug > 0 ) sendCommand( "ed " ~ std.string.toString( Globals.edDebug ) ~ "\n" );
			if( Globals.elDebug > 0 ) sendCommand( "el " ~ std.string.toString( Globals.elDebug ) ~ "\n" );
			foreach( char[] s; Globals.debuggerSearchPath )
			{
				sendCommand( "sp " ~ s ~ "\n" );
			}
		}
		else
		{
			bGetErrorMessage = true;
			//throw( new Exception( "Create Debug Process Error!!!" ) );
		}
	}

	~this()
	{
		if( fileIn !is null ) fileIn.close();
		if( fileOut !is null ) fileOut.close();
		killProcess();
	}

	bool openConsole( ToolEntry entry )
	{
		HANDLE consoleReadPipe = null;
		HANDLE consoleWritePipe = null;

		entry.cmd = std.string.strip( entry.cmd );
		entry.args = std.string.strip( entry.args );
		
		char[] ext = std.path.getExt( entry.cmd );
		
		Util.trace( entry.cmd );
		Util.trace( entry.args );


		// if an extention avaiable and rather than "exe" "com", ShellExcute it
		if( ext.length && std.string.icmp( ext, "exe" ) != 0 && std.string.icmp( ext, "com" ) != 0 )
		{
			// ShellExecute refuse relative path, try get a abs path
			// " " can't applied
			if( !std.path.isabs( entry.cmd ) )
			{
				if( entry.dir.length > 0 )
					entry.cmd = std.path.join( entry.dir, entry.cmd );
				else
					entry.cmd = std.path.join( std.file.getcwd(), entry.cmd );
				
			}
			return false;
		}
		

		SECURITY_ATTRIBUTES sa;
		sa.nLength = SECURITY_ATTRIBUTES.sizeof;
		sa.bInheritHandle = true;
		
		if( !CreatePipe( &consoleReadPipe, &hWritePipe, &sa, 0 ) ) return false;
		if( !CreatePipe( &hReadPipe, &consoleWritePipe, &sa, 0 ) )  return false;

		STARTUPINFO si;
		si.cb = STARTUPINFO.sizeof;
				
		si.dwFlags    	= STARTF_USESHOWWINDOW | ((entry.capture) ? STARTF_USESTDHANDLES : 0);
		si.wShowWindow 	= cast(ushort)(entry.hideWnd ? OS.SW_HIDE : OS.SW_SHOW);
		si.hStdInput 	= consoleReadPipe;
		si.hStdOutput 	= consoleWritePipe;
		si.hStdError 	= consoleWritePipe;

		char[] cmdline = entry.cmd ~ " " ~ entry.args;
		char* path = Converter.StrToMBCSz( entry.dir );
		char* pcmdline = Converter.StrToMBCSz( cmdline );
				
		Util.trace( entry.dir );
		Util.trace( cmdline );
				
		
		if( !CreateProcessA( null, pcmdline, &sa, &sa, true, NORMAL_PRIORITY_CLASS, null, path, &si, &pi ) )
			return false;
		else
		{
			bPipeCreate = true;
			
			fileIn 	= new File(hReadPipe, FileMode.In);
			fileOut = new File(hWritePipe, FileMode.Out);
			
			char[] result = readConsole();
			if( result.length > 4 )
			{
				if( result[length-5..length] == "-g\n->" ) return false;
			}
			else
				return false;
		}

		return true;
	}


	char[] sendCommand( char[] command, bool bShow = true )
	{
		try
		{
			fileOut.write( cast(ubyte[]) command );

			if( bShow ) sGUI.debuggerDMD.appendString( command );
			return readConsole( bShow );
		}
		catch( Exception e )
		{
			MessageBox.showMessage( "Send Command Error!!!\n" ~ e.toString );
		}

		return null;
	}

	char[] readConsole( bool bShow = true )
	{
		
		char	c;
		char[] 	result;
		
		while( !fileIn.eof() )
		{
			fileIn.read( c );

			result ~= c;

			if( c == '>' )
			{
				if( result.length > 2 )
				{
					if( result[length-3..length] == "\n->" ) break;
				}
				else if( result.length > 1 )
				{
					if( result[length-2..length] == "->" ) break;
				}
			}
		}

		if( bShow ) sGUI.debuggerDMD.appendString( result );

		return result;
	}	
		

	bool isPipeCreate(){ return bPipeCreate; }

	bool isError(){ return bGetErrorMessage; };
}