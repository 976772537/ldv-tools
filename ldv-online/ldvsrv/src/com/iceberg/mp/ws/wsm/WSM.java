package com.iceberg.mp.ws.wsm;

import org.w3c.dom.NodeList;

public class WSM {
	
	public final static String xmlheader = "<?xml version=\"1.0\"?>";
	
	public final static String tag_msg = "msg";
	public final static String tagB_msg = "<msg>";
	public final static String tagE_msg = "</msg>";
	
	public final static String tag_type = "type";
	public final static String tagB_type = "<type>";
	public final static String tagE_type = "</type>";

	
	private String type = null;
	
	public static String getType(NodeList nl) {
		for(int i=0; i<nl.getLength(); i++) {
			if(nl.item(i).getNodeName().equals(WSM.tag_type)) {
				return nl.item(i).getTextContent();
			}
		}
		return null;
	}
	
	public void parse(NodeList nl) {
		this.type = getType(nl);
	}
	
	public final static String wrapMsg(String msg) {
		return xmlheader+tagB_msg+msg+tagE_msg+"\n";
	}

	public String toWSXML() {
		return null;
	}
	
	public String toWSXML(String msg) {
		return wrapMsg(tagB_type+this.type+tagE_type+msg);
	}
	
	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}
}
