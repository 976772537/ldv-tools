package com.iceberg.mp.schelduler;

import java.io.Serializable;

public class MTask implements Serializable {
	
	public static enum Status {
		TS_WAIT_FOR_VERIFICATION,
		TS_VERIFICATION_FINISHED,
		TS_VERIFICATION_IN_PROGRESS,
		TS_PREPARE_FOR_SENDING_TO_VERIFICATION,
		TS_DIVIDED, 
		TS_UPLOADING // задача в процессе загрузки на сервер 
	}
	
	
	public int getId() {
		return id;
	}

	public String getVparams() {
		return vparams;
	}

	public byte[] getData() {
		return data;
	}

	private static final long serialVersionUID = 1L;
	private int id;
	private String vparams;
	private byte[] data;

	public MTask(int id, byte[] data, String vparams) {
		this.id = id;
		this.data = data;
		this.vparams = vparams;
	}
	
}
