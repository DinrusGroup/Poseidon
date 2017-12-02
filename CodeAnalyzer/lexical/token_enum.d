module CodeAnalyzer.lexical.token_enum;


//TODO: clean up this enum .. it has a lot of unused stuff. also rename the enumerations ..

//from dmd fe, with modifications
enum TOK
{
    INVALID,

    Whitespace, Newline, SpecialTokenSequence,
    LineComment, BlockComment, NestingComment,
    LineDocComment, BlockDocComment, NestingDocComment,

    //symbols ( ) [ ] { } : - ; ..
    Openparen,    Closeparen,
    Openbracket,    Closebracket,
    Opencurly,    Closecurly,
    Colon,    Tneg,
    Semicolon,    Tdotdotdot,

    Tcast,
    Tnull,
    Tassert,
    Ttrue,
    Tfalse,
    Tthrow,
    Tnew,
    Tdelete,
    Tslice,
    Tversion,
    Tmodule,
    Tdollar,
    Ttemplate,
    Ttypeof,
    Tpragma,
    Ttypeid,

    // Operators
    Tlt,
    Tgt,
    Tle,
    Tge,
    Teqeq,
    Tnoteq,
    Tis,

    Tshl,
    Tshr,
    Tshlass,
    Tshrass,
    Tushr,
    Tushrass,
    Tcat,   //~
    Tcatass,    // ~=
    Tadd,
    Tmin,
    Taddass,
    Tminass,
    Tmul,
    Tdiv,
    Tmod,
    Tmulass,
    Tdivass,
    Tmodass,
    Tand,
    Tor,
    Txor,
    Tandass,
    Torass,
    Txorass,
    Tassign,
    Tnot,
    Ttilde,
    Tplusplus,
    Tminusminus,
    Tdot,
    Tarrow,
    Comma,
    Tquestion,
    Tandand,
    Toror,

    // NCEG floating point compares
    // !<>=     <>    <>=    !>     !>=   !<     !<=   !<>
    Tunord,
    Tlg,
    Tleg,
    Tule,
    Tul,
    Tuge,
    Tug,
    Tue,
    
    // Char constants    
    Tcharconstant,
    Tescaped,
    Tnumber,

    // Leaf operators
    Identifier,    Tstring,
    Tthis,    Tsuper,

    // Aggregates
    Tstruct,
    Tclass,
    Tinterface,
    Tunion,
    Tenum,
    Timport,
    Ttypedef,
    Talias,
    Toverride,
    Tdelegate,
    Tfunction,
    Tmixin,

    //Attributes
    Talign,
    Textern,
    Tprivate,
    Tprotected,
    Tpublic,
    Texport,
    Tstatic,
    Tfinal,
    Tconst,
    Tabstract,
    Tvolatile,
    Tdebug,
    Tdeprecated,
    Tin,
    Tout,
    Tinout,
	Tref,
	Tpure,
	Tnothrow,
    Tlazy,
    Tauto,
    Tpackage,
	T__gshared,
	Tshared,

    // Statements
    Tif,
    Telse,
    Twhile,
    Tfor,
    Tdo,
    Tswitch,
    Tcase,
    Tdefault,
    Tbreak,
    Tcontinue,
    Twith,
    Tsynchronized,
    Treturn,
    Tgoto,
    Ttry,
    Tcatch,
    Tfinally,
    Tasm,
    Tforeach,
    Tforeach_reverse,
    Tscope,

    //DBC
    Tbody,
    Tinvariant,
    Tunittest,
	Timmutable,
}

char[] toString( TOK t )
{
    return enumToString[t];
}

public char[][TOK] enumToString;

static this()
{
    enumToString[ TOK.INVALID ] = "INVALID";
    enumToString[ TOK.Whitespace ] = "Whitespace";
    enumToString[ TOK.SpecialTokenSequence ] = "SpecialTokenSequence";
    enumToString[ TOK.LineComment ] = "LineComment";
    enumToString[ TOK.BlockComment ] = "BlockComment";
    enumToString[ TOK.NestingComment ] = "NestingComment";
    enumToString[ TOK.LineDocComment ] = "LineDocComment";
    enumToString[ TOK.BlockDocComment ] = "BlockDocComment";
    enumToString[ TOK.NestingDocComment ] = "NestingDocComment";
    enumToString[ TOK.Openparen ] = "Openparen";
    enumToString[ TOK.Closeparen ] = "Closeparen";
    enumToString[ TOK.Openbracket ] = "Openbracket";
    enumToString[ TOK.Closebracket ] = "Closebracket";
    enumToString[ TOK.Opencurly ] = "Opencurly";
    enumToString[ TOK.Closecurly ] = "Closecurly";
    enumToString[ TOK.Colon ] = "Colon";
    enumToString[ TOK.Tneg ] = "Tneg";
    enumToString[ TOK.Semicolon ] = "Semicolon";
    enumToString[ TOK.Tdotdotdot ] = "Tdotdotdot";
    enumToString[ TOK.Tcast ] = "Tcast";
    enumToString[ TOK.Tnull ] = "Tnull";
    enumToString[ TOK.Tassert ] = "Tassert";
    enumToString[ TOK.Ttrue ] = "Ttrue";
    enumToString[ TOK.Tfalse ] = "Tfalse";
    enumToString[ TOK.Tthrow ] = "Tthrow";
    enumToString[ TOK.Tnew ] = "Tnew";
    enumToString[ TOK.Tdelete ] = "Tdelete";
    enumToString[ TOK.Tslice ] = "Tslice";
    enumToString[ TOK.Tversion ] = "Tversion";
    enumToString[ TOK.Tmodule ] = "Tmodule";
    enumToString[ TOK.Tdollar ] = "Tdollar";
    enumToString[ TOK.Ttemplate ] = "Ttemplate";
    enumToString[ TOK.Ttypeof ] = "Ttypeof";
    enumToString[ TOK.Tpragma ] = "Tpragma";
    enumToString[ TOK.Ttypeid ] = "Ttypeid";
    enumToString[ TOK.Tlt ] = "Tlt";
    enumToString[ TOK.Tgt ] = "Tgt";
    enumToString[ TOK.Tle ] = "Tle";
    enumToString[ TOK.Tge ] = "Tge";
    enumToString[ TOK.Teqeq ] = "Teqeq";
    enumToString[ TOK.Tnoteq ] = "Tnoteq";
    enumToString[ TOK.Tis ] = "Tis";
    enumToString[ TOK.Tunord ] = "Tunord";
    enumToString[ TOK.Tlg ] = "Tlg";
    enumToString[ TOK.Tleg ] = "Tleg";
    enumToString[ TOK.Tule ] = "Tule";
    enumToString[ TOK.Tul ] = "Tul";
    enumToString[ TOK.Tuge ] = "Tuge";
    enumToString[ TOK.Tug ] = "Tug";
    enumToString[ TOK.Tue ] = "Tue";
    enumToString[ TOK.Tshl ] = "Tshl";
    enumToString[ TOK.Tshr ] = "Tshr";
    enumToString[ TOK.Tshlass ] = "Tshlass";
    enumToString[ TOK.Tshrass ] = "Tshrass";
    enumToString[ TOK.Tushr ] = "Tushr";
    enumToString[ TOK.Tushrass ] = "Tushrass";
    enumToString[ TOK.Tcat ] = "Tcat";
    enumToString[ TOK.Tcatass ] = "Tcatass";
    enumToString[ TOK.Tadd ] = "Tadd";
    enumToString[ TOK.Tmin ] = "Tmin";
    enumToString[ TOK.Taddass ] = "Taddass";
    enumToString[ TOK.Tminass ] = "Tminass";
    enumToString[ TOK.Tmul ] = "Tmul";
    enumToString[ TOK.Tdiv ] = "Tdiv";
    enumToString[ TOK.Tmod ] = "Tmod";
    enumToString[ TOK.Tmulass ] = "Tmulass";
    enumToString[ TOK.Tdivass ] = "Tdivass";
    enumToString[ TOK.Tmodass ] = "Tmodass";
    enumToString[ TOK.Tand ] = "Tand";
    enumToString[ TOK.Tor ] = "Tor";
    enumToString[ TOK.Txor ] = "Txor";
    enumToString[ TOK.Tandass ] = "Tandass";
    enumToString[ TOK.Torass ] = "Torass";
    enumToString[ TOK.Txorass ] = "Txorass";
    enumToString[ TOK.Tassign ] = "Tassign";
    enumToString[ TOK.Tnot ] = "Tnot";
    enumToString[ TOK.Ttilde ] = "Ttilde";
    enumToString[ TOK.Tplusplus ] = "Tplusplus";
    enumToString[ TOK.Tminusminus ] = "Tminusminus";
    enumToString[ TOK.Tdot ] = "Tdot";
    enumToString[ TOK.Tarrow ] = "Tarrow";
    enumToString[ TOK.Comma ] = "Comma";
    enumToString[ TOK.Tquestion ] = "Tquestion";
    enumToString[ TOK.Tandand ] = "Tandand";
    enumToString[ TOK.Toror ] = "Toror";
    enumToString[ TOK.Tcharconstant ] = "Tcharconstant";
    enumToString[ TOK.Tescaped ] = "Tescaped";
    enumToString[ TOK.Tnumber ] = "Tnumber";
    enumToString[ TOK.Identifier ] = "Identifier";
    enumToString[ TOK.Tstring ] = "Tstring";
    enumToString[ TOK.Tthis ] = "Tthis";
    enumToString[ TOK.Tsuper ] = "Tsuper";
    enumToString[ TOK.Tstruct ] = "Tstruct";
    enumToString[ TOK.Tclass ] = "Tclass";
    enumToString[ TOK.Tinterface ] = "Tinterface";
    enumToString[ TOK.Tunion ] = "Tunion";
    enumToString[ TOK.Tenum ] = "Tenum";
    enumToString[ TOK.Timport ] = "Timport";
    enumToString[ TOK.Ttypedef ] = "Ttypedef";
    enumToString[ TOK.Talias ] = "Talias";
    enumToString[ TOK.Toverride ] = "Toverride";
    enumToString[ TOK.Tdelegate ] = "Tdelegate";
    enumToString[ TOK.Tfunction ] = "Tfunction";
    enumToString[ TOK.Tmixin ] = "Tmixin";
    enumToString[ TOK.Talign ] = "Talign";
    enumToString[ TOK.Textern ] = "Textern";
    enumToString[ TOK.Tprivate ] = "Tprivate";
    enumToString[ TOK.Tprotected ] = "Tprotected";
    enumToString[ TOK.Tpublic ] = "Tpublic";
    enumToString[ TOK.Texport ] = "Texport";
    enumToString[ TOK.Tstatic ] = "Tstatic";
    enumToString[ TOK.Tfinal ] = "Tfinal";
    enumToString[ TOK.Tconst ] = "Tconst";
    enumToString[ TOK.Tabstract ] = "Tabstract";
    enumToString[ TOK.Tvolatile ] = "Tvolatile";
    enumToString[ TOK.Tscope ] = "Tscope";
    enumToString[ TOK.Tdebug ] = "Tdebug";
    enumToString[ TOK.Tdeprecated ] = "Tdeprecated";
    enumToString[ TOK.Tin ] = "Tin";
    enumToString[ TOK.Tout ] = "Tout";
    enumToString[ TOK.Tinout ] = "Tinout";
	enumToString[ TOK.Tref ] = "Tref";
	enumToString[ TOK.Tpure ] = "Tpure";
	enumToString[ TOK.Tnothrow ] = "Tnothrow";
	enumToString[ TOK.T__gshared ] = "T__gshared";
	enumToString[ TOK.Tshared ] = "Tshared";
    enumToString[ TOK.Tlazy ] = "Tlazy";
    enumToString[ TOK.Tauto ] = "Tauto";
    enumToString[ TOK.Tpackage ] = "Tpackage";
    enumToString[ TOK.Tif ] = "Tif";
    enumToString[ TOK.Telse ] = "Telse";
    enumToString[ TOK.Twhile ] = "Twhile";
    enumToString[ TOK.Tfor ] = "Tfor";
    enumToString[ TOK.Tdo ] = "Tdo";
    enumToString[ TOK.Tswitch ] = "Tswitch";
    enumToString[ TOK.Tcase ] = "Tcase";
    enumToString[ TOK.Tdefault ] = "Tdefault";
    enumToString[ TOK.Tbreak ] = "Tbreak";
    enumToString[ TOK.Tcontinue ] = "Tcontinue";
    enumToString[ TOK.Twith ] = "Twith";
    enumToString[ TOK.Tsynchronized ] = "Tsynchronized";
    enumToString[ TOK.Treturn ] = "Treturn";
    enumToString[ TOK.Tgoto ] = "Tgoto";
    enumToString[ TOK.Ttry ] = "Ttry";
    enumToString[ TOK.Tcatch ] = "Tcatch";
    enumToString[ TOK.Tfinally ] = "Tfinally";
    enumToString[ TOK.Tasm ] = "Tasm";
    enumToString[ TOK.Tforeach ] = "Tforeach";
    enumToString[ TOK.Tforeach_reverse ] = "Tforeach_reverse";
    enumToString[ TOK.Tbody ] = "Tbody";
    enumToString[ TOK.Tinvariant ] = "Tinvariant";
    enumToString[ TOK.Tunittest ] = "Tunittest";
	enumToString[ TOK.Timmutable ] = "Timmutable";
}