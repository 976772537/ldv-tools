package com.iceberg.reportbuilder.brnodes;

import java.util.Iterator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class BRNodeIncluded extends BRNode implements BRNodeInterface {

	private List<BRNodeInterface> brnodes;

	public BRNodeIncluded(BRNodeType type, String source, int line,
			String content, List<BRNodeInterface> brnodes) {
		super(type, source, line, content);
		this.brnodes = brnodes;
	}

	@Override
	public List<BRNodeInterface> getBRNodes() {
		return brnodes;
	}


	@Override
	public boolean printRecursive(int i, boolean returnIsPrint) {
		String beginType="";
		String endType="";

		if(this.getType() == BRNodeType.BRTYPE_BRNODE) {
			beginType = "<Blast_Report_Block>";
			endType = "</Blast_Report_Block>";
		}
		else if(this.getType() == BRNodeType.BRTYPE_FunctionCall) {
			//String content = this.getContent().replaceAll("\\s", "").trim().replaceAll("tmp_*\\d*\\@", "");
			String content = this.getContent().replaceAll("\\s", "").trim();
			/*beginType = content+ " {";
			endType = "}";*/
			beginType = "FunctionCall("+ content +") {";
			endType = "}";
		}

		/* печать открывающего тэга */
		if(this.getType() != BRNodeType.BRTYPE_BRNODE &&
				this.getType() != BRNodeType.BRTYPE_FunctionCall_BLAST_initialize &&
				this.getType() != BRNodeType.BRTYPE_FunctionCall_BLAST_mycor) {
			printLine(i, beginType);
		}
		/* вызов распечатки вложенных нодов */
		boolean lastIsReturnCorrect = false;
		if((this.getType() == BRNodeType.BRTYPE_FunctionCall)||
				this.getType() == BRNodeType.BRTYPE_BRNODE) {
			// если это вызов функции, то идем далее по всему списку
			if(this.getBRNodes()!=null) {
				Iterator<BRNodeInterface> nodeIterator = this.getBRNodes().iterator();
				while(nodeIterator.hasNext())
					lastIsReturnCorrect = nodeIterator.next().printRecursive(i+5, false);
			}
		}
		/* печать закрывающего тэга */
		if(this.getType() != BRNodeType.BRTYPE_BRNODE &&
				this.getType() != BRNodeType.BRTYPE_FunctionCall_BLAST_initialize &&
				this.getType() != BRNodeType.BRTYPE_FunctionCall_BLAST_mycor) {
			if(endType.length()!=0 && lastIsReturnCorrect) {
				printFreeLine(i, endType);
			}
		}
		return false;
	}
}
