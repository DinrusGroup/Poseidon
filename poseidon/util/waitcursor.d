module poseidon.util.waitcursor;

private import dwt.all;


auto class WaitCursor
{
	private Control control;
	this(Control control) {
		assert(control);
		this.control = control;
		Cursor wait = Display.getCurrent().getSystemCursor(DWT.CURSOR_WAIT);
		control.getShell().setCursor(wait);
	}
	~this(){
		control.getShell().setCursor(null);
	}
}