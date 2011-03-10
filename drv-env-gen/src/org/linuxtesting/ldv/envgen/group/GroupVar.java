package org.linuxtesting.ldv.envgen.group;

public class GroupVar extends Var {
	private VarInfo info;
	private GroupInfo g;

	public GroupVar(VarInfo info, GroupInfo g) {
		super();
		this.info = info;
		this.g = g;
	}
	
	@Override
	public String getReplacementParam() {
		return info.replacementParam;
	}

	@Override
	public String getVarName() {
		return g.getVarName();
	}

	@Override
	public String toString() {
		return "GroupVar [info=" + info + ", g=" + g + "]";
	}

	@Override
	public int hashCode() {
		return g.getId();
	}

	@Override
	public boolean equals(Object obj) {
		if(! (obj instanceof GroupVar)) {
			return false;
		}
		GroupVar other = (GroupVar)obj;
		return g.getId() == other.g.getId();
	}
}
