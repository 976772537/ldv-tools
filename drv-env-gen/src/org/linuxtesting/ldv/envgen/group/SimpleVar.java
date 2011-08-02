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

	@Override
	public String toString() {
		return "SimpleVar [info=" + info + "]";
	}

	@Override
	public int hashCode() {
		String name = getVarName();
		if(name!=null) {
			return name.hashCode();
		} else {
			return 0;
		}
	}

	@Override
	public boolean equals(Object obj) {
		String name = getVarName();
		if(! (obj instanceof SimpleVar)) {
			return false;
		}
		SimpleVar other = (SimpleVar)obj;
		String name2 = other.getVarName();
		return name==name2 || name!=null && name.equals(name2);
	}
	
}
