package com.iceberg.mp.ws.wsm;

import java.util.List;

import com.iceberg.mp.schelduler.Env;
import com.iceberg.mp.schelduler.Rule;
import com.iceberg.mp.vs.client.Result;

public class WSMLdvstowsTaskGetStatusResponse extends WSM {
	private final static String tagB_user = "<user>";
	//private final static String tag_user = "user";
	private final static String tagE_user = "</user>";
	private final static String tagB_id = "<id>";
	//private final static String tag_id = "id";
	private final static String tagE_id = "</id>";
	//private final static String tagB_env = "<env>";
	private final static String tag_env = "env";
	private final static String tagE_env = "</env>";
	//private final static String tagB_rule = "<rule>";
	private final static String tag_rule = "rule";
	private final static String tagE_rule = "</rule>";
	private final static String tagB_status = "<status>";
	//private final static String tag_status = "status";
	private final static String tagE_status = "</status>";
	private final static String tagB_result = "<result>";
	//private final static String tag_result = "result";
	private final static String tagE_result = "</result>";
	private final static String tagB_verdict = "<verdict>";
	//private final static String tag_verdict = "verdict";
	private final static String tagE_verdict = "</verdict>";
	private final static String tagB_report = "<report>";
	//private final static String tag_report = "report";
	private final static String tagE_report = "</report>";
	
	private int task_id;
	private String user;
	private List<Env> envs;
	private String task_status;
	
	public void setParameters(int task_id, List<Env> envs, String task_status, String name) {
		this.task_id = task_id;
		this.envs = envs;
		this.task_status = task_status;
		this.user = name;
	}
	
	public String getTaskStatus() {
		return task_status;
	}
	
	public int getTaskId() {
		return task_id;
	}
	
	public String getUserName() {
		return user;
	}
	
	public List<Env> getEnvs() {
		return envs;
	}
	
	public String toWSXML() {
		// перобразовываем все в xml
		String msg = tagB_user + this.user + tagE_user +
			tagB_id + task_id + tagE_id;
		for(int i=0; i<envs.size(); i++) {
			msg += '<'+tag_env+" name=\""+envs.get(i).getName()+"\">";
			List<Rule> rules = envs.get(i).getRules();
			for(int j=0; j<rules.size(); j++) {
				msg += '<'+tag_rule+" name=\""+rules.get(j).getName()+"\">";
				msg += tagB_status + rules.get(j).getStatus() + tagE_status;
				List<Result> results = rules.get(j).getResults();
				for(int k=0; k<results.size(); k++) {
					msg += tagB_result;
					msg += tagB_verdict + results.get(k).getRresult()+ tagE_verdict;
					if(results.get(k).getRresult().equals("UNSAFE"))
						msg += tagB_report + results.get(k).getId()+ tagE_report;	
					msg += tagE_result;
				}
				msg += tagE_rule;
			}
			msg += tagE_env;
		}
		return super.toWSXML(msg);
	}
	
}
