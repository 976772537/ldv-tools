package com.iceberg.generators.fungen;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import com.iceberg.Logger;
import com.iceberg.cbase.tokens.TokenFunctionDecl;

public class FuncGeneratorStruct implements FuncGenerator {

	private TokenFunctionDecl token;
	
	@Override
	public List<String> generateVarInit() {
		List<String> replacementParams = token.getReplacementParams();
		int paramCnt = 0;
		List<String> initParamsList = new ArrayList<String>();
		Iterator<String> replacementParamsIterator =  replacementParams.iterator();
		while(replacementParamsIterator.hasNext()) {
			String replacementParam = replacementParamsIterator.next();
			String initializedParam = null;
			/* проверяем - может ли это быть указатель? */
			int indexOfPointer = replacementParam.indexOf('*');
			if(indexOfPointer!=-1) {
				int replaceIndex = replacementParam.indexOf("$var");
				assert replaceIndex!=-1;
				try {
					if((indexOfPointer+1)==replaceIndex || (indexOfPointer<replaceIndex &&
							replacementParam.substring(indexOfPointer+1, replaceIndex).trim().length()==0)) {
						if(replacementParam.charAt(indexOfPointer-1)!='(') {
							String pointerType = replacementParam.substring(0,indexOfPointer+1);
							initializedParam = getVarName(paramCnt) +" = ("+pointerType+")kmalloc(1,GFP_KERNEL);";
						}
					} //else
				} catch(Exception e) {
					Logger.debug("DEBUG ===============================================");
					Logger.debug("rparam :" + replacementParam);
				}
			}
			paramCnt++;
			if(initializedParam != null)
				initParamsList.add(initializedParam);
		}
		return initParamsList;
	}

	@Override
	public void set(TokenFunctionDecl token) {
		this.token = token;
	}

	@Override
	public List<String> generateVarDeclare() {
		List<String> replacementParams = token.getReplacementParams();
		int paramCnt = 0;
		List<String> paramsList = new ArrayList<String>();
		Iterator<String> replacementParamsIterator =  replacementParams.iterator();
		while(replacementParamsIterator.hasNext()) {
			String replacementParam = replacementParamsIterator.next().trim();
			if(!replacementParam.equals("...")) {
				if(!replacementParam.equals("void")) {
					if(replacementParam.contains("const"))
						paramsList.add(replacementParam.replaceAll("\\$var", getVarName(paramCnt))+"=0;");
					else
						paramsList.add(replacementParam.replaceAll("\\$var", getVarName(paramCnt))+";");
				}
			}
			paramCnt++;
		}
		return paramsList;
	}

	@Override
	public String generateFunctionCall() {
		return genFuncCallExpr() + ";";
	}

	@Override
	public String generateCheckedFunctionCall(String check_label) {
		assert token.getTestString()!=null && !token.getRetType().contains("void");
		String funcCallStr = genFuncCallExpr();
		funcCallStr = token.getTestString().
				replaceAll("\\$retvar", getRetName()).
				replaceAll("\\$fcall", funcCallStr).
				replaceAll("\\$check_label", check_label);
		return funcCallStr;
	}

	@Override
	public String generateRetDecl() {
		assert token.getTestString()!=null && !token.getRetType().contains("void");
		return token.getRetType() + " " + getRetName() + ";";
	}
	
	private String genFuncCallExpr() {
		List<String> replacementParams = token.getReplacementParams();
		int paramCnt = 0;
		Iterator<String> replacementParamsIterator =  replacementParams.iterator();
		StringBuffer ifunCall = new StringBuffer(token.getName()+'(');
		while(replacementParamsIterator.hasNext()) {
			String replacementParam = replacementParamsIterator.next().trim();
			if(!replacementParam.equals("...")) {
				if(!replacementParam.equals("void")) {
					ifunCall.append(" " + getVarName(paramCnt));
					if(replacementParamsIterator.hasNext())
						ifunCall.append(',');
				}
			}
			paramCnt++;
		}
		ifunCall.append(")");
		return ifunCall.toString();
	}

	private String getVarName(int paramCnt) {
		return "var_"+ token.getId() + "_p" + paramCnt;
	}

	private String getRetName() {
		return "res_" + token.getId();
	}
}
