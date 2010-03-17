package com.iceberg.generators.fungen;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import com.iceberg.cbase.tokens.TokenFunctionDecl;

public class FuncGeneratorStruct implements FuncGenerator {

	private TokenFunctionDecl token;
	private int startFVar;

	@Override
	public List<String> generateVarInit() {
		List<String> replacementParams = token.getReplacementParams();
		int startVar = this.startFVar;
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
							initializedParam ="var"+startVar+" = ("+pointerType+")kmalloc(1,GFP_KERNEL);";
						}
					} //else
				} catch(Exception e) {
					System.out.println("DEBUG ===============================================");
					System.out.println("ppp :" + replacementParam);
				}
			}
			startVar++;
			if(initializedParam != null)
				initParamsList.add(initializedParam);
		}
		return initParamsList;
	}

	@Override
	public void set(TokenFunctionDecl token, int startVar) {
		this.startFVar = startVar;
		this.token = token;
	}

	@Override
	public List<String> generateVarDeclare() {
		List<String> replacementParams = token.getReplacementParams();
		int startVar = this.startFVar;
		List<String> paramsList = new ArrayList<String>();
		Iterator<String> replacementParamsIterator =  replacementParams.iterator();
		while(replacementParamsIterator.hasNext()) {
			String replacementParam = replacementParamsIterator.next().trim();
			if(!replacementParam.equals("...")) {
				if(!replacementParam.equals("void")) {
					if(replacementParam.contains("const"))
						paramsList.add(replacementParam.replaceAll("\\$var", "var"+startVar)+"=0;");
					else
						paramsList.add(replacementParam.replaceAll("\\$var", "var"+startVar)+";");
				}
			}
			startVar++;
		}
		return paramsList;
	}

	@Override
	public String generateFunctionCall() {
		List<String> replacementParams = token.getReplacementParams();
		int startVar = this.startFVar;
		Iterator<String> replacementParamsIterator =  replacementParams.iterator();
		StringBuffer ifunCall = new StringBuffer(token.getName()+'(');
		while(replacementParamsIterator.hasNext()) {
			String replacementParam = replacementParamsIterator.next().trim();
			if(!replacementParam.equals("...")) {
				if(!replacementParam.equals("void")) {
					ifunCall.append(" var"+startVar);
					if(replacementParamsIterator.hasNext())
						ifunCall.append(',');
				}
			}
			startVar++;
		}
		ifunCall.append(");");
		return ifunCall.toString();
	}

}
