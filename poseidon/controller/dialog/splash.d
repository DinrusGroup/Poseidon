module poseidon.controller.dialog.splash;

private import dwt.all;
private import poseidon.globals;


class Splash : Shell
{
	Canvas canvas;
	Image image;
	Point pt;
	Font font;
	
	this(Shell shell) 
	{
		super(shell, DWT.NO_TRIM);
		
		try{
			image = new Image(display, std.path.join(Globals.appDir, "splash.jpg"));
		}catch(Object o){
			// do nothing, don't report error
			image = null;
		}
		if(image) 
		{
			font = new Font(getDisplay(), "Verdana", 11, DWT.NORMAL);
			
			canvas = new Canvas(this, DWT.NONE);
			canvas.handleEvent(null, DWT.Paint, &onPaint);
			Rectangle rect = image.getBounds(); 
			pt = new Point(rect.width, rect.height);
			setSize(pt);
			pt.x -= 1;
			pt.y -= 1;
			setLayout(new FillLayout());
			centerWindow(null);
			open();
		}else{
			// since we failed to load the splash image, dispose me
			dispose();
		}
	}

	private void onPaint(Event e){
		int x = pt.x - 80;
		int y = 80;
		
		GC gc = e.gc;
		gc.setForeground(getDisplay().getSystemColor(DWT.COLOR_WHITE));
		gc.setFont(font);
		gc.drawImage(image, 0, 0);
		gc.drawString("v " ~ Globals.getVersionS(), x, y, true);
		// draw a frame outside the image
		gc.setForeground(getDisplay().getSystemColor(DWT.COLOR_BLACK));
		gc.drawRectangle(0, 0, pt.x, pt.y);
	}
	
	~this()
	{
		// release image here
		if(image)
			image.dispose();
		if(font)
			font.dispose();
		dispose();
	}
}

