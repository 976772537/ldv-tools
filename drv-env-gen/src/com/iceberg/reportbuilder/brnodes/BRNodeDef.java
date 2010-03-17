package com.iceberg.reportbuilder.brnodes;

import java.util.List;

public class BRNodeDef extends BRNode implements BRNodeInterface {

	public BRNodeDef(BRNodeType type, String source, int line, String content) {
		super(type, source, line, content);
	}

	@Override
	public List<BRNodeInterface> getBRNodes() {
		return null;
	}

	@Override
	public boolean printRecursive(int i, boolean returnIsPrint) {
		String beginType="";
		String endType="";
		String content="";
		if(this.getType() == BRNodeType.BRTYPE_Block) {
			beginType = this.getContent();
		}
		else if(this.getType() == BRNodeType.BRTYPE_Block_BRNODERETURN) {
			beginType = this.getContent().replaceAll("\\s", "").trim();
		}
		else if(this.getType() == BRNodeType.BRTYPE_BRNODE) {
			beginType = "<Blast_Report_Block>";
			content = this.getContent();
			endType = "</Blast_Report_Block>";
		}
		else if(this.getType() == BRNodeType.BRTYPE_FunctionCallWithoutBody) {
			beginType = "FunctionCall("+this.getContent()+")";
		}
		else if(this.getType() == BRNodeType.BRTYPE_Pred) {
			if(!this.getContent().equals("0  ==  0"))
				beginType = "True condition ("+ this.getContent() +")";
		}
		printLine(i, beginType);
		printFreeLine(i, content);
		printFreeLine(i, endType);
		if(this.getType() == BRNodeType.BRTYPE_Block_BRNODERETURN)
			return true;
		return false;
	}

}
