package com.iceberg.reportbuilder.brnodes;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.iceberg.FSOperationsBase;

public class BlastTraceParser {

	private static final String ERROR_TRACE_BEGIN_TAG="Error found! The system is unsafe :-(\n\n Error trace:";
	private static final String ERROR_TRACE_END_TAG="vardec";

	public static final String BLAST_LABEL_FUCNTION = "__BLAST_initialize_";

	private String blastReportFile;
	private boolean traceContainsError = false;

	public BlastTraceParser(String blastReportFile) {
		this.blastReportFile = blastReportFile;
	}

	public BRNodeInterface parse() {
		String buffer = FSOperationsBase.readFileCRLF(blastReportFile);
		int indexOfBeginErrorTrace = buffer.indexOf(ERROR_TRACE_BEGIN_TAG);
		if (indexOfBeginErrorTrace != -1) {
			indexOfBeginErrorTrace += ERROR_TRACE_BEGIN_TAG.length();
			this.traceContainsError = true;
			int indexOfEndErrorTrace = buffer.indexOf(ERROR_TRACE_END_TAG, indexOfBeginErrorTrace);
			/* если всетаки не нашли,то читаем до конца */
			if (indexOfEndErrorTrace == -1)
				indexOfEndErrorTrace = buffer.length();
			buffer = buffer.substring(indexOfBeginErrorTrace, indexOfEndErrorTrace);
			BRNodeInterface bntree = parseErrorTrace(buffer);
			return bntree;
		}
		System.out.println("System is safe.");
		return null;
	}

	public static final String stringPattern = "(Block|FunctionCall|Pred)\\(|src=\"|line=";
	public static final String stringPatternSecond = "(Block|FunctionCall|Pred)\\(|src=\"|line=|(LDV: undefined function called:)";
	public static Pattern brPattern = Pattern.compile(stringPattern);
	public static Pattern brPatternSecond = Pattern.compile(stringPatternSecond);

	//private static final String filter_blast_mycor_pattern = "blast_must_tmp__\\s*\\d*\\s*@ldv_main\\d*\\s*=\\s*__kmalloc\\s*\\([\\d\\D\\w\\W]*";

	private static List<BRNodeInterface> recursiveParse(Matcher brm, String buffer, String src, int line) {
		if (brm != null) {
			List<BRNodeInterface> brnlist = new ArrayList<BRNodeInterface>();
			while (brm.find()) {
				String matchedString = brm.group();
				int position = brm.end();
				if(matchedString == null || matchedString.length() == 0) {
					System.out.println("ERROR: Empty matched string.");
					return brnlist;
				}
				if(matchedString.indexOf("FunctionCall(") == 0) {
					int endPosition = findEndOfPattern(buffer, '(', ')', position);
					String content = buffer.substring(position,endPosition);
					BRNodeInterface brnlocal = null;
					Matcher lm = brPatternSecond.matcher(buffer.substring(endPosition));
					if(lm.find() && lm.group().equals("LDV: undefined function called:")) {
						brnlocal = new BRNodeDef(BRNodeType.BRTYPE_FunctionCallWithoutBody
								, src, line, content);
					} else {
						List<BRNodeInterface> inBrnList = recursiveParse(brm, buffer, src, -1);
						if(content.contains(BLAST_LABEL_FUCNTION)) {
							brnlocal = new BRNodeIncluded(BRNodeType.BRTYPE_FunctionCall_BLAST_initialize
									, src, line, content,inBrnList);
						} else {
							brnlocal = new BRNodeIncluded(BRNodeType.BRTYPE_FunctionCall
									, src, line, content,inBrnList);
						}
					}
					line = -1;
					brnlist.add(brnlocal);
				} else
				if(matchedString.indexOf("Pred(") == 0) {
					int endPosition = findEndOfPattern(buffer, '(', ')', position);
					String content = buffer.substring(position,endPosition);
					BRNodeInterface brnlocal = new BRNodeDef(BRNodeType.BRTYPE_Pred
							, src, line, content);
					line = -1;
					brnlist.add(brnlocal);
				} else
				if(matchedString.indexOf("Block(") == 0) {
					int endPosition = findEndOfPattern(buffer, '(', ')', position);
					String content = buffer.substring(position,endPosition);
					BRNodeInterface brnlocal = new BRNodeDef(
							(content.contains("Return") || content.contains("return") ) ? BRNodeType.BRTYPE_Block_BRNODERETURN :
								BRNodeType.BRTYPE_Block, src, line, content);
					brnlist.add(brnlocal);
					line = -1;
					if(brnlocal.getType() == BRNodeType.BRTYPE_Block_BRNODERETURN)
						return brnlist;
				}
				if(matchedString.indexOf("line=") == 0) {
					int endPosition = position;
					char c = buffer.charAt(endPosition);
					boolean negative = false;
					if (c == '-') {
						negative = true;
						endPosition++;
						c = buffer.charAt(endPosition);
					}
					while(  c == '0' || c == '1' || c == '2' || c == '3' ||
							c == '4' || c == '5' || c == '6' || c == '7' || c == '8' ||
							c == '9' ) {
						endPosition++;
						c = buffer.charAt(endPosition);
					}
					if(negative == true)
						line = -Integer.valueOf(buffer.substring(position+1,endPosition));
					else
						line =  Integer.valueOf(buffer.substring(position,endPosition));
				} else
				if(matchedString.indexOf("src=\"") == 0) {
					int endPosition = findEndOfPatternNotRec(buffer, '"', position);
					src = buffer.substring(position,endPosition);
					line = -1;
				}
			}
			return brnlist;
		} else
			return null;
	}


	public static int findEndOfPattern(String buffer, char openSymbol, char closeSymbol,int position) {
		int level = 1;
		while (level != 0) {
			if(buffer.charAt(position)== openSymbol)
				level++;
			else if(buffer.charAt(position)== closeSymbol)
				level--;
			position++;
		}
		return --position;
	}

	public static int findEndOfPatternNotRec(String buffer, char symbol, int position) {
		while (buffer.charAt(position) != symbol) {
			position++;
		}
		return position;
	}


	private static BRNodeInterface parseErrorTrace(String buffer) {
		if (buffer == null || buffer.length() == 0) {
			System.out.println("ERROR: Empty error trace part in buffer.\n");
			return null;
		}
		/* матчим */
		Matcher brm = brPattern.matcher(buffer);
		List<BRNodeInterface> bnrlist = recursiveParse(brm, buffer, "ERROR_TRACE", -1);
		return new BRNodeIncluded(BRNodeType.BRTYPE_BRNODE, "ERROR_TRACE", 0, "UNDEF", bnrlist);
	}

	public String getBlastReportFile() {
		return blastReportFile;
	}

	public boolean isTraceContainsError() {
		return traceContainsError;
	}

}
