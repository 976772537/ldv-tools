package org.linuxtesting.ldv.envgen.group;

public class SimpleVar extends Var {
	private VarInfo info;

	public SimpleVar(VarInfo info) {
		super();
		this.info = info;
	}

	@Override
	public String getReplacementParam() {
		return info.replacementParam;
	}

	@Override
	public String getVarName() {
		if(info.isReturnVar()) {
			return getRetName();
		} else {
			return getVarName(info.index);
		}
	}

	private String getVarName(int paramCnt) {
		return "var_"+ info.token.getId() + "_p" + paramCnt;
	}

	private String getRetName() {
		return "res_" + info.token.getId();
	}
}
