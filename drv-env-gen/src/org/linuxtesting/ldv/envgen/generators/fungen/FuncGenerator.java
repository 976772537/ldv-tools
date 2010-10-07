package org.linuxtesting.ldv.envgen.generators.fungen;

import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;


public interface FuncGenerator {
	public void set(TokenFunctionDecl token);
	public List<String> generateVarDeclare();
	public List<String> generateVarInit();
	public String generateFunctionCall();
	public String generateRetDecl();

	public final String CHECK_NONZERO = 
		"\n$indent$retvar = $fcall;"
		+ "\n$indent check_return_value($retvar);"
		+ "\n$indent if($retvar) " 
			+ "\n$indent\tgoto $check_label;";
	public final String CHECK_LESSTHANZERO = 
		"\n$indent$retvar = $fcall;"
		+ "\n$indent check_return_value($retvar);" 
		+ "\n$indent if($retvar < 0) " 
			+ "\n$indent\tgoto $check_label;";

	/**
	 * Variables to be replaced in the patterns:
	 * $retvar
	 * $fcall
	 * $p0,..,$pn
	 * $check_label
	 * $indent
	 * 
	 * Predefined expressions: 
	 * $CHECK_NONZERO
	 * $CHECK_LESSTHANZERO
	 */
	public String generateCheckedFunctionCall(String checkLabel, String indent);
}
