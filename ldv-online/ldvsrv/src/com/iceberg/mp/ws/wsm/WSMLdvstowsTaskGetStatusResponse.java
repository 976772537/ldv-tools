package com.iceberg.mp.ws.wsm;

import java.util.List;

import com.iceberg.mp.schelduler.Env;

public class WSMLdvstowsTaskGetStatusResponse extends WSM {
	private final static String tagB_result = "<result>";
	private final static String tagE_result = "</result>";
	
	private int task_id;
	private List<Env> envs;
	private String task_status;
	
	public void setParameters(int task_id, List<Env> envs, String task_status) {
		this.task_id = task_id;
		this.envs = envs;
		this.task_status = task_status;
	}
	
	/*public WSMLdvstowsTaskGetStatusResponse(int task_id, List<Env> envs, String task_status) {
		this.task_id = task_id;
		this.envs = envs;
		this.task_status = task_status;
	}*/
	
	public String getTaskStatus() {
		return task_status;
	}
	
	public int getTaskId() {
		return task_id;
	}
	
	public List<Env> getEnvs() {
		return envs;
	}
	
	public String toWSXML() {
		// перобразовываем все в xml
		return super.toWSXML(tagB_result+tagE_result);
	}
	
}
