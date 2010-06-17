package com.iceberg.mp.ws.wsm;

import org.w3c.dom.NodeList;

public class WSMWstoldvsTaskStatusGetRequest extends WSM {
	
	public final static String tag_id = "id";
	public final static String tag_user = "user";
	
	private String user;
	private int id;
		
	public String getUser() {
		return user;
	}
	
	public int getId() {
		return id;
	}
	
	public void parse(NodeList nl) {
		super.parse(nl);
		for(int i=0; i<nl.getLength(); i++) {
			if(nl.item(i).getNodeName().equals(WSMWstoldvsTaskStatusGetRequest.tag_user))
				this.user = nl.item(i).getTextContent(); 
			else if(nl.item(i).getNodeName().equals(WSMWstoldvsTaskStatusGetRequest.tag_id))
				this.id = Integer.valueOf(nl.item(i).getTextContent());
		}		
	}
}
