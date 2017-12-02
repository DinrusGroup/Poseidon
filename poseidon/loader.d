module poseidon.loader;


private import dwt.all;
private import poseidon.controller.gui;
private import poseidon.globals;
private import poseidon.controller.dialog.splash;
private import std.c.windows.windows;
private import std.utf;
	
//extern( Windows ) HANDLE CreateMutexA(LPSECURITY_ATTRIBUTES, BOOL, LPCSTR);

const int TH32CS_SNAPPROCESS = 0x2;

struct PROCESSENTRY32W
{
    DWORD dwSize;
    DWORD cntUsage;
    DWORD th32ProcessID;
    DWORD th32DefaultHeapID;
	DWORD th32ModuleID;
    DWORD cntThreads;
    DWORD th32ParentProcessID;
    LONG pcPriClassBase;
    DWORD dwFlags;
    WCHAR szExeFile[MAX_PATH];
}

struct PROCESSENTRY32
{
    DWORD dwSize;
    DWORD cntUsage;
	DWORD th32ProcessID;
	DWORD th32DefaultHeapID;
    DWORD th32ModuleID;
    DWORD cntThreads;
    DWORD th32ParentProcessID;
	LONG pcPriClassBase;
	DWORD dwFlags;
	CHAR  szExeFile[MAX_PATH];
}

alias PROCESSENTRY32W* PPROCESSENTRY32W;
alias PROCESSENTRY32W* LPPROCESSENTRY32W;


alias PROCESSENTRY32* PPROCESSENTRY32;
alias PROCESSENTRY32* LPPROCESSENTRY32;

alias int WINBOOL;
alias WINBOOL (*ENUMWINDOWSPROC)(HWND, LPARAM);

DWORD 	m_dwProcessId;
HWND	targetHWND;

extern( Windows )
{
	BOOL Process32FirstW(HANDLE,LPPROCESSENTRY32W);
	BOOL Process32NextW(HANDLE,LPPROCESSENTRY32W);
	BOOL Process32First(HANDLE,LPPROCESSENTRY32);
	BOOL Process32Next(HANDLE,LPPROCESSENTRY32);
	HANDLE CreateToolhelp32Snapshot(DWORD,DWORD);

	BOOL EnumWindows(ENUMWINDOWSPROC, LPARAM);
	DWORD GetWindowThreadProcessId(HWND, LPDWORD);

	LRESULT SendMessageA(HWND, UINT, WPARAM, LPARAM );
}

BOOL MyEnumProc( HWND hwnd, LPARAM lparam ) 
{ 
	char[]  strPrompt; 
	DWORD  ProcId; 
	DWORD  ThreadId; 
	ThreadId = GetWindowThreadProcessId( hwnd, &ProcId );

	if( ProcId == m_dwProcessId ) 
	{
		targetHWND = hwnd;
		return  FALSE;
	} 
	else
	{
		return  TRUE; 
	}
} 

HWND getHWND( char[] exeName )
{
	PROCESSENTRY32W 	Pro;
	HANDLE				HSnapshot;
	HSnapshot   =   	CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );
	if( HSnapshot )
	{
		Pro.dwSize = Pro.sizeof;
		if( Process32FirstW(HSnapshot, &Pro) )
		{
			do
			{
				char[] fileName = toUTF8( Pro.szExeFile );
				int posEXE = std.string.find( fileName, ".exe" );
				if( posEXE > 0 )
				{
					fileName = fileName[0..posEXE] ~ ".exe";
				}

				if( fileName == exeName )
				{
					//writef( fileName ~ " " );
					//writefln( Pro.th32ProcessID );
					m_dwProcessId = Pro.th32ProcessID;
					EnumWindows( &MyEnumProc,  Pro.th32ProcessID );					
					break;
				}
			} while(Process32NextW( HSnapshot, &Pro ) > 0 ) 
		}

		CloseHandle( HSnapshot );  
	}

	return targetHWND;
}



class Loader {

	private import std.stdio, std.stream;
	private import dwt.internal.win32.os;

	private Display display;
	private Shell	shell;

	//private static HANDLE handle;

	/** Load GUI and display a Splashscreen while loading */
	private this(){

		/** Apply application name to Display */
		Display.setAppName("Poseidon");
	
		/** Create a new Display */
		display = Display.getDefault();
		shell = new Shell(display);

		// show splash screen if desired
		Shell splash;
		if(Globals.showSplash){
			splash = new Splash(shell);
		}

		Globals.initI18N();
		Globals.loadI18N(Globals.curLang);


		/** Load the application */
		(new GUI(display, shell, splash)).showGui();
	}

	private static bool startupProcess(char[][] args)
	{
		/+
		// the first call
		handle = CreateMutexA( null, true, "Test".ptr );
		int ERROR_ALREADY_EXISTS = 183;
		if( GetLastError == ERROR_ALREADY_EXISTS )
		{
			HANDLE h = OS.FindWindow( null, "Poseidon" );
			if( h !is null )
			{
				if( args.length > 0 )
				{
					char[] fileName = args[0];

					struct COPYDATASTRUCT
					{
						int		dwData;
						int		cbData;
						int*	lpData;
					}					

					COPYDATASTRUCT copy;
					copy.cbData = fileName.length;
					copy.lpData = cast(int*) fileName.ptr;

					int WM_COPYDATA = 0x004A;
					OS.SendMessage( h, WM_COPYDATA, null, &copy );
				}
			}

			return false;
		}
		+/
		HWND myHWND;
		
		if( args.length > 0 ) myHWND = getHWND( std.path.getBaseName( args[0] ) );
		
		if( myHWND )
		{
			if( args.length > 1 )
			{
				char[] fileName = args[1];

				struct COPYDATASTRUCT
				{
					int		dwData;
					int		cbData;
					int*	lpData;
				}					

				COPYDATASTRUCT copy;
				copy.cbData = fileName.length;
				copy.lpData = cast(int*) fileName.ptr;

				if( OS.IsIconic( myHWND ) )	OS.ShowWindow( myHWND, SW_RESTORE );
					
				OS.SetForegroundWindow( myHWND );

				int WM_COPYDATA = 0x004A;
				OS.SendMessage( myHWND, WM_COPYDATA, null, &copy );
			}

			return false;
		}
		
		Globals.firstCall( args );
		return true;
	}

	public static void main(char[][] args){

		if( startupProcess(args) )
		{
			/** Start loading of Maincontroller */
			new Loader();
		}
		//if( handle !is null ) CloseHandle( handle );
	}
}
