module poseidon.controller.scintillaex;

private import dwt.all;
private import dwt.extra.all;


private import dwt.internal.win32.os;
private import poseidon.util.fileutil;


public class ScintillaEx : Scintilla {

	private import std.system;
	private import std.utf;
	private import std.file;
	private import poseidon.controller.gui;
	
	const int SCMOD_NORM = 0;
	const int SCMOD_ASHIFT = SCMOD_ALT | SCMOD_SHIFT;
	const int SCMOD_CSHIFT = SCMOD_CTRL | SCMOD_SHIFT;

	int ibom = BOM.UTF8;
	
	char[] filename;
  
		
public this(Composite parent, int style){

	setDllFileName("scilexer.dll");
	
	super(parent, style);
	
	init();
	
	handleNotify(null, SCN_UPDATEUI, &onUpdateUI);
	handleNotify(null, SCN_MARGINCLICK, &onMarginClick);
	handleNotify(null, SCN_CHARADDED, &onCharAdded);
}

int getCurrentLineNumber()
{
	return lineFromPosition(getCurrentPos());
}


private void onCharAdded(SCNotifyEvent e) {

	// copied from akIDE
	int ch = e.ch;
	//const int INDENT = 4;
	const boolean SETTING_AUTOINDENT = true;

	int INDENT = sGUI.editor.settings._setting.tabIndents;
		
	int fl=((getEOLMode()==SC_EOL_CR && ch=='\r') || ch=='\n')!=0;
	
	if(SETTING_AUTOINDENT && (fl || ch=='}'))
	{
		int curline=getCurrentLineNumber();
		int identpos=getLineIndentPosition(curline);
		int curpos=getCurrentPos();
		if((fl && identpos==curpos) || (ch=='}' && identpos==getLineEndPosition(curline)-1))
		{
			int lastline=curline-1;
			int previ=getLineIndentation(lastline);
			int indent=previ;
			if(getLineEndPosition(lastline)==getLineIndentPosition(lastline)) setLineIndentation(lastline,0);
			int c=getCharAt(getLineEndPosition(lastline)-1);
			if(fl && '{' && '{'==c) indent=previ+INDENT;
			else if(ch=='}') indent=getLineIndentation(curline)-INDENT;//getlastindentopen(lastline);
			//else if(m_template.settings.autoindentendofstatement && m_template.settings.autoindentendofstatement!=c) indent=getlastindentopen(lastline)+(INDENT*2);
	
			setLineIndentation(curline,indent);
			int pos=getLineIndentPosition(curline);
			if(ch=='}') pos++;
			setSearchPolicy();
			gotoPos(pos);
			setDefaultPolicy();
			// m_lastpos=pos;
			// m_parent.UpdateMenu_Editor(this,1,0,0);
		}
		// else m_lastpos=-1;
	}
	
	// else m_lastpos=-1;	
}


	void setSearchPolicy()
	{
		setXOffset(0);
		setYCaretPolicy(CARET_SLOP|CARET_EVEN,3);
		setXCaretPolicy(CARET_JUMPS|CARET_EVEN,0);
	}

	void setDefaultPolicy()
	{
		setXCaretPolicy(CARET_SLOP|CARET_EVEN,50);
		setYCaretPolicy(CARET_EVEN,0);
	}

	
void onMarginClick(SCNotifyEvent event)
{	
	if( event.margin == 2 )
	{
		int nLine = lineFromPosition(event.position);
		toggleFold(nLine);
		ensureVisibleEnforcePolicy( nLine );
	}
}
	
	
void onUpdateUI(SCNotifyEvent event)
{
	this.doBraceMatching();
}

void setFileName(char[] fn){
	this.filename = fn;
}
char[] getFileName(){
	return filename;
}

void setAStyle(int style, int fore = -1, int back = -1, int size = -1,  char[] face = null, int bold=-1, int italic=-1, int underline=-1)
{
	if(fore >= 0)
		styleSetFore(style, fore);
	if(back >= 0)
		styleSetBack(style, back);
	if (size > 0)
		styleSetSize(style, size);
	if (face.length > 0) 
		styleSetFont(style, face);
	if(bold >= 0)
		styleSetBold(style, bold);
	if(italic >= 0)
		styleSetItalic(style, italic);
	if(underline >= 0 )
		styleSetUnderline(style, underline);
}

void defineMarker(int marker, int markerType, int fore, int back)
{
	markerDefine(marker, markerType);
	markerSetFore(marker, fore);
	markerSetBack(marker, back);
}

char[] getTextInRange(int start, int end) {
	if(end == start)
		return "";
	assert(end > start);
	
	TextRange tr = TextRange(start, end);
	getTextRange(&tr);
	return tr.text;
}

public void init(){

	setCodePage(SC_CP_UTF8);

	// F3
	// F4
//	clearCmdKey('/' + (SCMOD_CTRL << 16)); // this is not handled by scintilla default		
	clearCmdKey('A' + (SCMOD_CTRL << 16));
	clearCmdKey('C' + (SCMOD_CTRL << 16));
	clearCmdKey('D' + (SCMOD_CTRL << 16));
//	clearCmdKey('F' + (SCMOD_CTRL << 16));
//	clearCmdKey('G' + (SCMOD_CTRL << 16));
//	clearCmdKey('H' + (SCMOD_CTRL << 16));
	clearCmdKey('L' + ((SCMOD_CTRL|SCMOD_SHIFT) << 16));
	clearCmdKey('L' + (SCMOD_CTRL << 16));
//	clearCmdKey('S' + (SCMOD_CTRL << 16));
	clearCmdKey('T' + ((SCMOD_CTRL|SCMOD_SHIFT) << 16));
	clearCmdKey('T' + (SCMOD_CTRL << 16));
	clearCmdKey('U' + ((SCMOD_CTRL|SCMOD_SHIFT) << 16)); 
	clearCmdKey('U' + (SCMOD_CTRL << 16));
	clearCmdKey('V' + (SCMOD_CTRL << 16));
	clearCmdKey('X' + (SCMOD_CTRL << 16));	
	clearCmdKey('Y' + (SCMOD_CTRL << 16));	
	clearCmdKey('Z' + (SCMOD_CTRL << 16));

	
/**	some keys can't work well	

	// clear all default key command binding
	// I will handle these command myself
	clearAllCmdKeys();
	
	// install some key binding not customizable
	assignCmdKey(SCK_DOWN		+ (SCMOD_NORM << 16),	SCI_LINEDOWN);
    assignCmdKey(SCK_DOWN		+ (SCMOD_SHIFT << 16),	SCI_LINEDOWNEXTEND);
    assignCmdKey(SCK_DOWN		+ (SCMOD_CTRL << 16),	SCI_LINESCROLLDOWN);
    assignCmdKey(SCK_DOWN		+ (SCMOD_ASHIFT << 16),	SCI_LINEDOWNRECTEXTEND);
    assignCmdKey(SCK_UP			+ (SCMOD_NORM << 16),	SCI_LINEUP);
    assignCmdKey(SCK_UP			+ (SCMOD_SHIFT << 16),	SCI_LINEUPEXTEND);
    assignCmdKey(SCK_UP			+ (SCMOD_CTRL << 16),	SCI_LINESCROLLUP);
    assignCmdKey(SCK_UP			+ (SCMOD_ASHIFT << 16),	SCI_LINEUPRECTEXTEND);
    assignCmdKey('[',			+ (SCMOD_CTRL << 16),	SCI_PARAUP);
    assignCmdKey('[',			+ (SCMOD_CSHIFT << 16),	SCI_PARAUPEXTEND);
    assignCmdKey(']',			+ (SCMOD_CTRL << 16),	SCI_PARADOWN);
    assignCmdKey(']',			+ (SCMOD_CSHIFT << 16),	SCI_PARADOWNEXTEND);
    assignCmdKey(SCK_LEFT		+ (SCMOD_NORM << 16),	SCI_CHARLEFT);
    assignCmdKey(SCK_LEFT		+ (SCMOD_SHIFT << 16),	SCI_CHARLEFTEXTEND);
    assignCmdKey(SCK_LEFT		+ (SCMOD_CTRL << 16),	SCI_WORDLEFT);
    assignCmdKey(SCK_LEFT		+ (SCMOD_CSHIFT << 16),	SCI_WORDLEFTEXTEND);
    assignCmdKey(SCK_LEFT		+ (SCMOD_ASHIFT << 16),	SCI_CHARLEFTRECTEXTEND);
    assignCmdKey(SCK_RIGHT		+ (SCMOD_NORM << 16),	SCI_CHARRIGHT);
    assignCmdKey(SCK_RIGHT		+ (SCMOD_SHIFT << 16),	SCI_CHARRIGHTEXTEND);
    assignCmdKey(SCK_RIGHT		+ (SCMOD_CTRL << 16),	SCI_WORDRIGHT);
    assignCmdKey(SCK_RIGHT		+ (SCMOD_CSHIFT << 16),	SCI_WORDRIGHTEXTEND);
    assignCmdKey(SCK_RIGHT		+ (SCMOD_ASHIFT << 16),	SCI_CHARRIGHTRECTEXTEND);
    assignCmdKey('/',			+ (SCMOD_CTRL << 16),	SCI_WORDPARTLEFT);
    assignCmdKey('/',			+ (SCMOD_CSHIFT << 16),	SCI_WORDPARTLEFTEXTEND);
    assignCmdKey('\\',			+ (SCMOD_CTRL << 16),	SCI_WORDPARTRIGHT);
    assignCmdKey('\\',			+ (SCMOD_CSHIFT << 16),	SCI_WORDPARTRIGHTEXTEND);
    assignCmdKey(SCK_HOME		+ (SCMOD_NORM << 16),	SCI_VCHOME);
    assignCmdKey(SCK_HOME 		+ (SCMOD_SHIFT << 16), 	SCI_VCHOMEEXTEND);
    assignCmdKey(SCK_HOME 		+ (SCMOD_CTRL << 16), 	SCI_DOCUMENTSTART);
    assignCmdKey(SCK_HOME 		+ (SCMOD_CSHIFT << 16), SCI_DOCUMENTSTARTEXTEND);
    assignCmdKey(SCK_HOME 		+ (SCMOD_ALT << 16), 	SCI_HOMEDISPLAY);
//  assignCmdKey(SCK_HOME		+ (SCMOD_ASHIFT << 16),	SCI_HOMEDISPLAYEXTEND);
    assignCmdKey(SCK_HOME		+ (SCMOD_ASHIFT << 16),	SCI_VCHOMERECTEXTEND);
    assignCmdKey(SCK_END	 	+ (SCMOD_NORM << 16),	SCI_LINEEND);
    assignCmdKey(SCK_END	 	+ (SCMOD_SHIFT << 16), 	SCI_LINEENDEXTEND);
    assignCmdKey(SCK_END 		+ (SCMOD_CTRL << 16), 	SCI_DOCUMENTEND);
    assignCmdKey(SCK_END 		+ (SCMOD_CSHIFT << 16), SCI_DOCUMENTENDEXTEND);
    assignCmdKey(SCK_END 		+ (SCMOD_ALT << 16), 	SCI_LINEENDDISPLAY);
//  assignCmdKey(SCK_END		+ (SCMOD_ASHIFT << 16),	SCI_LINEENDDISPLAYEXTEND);
    assignCmdKey(SCK_END		+ (SCMOD_ASHIFT << 16),	SCI_LINEENDRECTEXTEND);
    assignCmdKey(SCK_PRIOR		+ (SCMOD_NORM << 16),	SCI_PAGEUP);
    assignCmdKey(SCK_PRIOR		+ (SCMOD_SHIFT << 16), 	SCI_PAGEUPEXTEND);
    assignCmdKey(SCK_PRIOR		+ (SCMOD_ASHIFT << 16),	SCI_PAGEUPRECTEXTEND);
    assignCmdKey(SCK_NEXT 		+ (SCMOD_NORM << 16), 	SCI_PAGEDOWN);
    assignCmdKey(SCK_NEXT		+ (SCMOD_ASHIFT << 16),	SCI_PAGEDOWNRECTEXTEND);
    assignCmdKey(SCK_DELETE 	+ (SCMOD_NORM << 16),	SCI_CLEAR);
    assignCmdKey(SCK_DELETE 	+ (SCMOD_SHIFT << 16),	SCI_CUT);
    assignCmdKey(SCK_DELETE 	+ (SCMOD_CTRL << 16),	SCI_DELWORDRIGHT);
    assignCmdKey(SCK_DELETE		+ (SCMOD_CSHIFT << 16),	SCI_DELLINERIGHT);
    assignCmdKey(SCK_INSERT 	+ (SCMOD_NORM << 16),	SCI_EDITTOGGLEOVERTYPE);
    assignCmdKey(SCK_INSERT 	+ (SCMOD_SHIFT << 16),	SCI_PASTE);
    assignCmdKey(SCK_INSERT 	+ (SCMOD_CTRL << 16),	SCI_COPY);
    assignCmdKey(SCK_ESCAPE  	+ (SCMOD_NORM << 16),	SCI_CANCEL);
    assignCmdKey(SCK_BACK		+ (SCMOD_NORM << 16), 	SCI_DELETEBACK);
    assignCmdKey(SCK_BACK		+ (SCMOD_SHIFT << 16), 	SCI_DELETEBACK);
    assignCmdKey(SCK_BACK		+ (SCMOD_CTRL << 16), 	SCI_DELWORDLEFT);
    assignCmdKey(SCK_BACK 		+ (SCMOD_ALT << 16),	SCI_UNDO);
    assignCmdKey(SCK_BACK		+ (SCMOD_CSHIFT << 16),	SCI_DELLINELEFT);
    assignCmdKey(SCK_TAB		+ (SCMOD_NORM << 16),	SCI_TAB);
    assignCmdKey(SCK_TAB		+ (SCMOD_SHIFT << 16),	SCI_BACKTAB);
    assignCmdKey(SCK_RETURN 	+ (SCMOD_NORM << 16),	SCI_NEWLINE);
    assignCmdKey(SCK_RETURN 	+ (SCMOD_SHIFT << 16),	SCI_NEWLINE);
    assignCmdKey(SCK_ADD 		+ (SCMOD_CTRL << 16),	SCI_ZOOMIN);
    assignCmdKey(SCK_SUBTRACT	+ (SCMOD_CTRL << 16),	SCI_ZOOMOUT);
    assignCmdKey(SCK_DIVIDE		+ (SCMOD_CTRL << 16),	SCI_SETZOOM);
*/    
}
/** Scintilla default key mapping in C++

const KeyToCommand KeyMap::MapDefault[] = {
    {SCK_DOWN,		SCI_NORM,	SCI_LINEDOWN},
    {SCK_DOWN,		SCI_SHIFT,	SCI_LINEDOWNEXTEND},
    {SCK_DOWN,		SCI_CTRL,	SCI_LINESCROLLDOWN},
    {SCK_DOWN,		SCI_ASHIFT,	SCI_LINEDOWNRECTEXTEND},
    {SCK_UP,		SCI_NORM,	SCI_LINEUP},
    {SCK_UP,			SCI_SHIFT,	SCI_LINEUPEXTEND},
    {SCK_UP,			SCI_CTRL,	SCI_LINESCROLLUP},
    {SCK_UP,		SCI_ASHIFT,	SCI_LINEUPRECTEXTEND},
    {'[',			SCI_CTRL,		SCI_PARAUP},
    {'[',			SCI_CSHIFT,	SCI_PARAUPEXTEND},
    {']',			SCI_CTRL,		SCI_PARADOWN},
    {']',			SCI_CSHIFT,	SCI_PARADOWNEXTEND},
    {SCK_LEFT,		SCI_NORM,	SCI_CHARLEFT},
    {SCK_LEFT,		SCI_SHIFT,	SCI_CHARLEFTEXTEND},
    {SCK_LEFT,		SCI_CTRL,	SCI_WORDLEFT},
    {SCK_LEFT,		SCI_CSHIFT,	SCI_WORDLEFTEXTEND},
    {SCK_LEFT,		SCI_ASHIFT,	SCI_CHARLEFTRECTEXTEND},
    {SCK_RIGHT,		SCI_NORM,	SCI_CHARRIGHT},
    {SCK_RIGHT,		SCI_SHIFT,	SCI_CHARRIGHTEXTEND},
    {SCK_RIGHT,		SCI_CTRL,	SCI_WORDRIGHT},
    {SCK_RIGHT,		SCI_CSHIFT,	SCI_WORDRIGHTEXTEND},
    {SCK_RIGHT,		SCI_ASHIFT,	SCI_CHARRIGHTRECTEXTEND},
    {'/',		SCI_CTRL,		SCI_WORDPARTLEFT},
    {'/',		SCI_CSHIFT,	SCI_WORDPARTLEFTEXTEND},
    {'\\',		SCI_CTRL,		SCI_WORDPARTRIGHT},
    {'\\',		SCI_CSHIFT,	SCI_WORDPARTRIGHTEXTEND},
    {SCK_HOME,		SCI_NORM,	SCI_VCHOME},
    {SCK_HOME, 		SCI_SHIFT, 	SCI_VCHOMEEXTEND},
    {SCK_HOME, 		SCI_CTRL, 	SCI_DOCUMENTSTART},
    {SCK_HOME, 		SCI_CSHIFT, 	SCI_DOCUMENTSTARTEXTEND},
    {SCK_HOME, 		SCI_ALT, 	SCI_HOMEDISPLAY},
//    {SCK_HOME,		SCI_ASHIFT,	SCI_HOMEDISPLAYEXTEND},
    {SCK_HOME,		SCI_ASHIFT,	SCI_VCHOMERECTEXTEND},
    {SCK_END,	 	SCI_NORM,	SCI_LINEEND},
    {SCK_END,	 	SCI_SHIFT, 	SCI_LINEENDEXTEND},
    {SCK_END, 		SCI_CTRL, 	SCI_DOCUMENTEND},
    {SCK_END, 		SCI_CSHIFT, 	SCI_DOCUMENTENDEXTEND},
    {SCK_END, 		SCI_ALT, 	SCI_LINEENDDISPLAY},
//    {SCK_END,		SCI_ASHIFT,	SCI_LINEENDDISPLAYEXTEND},
    {SCK_END,		SCI_ASHIFT,	SCI_LINEENDRECTEXTEND},
    {SCK_PRIOR,		SCI_NORM,	SCI_PAGEUP},
    {SCK_PRIOR,		SCI_SHIFT, 	SCI_PAGEUPEXTEND},
    {SCK_PRIOR,		SCI_ASHIFT,	SCI_PAGEUPRECTEXTEND},
    {SCK_NEXT, 		SCI_NORM, 	SCI_PAGEDOWN},
    {SCK_NEXT, 		SCI_SHIFT, 	SCI_PAGEDOWNEXTEND},
    {SCK_NEXT,		SCI_ASHIFT,	SCI_PAGEDOWNRECTEXTEND},
    {SCK_DELETE, 	SCI_NORM,	SCI_CLEAR},
    {SCK_DELETE, 	SCI_SHIFT,	SCI_CUT},
    {SCK_DELETE, 	SCI_CTRL,	SCI_DELWORDRIGHT},
    {SCK_DELETE,	SCI_CSHIFT,	SCI_DELLINERIGHT},
    {SCK_INSERT, 		SCI_NORM,	SCI_EDITTOGGLEOVERTYPE},
    {SCK_INSERT, 		SCI_SHIFT,	SCI_PASTE},
    {SCK_INSERT, 		SCI_CTRL,	SCI_COPY},
    {SCK_ESCAPE,  	SCI_NORM,	SCI_CANCEL},
    {SCK_BACK,		SCI_NORM, 	SCI_DELETEBACK},
    {SCK_BACK,		SCI_SHIFT, 	SCI_DELETEBACK},
    {SCK_BACK,		SCI_CTRL, 	SCI_DELWORDLEFT},
    {SCK_BACK, 		SCI_ALT,	SCI_UNDO},
    {SCK_BACK,		SCI_CSHIFT,	SCI_DELLINELEFT},
    //'L', 			SCI_CTRL,		SCI_FORMFEED,
    {'A', 			SCI_CTRL,	SCI_SELECTALL},
    {'C', 			SCI_CTRL,	SCI_COPY},
    {'D', 			SCI_CTRL,	SCI_LINEDUPLICATE},
    {'L', 			SCI_CSHIFT,	SCI_LINEDELETE},
    {'L', 			SCI_CTRL,	SCI_LINECUT},
    {'T', 			SCI_CSHIFT,	SCI_LINECOPY},
    {'T', 			SCI_CTRL,	SCI_LINETRANSPOSE},
    {'U', 			SCI_CSHIFT,	SCI_UPPERCASE},  
    {'U', 			SCI_CTRL,	SCI_LOWERCASE},
    {'V', 			SCI_CTRL,	SCI_PASTE},
    {'X', 			SCI_CTRL,	SCI_CUT},
    {'Y', 			SCI_CTRL,	SCI_REDO},
    {'Z', 			SCI_CTRL,	SCI_UNDO},
    {SCK_TAB,		SCI_NORM,	SCI_TAB},
    {SCK_TAB,		SCI_SHIFT,	SCI_BACKTAB},
    {SCK_RETURN, 	SCI_NORM,	SCI_NEWLINE},
    {SCK_RETURN, 	SCI_SHIFT,	SCI_NEWLINE},
    {SCK_ADD, 		SCI_CTRL,	SCI_ZOOMIN},
    {SCK_SUBTRACT,	SCI_CTRL,	SCI_ZOOMOUT},
    {SCK_DIVIDE,	SCI_CTRL,	SCI_SETZOOM},

    {0,0,0},
};

*/

bool loadFile(char[] filename)
{
	//Tell the control not to maintain any undo info while we stream the data 
	cancel();
	setUndoCollection(false);
	clearAll();
	
	char[] buffer;
	
	try{
		FileReader.read(filename, buffer, ibom);
	}catch(Exception e){
		MessageBox.showMessage(e.toString());
		return false;
	}
	
	// add text to scintilla
	this.addText(buffer);
	
	this.setFileName(filename);
	
	//Set the read only state if required
	if ((std.file.getAttributes(filename) & std.c.windows.windows.FILE_ATTRIBUTE_READONLY)
		== std.c.windows.windows.FILE_ATTRIBUTE_READONLY)
		setReadOnly(true);
	else
		setReadOnly(false);
	
	
	//Reinitialize the control settings
	setUndoCollection(true);
	emptyUndoBuffer();
	setSavePoint();
	gotoPos(0);

	// reset line number margin width if necessary
	resetLineNumWidth();
	
	return true;
}

boolean saveFile(char[] filename, bool bClose = false) {

	// get UTF8 text
	
	char[] buffer = this.getText();
	
	try{
		FileSaver.save(filename, buffer, ibom);
	}catch(Exception e){
		MessageBox.showMessage(e.toString());
		return false;
	}

	if( !bClose ) setSavePoint();
	// reset line number margin width if necessary
	resetLineNumWidth();
	
	return true;
}

void resetLineNumWidth(){
	if(getMarginWidthN(0) > 0 ){
		int len = getLineCount();
		char[] sChar = std.string.toString(len);		
		len = Math.max(cast(uint)3, sChar.length);
		setMarginWidthN(0, 8 + 10*len);
	}
}

void doBraceMatching() {
	int braceAtCaret = -1;
	int braceOpposite = -1;
	findMatchingBracePos(braceAtCaret, braceOpposite);

	if ((braceAtCaret != -1) && (braceOpposite == -1))
    {
		braceHighlight(braceAtCaret, 0);
		setHighlightGuide(0);
	} 
    else 
    {
		braceHighlight(braceAtCaret, braceOpposite);

		if (getIndentationGuides())
        {
            int columnAtCaret = getColumn(braceAtCaret);
		    int columnOpposite = getColumn(braceOpposite);
			setHighlightGuide((columnAtCaret < columnOpposite)?columnAtCaret:columnOpposite);
        }
    }
}

void findMatchingBracePos(inout int braceAtCaret, inout int braceOpposite){
	int caretPos = getCurrentPos();
	braceAtCaret = -1;
	braceOpposite = -1;
	char charBefore = '\0';
	//char styleBefore = '\0';
	int lengthDoc = getLength();

	if ((lengthDoc > 0) && (caretPos > 0)) 
	  {
	    charBefore = cast(char)getCharAt(caretPos - 1);
	  }
	// Priority goes to character before caret
	
	if (std.string.find("[](){}", charBefore)!= -1)
	  {
	    braceAtCaret = caretPos - 1;
	  }

	if (lengthDoc > 0  && (braceAtCaret < 0)) 
	  {
	    // No brace found so check other side
	    char charAfter = cast(char)getCharAt(caretPos);
	    if (std.string.find("[](){}", charAfter)!= -1)
	      {
		braceAtCaret = caretPos;
	      }
	  }
	if (braceAtCaret >= 0) 
	  braceOpposite = braceMatch(braceAtCaret, 0);	
}

}	// end of class ScintillaEx
