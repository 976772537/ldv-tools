package com.iceberg.mp.vs.vsm;

import com.iceberg.mp.vs.VProtocol;

public class VSMClientSendResults extends VSMClient {

	// здесь должен храниться объект, в котором расписано по всем
	// энваронментам и правилам статусы!!!
	private byte[] data;	
	
	public VSMClientSendResults(String name,byte[] data) {
		super(VProtocol.sSendResults, name);
		this.data = data;
	}
	
	private static final long serialVersionUID = 1L;
	
	public byte[] getData() {
		return this.data;
	}

}
