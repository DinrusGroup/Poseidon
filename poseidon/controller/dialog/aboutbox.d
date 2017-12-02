module poseidon.controller.dialog.aboutbox;

private import dwt.all;
private import poseidon.globals;

class AboutBox : Shell {

	private Font font;
	private Color color;
	
	const char[] info = "\nPoseidon is D file editor written using DWT.\n"
				"http://www.dsource.org/projects/dwt\n\n"
				"\nPoseidon is open source. It is provided \"as is\" without warranty of any kind.";
	
	this(Shell parent){
		super(parent, DWT.DIALOG_TRIM | DWT.APPLICATION_MODAL);
		initGUI();
		handleEvent(null, DWT.Dispose, &onDispose);

		setSize(420, 420);
		centerWindow(parent);
	}

	private void initGUI(){
		setText(Globals.getTranslation("ABOUT") ~ " Poseidon");
		GridLayout layout = new GridLayout();
		this.setLayout(layout);
		with(layout){
		}
		font =  new Font(getDisplay(), "Comic Sans MS", 16, DWT.ITALIC | DWT.BOLD);
		color = new Color(getDisplay(), 0, 0, 128);
		
		Composite top = new Composite(this, DWT.NONE);
		GridData data = new GridData(GridData.FILL, GridData.CENTER, true, false);
		top.setLayoutData(data);
		top.setLayout(new FillLayout());
		CLabel label;
		with(label = new CLabel(top, DWT.CENTER)){
			//setText("Poseidon Editor for D v " ~ Globals.getVersionS());
			setText("Poseidon Editor for D rev.272" );
			setForeground(color);
		}
		label.setFont(font);
		
		TabFolder tab = new TabFolder(this, DWT.TOP);
		tab.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true));
		with(new Button(this, DWT.PUSH)){
			setText(Globals.getTranslation("CLOSE"));
			GridData gd = new GridData(GridData.END, GridData.CENTER, true, false);
			gd.widthHint = 60;
			setLayoutData(gd);
			handleEvent(null, DWT.Selection, delegate(Event e){
				(cast(Control)e.widget).getShell().close();
			});
		}

		// init the tabfolder
		TabItem ti;
		Text txt;
		with(txt = new Text(tab, DWT.READ_ONLY|DWT.MULTI|DWT.WRAP|DWT.V_SCROLL)){
			setText(info);
		}
		with(ti = new TabItem(tab, DWT.NONE)){
			setText(Globals.getTranslation("ABOUT"));
			setControl(txt);
		}
		
		Composite cop = new Composite(tab, DWT.V_SCROLL);
		GridLayout gl = new GridLayout();
		cop.setLayout(gl);
		with(new CLabel(cop, DWT.NONE)){
			setText("Shawn Liu");// : liuxuhong.cn@gmail.com");
			setImage(Globals.getImage("gmail"));
		}
		with(new CLabel(cop, DWT.NONE)){
			setText("Charles Sanders");
			setImage(Globals.getImage("d-icon"));
		}
		with(new CLabel(cop, DWT.NONE)){
			setText("Tomohiro Matsuyama, Takeshi Nakanishi [ japanese translations]");
			setImage(Globals.getImage("d-icon"));
		}
		with(new CLabel(cop, DWT.NONE)){
			setText("Saleh Bawazeer [ arabic translations]");
			setImage(Globals.getImage("d-icon"));
		}
		with(new CLabel(cop, DWT.NONE)){
			setText("Kuan Hsu");
			setImage(Globals.getImage("d-icon"));
		}
		with(new CLabel(cop, DWT.NONE)){
			setText("Hasan [ code analyzer]");
			setImage(Globals.getImage("d-icon"));
		}		
		with(new CLabel(cop, DWT.NONE)){
			setText("Highwing [ simplified chinese translations]");
			setImage(Globals.getImage("d-icon"));
		}
		with(new CLabel(cop, DWT.NONE)){
			setText("Valinor [ french translations]");
			setImage(Globals.getImage("d-icon"));
		}
		with(new CLabel(cop, DWT.NONE)){
			setText("Rohan [ Russian translations]");
			setImage(Globals.getImage("d-icon"));
		}
		with(new CLabel(cop, DWT.NONE)){
			setText("krcko [ icon]");
			setImage(Globals.getImage("d-icon"));
		}				
		with(ti = new TabItem(tab, DWT.NONE)){
			setText(Globals.getTranslation("CONTRIBUTORS"));
			setControl(cop);
		}
		
/*  		with(txt = new Text(tab, DWT.READ_ONLY|DWT.MULTI)){
			setText("\n\tD language & Walter\n\thttp://www.digitalmars.com/d\n\n"
				"\tScintilla\n\thttp://www.scintilla.org\n\n"
				"\tdlex.dll from dgrogramming.com\n\thttp://wiki.dprogramming.com/DLex/HomePage\n\n"
				"\tak.xml from akIDE\n\thttp://www.lessequal.com/akide\n\n"
				);
		}
		with(ti = new TabItem(tab, DWT.NONE)){
			setText("Thanks To");
			setControl(txt);
		}  */
	}

	private void onDispose(Event e){
		font.dispose();
		color.dispose();
	}
}


