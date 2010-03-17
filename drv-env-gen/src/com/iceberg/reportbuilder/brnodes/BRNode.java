package com.iceberg.reportbuilder.brnodes;

public abstract class BRNode {

	private BRNodeType type;
	private String source;
	private int line;
	private String content;

	public BRNode(BRNodeType type, String source, int line, String content) {
		this.type = type;
		this.source = source;
		this.line = line;
		this.content = content;
	}

	public BRNodeType getType() {
		return type;
	}

	private static int fullshift = 45;
	private static String fullshiftString = "                                             ";
	private static int lshift = 35;
	private static int nshift = 6;

	protected void printLine(int space, String line) {
		String webline = "\n\t<tr>\n\t\t";
		webline += "<td>"+this.getSource()+"</td>\n\t\t";
		webline += "<td>"+this.getLine()+"</td>\n\t\t";
		webline += "<td>"+line+"</td>";
		webline += "\n\t</tr>";
		printOnlySelected(webline);
	}


	protected void __printLine(int space, String line) {
		if (line == null || line.length()==0)
			return;
		space += fullshift;
		String sline = this.getSource();
		/* добиваем пробелами до lshift */
		for(int j=0; j<(lshift-this.getSource().length()); j++)
			sline += " ";
		/* добавляем номер строки */
		String snumber="-1";
		if (this.getLine() != -1)
			snumber = String.valueOf(this.getLine());
		String presnumber = "";
		for(int j=0; j<(nshift-snumber.length()); j++)
			presnumber+=" ";
		/* добиваем ее пробелами */
		for(int j=0; j<(space-nshift-lshift); j++)
			snumber += " ";
		/* печататем */
		printOnlySelected(sline+presnumber+snumber+line);
	}

	private void printOnlySelected(String line) {
		/*if(this.getType() != BRNodeType.BRTYPE_Block &&
				this.getType() != BRNodeType.BRTYPE_Pred)*/
		System.out.print(line);
	}

	//private void __printOnlySelected(String line) {
		/*if(this.getType() != BRNodeType.BRTYPE_Block &&
				this.getType() != BRNodeType.BRTYPE_Pred)*/
		//System.out.println(line);
	//}


	protected void __printFreeLine(int space, String line) {
		if (line == null || line.length()==0)
			return;
		String sline = fullshiftString;
		/* добиваем пробелами до space */
		for(int j=0; j<space; j++)
			sline += " ";
		/* печататем */
		printOnlySelected(sline+line);
	}

	protected void printFreeLine(int space, String line) {
		if (line.trim()=="") return;
		String webline = "\n\t<tr>\n\t\t";
		webline += "<td></td>\n\t\t";
		webline += "<td></td>\n\t\t";
		webline += "<td>"+line+"</td>";
		webline += "\n\t</tr>";
		printOnlySelected(webline);
	}


	public String getSource() {
		int i;
		for(i=source.length()-1; i>=0; i--)
			if(source.charAt(i) == '/')
				break;
		return source.substring(i+1);
	}

	public String getFullSource() {
		return source;
	}

	public int getLine() {
		return line;
	}

	public String getContent() {
		return content;
	}
}
