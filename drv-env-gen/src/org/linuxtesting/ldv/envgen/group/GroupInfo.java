package org.linuxtesting.ldv.envgen.group;

public class GroupInfo {
	private static int group_id;
	
	//private VarInfo info;
	private int id;
	
	public GroupInfo(VarInfo info) {
		//this.info = info;//first info
		this.id = ++group_id;
	}
	
	public String getVarName() {
		return "var_group" + id;
	}
}
