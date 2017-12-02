/*********************************
 * Author: Shawn Liu
 *
 * History:
 *	20060127 add listener support, when navcache state changed, the listener will be notified. see addListener(). removeListener()
 */


module poseidon.model.navcache;

private import dwt.all;

	struct _NavPoint {
		char[]	filename;
		int 	line;
		static _NavPoint opCall(char[] filename, int line) {
			_NavPoint np;
			np.filename = filename;
			np.line = line;
			return np;
		}
	}
	alias _NavPoint* NavPoint;
/**
 * Navigate cache
 */
class NavCache 
{
	const uint THRESHOLD = 3;
	const uint MAXLENGTH = 50;
	const uint DECREACE  = 5;

	
	const int E_END = 1;
	const int E_BEGINNING = 2;
	const int E_NULL = 0;
	
	
	Listener[] listeners;
	
	_NavPoint[] list;
	int		pos = -1;
	
	public this() {
	}
	
	public NavPoint navForward(){
		if(canForward()){
			++pos;
			notifyListeners(&list[pos]);
			return &list[pos];
		}
		return null;
	}
	
	public NavPoint navBack() {
		if(canBack()){
			--pos;
			notifyListeners(&list[pos]);
			return &list[pos];
		}
		return null;
	}

	public void clear() {
		list.length = 0;
		pos = -1;
		notifyListeners(null);
	}
	
	public void clearFile(char[] filename) {
		for(int i=0; i<list.length; ++i) {
			NavPoint pt = &list[i];
			if(pt.filename == filename){
				SimpleType!(_NavPoint).remove(list, i);
				--pos;
				--i;
			}
		}

		notifyListeners(null);
	}

	public void addListener(Listener listener)
	{
		assert(listener);
		listeners ~= listener;
	}

	public void removeListener(Listener listener)
	{
		if(listener)
			TVector!(Listener).remove(listeners, listener);
	}

	private void notifyListeners(NavPoint pt)
	{
		foreach(Listener listener; listeners) {
			Event e = new Event();
			e.cData = cast(Object)pt;
			listener.handleEvent(e);
		}
	}
	
	public boolean hasCache() {
		return canForward() || canBack(); 
	}
	
	public boolean canForward() {
		return (pos < list.length - 1);
	}
	
	public boolean canBack() {
		return (pos > 0 );
	}
	
	private NavPoint getCurrent() {
		if(pos >= 0 && pos < list.length )
			return &list[pos];
		return null;
	}
	
	/*
	 * zero based line
	 */
	public void add(char[] filename, int line) {
		// Util.trace("%s, line %d, pos %d", filename, line, pos);
		
		// If the file name is equal to the most recently and line is not diff than THRESHOLD line, don't add it
		NavPoint cur = getCurrent();
		if(cur && cur.filename == filename && Math.abs(cur.line - line) < THRESHOLD )
				return;
		
		// If this has been added before, update its position
		for(int i=0; i<list.length; ++i) {
			NavPoint pt = &list[i];
			if(pt.filename == filename && pt.line == line){
				SimpleType!(_NavPoint).remove(list, i);
				break;
			}
		}
		
		SimpleType!(_NavPoint).insert(list, _NavPoint(filename, line), list.length);
		pos = list.length - 1;
		
		checkLength();

		notifyListeners(null);
	}
	
	/**
	 * force the length not to exceed MAXLENTH
	 */
	private void checkLength() {
		if(list.length > MAXLENGTH) {
			assert(DECREACE < MAXLENGTH);
			
			// remove DECREACE items from the header
			list = list[DECREACE..$];
			pos -= DECREACE;
		}
	}
	
	
}