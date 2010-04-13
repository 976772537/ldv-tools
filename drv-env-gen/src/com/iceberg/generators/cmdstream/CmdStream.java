package com.iceberg.generators.cmdstream;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FileWriter;
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

import com.iceberg.generators.MainGenerator;

public class CmdStream {
	
	public final static String tagBasedir = "basedir";
	public final static String tagRoot = "cmdstream";
	public final static String tagCc = "cc";
	public final static String tagLd = "ld";
	public final static String tagOpt = "opt";
	public final static String tagIn = "in";
	public final static String tagOut = "out";
	public final static String tagCwd = "cwd";
	public final static String tagMain = "main";
	
	// сдвиг
	//_____________________
	// <?xml version="1.0"?>
	// <cmdstream>
	// shift<ld>
	// shiftshift<in>..</in>
	// shiftshift<out>..</out>
	// shift</ld> 
	//...
	// </cmdstream>
	public final static String shift = "\t";
	
	private String rootTagName = null;
	private String inBasedir = null;
	private List<Command> cmdlist = new ArrayList<Command>();
	
	public static CmdStream getCmdStream(String path) throws ParserConfigurationException, SAXException, IOException {
		DocumentBuilder xml = DocumentBuilderFactory.newInstance().newDocumentBuilder();
		Document doc = xml.parse(new File(path));
		
		CmdStream cmdobj = new CmdStream();
		Element xmlRoot = doc.getDocumentElement();
		cmdobj.rootTagName = xmlRoot.getTagName();
		NodeList cmdstreamNodeList = xmlRoot.getChildNodes();
		for(int i=1; i<cmdstreamNodeList.getLength(); i++) {
			if (cmdstreamNodeList.item(i).getNodeType() == Node.ELEMENT_NODE) {
				if(cmdstreamNodeList.item(i).getNodeName().equals(tagBasedir)) {
					cmdobj.inBasedir = cmdstreamNodeList.item(i).getTextContent();
				} else if(cmdstreamNodeList.item(i).getNodeName().equals(tagCc)) {
					CommandCC cmd = new CommandCC(cmdstreamNodeList.item(i));
					cmdobj.cmdlist.add(cmd);
				} else if(cmdstreamNodeList.item(i).getNodeName().equals(tagLd)) {
					CommandLD cmd = new CommandLD(cmdstreamNodeList.item(i));
					cmdobj.cmdlist.add(cmd);
				}
			}
		}
		/*
		 * 
		 * теперь создадим дерево
		 * 
		 */
		return cmdobj;
	}
	
	public void putCmdStream(String filename) throws IOException {
		FileWriter fw = new FileWriter(filename);
		StringBuffer sb = new StringBuffer();
		sb.append("<?xml version=\"1.0\"?>\n");
		sb.append("<cmdstream>\n");
		sb.append(shift+"<"+tagBasedir+">"+inBasedir+"</"+tagBasedir+">\n");
		for(int i=0; i<cmdlist.size(); i++) {
			cmdlist.get(i).write(sb);
		}
		sb.append("</cmdstream>");
		//System.out.println(sb.toString());
		fw.write(sb.toString());
		fw.close();
	}

	public String getBaseDir() {
		return inBasedir;
	}

	
	private Command getObjectByOut(String infile) {
		for(int i=0; i<cmdlist.size(); i++) {
			List<String> outs = cmdlist.get(i).getOut();
			if(outs!=null)
				for(int j=0; j<outs.size(); j++)
					if(outs.get(j).equals(infile))
						return cmdlist.get(i); 
		}
		return null;
	}
	
	public void generateMains() {
		int counter=1;
		for(int i=0; i<cmdlist.size(); i++) {
			// Это модуль?
			if(cmdlist.get(i).isItForCheck()) {
				// тогда генерим для него энвайронмент
				// проходимся по входящим файлам
				int local_counter = counter;
				for(int j=0; j<cmdlist.get(i).getIn().size(); j++) {
					List<String> lklk = cmdlist.get(i).getIn();
					String njfjfk = cmdlist.get(i).getIn().get(j);
					Command cmd = getObjectByOut(cmdlist.get(i).getIn().get(j));
					if(cmd instanceof CommandCC) {
						for(int k=0; k<cmd.getIn().size(); k++) {
							if(MainGenerator.deg(cmd.getIn().get(k),local_counter)) {
								cmd.addOpt("-DLDV_MAIN"+local_counter++);
							}
						}
					}
				}
				while(counter!=local_counter) 
					((CommandLD)cmdlist.get(i)).addMain("ldv_main"+counter++);
			}
		}
	}
}
