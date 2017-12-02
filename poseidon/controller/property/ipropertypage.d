module poseidon.controller.property.ipropertypage;

public import dwt.all;


interface IPropertyPage
{
	char[] getTitle();

	// whether the Page content changed, save the change if required
	bool getDirty();

	// when change is made, call this routine to set the dirty flag
	void setDirty(bool dirty);

	void applyChanges();

	IPropertyPage getParentPage();

	void setTreeItem(TreeItem item);

	TreeItem getTreeItem();

	void restoreDefaults();
}

abstract class AbstractPage : Composite, IPropertyPage
{
	bool dirty = false;

	IPropertyPage parentPage;

	TreeItem treeItem;

	void delegate(bool) dirtyListener;

	bool getDirty() { return dirty; }

	void setDirty(bool dirty) 
	{ 
		if(this.dirty != dirty) {
			this.dirty = dirty;
			if(dirtyListener)
				dirtyListener(dirty);
		}
	}


	this(Composite parent, IPropertyPage parentPage, void delegate(bool) dirtyListener) {
		super(parent, DWT.NONE);
		this.parentPage = parentPage;
		this.dirtyListener = dirtyListener;
	}

	IPropertyPage getParentPage()
	{
		return parentPage;
	}

	void setTreeItem(TreeItem item)
	{
		treeItem = item;
	}

	TreeItem getTreeItem() 
	{
		return treeItem;
	}
}