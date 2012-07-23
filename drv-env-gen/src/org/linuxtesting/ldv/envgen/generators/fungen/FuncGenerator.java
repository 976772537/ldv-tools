/*
 * Copyright (C) 2010-2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.linuxtesting.ldv.envgen.generators.fungen;

import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;
import org.linuxtesting.ldv.envgen.generators.EnvParams;


public interface FuncGenerator {
	public void set(TokenFunctionDecl token);
	public List<String> generateVarDeclare(boolean init);
	public List<String> generateVarInit();
	public String generateRetDecl();

	public final String SIMPLE_CALL = "\n$indentldv_handler_precall();"
						+ "\n$indent$fcall;";

	public final String CHECK_INIT_MODULE =
		"\n$indentldv_handler_precall();"
			+ "\n$indent if($fcall) "
			+ "\n$indent\tgoto $check_label;";

	public final String CHECK_NONZERO =
		"\n$indentldv_handler_precall();"
		+ "\n$indent$retvar = $fcall;"
		+ "\n$indent ldv_check_return_value($retvar);"
		+ "\n$indent if($retvar) "
			+ "\n$indent\tgoto $check_label;";
	public final String CHECK_PROBE = 
		"\n$indent$retvar = $fcall;"
		+ "\n$indent ldv_check_return_value($retvar);"
		+ "\n$indent ldv_check_return_value_probe($retvar);"
		+ "\n$indent if($retvar) " 
			+ "\n$indent\tgoto $check_label;";
	public final String CHECK_LESSTHANZERO =
		"\n$indentldv_handler_precall();"
		+ "\n$indent$retvar = $fcall;"
		+ "\n$indent ldv_check_return_value($retvar);"
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
	public String generateCheckedFunctionCall(String checkExpr, String checkLabel, String indent);
	/**
	 * gets checkExpr from the token
	 */
	public String generateCheckedFunctionCall(String checkLabel, String indent);
	/**
	 * generates SIMPLE_CALL
	 */
	public String generateSimpleFunctionCall(String indent);

	public void setParams(EnvParams p);
}
