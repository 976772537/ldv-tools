package org.linuxtesting.ldv.envgen.generators.fungen;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Matcher;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;
import org.linuxtesting.ldv.envgen.generators.EnvParams;
import org.linuxtesting.ldv.envgen.group.Groups;
import org.linuxtesting.ldv.envgen.group.Var;


public class FuncGeneratorStruct implements FuncGenerator {

	private TokenFunctionDecl token;
	private Groups theGroups = new Groups();
	@Override
	public List<String> generateVarInit() {
		List<String> replacementParams = token.getReplacementParams();
		int paramCnt = 0;
		List<String> initParamsList = new ArrayList<String>();
		Iterator<String> replacementParamsIterator =  replacementParams.iterator();
		while(replacementParamsIterator.hasNext()) {
			String replacementParam = replacementParamsIterator.next();
			Var v = theGroups.getVar(replacementParam, paramCnt, token);
			String initializedParam = v.getVarInit();
			paramCnt++;
			if(initializedParam != null) {
				if(!theGroups.isInitialized(v)) {
					initParamsList.add(initializedParam);
					theGroups.addInitialized(v);
				} else {
					Logger.debug("variable is already declared v=" +v);
				}
			}
		}
		return initParamsList;
	}

	@Override
	public void set(TokenFunctionDecl token) {
		this.token = token;
	}

	@Override
	public List<String> generateVarDeclare(boolean init) {
		List<String> replacementParams = token.getReplacementParams();
		int paramCnt = 0;
		List<String> paramsList = new ArrayList<String>();
		Iterator<String> replacementParamsIterator =  replacementParams.iterator();
		while(replacementParamsIterator.hasNext()) {
			String replacementParam = replacementParamsIterator.next().trim();
			if(!replacementParam.equals("...")) {
				if(!replacementParam.equals("void")) {
					Var v = theGroups.getVar(replacementParam, paramCnt, token);
					if(!theGroups.isDeclared(v)) {
						paramsList.add(v.getVarDeclare(init));
						theGroups.addDeclared(v);
					} else {
						Logger.debug("variable is already declared v=" +v);
					}
				}
			}
			paramCnt++;
		}
		return paramsList;
	}

	@Override
	public String generateSimpleFunctionCall(String indent) {
		String checkString = FuncGenerator.SIMPLE_CALL;
		return replaceVariables(null, indent, checkString);
	}

	@Override
	public String generateCheckedFunctionCall(String checkString, String check_label, String indent) {
		//Replace predefined patterns
		checkString = checkString.replaceAll(
				"\\$CHECK_NONZERO", 
				Matcher.quoteReplacement(FuncGenerator.CHECK_NONZERO));
		checkString = checkString.replaceAll(
				"\\$CHECK_LESSTHANZERO", 
				Matcher.quoteReplacement(FuncGenerator.CHECK_LESSTHANZERO));
		//Replace variables
		return replaceVariables(check_label, indent, checkString);		
	}
	
	@Override
	public String generateCheckedFunctionCall(String check_label, String indent) {
		assert token.getTestString()!=null;
		String checkString = token.getTestString();
		return generateCheckedFunctionCall(checkString, check_label, indent);
	}

	private String replaceVariables(String check_label, String indent, String checkString) {
		assert checkString!=null;
		
		String funcCallStr = genFuncCallExpr();		
		
		if(checkString.contains("$retvar")) {
			if(token.getRetType().contains("void")) {
				Logger.err("Check string is not applicable for void function");
				Logger.err("checkString=" + checkString);
				Logger.err("retType=" + token.getRetType());
				Logger.err("funcCallStr=" + funcCallStr);
				Logger.err("Using default template");
				checkString = FuncGenerator.SIMPLE_CALL;
			}
			Var v = theGroups.getVar(token.getRetType(), token);
			checkString = checkString.replaceAll("\\$retvar", 
					Matcher.quoteReplacement(v.getVarName()));
		}

		if(check_label!=null) {
			checkString = checkString.replaceAll("\\$check_label", 
					Matcher.quoteReplacement(check_label));
		} else {
			assert !checkString.contains("$check_label");			
		}
		
		checkString = checkString.replaceAll("\\$fcall", 
				Matcher.quoteReplacement(funcCallStr));
		
		assert indent!=null;
		checkString = checkString.replaceAll("\\$indent", 
				Matcher.quoteReplacement(indent));
		
		for(int i=0; i<token.getReplacementParams().size(); i++) {
			Var v = theGroups.getVar(token.getReplacementParams().get(i), i, token);
			checkString = checkString.replaceAll("\\$p" + i, 
					Matcher.quoteReplacement(v.getVarName()));
		}
		return checkString;
	}

	@Override
	public String generateRetDecl() {
		assert token.getTestString()!=null && !token.getRetType().contains("void");
		String res;
		Var var = theGroups.getVar(token.getRetType(), token);
		if(!theGroups.isDeclared(var)) {
			res = var.getVarDeclare(false);
			theGroups.addDeclared(var);
		} else {
			Logger.debug("variable is already declared v=" + var);
			res = "";
		}
		return res; 
		//return token.getRetType() + " " + getRetName() + ";";
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
					Var v = theGroups.getVar(replacementParam, paramCnt, token);
					ifunCall.append(" " + v.getVarName());
					if(replacementParamsIterator.hasNext())
						ifunCall.append(',');
				}
			}
			paramCnt++;
		}
		ifunCall.append(")");
		return ifunCall.toString();
	}

	@Override
	public void setParams(EnvParams p) {
		theGroups.setEnabled(p.isGrouped());
	}
}
