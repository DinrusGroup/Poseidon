module poseidon.util.layoutshop;

private import dwt.all;

private import poseidon.controller.gui;
// private import poseidon.util.shop.fontshop;

class LayoutShop
{
	/** This utility class constructor is hidden */
	private this() {
	// Protect default constructor
	}
  
	/**
	 * Center a shell on the monitor
	 * 
	 * @param display
	 *            The display
	 * @param shell
	 *            The shell to center
	 */
	public static void centerShell(Display display, Shell shell) {
		Rectangle displayBounds = display.getPrimaryMonitor().getBounds();
		Rectangle shellBounds = shell.getBounds();
		int x = displayBounds.x + (displayBounds.width - shellBounds.width) >> 1;
		int y = displayBounds.y + (displayBounds.height - shellBounds.height) >> 1;
		shell.setLocation(x, y);
	}

	/**
	 * Create a new FillLayout with the given parameters
	 * 
	 * @param marginWidth
	 *            Margin width in pixel
	 * @param marginHeight
	 *            Margin height in pixel
	 * @return FillLayout New FillLayout with the given parameters
	 */
	public static FillLayout createFillLayout(int marginWidth = 0, int marginHeight = 0, int type = DWT.HORIZONTAL) {
		FillLayout f = new FillLayout();
		f.marginHeight = marginHeight;
		f.marginWidth = marginWidth;
		f.type = type;
		return f;
	}

	/**
	 * Create a new GridLayout with the given parameters
	 * 
	 * @param cols
	 *            The number of columns
	 * @param marginWidth
	 *            Margin width in pixel
	 * @param marginHeight
	 *            Margin height in pixel
	 * @param verticalSpacing
	 *            Vertical spacing in pixel
	 * @param horizontalSpacing
	 *            Horizontal spacing in pixel
	 * @param makeColumnsEqualWidth
	 *            TRUE if columns should be equals in size
	 * @return GridLayout New GridLayout with the given parameters
	 */
	public static GridLayout createGridLayout(int cols = 1, int marginWidth = 5, int marginHeight = 5, int horizontalSpacing = 5, int verticalSpacing = 5, bool makeColumnsEqualWidth = false) {
		GridLayout g = new GridLayout(cols, makeColumnsEqualWidth);
		g.marginWidth = marginWidth;
		g.marginHeight = marginHeight;
		g.horizontalSpacing = horizontalSpacing;
		g.verticalSpacing = verticalSpacing;
		return g;
	}

	/**
	 * Sets the initial location to use for the shell. The default implementation centers the shell horizontally (1/2 of
	 * the difference to the left and 1/2 to the right) and vertically (1/3 above and 2/3 below) relative to the parent
	 * shell
	 * 
	 * @param shell
	 *            The shell to set the location
	 * @param computeSize
	 *            If TRUE, initialSize is computed from the Shell
	 * @param sameDialogCount
	 *            In the case the same dialog is opened more than once, do not position the Shells on the same position.
	 *            The sameDialogCount integer tells how many dialogs of the same kind are already open. This number is
	 *            used to move the new dialog by some pixels.
	 */
	public static void positionShell(Shell shell, boolean computeSize, int sameDialogCount) {
		Rectangle containerBounds = sShell.getBounds();
		Point initialSize = (computeSize == true) ? shell.computeSize(DWT.DEFAULT, DWT.DEFAULT, true) : shell.getSize();
		int x = Math.max(0, containerBounds.x + (containerBounds.width - initialSize.x) >> 1);
		int y = Math.max(0, containerBounds.y + (containerBounds.height - initialSize.y) / 3);
		shell.setLocation(x + sameDialogCount * 20, y + sameDialogCount * 20);
	}

	/**
	 * Set invisible labels as spacer to a composite. The labels will grab vertical space.
	 * 
	 * @param composite
	 *            The control to add the spacer into
	 * @param cols
	 *            Is used as horizontal span in the GridData
	 * @param rows
	 *            Number of labels that are created
	 */
	public static void setDialogSpacer(Composite composite, int cols, int rows) {
		for (int a = 0; a < rows; a++) {
			Label spacer = new Label(composite, DWT.NONE);
			spacer.setLayoutData(LayoutDataShop.createGridData(GridData.HORIZONTAL_ALIGN_BEGINNING, cols));
			// spacer.setFont(FontShop.dialogFont);
		}
	}

	/**
	 * Recursivly update layout for given control and childs
	 * 
	 * @param control
	 *            The control to set the layout
	 */
	public static void setLayoutForAll(Control control) {
		if (cast(Composite)control) {
			Control[] childs = (cast(Composite) control).getChildren();
			for (int a = 0; a < childs.length; a++)
				setLayoutForAll(childs[a]);

			(cast(Composite) control).layout();
		}
	}
}


public class LayoutDataShop {

  /** This utility class constructor is hidden */
  private this() {
  // Protect default constructor
  }

  /**
   * Create a new FormData with the given Parameters
   * 
   * @param marginLeft Margin in pixel to the left
   * @param marginRight Margin in pixel to the right
   * @param marginTop Margin in pixel to the top
   * @param marginBottom Margin in pixel to the bottom
   * @return FormData with the given parameters
   */
  public static FormData createFormData(int marginLeft, int marginRight, int marginTop, int marginBottom) {
    FormData formData = new FormData();
    formData.top = new FormAttachment(0, marginTop);
    formData.left = new FormAttachment(0, marginLeft);
    formData.right = new FormAttachment(100, marginRight);
    formData.bottom = new FormAttachment(100, marginBottom);
    return formData;
  }

  /**
   * Create a new GridData with the given parameters
   * 
   * @param style GridData style
   * @param horizontalSpan Horizontal span
   * @param widthHint Width hint in pixel
   * @param heightHint Height hint in pixel
   * @return GridData with the given parameters
   */
  public static GridData createGridData(int style, int horizontalSpan = 1, int verticalSpan = 1, int widthHint = DWT.DEFAULT, int heightHint = DWT.DEFAULT ) {
    GridData g = new GridData(style);
    g.horizontalSpan = horizontalSpan;
	g.verticalSpan = verticalSpan;
    g.widthHint = widthHint;
    g.heightHint = heightHint;
    return g;
  }
}