/*******************************************************************************
 * Copyright (c) 2000, 2005 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Seidel      - enhancements for image-handling
 *******************************************************************************/
module poseidon.controller.imagecombo;

private import dwt.dwt;
private import dwt.widgets.display;
private import dwt.widgets.text;
private import dwt.widgets.table;
private import dwt.widgets.shell;
private import dwt.widgets.button;
private import dwt.widgets.label;
private import dwt.widgets.tableitem;
private import dwt.widgets.layout;
private import dwt.widgets.event;
private import dwt.widgets.listener;
private import dwt.widgets.typedlistener;

private import dwt.graphics.color;
private import dwt.graphics.point;
private import dwt.graphics.font;
private import dwt.graphics.image;
private import dwt.graphics.rectangle;

private import dwt.events.listeners;
private import dwt.events.events;

private import dwt.util.util;
private import dwt.util.eventhandler;
private import dwt.internal.converter;

version( OLE_COM )
{
	private import dwt.accessibility.acc;
	private import dwt.accessibility.accessible;
	private import dwt.accessibility.accevents;
}

/**
 * The ImageCombo class represents a selectable user interface object
 * that combines a text field and a table and issues notification
 * when an item is selected from the table.
 * <p>
 * Note that although this class is a subclass of <code>Composite</code>,
 * it does not make sense to add children to it, or set a layout on it.
 * </p>
 * <dl>
 * <dt><b>Styles:</b>
 * <dd>BORDER, READ_ONLY, FLAT</dd>
 * <dt><b>Events:</b>
 * <dd>Selection</dd>
 * </dl>
 */
public class ImageCombo : Composite
{

    Text text;
    Table table;
    int visibleItemCount = 5;
    Shell popup;
    Button arrow;
    boolean hasFocus;
    Listener listener, filter;
    Color foreground, background;
    Font font;
    
	/**
	 * Constructs a new instance of this class given its parent
	 * and a style value describing its behavior and appearance.
	 * <p>
	 * The style value is either one of the style constants defined in
	 * class <code>SWT</code> which is applicable to instances of this
	 * class, or must be built by <em>bitwise OR</em>'ing together 
	 * (that is, using the <code>int</code> "|" operator) two or more
	 * of those <code>SWT</code> style constants. The class description
	 * lists the style constants that are applicable to the class.
	 * Style bits are also inherited from superclasses.
	 * </p>
	 *
	 * @param parent a widget which will be the parent of the new instance (cannot be null)
	 * @param style the style of widget to construct
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the parent is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the parent</li>
	 * </ul>
	 *
	 * @see SWT#BORDER
	 * @see SWT#READ_ONLY
	 * @see SWT#FLAT
	 * @see Widget#getStyle()
	 */
	public this( Composite parent, int style )
	{
		super( parent, style = checkStyle(style) );
		
		int textStyle = DWT.SINGLE;
		if ( ( style & DWT.READ_ONLY) != 0 ) textStyle |= DWT.READ_ONLY;
		if ( ( style & DWT.FLAT ) != 0 ) textStyle |= DWT.FLAT;
		text = new Text( this, DWT.NONE | DWT.BORDER);
		int arrowStyle = DWT.ARROW | DWT.DOWN;
		if ( ( style & DWT.FLAT ) != 0 ) arrowStyle |= DWT.FLAT;
		arrow = new Button( this, arrowStyle );

		class Listener1 : Listener
		{
			ImageCombo c;
			public this( ImageCombo cc ){ c = cc; }

			public void handleEvent( Event event )
			{
				if( c.popup is event.widget )
				{
					popupEvent (event);
					return;
				}
				if( c.text is event.widget )
				{
					textEvent (event);
					return;
				}
				if( c.table is event.widget )
				{
					listEvent (event);
					return;
				}
				if( c.arrow is event.widget )
				{
					arrowEvent (event);
					return;
				}
				if( c is event.widget )
				{
					comboEvent (event);
					return;
				}
				if( c.getShell () is event.widget ) handleFocus( DWT.FocusOut );
			}
		}
		listener = new Listener1(this) ;
		
		class Listener2 : Listener
		{
			ImageCombo c;
			public this( ImageCombo cc ){ c = cc; }
			
			public void handleEvent( Event event )
			{
				Shell shell = ( cast(Control) event.widget ).getShell();
				if( shell == c.getShell ()) handleFocus( DWT.FocusOut );
			}
		}
		filter = new Listener2(this);
		
		int[] comboEvents = [ DWT.Dispose, DWT.Move, DWT.Resize ];
		for(int i=0; i<comboEvents.length; i++) this.addListener (comboEvents [i], listener);
		
		int[] textEvents = [ DWT.KeyDown, DWT.KeyUp, DWT.Modify, DWT.MouseDown, DWT.MouseUp, DWT.Traverse, DWT.FocusIn ];
		for(int i=0; i<textEvents.length; i++) text.addListener (textEvents [i], listener);
		
		int[] arrowEvents = [ DWT.Selection, DWT.FocusIn ];
		for(int i=0; i<arrowEvents.length; i++) arrow.addListener (arrowEvents [i], listener);
		
		createPopup( -1 );
		version( OLE_COM ){ initAccessible(); }
	}


	static int checkStyle( int style )
	{
		int mask = DWT.BORDER | DWT.READ_ONLY | DWT.FLAT | DWT.LEFT_TO_RIGHT | DWT.RIGHT_TO_LEFT;
		return style & mask;
	}
	/**
	 * Adds the argument to the end of the receiver's list.
	 *
	 * @param string the new item
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 *
	 * @see #add(String,int)
	 */
	public void add( char[] string, Image image )
	{
		checkWidget();
		if( string is null ) error( __FILE__, __LINE__, DWT.ERROR_NULL_ARGUMENT );
		TableItem newItem = new TableItem( this.table,DWT.NONE );
		newItem.setText( string );
		if( image !is null ) newItem.setImage( image );
	}
	/**
	 * Adds the argument to the receiver's list at the given
	 * zero-relative index.
	 * <p>
	 * Note: To add an item at the end of the list, use the
	 * result of calling <code>getItemCount()</code> as the
	 * index or use <code>add(String)</code>.
	 * </p>
	 *
	 * @param string the new item
	 * @param index the index for the item
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
	 *    <li>ERROR_INVALID_RANGE - if the index is not between 0 and the number of elements in the list (inclusive)</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 *
	 * @see #add(String)
	 */
	public void add( char[] string,Image image, int index )
	 {
		checkWidget();
		if( string is null ) error( __FILE__, __LINE__, DWT.ERROR_NULL_ARGUMENT );
		TableItem newItem = new TableItem( this.table,DWT.NONE,index );
		if( image !is null ) newItem.setImage( image );
	}
	/**
	 * Adds the listener to the collection of listeners who will
	 * be notified when the receiver's text is modified, by sending
	 * it one of the messages defined in the <code>ModifyListener</code>
	 * interface.
	 *
	 * @param listener the listener which should be notified
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the listener is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 *
	 * @see ModifyListener
	 * @see #removeModifyListener
	 */
	public void addModifyListener( ModifyListener listener )
	{
		checkWidget();
		if( listener is null ) error( __FILE__, __LINE__, DWT.ERROR_NULL_ARGUMENT );
		TypedListener typedListener = new TypedListener( listener );
		addListener( DWT.Modify, typedListener );
	}
	/**
	 * Adds the listener to the collection of listeners who will
	 * be notified when the receiver's selection changes, by sending
	 * it one of the messages defined in the <code>SelectionListener</code>
	 * interface.
	 * <p>
	 * <code>widgetSelected</code> is called when the combo's list selection changes.
	 * <code>widgetDefaultSelected</code> is typically called when ENTER is pressed the combo's text area.
	 * </p>
	 *
	 * @param listener the listener which should be notified
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the listener is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 *
	 * @see SelectionListener
	 * @see #removeSelectionListener
	 * @see SelectionEvent
	 */
	public void addSelectionListener( SelectionListener listener )
	{
		checkWidget();
		if( listener is null ) error(__FILE__, __LINE__, DWT.ERROR_NULL_ARGUMENT);
		TypedListener typedListener = new TypedListener ( listener );
		addListener( DWT.Selection,typedListener );
		addListener( DWT.DefaultSelection,typedListener );
	}

	void arrowEvent( Event event )
	{
		switch( event.type )
		{
			case DWT.FocusIn:
				handleFocus( DWT.FocusIn );
				break;
			case DWT.Selection:
				dropDown( !isDropped () );
				break;
		}
	}
	/**
	 * Sets the selection in the receiver's text field to an empty
	 * selection starting just before the first character. If the
	 * text field is editable, this has the effect of placing the
	 * i-beam at the start of the text.
	 * <p>
	 * Note: To clear the selected items in the receiver's list, 
	 * use <code>deselectAll()</code>.
	 * </p>
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 *
	 * @see #deselectAll
	 */
	public void clearSelection()
	{
		checkWidget();
		text.clearSelection();
		table.deselectAll();
	}
	
	void comboEvent (Event event)
	{
		switch( event.type )
		{
			case DWT.Dispose:
				if( popup !is null && !popup.isDisposed() )
				{
					table.removeListener( DWT.Dispose, listener );
					popup.dispose();
				}
				Shell shell = getShell();
				shell.removeListener( DWT.Deactivate, listener );
				Display display = getDisplay();
				display.removeFilter( DWT.FocusIn, filter );
				popup = null;  
				text = null;  
				table = null;  
				arrow = null;
				break;
			case DWT.Move:
				dropDown( false );
				break;
			case DWT.Resize:
				internalLayout( false );
				break;
		}
	}

	public Point computeSize( int wHint, int hHint, boolean changed )
	{
		checkWidget();
		int width = 0, height = 0;
		Point textSize = text.computeSize( wHint, DWT.DEFAULT, changed );
		Point arrowSize = arrow.computeSize( DWT.DEFAULT, DWT.DEFAULT, changed );
		Point tableSize = table.computeSize( wHint, DWT.DEFAULT, changed );
		int borderWidth = getBorderWidth();
		
		height = Math.max( hHint, Math.max( textSize.y, arrowSize.y)  + 2 * borderWidth );
		width = Math.max( wHint, Math.max( textSize.x + arrowSize.x + 2 * borderWidth, tableSize.x + 2 ) );
		return new Point( width, height );
	}

	void createPopup(int selectionIndex) {     
			// create shell and list
			popup = new Shell (getShell (), DWT.NO_TRIM | DWT.ON_TOP);
			int style = getStyle ();
			int listStyle = DWT.SINGLE | DWT.V_SCROLL;
			if ((style & DWT.FLAT) != 0) listStyle |= DWT.FLAT;
			if ((style & DWT.RIGHT_TO_LEFT) != 0) listStyle |= DWT.RIGHT_TO_LEFT;
			if ((style & DWT.LEFT_TO_RIGHT) != 0) listStyle |= DWT.LEFT_TO_RIGHT;
			// create a table instead of a list.
			table = new Table (popup, listStyle);

			/+
			if (font != null) table.setFont (font);
			if (foreground != null) table.setForeground (foreground);
			if (background != null) table.setBackground (background);
			+/
			
			int [] popupEvents = [DWT.Close, DWT.Paint, DWT.Deactivate];
			for (int i=0; i<popupEvents.length; i++) popup.addListener (popupEvents [i], listener);
			int [] listEvents = [DWT.MouseUp, DWT.Selection, DWT.Traverse, DWT.KeyDown, DWT.KeyUp, DWT.FocusIn, DWT.Dispose];
			for (int i=0; i<listEvents.length; i++) table.addListener (listEvents [i], listener);
			if (selectionIndex != -1) table.setSelection (selectionIndex);
	}
	/**
	 * Deselects the item at the given zero-relative index in the receiver's 
	 * list.  If the item at the index was already deselected, it remains
	 * deselected. Indices that are out of range are ignored.
	 *
	 * @param index the index of the item to deselect
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void deselect( int index )
	{
		checkWidget();
		table.deselect( index );
	}
	/**
	 * Deselects all selected items in the receiver's list.
	 * <p>
	 * Note: To clear the selection in the receiver's text field,
	 * use <code>clearSelection()</code>.
	 * </p>
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 *
	 * @see #clearSelection
	 */
	public void deselectAll()
	{
		checkWidget();
		table.deselectAll();
	}
	
	void dropDown( boolean drop )
	{
		if( drop == isDropped () ) return;
		if( !drop )
		{
			popup.setVisible( false );
			if (!isDisposed ()&& arrow.isFocusControl()) text.setFocus();
			return;
		}

		if( getShell() != popup.getParent() )
		{
			TableItem[] items = table.getItems();
			int selectionIndex = table.getSelectionIndex();
			table.removeListener( DWT.Dispose, listener );
			popup.dispose();
			popup = null;
			table = null;
			createPopup( selectionIndex );
		}
		
		Point size = getSize();
		int itemCount = table.getItemCount();
		itemCount = (itemCount == 0) ? visibleItemCount : Math.min(visibleItemCount, itemCount);
		int itemHeight = table.getItemHeight () * itemCount;
		Point listSize = table.computeSize (DWT.DEFAULT, itemHeight, false);
		table.setBounds (1, 1, Math.max (size.x - 2, listSize.x), listSize.y);
		
		int index = table.getSelectionIndex ();
		if (index != -1) table.setTopIndex (index);
		Display display = getDisplay ();
		Rectangle listRect = table.getBounds ();
		Rectangle parentRect = display.map (getParent (), null, getBounds ());
		Point comboSize = getSize ();
		Rectangle displayRect = getMonitor ().getClientArea ();
		int width = Math.max (comboSize.x, listRect.width + 2);
		int height = listRect.height + 2;
		int x = parentRect.x;
		int y = parentRect.y + comboSize.y;
		if (y + height > displayRect.y + displayRect.height) y = parentRect.y - height;
		popup.setBounds (x, y, width, height);
		popup.setVisible (true);
		table.setFocus ();
	}
	/* 
	 * Return the Label immediately preceding the receiver in the z-order, 
	 * or null if none. 
	 */
	Label getAssociatedLabel () {
		Control[] siblings = getParent().getChildren();
		for (int i = 0; i < siblings.length; i++) {
			if (siblings[i] is this) {
				if (i > 0 && cast(Label)siblings[i-1] ) {
					return cast(Label)siblings[i-1];
				}
			}
		}
		return null;
	}


	public Control [] getChildren () {
		checkWidget();
		return new Control [0];
	}
	/**
	 * Gets the editable state.
	 *
	 * @return whether or not the reciever is editable
	 * 
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 * 
	 * @since 3.0
	 */
	public boolean getEditable()
	{
		checkWidget();
		return text.getEditable();
	}
	/**
	 * Returns the item at the given, zero-relative index in the
	 * receiver's list. Throws an exception if the index is out
	 * of range.
	 *
	 * @param index the index of the item to return
	 * @return the item at the given index
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_INVALID_RANGE - if the index is not between 0 and the number of elements in the list minus 1 (inclusive)</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public TableItem getItem( int index )
	{
		checkWidget();
		return this.table.getItem( index );
	}
	/**
	 * Returns the number of items contained in the receiver's list.
	 *
	 * @return the number of items
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public int getItemCount()
	{
		checkWidget();
		return table.getItemCount();
	}
	/**
	 * Returns the height of the area which would be used to
	 * display <em>one</em> of the items in the receiver's list.
	 *
	 * @return the height of one item
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public int getItemHeight()
	{
		checkWidget();
		return table.getItemHeight();
	}
	/**
	 * Returns an array of <code>String</code>s which are the items
	 * in the receiver's list. 
	 * <p>
	 * Note: This is not the actual structure used by the receiver
	 * to maintain its list of items, so modifying the array will
	 * not affect the receiver. 
	 * </p>
	 *
	 * @return the items in the receiver's list
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public TableItem[] getItems()
	{
		checkWidget();
		return table.getItems();
	}

	char getMnemonic (char[] string) {
		int index = 0;
		int length = string.length;
		do {
			while ((index < length) && (string[index] != '&')) index++;
			if (++index >= length) return '\0';
			if (string[index] != '&') return string[index];
			index++;
		} while (index < length);
		return '\0';
	}

	char[][] getStringsFromTable()
	{
		char[][] items;
		items.length = this.table.getItems().length;
		for( int i = 0, n = items.length; i < n; i++ )
		{
			items[i] = this.table.getItem( i ).getText( 0 );
		}
		return items;
	}
	/**
	 * Returns a <code>Point</code> whose x coordinate is the start
	 * of the selection in the receiver's text field, and whose y
	 * coordinate is the end of the selection. The returned values
	 * are zero-relative. An "empty" selection as indicated by
	 * the the x and y coordinates having the same value.
	 *
	 * @return a point representing the selection start and end
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public Point getSelection()
	{
		checkWidget();
		return text.getSelection();
	}
	/**
	 * Returns the zero-relative index of the item which is currently
	 * selected in the receiver's list, or -1 if no item is selected.
	 *
	 * @return the index of the selected item
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public int getSelectionIndex()
	{
		checkWidget ();
		return table.getSelectionIndex();
	}
	
	public int getStyle()
	{
		int style = super.getStyle();
		style &= ~DWT.READ_ONLY;
		if( !text.getEditable() ) style |= DWT.READ_ONLY; 
		return style;
	}
	/**
	 * Returns a string containing a copy of the contents of the
	 * receiver's text field.
	 *
	 * @return the receiver's text
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public char[] getText()
	{
		checkWidget();
		return text.getText();
	}
	/**
	 * Returns the height of the receivers's text field.
	 *
	 * @return the text height
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public int getTextHeight()
	{
		checkWidget();
		return text.getLineHeight();
	}
	/**
	 * Returns the maximum number of characters that the receiver's
	 * text field is capable of holding. If this has not been changed
	 * by <code>setTextLimit()</code>, it will be the constant
	 * <code>Combo.LIMIT</code>.
	 * 
	 * @return the text limit
	 * 
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public int getTextLimit()
	{
		checkWidget();
		return text.getTextLimit();
	}
	/**
	 * Gets the number of items that are visible in the drop
	 * down portion of the receiver's list.
	 *
	 * @return the number of items that are visible
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 * 
	 * @since 3.0
	 */
	public int getVisibleItemCount()
	{
		checkWidget();
		return visibleItemCount;
	}
	
	void handleFocus( int type )
	{
		if (isDisposed ()) return;
		switch (type) {
			case DWT.FocusIn: {
				if (hasFocus) return;
				if (getEditable ()) text.selectAll ();
				hasFocus = true;
				Shell shell = getShell ();
				shell.removeListener (DWT.Deactivate, listener);
				shell.addListener (DWT.Deactivate, listener);
				Display display = getDisplay ();
				display.removeFilter (DWT.FocusIn, filter);
				display.addFilter (DWT.FocusIn, filter);
				Event e = new Event ();
				notifyListeners (DWT.FocusIn, e);
				break;
			}
			case DWT.FocusOut: {
				if (!hasFocus) return;
				Control focusControl = getDisplay ().getFocusControl ();
				if (focusControl == arrow || focusControl == table || focusControl == text) return;
				hasFocus = false;
				Shell shell = getShell ();
				shell.removeListener(DWT.Deactivate, listener);
				Display display = getDisplay ();
				display.removeFilter (DWT.FocusIn, filter);
				Event e = new Event ();
				notifyListeners (DWT.FocusOut, e);
				break;
			}
		}
	}
	/**
	 * Searches the receiver's list starting at the first item
	 * (index 0) until an item is found that is equal to the 
	 * argument, and returns the index of that item. If no item
	 * is found, returns -1.
	 *
	 * @param string the search item
	 * @return the index of the item
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public int indexOf( char[] string )
	{
		checkWidget();
		if( string is null ) DWT.error(__FILE__, __LINE__, DWT.ERROR_NULL_ARGUMENT);

		int count;
		foreach( char[] s; getStringsFromTable() )
		{
			if( s == string ) return count;
			count ++;
		}
		return -1;
		//return Arrays.asList(getStringsFromTable()).indexOf( string );
	}

	version(OLE_COM)
	{
		void initAccessible()
		{
			class AA1 : AccessibleAdapter
			{
				private ImageCombo c;
				public this( ImageCombo cc) { c=cc;}
				
				public void getName(AccessibleEvent e) {
					char[] name = null;
					Label label = c.getAssociatedLabel ();
					if (label !is null) {
						name = c.stripMnemonic(label.getText());
					}
					e.result = name;
				}
				public void getKeyboardShortcut(AccessibleEvent e) {
					char[] shortcut = null;
					Label label = c.getAssociatedLabel ();
					if (label !is null) {
						char[] text = label.getText();
						if (text !is null) {
							char mnemonic = c.getMnemonic(text);
							if (mnemonic != '\0') {
								shortcut = ("Alt+");
								shortcut ~= mnemonic; //$NON-NLS-1$
							}
						}
					}
					e.result = shortcut;
				}
				public void getHelp(AccessibleEvent e) {
					e.result = c.getToolTipText();
				}
			}
			AccessibleAdapter accessibleAdapter = new AA1(this) ;

			getAccessible ().addAccessibleListener (accessibleAdapter);
			text.getAccessible ().addAccessibleListener (accessibleAdapter);
			table.getAccessible ().addAccessibleListener (accessibleAdapter);

			class ATA1 : AccessibleTextAdapter 
			{
				public void getName (AccessibleEvent e) {
					e.result = isDropped () ? DWT.getMessage ("SWT_Close") : DWT.getMessage ("SWT_Open"); //$NON-NLS-1$ //$NON-NLS-2$
				}
				public void getKeyboardShortcut (AccessibleEvent e) {
					e.result = "Alt+Down Arrow"; //$NON-NLS-1$
				}
				public void getHelp (AccessibleEvent e) {
					e.result = getToolTipText ();
				}
			}
			arrow.getAccessible().addAccessibleTextListener(new ATA1);

			class ATA2 : AccessibleTextAdapter 
			{
				public void getCaretOffset (AccessibleTextEvent e) {
					e.offset = text.getCaretPosition ();
				}
			}
			getAccessible().addAccessibleTextListener(new ATA2);

			class ACA1 : AccessibleControlAdapter
			{
				private ImageCombo c;
				public this( ImageCombo cc) { c=cc;}
				
				public void getChildAtPoint(AccessibleControlEvent e) {
					Point testPoint = c.toControl(new Point(e.x, e.y));
					if (c.getBounds().contains(testPoint)) {
						e.childID = ACC.CHILDID_SELF;
					}
				}
				
				public void getLocation(AccessibleControlEvent e) {
					Rectangle location = c.getBounds();
					Point pt = c.toDisplay(new Point(location.x, location.y));
					e.x = pt.x;
					e.y = pt.y;
					e.width = location.width;
					e.height = location.height;
				}
				
				public void getChildCount(AccessibleControlEvent e) {
					e.detail = 0;
				}
				
				public void getRole(AccessibleControlEvent e) {
					e.detail = ACC.ROLE_COMBOBOX;
				}
				
				public void getState(AccessibleControlEvent e) {
					e.detail = ACC.STATE_NORMAL;
				}

				public void getValue(AccessibleControlEvent e) {
					e.result = c.getText();
				}
			}
			getAccessible().addAccessibleControlListener(new ACA1(this) );
			

			class ACA2 : AccessibleControlAdapter {
				public void getRole (AccessibleControlEvent e) {
					e.detail = text.getEditable () ? ACC.ROLE_TEXT : ACC.ROLE_LABEL;
				}
			}
			text.getAccessible ().addAccessibleControlListener( new ACA2 );

			class ACA3 : AccessibleControlAdapter {
				public void getDefaultAction (AccessibleControlEvent e) {
					e.result = isDropped () ? DWT.getMessage ("SWT_Close") : DWT.getMessage ("SWT_Open"); //$NON-NLS-1$ //$NON-NLS-2$
				}
			}
			arrow.getAccessible ().addAccessibleControlListener( new ACA3 );
		}
	}

	boolean isDropped(){ return popup.getVisible();	}
	
	public boolean isFocusControl()
	{
		checkWidget();
		if( text.isFocusControl() || arrow.isFocusControl() || table.isFocusControl() || popup.isFocusControl() )
			return true;

		return super.isFocusControl();
	}
	
	void internalLayout (boolean changed) {
		if (isDropped ()) dropDown (false);
		Rectangle rect = getClientArea ();
		int width = rect.width;
		int height = rect.height;
		Point arrowSize = arrow.computeSize (DWT.DEFAULT, height, changed);
		text.setBounds (0, 0, width - arrowSize.x, height);
		arrow.setBounds (width - arrowSize.x, 0, arrowSize.x, arrowSize.y);
	}
	
	void listEvent (Event event) {
		switch (event.type) {
			case DWT.Dispose:
				if (getShell () != popup.getParent ()) {
					TableItem[] items = table.getItems ();
					int selectionIndex = table.getSelectionIndex ();
					popup = null;
					table = null;
					createPopup (selectionIndex);
				}
				break;
			case DWT.FocusIn: {
				handleFocus (DWT.FocusIn);
				break;
			}
			case DWT.MouseUp: {
				if (event.button != 1) return;
				dropDown (false);
				break;
			}
			case DWT.Selection: {
				int index = table.getSelectionIndex ();
				if (index == -1) return;
				text.setText( table.getItem (index).getText(0) );
				text.selectAll ();
				table.setSelection (index);
				Event e = new Event ();
				e.time = event.time;
				e.stateMask = event.stateMask;
				e.doit = event.doit;
				notifyListeners (DWT.Selection, e);
				event.doit = e.doit;
				break;
			}
			case DWT.Traverse: {
				switch (event.detail) {
					case DWT.TRAVERSE_RETURN:
					case DWT.TRAVERSE_ESCAPE:
					case DWT.TRAVERSE_ARROW_PREVIOUS:
					case DWT.TRAVERSE_ARROW_NEXT:
						event.doit = false;
						break;
				}
				Event e = new Event ();
				e.time = event.time;
				e.detail = event.detail;
				e.doit = event.doit;
				e.character = event.character;
				e.keyCode = event.keyCode;
				notifyListeners (DWT.Traverse, e);
				event.doit = e.doit;
				event.detail = e.detail;
				break;
			}
			case DWT.KeyUp: {       
				Event e = new Event ();
				e.time = event.time;
				e.character = event.character;
				e.keyCode = event.keyCode;
				e.stateMask = event.stateMask;
				notifyListeners (DWT.KeyUp, e);
				break;
			}
			case DWT.KeyDown: {
				if (event.character == DWT.ESC) { 
					// Escape key cancels popup list
					dropDown (false);
				}
				if ((event.stateMask & DWT.ALT) != 0 && (event.keyCode == DWT.ARROW_UP || event.keyCode == DWT.ARROW_DOWN)) {
					dropDown (false);
				}
				if (event.character == DWT.CR) {
					// Enter causes default selection
					dropDown (false);
					Event e = new Event ();
					e.time = event.time;
					e.stateMask = event.stateMask;
					notifyListeners (DWT.DefaultSelection, e);
				}
				// At this point the widget may have been disposed.
				// If so, do not continue.
				if (isDisposed ()) break;
				Event e = new Event();
				e.time = event.time;
				e.character = event.character;
				e.keyCode = event.keyCode;
				e.stateMask = event.stateMask;
				notifyListeners(DWT.KeyDown, e);
				break;
				
			}
		}
	}

	void popupEvent(Event event) {
		switch (event.type) {
			case DWT.Paint:
				// draw black rectangle around list
				Rectangle listRect = table.getBounds();
				Color black = getDisplay().getSystemColor(DWT.COLOR_BLACK);
				event.gc.setForeground(black);
				event.gc.drawRectangle(0, 0, listRect.width + 1, listRect.height + 1);
				break;
			case DWT.Close:
				event.doit = false;
				dropDown (false);
				break;
			case DWT.Deactivate:
				dropDown (false);
				break;
		}
	}
	public void redraw()
	{
		super.redraw();
		text.redraw();
		arrow.redraw();
		if( popup.isVisible() ) table.redraw();
	}
	
	public void redraw(int x, int y, int width, int height, boolean all )
	{
		super.redraw( x, y, width, height, true );
	}

	/**
	 * Removes the item from the receiver's list at the given
	 * zero-relative index.
	 *
	 * @param index the index for the item
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_INVALID_RANGE - if the index is not between 0 and the number of elements in the list minus 1 (inclusive)</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void remove( int index )
	{
		checkWidget();
		table.remove( index );
	}
	/**
	 * Removes the items from the receiver's list which are
	 * between the given zero-relative start and end 
	 * indices (inclusive).
	 *
	 * @param start the start of the range
	 * @param end the end of the range
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_INVALID_RANGE - if either the start or end are not between 0 and the number of elements in the list minus 1 (inclusive)</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void remove( int start, int end )
	{
		checkWidget();
		table.remove( start, end );
	}
	/**
	 * Searches the receiver's list starting at the first item
	 * until an item is found that is equal to the argument, 
	 * and removes that item from the list.
	 *
	 * @param string the item to remove
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
	 *    <li>ERROR_INVALID_ARGUMENT - if the string is not found in the list</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void remove( char[] string )
	{
		checkWidget();
		if( string is null ) DWT.error(__FILE__, __LINE__, DWT.ERROR_NULL_ARGUMENT);
		int index = -1;
		for( int i = 0, n = table.getItemCount(); i < n; i++ )
		{
			if( table.getItem(i).getText( 0 ) == string )
			{
				index = i;
				break;
			}
		}
		remove( index );
	}
	/**
	 * Removes all of the items from the receiver's list and clear the
	 * contents of receiver's text field.
	 * <p>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void removeAll()
	{
		checkWidget();
		text.setText (""); //$NON-NLS-1$
		table.removeAll();
	}
	/**
	 * Removes the listener from the collection of listeners who will
	 * be notified when the receiver's text is modified.
	 *
	 * @param listener the listener which should no longer be notified
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the listener is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 *
	 * @see ModifyListener
	 * @see #addModifyListener
	 */
	public void removeModifyListener( ModifyListener listener )
	{
		checkWidget();
		if( listener is null ) DWT.error(__FILE__, __LINE__, DWT.ERROR_NULL_ARGUMENT);
		removeListener( DWT.Modify, listener );   
	}
	/**
	 * Removes the listener from the collection of listeners who will
	 * be notified when the receiver's selection changes.
	 *
	 * @param listener the listener which should no longer be notified
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the listener is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 *
	 * @see SelectionListener
	 * @see #addSelectionListener
	 */
	public void removeSelectionListener( SelectionListener listener )
	{
		checkWidget();
		if( listener is null ) DWT.error(__FILE__, __LINE__, DWT.ERROR_NULL_ARGUMENT);
		removeListener( DWT.Selection, listener );
		removeListener( DWT.DefaultSelection,listener );  
	}
	/**
	 * Selects the item at the given zero-relative index in the receiver's 
	 * list.  If the item at the index was already selected, it remains
	 * selected. Indices that are out of range are ignored.
	 *
	 * @param index the index of the item to select
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void select( int index )
	{
		checkWidget();
		if( index == -1 )
		{
			table.deselectAll ();
			text.setText (""); //$NON-NLS-1$
			return;
		}

		if( 0 <= index && index < table.getItemCount() )
			if( index != getSelectionIndex() )
			{
				text.setText( table.getItem( index ).getText( 0 ) );
				text.selectAll();
				table.select( index );
				table.showSelection();
			}
	}
	
	public void setBackground( Color color )
	{
		super.setBackground( color );
		background = color;
		if( text !is null ) text.setBackground( color );
		if( table !is null ) table.setBackground( color );
		if( arrow !is null ) arrow.setBackground( color );
	}
	/**
	 * Sets the editable state.
	 *
	 * @param editable the new editable state
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 * 
	 * @since 3.0
	 */
	public void setEditable( boolean editable )
	{
		checkWidget();
		text.setEditable( editable );
	}
	
	public void setEnabled( boolean enabled )
	{
		super.setEnabled(enabled);
		if (popup !is null) popup.setVisible (false);
		if (text !is null) text.setEnabled(enabled);
		if (arrow !is null) arrow.setEnabled(enabled);
	}
	public boolean setFocus () {
		checkWidget();
		return text.setFocus ();
	}
	public void setFont (Font font) {
		super.setFont (font);
		this.font = font;
		text.setFont (font);
		table.setFont (font);
		internalLayout (true);
	}
	public void setForeground( Color color )
	{
		super.setForeground( color );
		foreground = color;
		if( text !is null ) text.setForeground( color );
		if( table !is null ) table.setForeground( color );
		if( arrow !is null ) arrow.setForeground( color );
	}
	/**
	 * Sets the text of the item in the receiver's list at the given
	 * zero-relative index to the string argument. This is equivalent
	 * to <code>remove</code>'ing the old item at the index, and then
	 * <code>add</code>'ing the new item at that index.
	 *
	 * @param index the index for the item
	 * @param string the new text for the item
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_INVALID_RANGE - if the index is not between 0 and the number of elements in the list minus 1 (inclusive)</li>
	 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void setItem( int index, char[] string, Image image )
	{
		checkWidget();
		remove(index);
		add(string,image,index);
	}
	/**
	 * Sets the receiver's list to be the given array of items.
	 *
	 * @param items the array of items
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the items array is null</li>
	 *    <li>ERROR_INVALID_ARGUMENT - if an item in the items array is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void setItems( char[][] items )
	{
		checkWidget ();
		this.table.removeAll();
		for( int i = 0, n = items.length; i < n; i++ )
			add( items[i], null );
			
		if( !text.getEditable() ) text.setText( "" ); //$NON-NLS-1$
	}

	/**
	 * Sets the layout which is associated with the receiver to be
	 * the argument which may be null.
	 * <p>
	 * Note : No Layout can be set on this Control because it already
	 * manages the size and position of its children.
	 * </p>
	 *
	 * @param layout the receiver's new layout or null
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void setLayout( Layout layout )
	{
		checkWidget ();
		return;
	}
	/**
	 * Sets the selection in the receiver's text field to the
	 * range specified by the argument whose x coordinate is the
	 * start of the selection and whose y coordinate is the end
	 * of the selection. 
	 *
	 * @param selection a point representing the new selection start and end
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the point is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void setSelection( Point selection )
	{
		checkWidget();
		if( selection is null ) DWT.error( __FILE__, __LINE__, DWT.ERROR_NULL_ARGUMENT );
		text.setSelection( selection.x, selection.y );
	}

	/**
	 * Sets the contents of the receiver's text field to the
	 * given string.
	 * <p>
	 * Note: The text field in a <code>Combo</code> is typically
	 * only capable of displaying a single line of text. Thus,
	 * setting the text to a string containing line breaks or
	 * other special characters will probably cause it to 
	 * display incorrectly.
	 * </p>
	 *
	 * @param string the new text
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void setText( char[] string )
	{
		checkWidget();
		if( string is null ) DWT.error(__FILE__, __LINE__, DWT.ERROR_NULL_ARGUMENT);
		int index = -1;
		for( int i = 0, n = table.getItemCount(); i < n; i++ )
			if( table.getItem(i).getText(0) == string )
			{
				index = i;
				break;
			}

		if( index == -1 )
		{
			table.deselectAll();
			text.setText( string );
			return;
		}
		text.setText( string );
		text.selectAll();
		table.setSelection( index );
		table.showSelection();
	}
	/**
	 * Sets the maximum number of characters that the receiver's
	 * text field is capable of holding to be the argument.
	 *
	 * @param limit new text limit
	 *
	 * @exception IllegalArgumentException <ul>
	 *    <li>ERROR_CANNOT_BE_ZERO - if the limit is zero</li>
	 * </ul>
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 */
	public void setTextLimit( int limit )
	{
		checkWidget();
		text.setTextLimit( limit );
	}

	public void setToolTipText( char[] string )
	{
		checkWidget();
		super.setToolTipText( string );
		arrow.setToolTipText( string );
		text.setToolTipText( string );       
	}

	public void setVisible( boolean visible )
	{
		super.setVisible( visible );
		if( !visible ) popup.setVisible( false );
	}
	/**
	 * Sets the number of items that are visible in the drop
	 * down portion of the receiver's list.
	 *
	 * @param count the new number of items to be visible
	 *
	 * @exception SWTException <ul>
	 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
	 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
	 * </ul>
	 * 
	 * @since 3.0
	 */
	public void setVisibleItemCount( int count )
	{
		checkWidget ();
		if( count < 0 ) return;
		visibleItemCount = count;
	}


	char[] stripMnemonic (char[] string) {
		int index = 0;
		int len = string.length;
		do {
			while ((index < len) && (Converter.charAt(string, index) != '&')) index++;
			if (++index >= len) return string;
			if (Converter.charAt(string, index) != '&') {
				return Converter.substring(string, 0, index-1) ~ Converter.substring(string, index, len);
			}
			index++;
		} while (index < len);
		return string;
	}


	void textEvent (Event event) {
		switch (event.type) {
			case DWT.FocusIn: {
				handleFocus (DWT.FocusIn);
				break;
			}
			case DWT.KeyDown: {
				if (event.character == DWT.CR) {
					dropDown (false);
					Event e = new Event ();
					e.time = event.time;
					e.stateMask = event.stateMask;
					notifyListeners (DWT.DefaultSelection, e);
				}
				//At this point the widget may have been disposed.
				// If so, do not continue.
				if (isDisposed ()) break;
				
				if (event.keyCode == DWT.ARROW_UP || event.keyCode == DWT.ARROW_DOWN) {
					event.doit = false;
					if ((event.stateMask & DWT.ALT) != 0) {
						boolean dropped = isDropped ();
						text.selectAll ();
						if (!dropped) setFocus ();
						dropDown (!dropped);
						break;
					}

					int oldIndex = getSelectionIndex ();
					if (event.keyCode == DWT.ARROW_UP) {
						select (Math.max (oldIndex - 1, 0));
					} else {
						select (Math.min (oldIndex + 1, getItemCount () - 1));
					}
					if (oldIndex != getSelectionIndex ()) {
						Event e = new Event();
						e.time = event.time;
						e.stateMask = event.stateMask;
						notifyListeners (DWT.Selection, e);
					}
					//At this point the widget may have been disposed.
					// If so, do not continue.
					if (isDisposed ()) break;
				}
				
				// Further work : Need to add support for incremental search in 
				// pop up list as characters typed in text widget
							
				Event e = new Event ();
				e.time = event.time;
				e.character = event.character;
				e.keyCode = event.keyCode;
				e.stateMask = event.stateMask;
				notifyListeners (DWT.KeyDown, e);
				break;
			}
			case DWT.KeyUp: {
				Event e = new Event ();
				e.time = event.time;
				e.character = event.character;
				e.keyCode = event.keyCode;
				e.stateMask = event.stateMask;
				notifyListeners (DWT.KeyUp, e);
				break;
			}
			case DWT.Modify: {
				table.deselectAll ();
				Event e = new Event ();
				e.time = event.time;
				notifyListeners (DWT.Modify, e);
				break;
			}
			case DWT.MouseDown: {
				if (event.button != 1) return;
				if (text.getEditable ()) return;
				boolean dropped = isDropped ();
				text.selectAll ();
				if (!dropped) setFocus ();
				dropDown (!dropped);
				break;
			}
			case DWT.MouseUp: {
				if (event.button != 1) return;
				if (text.getEditable ()) return;
				text.selectAll ();
				break;
			}
			case DWT.Traverse: {        
				switch (event.detail) {
					case DWT.TRAVERSE_RETURN:
					case DWT.TRAVERSE_ARROW_PREVIOUS:
					case DWT.TRAVERSE_ARROW_NEXT:
						// The enter causes default selection and
						// the arrow keys are used to manipulate the list contents so
						// do not use them for traversal.
						event.doit = false;
						break;
				}
				
				Event e = new Event ();
				e.time = event.time;
				e.detail = event.detail;
				e.doit = event.doit;
				e.character = event.character;
				e.keyCode = event.keyCode;
				notifyListeners (DWT.Traverse, e);
				event.doit = e.doit;
				event.detail = e.detail;
				break;
			}
		}
	}
}

