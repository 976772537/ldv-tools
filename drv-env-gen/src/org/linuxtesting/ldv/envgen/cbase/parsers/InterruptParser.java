package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.tokens.CallbackCollectionToken;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenBodyElement;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFuncCollection;
//import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionCall;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;

public class InterruptParser implements FunctionBodyParser {
	
	public static TokenFuncCollection createInterrupts(
			Map<String, TokenFunctionDecl> parsedFunctions) {
		String targetFunction = "request_irq";
		//int callbackParamInd = 1;
		Logger.debug("Create callbacks for " + targetFunction);
		List<TokenFunctionDecl> tokens = new LinkedList<TokenFunctionDecl>();
		Set<String> set = new HashSet<String>();
		//get second parameter
		for(Map.Entry<String, TokenFunctionDecl> e : parsedFunctions.entrySet()) {
			TokenFunctionDecl tfd = e.getValue();
			//find by interrupt handler function type
			//static irqreturn_t f(int irq, void *data)
			if(tfd.getRetType()!=null && tfd.getRetType().contains("irqreturn_t")) {
				Logger.debug("return type matched");
				List<String> pr = tfd.getReplacementParams();
				if(pr.size()==2) {
					String first = pr.get(0);
					String second = pr.get(1);
					Logger.debug("params size matched first=" + first + ", second=" + second);
					if(Pattern.matches("\\s*" + "int"
							+ "\\s*" + "\\$\\w*" + "\\s*", first) 
							&& Pattern.matches("\\s*" + "void" 
									+ "\\s*" + "\\*"
									+ "\\s*" + "\\$\\w*" + "\\s*", second)) {
						Logger.debug("types matched");
						if(set.contains(tfd.getName())) {
							Logger.debug("Duplicate callback=" + tfd.getName());
						} else {
							Logger.debug("callback found " + tfd.getName());
							tokens.add(tfd);
							set.add(tfd.getName());
						}
					}
				}
			}
			
			//find by function calls
			//deprecated
//			assert tfd.getTokens()!=null;
//			for(TokenFunctionCall tcall : FunctionCallParser.getFunctionCalls(tfd)) {
//				Logger.debug("Process call=" + tcall);
//				if(targetFunction.equals(tcall.getName())) {
//					Logger.debug("Found " + targetFunction + " call=" + tcall);
//					String callbackParam = tcall.getParams().get(callbackParamInd);
//					Logger.debug("Get parameter " + callbackParamInd + "=" + callbackParam);
//					TokenFunctionDecl callback = parsedFunctions.get(callbackParam);
//					if(callback!=null) {
//						if(set.contains(callback.getName())) {
//							Logger.debug("Duplicate callback=" + callbackParam);
//						} else {
//							Logger.debug("callback found " + callback.getName());
//							tokens.add(callback);
//							set.add(callback.getName());
//						}
//					} else {
//						Logger.debug("callback not found " + callbackParam);
//					}
//				}
//			}
		}
		return new CallbackCollectionToken(targetFunction, 
				"interrupt handler calls", tokens);
	}

	@Override
	public List<TokenBodyElement> parse(String buffer) {
		//return empty list
		return new LinkedList<TokenBodyElement>();
	}


}
