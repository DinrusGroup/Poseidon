module poseidon.i18n.i18nshop;


private import dwt.all;
private import poseidon.globals;
private import poseidon.i18n.itranslatable;


class I18NShop
{
	public static void setWidgetText(Widget widget, char[] text)
	{
		if(widget is null || widget.isDisposed())
			return;
			
		if(cast(Button)widget)
			(cast(Button)widget).setText(text);
		else if(cast(Label)widget)
			(cast(Label)widget).setText(text);
		else if(cast(CLabel)widget)
			(cast(CLabel)widget).setText(text);
		else if(cast(Combo)widget)
			(cast(Combo)widget).setText(text);
		else if(cast(CCombo)widget)
			(cast(CCombo)widget).setText(text);
		else if(cast(Group)widget)
			(cast(Group)widget).setText(text);
		else if(cast(Text)widget)
			(cast(Text)widget).setText(text);
		else if(cast(MenuItem)widget)
			(cast(MenuItem)widget).setText(text);
		else if(cast(ToolItem)widget)
			(cast(ToolItem)widget).setText(text);
		else if(cast(Decorations)widget)
			(cast(Decorations)widget).setText(text);
	}

	public static void updateMenuI18N(Menu menu)
	{
		if(menu && !menu.isDisposed()) 
		{
			MenuItem[] items = menu.getItems();
			foreach(MenuItem item; items) {
				updateWidgetI18N(item);
				I18NShop.updateMenuI18N(item.getMenu());
			}
		}
	}

	public static void updateToolBarI18N(ToolBar bar)
	{
		if(bar && !bar.isDisposed()) 
		{
			ToolItem[] items = bar.getItems();
			foreach(ToolItem item; items) {
				updateWidgetI18N(item);
			}
		}
	}

	// update the single widget 's text
	public static void updateWidgetI18N(Widget widget)
	{
		if(widget is null || widget.isDisposed())
			return;

		char[] id = getLangId(widget);
		if(id) 
		{
			char[] text = Globals.getTranslation(id);
			I18NShop.setWidgetText(widget, text);
		}
	}

	// enum the Composite' children to update all text to corresponding translation
	public static void updateCompositeI18N(Composite parent)
	{
		if(parent is null || parent.isDisposed())
			return;
		
		updateWidgetI18N(parent);
		
		// Decorations may has menubar
		if(cast(Decorations)parent) 
		{
			updateMenuI18N((cast(Decorations)parent).getMenuBar());
		}

		// toolbar may has ToolItem
		if(cast(ToolBar)parent) {
			updateToolBarI18N((cast(ToolBar)parent));
		}
			
		Control[] children = parent.getChildren();
		foreach(Control control; children)
		{
			updateWidgetI18N(control);

			// the control may has a menu
			if(control.getMenu())
				updateMenuI18N(control.getMenu());
				
			// the control may has children
			if(cast(Composite)control)
				updateCompositeI18N(cast(Composite)control);
		}
	}

	static char[] getLangId(Widget widget) {
		if(widget)
		{
			StringObj str = cast(StringObj)widget.getData(LANG_ID);
			if(str && str.data)
				return str.data;
		}
		return null;
	}

	static char[] getLangData(Widget widget)
	{
		char[] id = getLangId(widget);
		if(id)
			return Globals.getTranslation(id);
		return null;
	}
}