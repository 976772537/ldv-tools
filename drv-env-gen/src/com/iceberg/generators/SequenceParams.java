package com.iceberg.generators;

public class SequenceParams extends EnvParams {
	enum Length {
		one, n, infinite
	};
	boolean stateful;
	Length length;
	int n;
	
	public SequenceParams(boolean check, boolean stateful, Length length) {
		super(true, check);
		assert length!=Length.n;
		this.stateful = stateful;
		this.length = length;
		this.n = -1;
	}

	public SequenceParams(boolean check, boolean stateful, int n) {
		super(true, check);
		this.stateful = stateful;
		this.length = Length.n;
		this.n = n;
	}
	
	public boolean isStatefull() {
		return stateful;
	}

	public Length getLength() {
		return length;
	}

	public int getN() {
		return n;
	}

	@Override
	public String getStringId() {
		return "seq" + "_" + length + (check?"_withcheck":"") + (stateful?"_stateful":"");
	}
	
	
}
