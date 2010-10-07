package org.linuxtesting.ldv.envgen.generators.fungen;

import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;


public interface FuncGenerator {
	public void set(TokenFunctionDecl token);
	public List<String> generateVarDeclare();
	public List<String> generateVarInit();
	public String generateFunctionCall();
	public String generateRetDecl();
	
	/**
	 * variables to be replaced in the patterns
	 * $retvar
	 * $fcall
	 * $p0,..,$pn
	 * $check_label
	 * $indent
	 */
	public String generateCheckedFunctionCall(String checkLabel, String indent);
}