package com.iceberg.reportbuilder.brnodes;

import java.util.List;

public interface BRNodeInterface {
	public abstract List<BRNodeInterface> getBRNodes();
	public BRNodeType getType();
	public String getSource();
	public int getLine();
	public String getContent();
	public abstract boolean printRecursive(int i, boolean returnIsPrint);
}
