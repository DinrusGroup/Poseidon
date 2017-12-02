module CodeAnalyzer.lexical.token_tables;

import CodeAnalyzer.lexical.token;
import CodeAnalyzer.utilCA.string;

public bool isKnownSymbol( dchar[] sym)
{
    char[] symbol = sym.utf8();
    return (symbol in tokenSymbolTable) != null;
}

public bool isKeyword( dchar[] ident)
{
    char[] identifier = ident.utf8();
    return (identifier in tokenKeywordTable) != null;
}

public TOK getTokenOfSymbol( dchar[] sym )
{
    char[] symbol = sym.utf8();
    return tokenSymbolTable[symbol];
}

public TOK getTokenOfKeyword( dchar[] kw )
{
    char[] keyword = kw.utf8();
    return tokenKeywordTable[keyword];
}

static this()
{
    initTokenSymbolTable();
    initTokenKeywordTable();
}

private TOK[char[]] tokenSymbolTable;

/*
    maps textual symbols (operators) to their tokens,
    for easy conversion from text to token
*/
void initTokenSymbolTable()
{
    tokenSymbolTable["+"] = TOK.Tadd;
    tokenSymbolTable["-"] = TOK.Tmin;
    tokenSymbolTable["*"] = TOK.Tmul;
    tokenSymbolTable["/"] = TOK.Tdiv;
    tokenSymbolTable["%"] = TOK.Tmod;
    tokenSymbolTable["^"] = TOK.Txor;
    tokenSymbolTable["&"] = TOK.Tand;
    tokenSymbolTable["|"] = TOK.Tor;
    tokenSymbolTable["="] = TOK.Tassign;
    tokenSymbolTable["<"] = TOK.Tlt;
    tokenSymbolTable[">"] = TOK.Tgt;
    tokenSymbolTable["~"] = TOK.Ttilde;
    tokenSymbolTable["!"] = TOK.Tnot;
    tokenSymbolTable["$"] = TOK.Tdollar;
    tokenSymbolTable["."] = TOK.Tdot;
    tokenSymbolTable[","] = TOK.Comma;
    tokenSymbolTable[";"] = TOK.Semicolon;
    tokenSymbolTable[":"] = TOK.Colon;
    tokenSymbolTable["?"] = TOK.Tquestion;
    tokenSymbolTable["("] = TOK.Openparen;
    tokenSymbolTable[")"] = TOK.Closeparen;
    tokenSymbolTable["["] = TOK.Openbracket;
    tokenSymbolTable["]"] = TOK.Closebracket;
    tokenSymbolTable["{"] = TOK.Opencurly;
    tokenSymbolTable["}"] = TOK.Closecurly;
    tokenSymbolTable[".."] = TOK.Tslice;
    tokenSymbolTable["<="] = TOK.Tle;
    tokenSymbolTable[">="] = TOK.Tge;
    tokenSymbolTable["=="] = TOK.Teqeq;
    tokenSymbolTable["!="] = TOK.Tnoteq;
    tokenSymbolTable["<<"] = TOK.Tshl;
    tokenSymbolTable[">>"] = TOK.Tshr;
    tokenSymbolTable["+="] = TOK.Taddass;
    tokenSymbolTable["-="] = TOK.Tminass;
    tokenSymbolTable["*="] = TOK.Tmulass;
    tokenSymbolTable["/="] = TOK.Tdivass;
    tokenSymbolTable["%="] = TOK.Tmodass;
    tokenSymbolTable["&="] = TOK.Tandass;
    tokenSymbolTable["|="] = TOK.Torass;
    tokenSymbolTable["^="] = TOK.Txorass;
    tokenSymbolTable["~="] = TOK.Tcatass;
    tokenSymbolTable["<>"] = TOK.Tlg;
    tokenSymbolTable["++"] = TOK.Tplusplus;
    tokenSymbolTable["--"] = TOK.Tminusminus;
    tokenSymbolTable["&&"] = TOK.Tandand;
    tokenSymbolTable["||"] = TOK.Toror;
    tokenSymbolTable["!<"] = TOK.Tul;
    tokenSymbolTable["!>"] = TOK.Tug;
    tokenSymbolTable["!<="] = TOK.Tule;
    tokenSymbolTable["!>="] = TOK.Tuge;
    tokenSymbolTable["..."] = TOK.Tdotdotdot;
    tokenSymbolTable["<<="] = TOK.Tshlass;
    tokenSymbolTable[">>="] = TOK.Tshrass;
    tokenSymbolTable["<>="] = TOK.Tleg;
    tokenSymbolTable["!<>"] = TOK.Tue;
    tokenSymbolTable[">>>"] = TOK.Tushr;
    tokenSymbolTable[">>>="] = TOK.Tushrass;
    tokenSymbolTable["!<>="] = TOK.Tunord;
}


 TOK[char[]] tokenKeywordTable;

void initTokenKeywordTable()
{
	tokenKeywordTable["__gshared"] = TOK.T__gshared;
    tokenKeywordTable["abstract"] = TOK.Tabstract;
    tokenKeywordTable["alias"] = TOK.Talias;
    tokenKeywordTable["align"] = TOK.Talign;
    tokenKeywordTable["asm"] = TOK.Tasm;
    tokenKeywordTable["assert"] = TOK.Tassert;
    tokenKeywordTable["auto"] = TOK.Tauto;
    tokenKeywordTable["body"] = TOK.Tbody;
    tokenKeywordTable["break"] = TOK.Tbreak;
    tokenKeywordTable["case"] = TOK.Tcase;
    tokenKeywordTable["cast"] = TOK.Tcast;
    tokenKeywordTable["catch"] = TOK.Tcatch;
    tokenKeywordTable["class"] = TOK.Tclass;
    tokenKeywordTable["const"] = TOK.Tconst;
    tokenKeywordTable["continue"] = TOK.Tcontinue;
    tokenKeywordTable["debug"] = TOK.Tdebug;
    tokenKeywordTable["default"] = TOK.Tdefault;
    tokenKeywordTable["delegate"] = TOK.Tdelegate;
    tokenKeywordTable["delete"] = TOK.Tdelete;
    tokenKeywordTable["deprecated"] = TOK.Tdeprecated;
    tokenKeywordTable["do"] = TOK.Tdo;
    tokenKeywordTable["else"] = TOK.Telse;
    tokenKeywordTable["enum"] = TOK.Tenum;
    tokenKeywordTable["export"] = TOK.Texport;
    tokenKeywordTable["extern"] = TOK.Textern;
    tokenKeywordTable["final"] = TOK.Tfinal;
    tokenKeywordTable["finally"] = TOK.Tfinally;
    tokenKeywordTable["for"] = TOK.Tfor;
    tokenKeywordTable["foreach"] = TOK.Tforeach;
    tokenKeywordTable["foreach_reverse"] = TOK.Tforeach_reverse;
    tokenKeywordTable["function"] = TOK.Tfunction;
    tokenKeywordTable["goto"] = TOK.Tgoto;
    tokenKeywordTable["if"] = TOK.Tif;
	tokenKeywordTable["immutable"] = TOK.Timmutable;
    tokenKeywordTable["import"] = TOK.Timport;
    tokenKeywordTable["in"] = TOK.Tin;
    tokenKeywordTable["inout"] = TOK.Tinout;
    tokenKeywordTable["interface"] = TOK.Tinterface;
    tokenKeywordTable["invariant"] = TOK.Tinvariant;
    tokenKeywordTable["is"] = TOK.Tis;
    tokenKeywordTable["lazy"] = TOK.Tlazy;
    tokenKeywordTable["mixin"] = TOK.Tmixin;
    tokenKeywordTable["module"] = TOK.Tmodule;
    tokenKeywordTable["new"] = TOK.Tnew;
	tokenKeywordTable["nothrow"] = TOK.Tnothrow;
    tokenKeywordTable["out"] = TOK.Tout;
    tokenKeywordTable["override"] = TOK.Toverride;
    tokenKeywordTable["package"] = TOK.Tpackage;
    tokenKeywordTable["pragma"] = TOK.Tpragma;
    tokenKeywordTable["private"] = TOK.Tprivate;
    tokenKeywordTable["protected"] = TOK.Tprotected;
    tokenKeywordTable["public"] = TOK.Tpublic;
	tokenKeywordTable["pure"] = TOK.Tpure;
	tokenKeywordTable["ref"] = TOK.Tref;
    tokenKeywordTable["return"] = TOK.Treturn;
    tokenKeywordTable["scope"] = TOK.Tscope;
	tokenKeywordTable["shared"] = TOK.Tshared;
    tokenKeywordTable["static"] = TOK.Tstatic;
    tokenKeywordTable["struct"] = TOK.Tstruct;
    tokenKeywordTable["switch"] = TOK.Tswitch;
    tokenKeywordTable["synchronized"] = TOK.Tsynchronized;
    tokenKeywordTable["template"] = TOK.Ttemplate;
    tokenKeywordTable["this"] = TOK.Tthis;
    tokenKeywordTable["throw"] = TOK.Tthrow;
    tokenKeywordTable["try"] = TOK.Ttry;
    tokenKeywordTable["typedef"] = TOK.Ttypedef;
    tokenKeywordTable["typeid"] = TOK.Ttypeid;
    tokenKeywordTable["typeof"] = TOK.Ttypeof;
    tokenKeywordTable["union"] = TOK.Tunion;
    tokenKeywordTable["unittest"] = TOK.Tunittest;
    tokenKeywordTable["version"] = TOK.Tversion;
    tokenKeywordTable["volatile"] = TOK.Tvolatile;
    tokenKeywordTable["while"] = TOK.Twhile;
    tokenKeywordTable["with"] = TOK.Twith;
    /*
        OK .. these don't need to be keywords! parsing would be alot 
        easier without them! They are just predefined identifiers!
    */
    //tokenKeywordTable["bit"] = TOK.Tbit;
    //tokenKeywordTable["byte"] = TOK.Tbyte;
    //tokenKeywordTable["cent"] = TOK.Tcent;
    //tokenKeywordTable["cfloat"] = TOK.Tcfloat;
    //tokenKeywordTable["char"] = TOK.Tchar;
    //tokenKeywordTable["creal"] = TOK.Tcreal;
    //tokenKeywordTable["cdouble"] = TOK.Tcdouble;
    //tokenKeywordTable["char"] = TOK.Tdchar;
    //tokenKeywordTable["double"] = TOK.Tdouble;
    //tokenKeywordTable["false"] = TOK.Tfalse;
    //tokenKeywordTable["float"] = TOK.Tfloat;
    //tokenKeywordTable["idouble"] = TOK.Tidouble;
    //tokenKeywordTable["ifloat"] = TOK.Tifloat;
    //tokenKeywordTable["int"] = TOK.Tint;
    //tokenKeywordTable["ireal"] = TOK.Tireal;
    //tokenKeywordTable["long"] = TOK.Tlong;
    //tokenKeywordTable["null"] = TOK.Tnull;
    //tokenKeywordTable["real"] = TOK.Treal;
    //tokenKeywordTable["short"] = TOK.Tshort;
    //tokenKeywordTable["super"] = TOK.Tsuper;
    //tokenKeywordTable["true"] = TOK.Ttrue;
    //tokenKeywordTable["ubyte"] = TOK.Tubyte;
    //tokenKeywordTable["ucent"] = TOK.Tucent;
    //tokenKeywordTable["uint"] = TOK.Tuint;
    //tokenKeywordTable["ulong"] = TOK.Tulong;
    //tokenKeywordTable["ushort"] = TOK.Tushort;
    //tokenKeywordTable["void"] = TOK.Tvoid;
    //tokenKeywordTable["wchar"] = TOK.Twchar;
}



 