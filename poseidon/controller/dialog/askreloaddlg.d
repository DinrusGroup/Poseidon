module poseidon.controller.dialog.askreloaddlg;


private import poseidon.globals;
private import dwt.all;


class AskReloadDlg : Dialog 
{
	char[] filename;
	
	private int result = -1;
		
	public this (Shell parent, int style) {
		super (parent, style);
	}
	public this (Shell parent, char[] filename) {
		this (parent, 0); // your default style bits go here (not the Shell's style bits)
		this.filename = filename;
	}
	
	private void createButton(Composite parent, char[] text) {
		with(new Button(parent, DWT.PUSH)){
			setText(text);
			handleSelection(null, &onClose);
			GridData gd = new GridData(GridData.HORIZONTAL_ALIGN_FILL);
			gd.widthHint = 60;
			setLayoutData(gd);
		}
	}
	
	private void initGUI(Shell shell) {
		shell.setText(Globals.getTranslation("mb.ask_reload"));
		char[] string;
		filename ~= Globals.getTranslation("mb.ask_reload_detail");
		GridLayout layout = new GridLayout();
		shell.setLayout(layout);
		layout.marginWidth = 20;
		layout.marginHeight = 12;
		layout.verticalSpacing = 12;
		Label label = new Label(shell, DWT.NONE); //| DWT.WRAP);
		label.setText(filename);
		Composite cp = new Composite(shell, DWT.NONE);
		cp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_CENTER));
		GridLayout gridlayout = new GridLayout();
		with(gridlayout) {
			numColumns = 4;
			horizontalSpacing = 12;
		}
		cp.setLayout(gridlayout);
		createButton(cp, "Yes");
		createButton(cp, "No");
		createButton(cp, "All");
		createButton(cp, "None");
		shell.pack();
	}
	
	private void onClose(SelectionEvent e) {
		// yes no all none
		Button btn = cast(Button)e.widget;
		switch(btn.getText()){
		case "Yes" :
			result = 0; break;
		case "No" :
			result = 1; break;
		case "All" :
			result = 2; break;
		case "None" :
			result = 3; break;
		default : assert(0);
		}
		btn.getShell().close();
	}
		
	public int open () {
		Shell parent = getParent();
		Shell shell = new Shell(parent, DWT.DIALOG_TRIM | DWT.APPLICATION_MODAL);
		initGUI(shell);		
		shell.centerWindow(parent);
		shell.open();
		Display display = parent.getDisplay();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch()) display.sleep();
		}
		return result;
	}
}

