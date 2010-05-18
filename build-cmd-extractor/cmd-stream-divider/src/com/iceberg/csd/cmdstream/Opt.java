package com.iceberg.csd.cmdstream;

import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

public class Opt {
	
	List<String> attNames = new ArrayList<String>();
	List<String> attValues = new ArrayList<String>();
	String value;

	public Opt(Node node) {
		NamedNodeMap nl = node.getAttributes();
		if(nl!=null) {
			for(int i=0; i<nl.getLength(); i++) {
				String attName = nl.item(i).getNodeName();
				if(attName!=null) attNames.add(attName);
				String attValue = nl.item(i).getTextContent();
				if(attValue!=null) attValues.add(attValue);
			}
		}
		value = node.getTextContent();
	}

	public Opt(String content) {
		value = content;
	}

	public String getValue() {
		return value;
	}

	public String getAttsString() {
		if(attNames.size()==0) return "";
		StringBuffer sb = new StringBuffer(" ");
		for(int i=0; i<attNames.size(); i++)
			sb.append(attNames.get(i)+"=\""+attValues.get(i)+"\"");
		return sb.toString();
	}
	
}
