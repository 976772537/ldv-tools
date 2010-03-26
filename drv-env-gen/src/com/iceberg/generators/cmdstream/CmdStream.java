package com.iceberg.generators.cmdstream;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

public class CmdStream {
	
	private final static String tagBasedir = "basedir";
	private final static String tagRoot = "cmdstream";
	private final static String tagCc = "cc";
	private final static String tagLd = "ld";
	private final static String tagOpt = "opt";
	private final static String tagIn = "in";
	private final static String tagOut = "out";
	private final static String tagCwd = "cwd";
	private final static String tagMain = "main";
	
	private String rootTagName = null;
	private String inBasedir = null;
	private List<Command> cmdlist = new ArrayList<Command>();
	
	public static CmdStream getCmdStream(String path) throws ParserConfigurationException, SAXException, IOException {
		DocumentBuilder xml = DocumentBuilderFactory.newInstance().newDocumentBuilder();
		Document doc = xml.parse(new File(path));
		
		CmdStream cmdobj = new CmdStream();
		Element xmlRoot=doc.getDocumentElement();
		cmdobj.rootTagName = xmlRoot.getTagName();
		NodeList cmdstreamNodeList = xmlRoot.getChildNodes();
		for(int i=1; i<cmdstreamNodeList.getLength(); i++) {
			if (cmdstreamNodeList.item(i).getNodeType() == Node.ELEMENT_NODE) {
				if(cmdstreamNodeList.item(i).getNodeName().equals(tagBasedir)) {
					cmdobj.inBasedir = cmdstreamNodeList.item(i).getTextContent();
				} else if(cmdstreamNodeList.item(i).getNodeName().equals(tagCc)) {
					CommandCC cmdcc = new CommandCC(cmdstreamNodeList.item(i));
				}
			}
		}
		System.out.println("!!!!!");
		return null;
	}
}
