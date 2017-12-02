module poseidon.poseidon;

private import poseidon.loader;


version(build){
	debug{
		pragma(link, "DD-dwt.lib");
		pragma(link, "DD-dwtx.lib");
		//pragma(link, "dparser/dparser.lib");
	}else{
		pragma(link, "DD-dwt.lib");
		pragma(link, "DD-dwtx.lib");
		//pragma(link, "dparser/dparser.lib");
	}
	
	pragma(link, "poseidon.res");

	pragma(link, "advapi32.lib");
	pragma(link, "comctl32.lib");
	pragma(link, "gdi32.lib");
	pragma(link, "shell32.lib");
	pragma(link, "comdlg32.lib");
	pragma(link, "ole32.lib");
	pragma(link, "uuid.lib");
	pragma(link, "phobos.lib");
	
	pragma(link, "user32_dwt.lib");
	pragma(link, "imm32_dwt.lib");
	pragma(link, "shell32_dwt.lib");
	pragma(link, "msimg32_dwt.lib");
	pragma(link, "gdi32_dwt.lib");
	pragma(link, "kernel32_dwt.lib");
	pragma(link, "usp10_dwt.lib");
	pragma(link, "olepro32_dwt.lib");
	pragma(link, "oleaut32_dwt.lib");
	pragma(link, "oleacc_dwt.lib");
}else
{
	debug{
		pragma(lib, "dwtd.lib");
		pragma(lib, "dwtextrad.lib");
	}else{
		pragma(lib, "dwt.lib");
		pragma(lib, "dwtextra.lib");
	}	

	pragma( lib, "advapi32.lib");
	pragma( lib, "comctl32.lib");
	pragma( lib, "gdi32.lib");
	pragma( lib, "shell32.lib");
	pragma( lib, "comdlg32.lib");
	pragma( lib, "ole32.lib");
	pragma( lib, "uuid.lib");
	
	pragma( lib, "user32_dwt.lib");
	pragma( lib, "imm32_dwt.lib");
	pragma( lib, "shell32_dwt.lib");
	pragma( lib, "msimg32_dwt.lib");
	pragma( lib, "gdi32_dwt.lib");
	pragma( lib, "kernel32_dwt.lib");
	pragma( lib, "usp10_dwt.lib");
	pragma( lib, "olepro32_dwt.lib");
	pragma( lib, "oleaut32_dwt.lib");
	pragma( lib, "oleacc_dwt.lib");

}

/**
 * the global entrance
 */
void main(char[][] args){
	Loader.main(args);
}
