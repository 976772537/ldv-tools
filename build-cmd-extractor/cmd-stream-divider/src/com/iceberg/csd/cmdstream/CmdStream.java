package com.iceberg.csd.cmdstream;

import java.io.File;
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

import com.iceberg.csd.CSD;
import com.iceberg.csd.FSOperationBase;

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
	
	public final static String defaultDriverDirName = "driver";
	
	
	public String basedir;
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
	
	private String inBasedir = null;
	private List<Command> cmdlist = new ArrayList<Command>();
	
	public CmdStream() {
		
	}
	
	public CmdStream(List<Command> cmdList, String basedir) {
		inBasedir = basedir;
		cmdlist = cmdList;
	}

	
	
	public static CmdStream getCmdStream(String path, String basedir) throws ParserConfigurationException, SAXException, IOException {
		DocumentBuilder xml = DocumentBuilderFactory.newInstance().newDocumentBuilder();
		Document doc = xml.parse(new File(path));	
		CmdStream cmdobj = new CmdStream();
		Element xmlRoot = doc.getDocumentElement();
		NodeList cmdstreamNodeList = xmlRoot.getChildNodes();
		for(int i=1; i<cmdstreamNodeList.getLength(); i++) {
			if (cmdstreamNodeList.item(i).getNodeType() == Node.ELEMENT_NODE) {
				if(cmdstreamNodeList.item(i).getNodeName().equals(tagBasedir)) {
					File baseDir = new File(cmdstreamNodeList.item(i).getTextContent());
					cmdobj.inBasedir = baseDir.getAbsolutePath();
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
		 *  скопируем драйвер 
		 * 
		 */
		//FSOperationsBase.copyDirectory(cmdobj.getBaseDir(),newdriverdir);
		cmdobj.basedir = basedir;
		return cmdobj;
	}
	
	private List<Command> stack;
	private List<CmdStream> independentCommands;
	
	private static String genFilename="cmd_after_deg";
	
	public void generateTree(String tempdir, boolean printdigraph, boolean driversplit, boolean fullcopy, String statefile) {
		//vortexList = new ArrayList<Command>();
		// стэк - просто для ускорения, так можно было всегда ходить по списку,
		// если бы не знали, что предыдущая комманда не может включать последующую
		FileWriter stateFw = null;
		try {
			if(statefile!=null)
				stateFw = new FileWriter(statefile);
		} catch (IOException e1) {
			System.out.println("csd: ERROR: Can't create state file:\""+statefile+"\".");
			System.exit(1);
		}
		if(driversplit) {
			stack = new ArrayList<Command>();
			// 1. взять из общего списка
			for(int i=0; i<cmdlist.size(); i++) {
				// 2. взять ее in-ы
				Command inCmd = cmdlist.get(i);
				for(int j=0; j<inCmd.getIn().size(); j++) {
					//if(inCmd.getIn().get(j).equals("drivers/isdn/hardware/eicon/divamnt.o")) {
					//	System.out.println("DEBUG");
					//}
					// 3. пройтись по всему стэку комманд
					// до того как не найдем входящий in
					// или вообще его не найдем
					for(int k=0; k<stack.size(); k++) {
						// 4. если что-нибудь найдем, то связываем.
						if(stack.get(k).getOut().size()>0) {
							//System.out.println("CMP :"+inCmd.getCwd()+"/"+inCmd.getIn().get(j));
							//System.out.println("WITH:"+stack.get(k).getOut().get(0));
							if(stack.get(k).getOut().get(0).equals(inCmd.getIn().get(j))) {
								inCmd.addObjIn(stack.get(k));
								break;
							} 

						} else
						{
						System.out.println("csd: WARNING: Elment have no out!");
						}
					}
				}
				// 5. положить нашу комманду  в стэк
				stack.add(cmdlist.get(i));
			}
		}
		{
			stack = cmdlist;
		}
		// DEBUG: распечатаем стэк со свзанными коммандами
		if(printdigraph)
			printDebugStackGraphviz();
		// создадим список с незаисимыми cmd-файлами
		// TODO: сейчас только заглушка -> сделать как надо!
		//       - берем головной файл и если он check-ld,
		//         добавляем его в список
		independentCommands = new ArrayList<CmdStream>();
		if(driversplit) {
			for(int i=0; i<stack.size(); i++) {
				if(stack.get(i).isCheck()) {
					List<Command> lcmd = new ArrayList<Command>();
					// 	рекурсивно снизу-вверх добавляем комманды
					addCommandsRecursive(lcmd,stack.get(i));
					lcmd.add(stack.get(i));
					CmdStream lcmdstream = new CmdStream(lcmd,inBasedir);
					independentCommands.add(lcmdstream);
					System.out.println("csd: NORMAL: Generate cmdstream for driver: \""+stack.get(i).out.get(0)+"\".");
				}
			}
		} else
			independentCommands.add(this);
		// если установлена опция - разделить и сам драйвер, то
		// 
		// Для каждого CmdStream'а
		// 1. создаем директорию в tempdir с именем driver[index]
		// 2. поочереди берем комманды
		//    для каждой комманды:
		// 
		//    - заменяем заменяем в in и out часть basedir на новую
		//      - делаем это в переменной
		//      и если файл реально существует, то
		//       - рекурсивно создаем директории в новой папке
		//       - копируем туда наш файл 
		//       - 
		//
		if(driversplit) {
			for(int i=0; i<independentCommands.size(); i++) {
				CmdStream lcmd = independentCommands.get(i);
				String newDriverDirString = tempdir+"/"+defaultDriverDirName+i;
				lcmd.relocateDriver(newDriverDirString,fullcopy);
			}
		}
		genFilename = CSD.cmdfileout;
		for(int i=0; i<independentCommands.size(); i++) {
			try {
				long start = System.currentTimeMillis();
				independentCommands.get(i).putCmdStream(tempdir+"/"+genFilename+i+".xml");
				long end = System.currentTimeMillis();
				long workTime = end - start;
				if(stateFw!=null) {
					for(int j=0 ;j<independentCommands.get(i).getCmdList().size(); j++) {
						Command lcmd = independentCommands.get(i).getCmdList().get(j);
						stateFw.append(lcmd.getId()+":"+workTime+"\n");
					}
				}
			} catch (IOException e) {
				System.out.println("csd: WARNING: Failed \""+tempdir+"/"+genFilename+"1"+".xml"+"\".");
			}
		}
		if(stateFw!=null)
			try {
				stateFw.close();
			} catch (IOException e) {
				System.out.println("csd: ERROR: Can't close state file after write:\""+statefile+"\".");
				System.exit(1);
			}
		System.out.println("csd: NORMAL: Number of extracted command streams: "+independentCommands.size()+".");
	}

	private boolean relocateDriver(String newDriverDirString, boolean fullcopy) {
		File newDriverDir = new File(newDriverDirString);
		if(newDriverDir.exists()) {
			System.out.println("csd: WARNING: Directory \""+newDriverDirString+"\" - already exists. Try to rewrite it.");
			FSOperationBase.removeDirectoryRecursive(newDriverDir);
		}
		newDriverDir.mkdirs();
		File oldDriverDir = new File(inBasedir);
		if(!oldDriverDir.exists()) {
			System.out.println("csd: ERROR: Basedir \""+inBasedir+"\" - not exists.");
			System.exit(1);
		}
		String newDDFullCanPath = newDriverDir.getAbsolutePath();
		String oldDDFullCanPath = oldDriverDir.getAbsolutePath();
		
		try {
			if(fullcopy) {
				FSOperationBase.copyDirectory(oldDriverDir, newDriverDir);
			}
		} catch (IOException e) {
			System.out.println("csd: ERROR: Can't copy directory.");
			System.exit(1);
		}
		List<Command> lCmdList = cmdlist;
		for(int i=0; i<lCmdList.size(); i++)
			lCmdList.get(i).relocateCommand(oldDDFullCanPath,newDDFullCanPath,fullcopy);
		inBasedir = newDDFullCanPath;
		return true;
	}

	private void addCommandsRecursive(List<Command> lcmd, Command command) {
		for(int i=0; i<command.getObjIn().size(); i++) {
			addCommandsRecursive(lcmd, command.getObjIn().get(i));
			lcmd.add(command.getObjIn().get(i));
		}
	}
	
	public void printDebugStackGraphviz() {
		StringBuffer tsb = new StringBuffer("digraph G{\n");
		List<String> gvstack = new ArrayList<String>();
		for(int i=0; i<stack.size(); i++) {
			if(stack.get(i).isCheck()==false)
				continue;
			gvstack.add("\""+stack.get(i).getOut().get(0).replaceAll(".*\\/", "")+"\"");
			printStackRecursiveGraphviz(gvstack,stack.get(i),tsb);
			gvstack.remove(gvstack.size()-1);
		}
		tsb.append("}\n");
		System.out.println(tsb.toString());
	}

	private static void printStackRecursiveGraphviz(List<String> gvstack, Command rcmd, StringBuffer tsb) {
		if(rcmd.isCheck()==false) {
			for(int i=0; i<gvstack.size(); i++)
				tsb.append(gvstack.get(i));
			tsb.append("\n");
			return;
		}
		if(rcmd.getObjIn().size()==0) {
			for(int i=0; i<gvstack.size(); i++)
				tsb.append(gvstack.get(i));

			tsb.append("\n");
			return;
		}
		for(int i=0; i<rcmd.getObjIn().size(); i++) {
			gvstack.add("->"+"\""+rcmd.getObjIn().get(i).getOut().get(0).replaceAll(".*\\/", "")+"\"");
			printStackRecursiveGraphviz(gvstack,rcmd.getObjIn().get(i),tsb);
			gvstack.remove(gvstack.size()-1);
		}
	}
	
	public void putCmdStream(String filename) throws IOException {
		File gfile = new File(filename);
		if(gfile.exists())
			System.out.println("csd: WARNING: File: \""+filename+"\" - already exists. I am rewite it.");
		if(CSD.ldv_debug >= 40 )
			System.out.println("csd: INFO: Generate xml-file: \""+filename+"\".");
		FileWriter fw = new FileWriter(filename);
		StringBuffer sb = new StringBuffer();
		sb.append("<?xml version=\"1.0\"?>\n");
		sb.append("<cmdstream>\n");
		sb.append(shift+"<"+tagBasedir+">"+inBasedir+"</"+tagBasedir+">\n");
		for(int i=0; i<cmdlist.size(); i++) 
			cmdlist.get(i).write(sb);
		sb.append("</cmdstream>");
		fw.write(sb.toString());
		fw.close();
	}

	public List<Command> getCmdList() {
		return cmdlist;
	}
	
	public String getBaseDir() {
		return inBasedir;
	}

}
