package com.iceberg.generators.fungen;

import java.util.List;

import com.iceberg.cbase.tokens.TokenFunctionDecl;

public interface FuncGenerator {
	public void set(TokenFunctionDecl token);
	public List<String> generateVarDeclare();
	public List<String> generateVarInit();
	public String generateFunctionCall();
	public String generateRetDecl();
	public String generateCheckedFunctionCall(String checkLabel);
}
