package org.linuxtesting.ldv.envgen.group;

public class GroupKey {
	String key;
	
	public GroupKey(String replacementParam) {
		assert key!=null;
		this.key = replacementParam.replaceAll("\\$var", "").trim();
	}

	@Override
	public String toString() {
		return "GroupKey [key=" + key + "]";
	}

	@Override
	public int hashCode() {
		return key.hashCode();
	}

	@Override
	public boolean equals(Object obj) {
		return key.equals(obj);
	}
}
