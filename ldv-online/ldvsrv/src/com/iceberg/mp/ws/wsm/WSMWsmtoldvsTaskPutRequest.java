package com.iceberg.mp.ws.wsm;

import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.NodeList;

import com.iceberg.mp.schelduler.Env;

public class WSMWsmtoldvsTaskPutRequest extends WSM {
	
	public final static String tag_env = "env";
	public final static String tag_rule = "rule";
	public final static String tag_user = "user";
	public final static String tag_driver = "driver";
	public final static String tag_sourcelen = "sourcelen";
	public final static String attr_name = "name";
	
	private List<Env> envs = new ArrayList<Env>();
	
	private String user;
	private String driver;
	private int sourcelen;
	
	private static List<String> parseRules(NodeList nl) {
		List<String> ruleList = new ArrayList<String>();  
		for(int i=0; i<nl.getLength(); i++) {
			if(nl.item(i).getNodeName().equals(WSMWsmtoldvsTaskPutRequest.tag_rule)) {
				ruleList.add(nl.item(i).getTextContent());
			}
		}
		return ruleList;
	}
	
	private static List<Env> parseEnv(NodeList nl) {
		List<Env> envList = new ArrayList<Env>();
		for(int i=0; i<nl.getLength(); i++) {
			if(nl.item(i).getNodeName().equals(WSMWsmtoldvsTaskPutRequest.tag_env)) {
				String envName = nl.item(i).getAttributes().getNamedItem(attr_name).getTextContent();
				List<String> ruleList = parseRules(nl.item(i).getChildNodes());  
				envList.add(new Env(ruleList,envName));
			}
		}
		return envList;
	}
	
	public List<Env> getEnvs() {
		return envs;
	}
	
	public String getUser() {
		return user;
	}
	
	public int getSourceLen() {
		return sourcelen;
	}
	
	public void parse(NodeList nl) {
		super.parse(nl);
		this.envs = parseEnv(nl);
		for(int i=0; i<nl.getLength(); i++) {
			if(nl.item(i).getNodeName().equals(WSMWsmtoldvsTaskPutRequest.tag_user))
				this.user = nl.item(i).getTextContent(); 
			else if(nl.item(i).getNodeName().equals(WSMWsmtoldvsTaskPutRequest.tag_sourcelen))
				this.sourcelen = Integer.valueOf(nl.item(i).getTextContent());
			else if(nl.item(i).getNodeName().equals(WSMWsmtoldvsTaskPutRequest.tag_driver))
				this.driver = nl.item(i).getTextContent();
		}		
	}

	public String getDriver() {
		return driver;
	}
}
