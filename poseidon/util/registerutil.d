module poseidon.util.registerutil;

version( Windows ):

extern( Windows ) void SHChangeNotify( int, uint, void*, void* );

class CRegister
{
private:
	import std.c.windows.windows;
	import std.path, std.string;

	const int MAX_KEY_LENGTH = 256;
	const int SHCNE_ASSOCCHANGED = 0x8000000;
	const int SHCNF_IDLIST = 0;	

	// [操作 function]
	// 對應滑鼠點兩下對應的動作 HKEY_CLASSES_ROOT\.<Extension>
	// Usage:
	// RegSetExtension(_T("abc"),_T("MyType.Document"),_T("MyPrograme.exe \%1"));
	static BOOL RegSetExtension( char[] strExt, char[] strDocumentClassName, char[] strShellOpenCommand )
	{
		// Step 1: 檢查指定的副檔名是否有問題
		if( !strExt.length ) return false;

		// Step 2: 建立 副檔名 key 並且設定 document class name 
		//         ex: .abc --> ABC.Document
		SetRegistryValue( HKEY_CLASSES_ROOT, strExt, null, strDocumentClassName );

		// Step 3: 指定開檔指令
		if( strShellOpenCommand.length )
		{
			strExt ~= "\\shell\\open\\command";
			SetRegistryValue( HKEY_CLASSES_ROOT, strExt, null, strShellOpenCommand );
		}

		return true;
	}

	// [操作 function]
	// 對應檔案總管滑鼠按右鍵, 以及檔案 icon 圖案設定
	// Usage:
	//      RegSetDocumentType(_T("MyType.Document"),_T("這是我自己設定的檔案型態"),_T("MyPrograme.exe,0"),_T("MyPrograme.exe \%1"));
	static bool RegSetDocumentType( char[] strDocumentClassName, char[] strDocumentDescription, char[] strDocumentDefaultIcon, char[] strShellOpenCommand )
	{

		// Step 1: 檢查輸入的 document class name  是否有問題
		if( !strDocumentClassName.length ) return false;


		// Step 2: 建立 document class name  key 並且指定對應的描述
		char[] csKey = strDocumentClassName;
		SetRegistryValue( HKEY_CLASSES_ROOT, csKey, null, strDocumentDescription );

		// Step 3: 指定檔案 DefaultIcon
		if( strDocumentDefaultIcon.length )
		{
			csKey  = strDocumentClassName;
			csKey ~= "\\DefaultIcon";
			SetRegistryValue( HKEY_CLASSES_ROOT, csKey, null, strDocumentDefaultIcon );
		}

		// Step 4: 設定開檔指令
		if( strShellOpenCommand.length )
		{
			csKey  = strDocumentClassName;
			csKey ~= "\\shell\\open\\command";
			SetRegistryValue( HKEY_CLASSES_ROOT, csKey, null, strShellOpenCommand );
		}

		return true;
	}	

	// [核心 function] 
	// 設定 [szKey, szValue] = szData
	// 例如: 
	//       [HKEY_CLASSES_ROOT\\shell\\open\\command,""]= abc.exe %1
	static BOOL SetRegistryValue( HKEY	hOpenKey, char[] szKey, char[] szValue, char[] szData )
	{
		BOOL 	bRetVal = FALSE;
		DWORD	dwDisposition;
		DWORD	dwReserved = 0;
		HKEY  	hTempKey;

		/*
		// Step 1: 先驗證輸入是否有問題
		if( !hOpenKey || !szKey || !szKey[0] || !szData ){
			//SetLastError(E_INVALIDARG);
			return FALSE;
		}
		*/

		// Step 2: 建立新的 Key (若 Key 已經存在, 則開啟他)
		if( ERROR_SUCCESS == RegCreateKeyExA( hOpenKey, szKey.ptr, 0, null, REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, null, &hTempKey, &dwDisposition ) )
		{
			if( ERROR_SUCCESS == RegSetValueExA( hTempKey, null, 0, REG_SZ, cast(ubyte*) szData.ptr, szData.length ) )
			{
				bRetVal = TRUE;
			}
		}

		// Step 3: Close key
		if( hTempKey ) RegCloseKey( hTempKey );

		return bRetVal;
	}

	static bool UnRegDocumentType( char[] strDocumentClassName )
	{
		// Step 1: 檢查輸入的 document class name  是否有問題
		if( !strDocumentClassName.length ) return false;

		char[] csKey = strDocumentClassName;
		char[] csShellCommandKey = csKey ~ "\\shell\\open\\command";

		// Step 2: Delete ShellCommand Key
		if( ERROR_SUCCESS != RegDeleteKeyA( HKEY_CLASSES_ROOT, csShellCommandKey.ptr ) ) return false;

		// Step 3: Delete strDocumentClassName key
		if( ERROR_SUCCESS != RegDeleteKeyA( HKEY_CLASSES_ROOT, csKey.ptr )) return false;

		return true;
	}

	static DWORD RegDeleteKeyNT( HKEY hStartKey, char[] KeyName )
	{
		DWORD   				dwRtn, dwSubKeyLength;
		char[]  				pSubKey;
		char[MAX_KEY_LENGTH]  	szSubKey; // (256) this should be dynamic.
		HKEY    				hKey;

		// Do not allow NULL or empty key name
		if( KeyName.length )
		{
			if( ( dwRtn = RegOpenKeyExA( hStartKey, KeyName.ptr, 0, KEY_ENUMERATE_SUB_KEYS | DELETE, &hKey ) ) == ERROR_SUCCESS )
			{
				while( dwRtn == ERROR_SUCCESS )
				{
					dwSubKeyLength = MAX_KEY_LENGTH;
					dwRtn = RegEnumKeyExA(
							hKey,
							0,       // always index zero
							szSubKey.ptr,
							&dwSubKeyLength,
							null,
							null,
							null,
							null
                            );

					if( dwRtn == ERROR_NO_MORE_ITEMS )
					{
						dwRtn = RegDeleteKeyA( hStartKey, KeyName.ptr );
						break;
					}
					else if( dwRtn == ERROR_SUCCESS )
						dwRtn = RegDeleteKeyNT( hKey, szSubKey );
				}
				RegCloseKey( hKey );
				// Do not save return code because error
				// has already occurred
			}
		}
		else
			dwRtn = 2;//ERROR_BADKEY;

		return dwRtn;
	}

public:
	static bool register( char[] ext, char[] documentType, char[] documentDescription, char[] exeFullPath, char[] iconIndex )
	{
		// Step 1: 設定想要註冊的副檔名以及檔案型態
		char[] 	strExt = "." ~ ext;
		char[]	strDoucumentType = documentType;
		
		// Step 2: 取得目前執行檔的位置
		char[] strShellCommand = exeFullPath ~ " %1";

		// Step 3: 設定 icon
		char[] strIcon = '"'~ exeFullPath ~ "\"," ~ iconIndex;
		
		// 關鍵片段: 
		// 註冊 strExt: 對應滑鼠點兩下對應的動作 
		if( !RegSetExtension( strExt, strDoucumentType, strShellCommand ) ) return false;

		// 註冊 strDoucumentType: 對應檔案總管滑鼠按右鍵, 以及檔案 icon 圖案設定
		if( !RegSetDocumentType( strDoucumentType, documentDescription, strIcon, strShellCommand ) ) return false;

		return true;
	}

	// 反向註冊
	static void unRegister( char[] ext, char[] documentType )
	{
		char[]  strFullExt = "." ~ ext;
		RegDeleteKeyNT( HKEY_CLASSES_ROOT, strFullExt );
		RegDeleteKeyNT( HKEY_CLASSES_ROOT, documentType );
	}

	static void refreshIcon()
	{
		// 通知 檔案總管我們換 icon 了
		SHChangeNotify( SHCNE_ASSOCCHANGED, SHCNF_IDLIST, null, null );
	}
}