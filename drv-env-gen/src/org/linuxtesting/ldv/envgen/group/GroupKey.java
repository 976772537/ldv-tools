package org.linuxtesting.ldv.envgen.group;

public class GroupKey {
	String key;
	
	public GroupKey(String replacementParam) {
		assert replacementParam!=null;
		this.key = replacementParam.replaceAll("\\$var", "").trim();
	}

	@Override
	public String toString() {
		return "GroupKey [key=" + key + "]";
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((key == null) ? 0 : key.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		GroupKey other = (GroupKey) obj;
		if (key == null) {
			if (other.key != null)
				return false;
		} else if (!key.equals(other.key))
			return false;
		return true;
	}

}
