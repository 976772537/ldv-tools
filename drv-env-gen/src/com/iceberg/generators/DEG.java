package com.iceberg.generators;

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

import com.iceberg.FSOperationsBase;
import com.sun.org.apache.xml.internal.serialize.DOMSerializer;
import com.sun.org.apache.xml.internal.serialize.OutputFormat;
import com.sun.org.apache.xml.internal.serialize.XMLSerializer;

public class DEG {
	
	private static String defaultdir = "deg_tempdir";
	private static String defaultxml = "cmd.xml";
	
	private static String nextInstrumentDir = "dscv_tempdir";
	private static String myInstrumentDir = "deg_tempdir";
	private static String replacedInstrumentDir = "bce_tempdir";
	
	private static String rootTag = "cmdstream";
	private static String basedirTag = "basedir";
	private static String ccTag = "cc";
	private static String ldTag = "ld";
	private static String inTag = "in";
	private static String outTag = "out";
	private static String optTag = "opt";
	private static String mainTag = "main";
	
	public static void main(String[] args) {
		long startf = System.currentTimeMillis();
		if(args.length != 2 && args.length != 3) {
			System.out.println("USAGE: java -ea -jar drv-env-gen.jar work_dir command_file.xml <out_command_file.xml>");
			return;
		}
		String outXmlFile = args[0]+'/'+defaultdir+'/'+defaultxml;
		if(args.length == 3)
			outXmlFile = args[2];
		
		try {
			DocumentBuilder xml = DocumentBuilderFactory.newInstance().newDocumentBuilder();
			Document doc = xml.parse(new File(args[1]));
			Element xmlRoot=doc.getDocumentElement();
			if (!xmlRoot.getTagName().equals(rootTag)) {
				System.out.println("Can not find root tag:\""+rootTag+"\"");
				return;
			}
			
			List<String> mainList = new ArrayList<String>();
			NodeList cmdstreamNodeList = xmlRoot.getChildNodes();
			String lbasedir = null;
			int main_counter=1;
			for(int i=1; i<cmdstreamNodeList.getLength(); i++) {
				if (cmdstreamNodeList.item(i).getNodeType() == Node.ELEMENT_NODE) {
					if(cmdstreamNodeList.item(i).getNodeName().equals(basedirTag)) {
						// copy driver sources for next instrument
						// TODO: add test for errors
						lbasedir = cmdstreamNodeList.item(i).getTextContent();
						File sourceDir = new File(lbasedir);
						File destinationDir = new File(args[0]+'/'+nextInstrumentDir);
						FSOperationsBase.copyDirectory(sourceDir, destinationDir);
						
						String newinTagContent = lbasedir.replace(myInstrumentDir, nextInstrumentDir);
						cmdstreamNodeList.item(i).setTextContent(newinTagContent);
					} else if(cmdstreamNodeList.item(i).getNodeName().equals(ldTag)) {
						NodeList ldNodes = cmdstreamNodeList.item(i).getChildNodes();
						//boolean isgenerated = false;
						for(int j=1; j<ldNodes.getLength(); j++) {
							if (ldNodes.item(j).getNodeType() == Node.ELEMENT_NODE) {
								if(ldNodes.item(j).getNodeName().equals(inTag)) {
									String inTagContent = ldNodes.item(j).getTextContent();
									String newinTagContent = inTagContent.replace(replacedInstrumentDir, nextInstrumentDir);
									ldNodes.item(j).setTextContent(newinTagContent);
									File inFile = new File(inTagContent);
									if(inFile.exists()) {
										String buffer = FSOperationsBase.readFileCRLF(inTagContent);
										if(buffer.length()>=9) {
											//mainList.add(buffer);
											String main_number = buffer.replace("ldv_main","").trim();
											mainList.add(main_number);
										}
									}
								//} else if(ccNodes.item(j).getNodeName().equals(optTag)) {
								} else if(ldNodes.item(j).getNodeName().equals(outTag)) {
									String inTagContent = ldNodes.item(j).getTextContent();
									String newinTagContent = inTagContent.replace(replacedInstrumentDir, nextInstrumentDir);
									ldNodes.item(j).setTextContent(newinTagContent);
								} 
							}
						}
						// add mains
						for(int k=0; k<mainList.size(); k++) {
							Node mainNode = doc.createElement(mainTag);
							Node mainTextNode = doc.createTextNode("ldv_main"+mainList.get(k));
							mainNode.appendChild(mainTextNode);
							cmdstreamNodeList.item(i).appendChild(mainNode);
						}
					} else if(cmdstreamNodeList.item(i).getNodeName().equals(ccTag)) {
						NodeList ccNodes = cmdstreamNodeList.item(i).getChildNodes();
						boolean isgenerated = false;
						List<Node> ins = new ArrayList<Node>();
						Node out = null;
						for(int j=1; j<ccNodes.getLength(); j++) {
							if (ccNodes.item(j).getNodeType() == Node.ELEMENT_NODE) {
								if(ccNodes.item(j).getNodeName().equals(inTag)) {
									ins.add(ccNodes.item(j)); 
								} else if(ccNodes.item(j).getNodeName().equals(optTag)) {
									//TODO ifdef opt
								} else if(ccNodes.item(j).getNodeName().equals(outTag)) {
									out = ccNodes.item(j);
								} 
							}
						}
						int local_counter=main_counter;
						for(Node in : ins) {
							String inTagContent = in.getTextContent();
							String newinTagContent = inTagContent.replace(replacedInstrumentDir, nextInstrumentDir);
							if(MainGenerator.deg(newinTagContent,local_counter++))
								isgenerated = true;
							in.setTextContent(newinTagContent);
						}
							
						assert out!=null;
						String outTagContent = out.getTextContent();
						String newoutTagContent = out.getTextContent().replace(replacedInstrumentDir, nextInstrumentDir);
						out.setTextContent(newoutTagContent);
						// if c-file conatins main -> then create o-file in old
						// dir, that contains info
						if(isgenerated) {
							FileWriter fw = new FileWriter(outTagContent);
							//for(; main_counter!=local_counter; main_counter++)
								fw.write("ldv_main" + main_counter++);
							fw.close();
						}
					}
				}
			}
			OutputFormat format = new OutputFormat();
			format.setIndenting(true);
			File xmlOutFile = new File(outXmlFile);
			FileOutputStream os = new FileOutputStream(xmlOutFile);
			DOMSerializer serializer = new XMLSerializer(os, format);
			serializer.serialize(xmlRoot);
			os.flush();
			os.close();
        } catch (SAXException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		}
		

		long endf = System.currentTimeMillis();
		System.out.println("generate time: " + (endf-startf) + "ms");
	}
}
