module poseidon.style.xpm;


private import std.stream;

/* XPM */
static char** private_method_xpm, protected_method_xpm, public_method_xpm, private_variable_xpm, alias_obj_xpm,
				protected_variable_xpm, public_variable_xpm, class_private_obj_xpm, class_protected_obj_xpm,
				class_obj_xpm, struct_private_obj_xpm, struct_protected_obj_xpm, struct_obj_xpm, mixin_template_obj_xpm, 
				interface_private_obj_xpm, interface_protected_obj_xpm, interface_obj_xpm, union_private_obj_xpm,
				union_protected_obj_xpm, union_obj_xpm, enum_private_obj_xpm, enum_protected_obj_xpm, enum_obj_xpm,
				normal_xpm, import_xpm, autoWord_xpm, parameter_xpm, enum_member_obj_xpm, template_obj_xpm,
				functionpointer_obj_xpm, template_function_obj_xpm, template_class_obj_xpm, template_struct_obj_xpm,
				template_union_obj_xpm, template_interface_obj_xpm;

public static char** getXpm( char[] fileName )
{
	try
	{
		scope file = new File( fileName, FileMode.In );

		if( file.readLine() != "/* XPM */" ) return null;
			

		char[][] data;
		int countActiveLine;
		while( !file.eof )
		{
			char[] f = file.readLine();
			if( f.length )
			{
				if( f[0] == '"' )
				{
					int rPos = std.string.rfind( f, "\"" );

					data ~= ( f[1..rPos].dup );
					countActiveLine ++;
				}
			}
		}

		file.close;

		char** result = (new char*[countActiveLine]).ptr;
		for( int i; i < data.length; ++ i )
		{
			char[] charData = data[i];
			*( result + i ) = charData.ptr;
		}

		return result;
	}
	catch
	{
		return null;
	}
}