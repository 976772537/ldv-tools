package org.linuxtesting.ldv.envgen.generators.fungen;

import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;


public interface FuncGenerator {
	public void set(TokenFunctionDecl token);
	public List<String> generateVarDeclare();
	public List<String> generateVarInit();
	public String generateFunctionCall();
	public String generateRetDecl();
	public String generateCheckedFunctionCall(String checkLabel, String indent);
}
