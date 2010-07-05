package com.iceberg.mp.vs.vsm;

import com.iceberg.mp.vs.VProtocol;

public class VSMClientGetTask extends VSMClient {

	public VSMClientGetTask(String name) {
		super(VProtocol.sGetTask, name);
	}

	private static final long serialVersionUID = 1L;
	
}
