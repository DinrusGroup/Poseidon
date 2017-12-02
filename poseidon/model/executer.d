module poseidon.model.executer;

private import dwt.all;
private import dwt.internal.win32.os;
private import dwt.internal.converter;
private import poseidon.model.misc;
private import std.c.windows.windows;

private import poseidon.globals;


extern (Windows) {

const uint HANDLE_FLAG_INHERIT		= 0x00000001;
const uint STARTF_USESHOWWINDOW    	= 0x00000001;
const uint STARTF_USESTDHANDLES    	= 0x00000100;
const uint CREATE_NO_WINDOW			= 0x08000000;
const uint DEBUG_ONLY_THIS_PROCESS 	= 0x00000002; 
const uint NORMAL_PRIORITY_CLASS	= 0x00000020;
//const uint WAIT_OBJECT_0			= 0x00000000;
const uint WAIT_TIMEOUT 			= 0x00000102;
const uint STILL_ACTIVE				= 0x00000103;

struct STARTUPINFO { // si 
    DWORD   cb; 
    LPTSTR  lpReserved; 
    LPTSTR  lpDesktop; 
    LPTSTR  lpTitle; 
    DWORD   dwX; 
    DWORD   dwY; 
    DWORD   dwXSize; 
    DWORD   dwYSize; 
    DWORD   dwXCountChars; 
    DWORD   dwYCountChars; 
    DWORD   dwFillAttribute; 
    DWORD   dwFlags; 
    WORD    wShowWindow; 
    WORD    cbReserved2; 
    LPBYTE  lpReserved2; 
    HANDLE  hStdInput; 
    HANDLE  hStdOutput; 
    HANDLE  hStdError; 
}
alias STARTUPINFO* PSTARTUPINFO, LPSTARTUPINFO;

struct PROCESS_INFORMATION { // pi 
    HANDLE hProcess; 
    HANDLE hThread; 
    DWORD dwProcessId; 
    DWORD dwThreadId; 
}
alias PROCESS_INFORMATION* PPROCESS_INFORMATION, LPPROCESS_INFORMATION;
	
BOOL CreatePipe(
  HANDLE* hReadPipe,                       // pointer to read handle
  HANDLE* hWritePipe,                      // pointer to write handle
  LPSECURITY_ATTRIBUTES lpPipeAttributes,  // pointer to security attributes
  DWORD nSize                              // pipe size
);

BOOL CreateProcessA(
	LPCTSTR lpApplicationName,
	                 // pointer to name of executable module
	LPTSTR lpCommandLine,  // pointer to command line string
	LPSECURITY_ATTRIBUTES lpProcessAttributes,  // process security attributes
	LPSECURITY_ATTRIBUTES lpThreadAttributes,   // thread security attributes
	BOOL bInheritHandles,  // handle inheritance flag
	DWORD dwCreationFlags, // creation flags
	LPVOID lpEnvironment,  // pointer to new environment block
	LPCTSTR lpCurrentDirectory,   // pointer to current directory name
	LPSTARTUPINFO lpStartupInfo,  // pointer to STARTUPINFO
	LPPROCESS_INFORMATION lpProcessInformation  // pointer to PROCESS_INFORMATION
);


BOOL SetHandleInformation(
  HANDLE hObject,  // handle to an object
  DWORD dwMask,    // specifies flags to change
  DWORD dwFlags    // specifies new values for flags
);

BOOL TerminateThread(
  HANDLE hThread,    // handle to the thread
  DWORD dwExitCode   // exit code for the thread
);

BOOL PeekNamedPipe(
  HANDLE hNamedPipe,
  LPVOID lpBuffer,
  DWORD nBufferSize,
  LPDWORD lpBytesRead,
  LPDWORD lpTotalBytesAvail,
  LPDWORD lpBytesLeftThisMessage
);

BOOL TerminateProcess(
  HANDLE      hProcess,
  UINT        uExitCode
);
}


/**
 * A windows program will not be blocked or capture output
 */
class Executer
{	
	private import std.thread;
	private import std.stream;
	
	public static int run(ToolEntry entry, void delegate(Object) dgEcho, Display display) {

		// sometime space is added to cmd or argument lists by accident, remove they as well
		entry.cmd = std.string.strip(entry.cmd);
		entry.args = std.string.strip(entry.args);
		
		char[] ext = std.path.getExt(entry.cmd);
		
		Util.trace(entry.cmd);
		Util.trace(entry.args);

		// if an extention avaiable and rather than "exe" "com", ShellExcute it
		if(ext.length && std.string.icmp(ext, "exe") != 0 && std.string.icmp(ext, "com") != 0)
		{
			// ShellExecute refuse relative path, try get a abs path
			// " " can't applied
			if(!std.path.isabs(entry.cmd)){
				if(entry.dir.length > 0){
					entry.cmd = std.path.join(entry.dir, entry.cmd);
				}else{
					entry.cmd = std.path.join(std.file.getcwd(), entry.cmd);
				}
			}
			return Program.launch(entry.cmd ~ " " ~ entry.args);			
		}
		
		
		HANDLE hReadPipe = null;
		HANDLE hWritePipe = null;
				
		int lError = 0;

		if(entry.capture) 
		{
			SECURITY_ATTRIBUTES sa;
			sa.nLength = SECURITY_ATTRIBUTES.sizeof;
			sa.bInheritHandle = true;
			if(!CreatePipe(&hReadPipe, &hWritePipe, &sa, 0)){
				char[] err = "Failed to create pipe !\n";
				lError = GetLastError();
				err ~= std.windows.syserror.sysErrorString(lError);
				Util.trace(err);
				if(dgEcho && display){
					display.asyncExec(new StringObj(err), dgEcho);
				}
				return lError;
			}
			
			SetHandleInformation(hReadPipe, HANDLE_FLAG_INHERIT, 0);
		}
		
		STARTUPINFO si;
		si.cb = STARTUPINFO.sizeof;
		
		si.dwFlags    	= STARTF_USESHOWWINDOW | ((entry.capture) ? STARTF_USESTDHANDLES : 0);
		si.wShowWindow 	= cast(ushort)(entry.hideWnd ? OS.SW_HIDE : OS.SW_SHOW);
		si.hStdInput 	= null;
		si.hStdOutput 	= hWritePipe;
		si.hStdError 	= hWritePipe;

		char[] cmdline = entry.cmd ~ " " ~ entry.args;
		char* path = Converter.StrToMBCSz(entry.dir);
		char* pcmdline = Converter.StrToMBCSz(cmdline);
		
		Util.trace(entry.dir);
		Util.trace(cmdline);
		
		PROCESS_INFORMATION pi;
		if( !CreateProcessA(null, pcmdline, null, null, true,
		    NORMAL_PRIORITY_CLASS, null, path, &si, &pi)){
			if(entry.capture){
				CloseHandle( hReadPipe );
	        	CloseHandle( hWritePipe );
			}
			char[] err = "Failed to create proccess !\n";
			lError = GetLastError();
			/**
			 * Note : there is bug in Phobos std.windows.syserror.sysErrorString(), fromMBSz() need be called.
			 * use the DWT implment instead
			 */
//			err ~= std.windows.syserror.sysErrorString(lError);
			err ~= Display.getLastErrorText();
        	Util.trace(err);
        	if(dgEcho && display)
				display.asyncExec(new StringObj(err), dgEcho);
        	return lError;
		}
				
		
		if(entry.capture)
		{
			CloseHandle(hWritePipe);

			char[] s;
			File file = new File(hReadPipe, FileMode.In);
			while(!file.eof())
			{
				s = file.readLine();
					
				//if(s.length == 0 ) break;
				if(dgEcho && display) display.syncExec(new StringObj(s), dgEcho);
				if( Globals.bOutputStop ) break;
			}			
			file.close();

			Globals.bOutputStop = false;

			
			
			// hReadPipe automatically closed by file
//			if(entry.capture)
//				CloseHandle(hReadPipe);		
		}
		
		// Those process already opened such as explorer.exe by the call will not be blokced
		// Not used currently		
		bool block = false;
		if(block){
			uint dwExitCode;
				
			switch(WaitForSingleObject(pi.hProcess, -1)){
			case WAIT_OBJECT_0:
				// Process exit successfully
				Util.trace("OK");
				break;
			default:
				// Something error	or timeout		
				lError = GetLastError();
				if(dgEcho && display){
					char[] err = Display.getLastErrorText();
					display.asyncExec(new StringObj(err), dgEcho);
				}
				break;
			}
			CloseHandle(pi.hThread);
			CloseHandle(pi.hProcess);
		}
		
		return lError;
	}
	
}