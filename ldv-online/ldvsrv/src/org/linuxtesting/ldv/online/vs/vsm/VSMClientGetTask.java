package org.linuxtesting.ldv.online.vs.vsm;

import org.linuxtesting.ldv.online.vs.VProtocol;

public class VSMClientGetTask extends VSMClient {

	public VSMClientGetTask(String name) {
		super(VProtocol.sGetTask, name);
	}

	private static final long serialVersionUID = 1L;
	
}
