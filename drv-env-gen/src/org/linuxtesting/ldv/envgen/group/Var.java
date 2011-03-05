package org.linuxtesting.ldv.envgen.group;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.generators.MainGenerator;

public abstract class Var {
	
	public abstract String getVarName();
	public abstract String getReplacementParam();

	public abstract int hashCode();
	public abstract boolean equals(Object obj);
	
	public String getVarDeclare(boolean init) {
		String replacementParam = getReplacementParam();
		String res;
		if(replacementParam.contains("const") && init) {
			res = replacementParam.replaceAll("\\$var", getVarName())
					+"= " + MainGenerator.NONDET_INT + "();";
		} else {
			res = replacementParam.replaceAll("\\$var", getVarName())+";";
		}
		Logger.trace("generated declare=" + res);
		
		return res;
	}
	
	public String getVarInit() {
		String initializedParam = null;
		String replacementParam = getReplacementParam();
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
						initializedParam = getVarName() +" = ("+pointerType+")kmalloc(1,GFP_KERNEL);";
					}
				} //else
			} catch(Exception e) {
				Logger.debug("DEBUG ===============================================");
				Logger.debug("rparam :" + replacementParam);
			}
		}
		Logger.trace("generated init=" + initializedParam);
		return initializedParam;
	}
}
