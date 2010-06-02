package com.iceberg.mp.vs.vsm;

import com.iceberg.mp.vs.VProtocol;

public class VSMClientSendResults extends VSMClient {

	// здесь должен храниться объект, в котором расписано по всем
	// энваронментам и правилам статусы!!!
	
	public VSMClientSendResults(String name) {
		super(VProtocol.sSendResults, name);
	}
	
	private static final long serialVersionUID = 1L;

}
