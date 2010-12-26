package org.linuxtesting.ldv.csd.cmdstream;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

import javax.naming.NamingException;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.linuxtesting.ldv.csd.CSD;
import org.linuxtesting.ldv.csd.FSOperationBase;
import org.linuxtesting.ldv.csd.utils.Logger;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

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

	public final static String shift = "\t";

	private String inBasedir = null;
	private List<Command> cmdlist = Collections
			.synchronizedList(new ArrayList<Command>());
	private static List<Command> badlist = Collections
			.synchronizedList(new ArrayList<Command>());
	private final static BlockingQueue<Command> commandsQueue = new ArrayBlockingQueue<Command>(
			400000);

	public CmdStream(List<Command> cmdList, String basedir, boolean fullcopy,
			String statefile, String tempdir) {
		inBasedir = basedir;
		cmdlist = cmdList;
		this.fullcopy = fullcopy;
		this.statefile = statefile;
		this.tempdir = tempdir;
	}

	private boolean fullcopy = false;

	private String tempdir;

	public CmdStream(String tempdir, String tagbd, boolean fullcopy,
			String statefile) {
		this.statefile = statefile;
		this.tempdir = tempdir;
		this.fullcopy = fullcopy;
		if (tagbd != null)
			this.inBasedir = (new File(tagbd)).getAbsolutePath();

	}

	public static Map<String, Command> fullCmdHash = new HashMap<String, Command>();
	public static Map<String, Command> badCmdHash = new HashMap<String, Command>();
	private String statefile;

	public static boolean isExistsLD(String cmd) {
		Logger.trace("Called isExistsLD for command \"" + cmd + "\".");
		if (fullCmdHash.containsKey(cmd)) {
			Logger.trace("Command \"" + cmd + "\" exists.");
			Command cmdl = fullCmdHash.get(cmd);
			if (cmdl instanceof CommandLD) {
				Logger.trace("Command \"" + cmd + "\" is LD.");
				return true;
			}
		}
		return false;
	}

	public static synchronized boolean isExists(Command cmd) {
		List<String> outCmds = cmd.getOut();

		boolean result = false;

		for (int i = 0; i < outCmds.size(); i++) {
			if (fullCmdHash.containsKey(outCmds.get(i))) {
				result = true;
				break;
			}
			// cmd.addObjIn(fullCmdHash.get(outCmds.get(i)));
		}
		return result;
	}

	public static synchronized boolean isItFull(Command cmd) {
		if (cmd instanceof CommandCC)
			return true;
		List<String> inCmds = cmd.getIn();
		boolean result = true;
		// проверяем присутствие всех зщависимостей в хэше,
		// а заодно связываем
		for (int i = 0; i < inCmds.size(); i++) {
			if (!fullCmdHash.containsKey(inCmds.get(i))) {
				result = false;
				break;
			}
			cmd.addObjIn(fullCmdHash.get(inCmds.get(i)));
		}
		return result;
	}

	public static Map<String, Command> ismodule = new HashMap<String, Command>();

	public synchronized void processObjectCmd(Command cmd) {
		/*
		 * if(cmd instanceof CommandLD) { ismodule.put(cmd.getOut().get(0),cmd);
		 * }
		 */
		// комманда уже существует ?
		if (isExists(cmd)) {
			Logger.norm("Already exists: \"" + cmd.out.get(0) + "\".");
			return;
		}

		// комманда целая?
		if (isItFull(cmd)) {

			// тогда добавим хэш из всех ее выходов
			addToHashAllOutputs(cmd, fullCmdHash);

			// если комманда для верификации, то создаем задания
			if (cmd.isCheck())
				prepareTask(cmd);

			// проходимся по списку ld комманд на верификацию и
			/*
			 * for(int i=0; i<ldCmdlist.size(); i++) { Command ccmd =
			 * ldCmdlist.remove(i);
			 */
			// }

			// разгребаем битые комманды
			while (checkOtherBadCommands()) {
			}
			;
		} else {

			// не целая - тогда в сответствующий список и хэш
			addToHashAllOutputs(cmd, badCmdHash);
			cmdlist.add(cmd);
		}

	}

	// private List<Command> cmdlistFull = Collections.synchronizedList(new
	// ArrayList<Command>());
	public synchronized void processCmdStream(String xmlcommand)
			throws ParserConfigurationException, SAXException, IOException,
			NamingException {
		Command cmd = addCommandFromXML(xmlcommand);

		processObjectCmd(cmd);

	}

	public synchronized boolean checkOtherBadCommands() {
		for (int i = 0; i < badlist.size(); i++) {
			// берем комманду и проверяем ее зависимости
			Command badCmd = badlist.get(i);
			if (isItFull(badCmd)) {
				badlist.remove(i);
				removeFromHashAllOutputs(badCmd, badCmdHash);
				addToHashAllOutputs(badCmd, fullCmdHash);
				if (badCmd.isCheck())
					prepareTask(badCmd);
				return true;
			}
		}
		return false;
	}

	private static void removeFromHashAllOutputs(Command cmd,
			Map<String, Command> outputHash) {
		List<String> outs = cmd.getOut();
		for (int i = 0; i < outs.size(); i++) {
			outputHash.remove(outs.get(i));
		}
	}

	private static void addToHashAllOutputs(Command cmd,
			Map<String, Command> outputHash) {
		List<String> outs = cmd.getOut();
		for (int i = 0; i < outs.size(); i++) {
			outputHash.put(outs.get(i), cmd);
		}
	}

	protected static Map<Integer, Command> preparedCommands = new HashMap<Integer, Command>(
			4000);

	private synchronized void prepareTask(Command cmd) {
		if (preparedCommands.containsKey(cmd.getId())) {
			Logger.norm("Command \"" + cmd.getOut().get(0)
					+ "\" already exists and prepared as \"" + cmd.getId()
					+ "\".");
			return;
		}
		Logger.norm("Starting prepare task for : \"" + cmd.out.get(0)
				+ "\" with id = \"" + cmd.getId() + "\".");
		List<Command> listCmd = new ArrayList<Command>();
		// рекурсивно снизу-вверх добавляем комманды
		//Command pcmd = cmd;
		// addCommandsRecursive(listCmd, cmd);
		
		cmd = cmd.clone();
		
		//cmd = (Command)cmd.clone();
		copyCommandsRecursive(listCmd, cmd);
		listCmd.add(cmd);
		
		
		// inBasedir = tempdir;
		Logger.trace("FULLCOPY: " + fullcopy);
		CmdStream lcmdstream = new CmdStream(listCmd, inBasedir, fullcopy,
				statefile, tempdir);
		Logger.norm("Generate cmdstream for : \"" + cmd.toString() + "\".");
/*		Logger.norm("PGenerate cmdstream for : \"" + pcmd.toString() + "\".");

		Logger.norm("Generate cmdstream for : \"" + cmd.out.get(0) + "\".");
		Logger.norm("PGenerate cmdstream for : \"" + pcmd.out.get(0) + "\".");
		
		Logger.norm("EEE:BEFOREIN : \"" + cmd.in.get(0) + "\".");
		Logger.norm("EEE:BEFOREPIN : \"" + pcmd.in.get(0) + "\".");*/

		
		String driverTaskDir = tempdir + "/" + cmd.getId();
		String newDriverDirString = driverTaskDir + "/driver";
		lcmdstream.relocateDriver(newDriverDirString, fullcopy);
		
		/*Logger.norm("EEE_ONE:Generate cmdstream for : \"" + cmd.out.get(0) + "\".");
		Logger.norm("EEE_ONE:PGenerate cmdstream for : \"" + pcmd.out.get(0) + "\".");
		
		Logger.norm("EEE_ONE:IN : \"" + cmd.in.get(0) + "\".");
		Logger.norm("EEE_ONE:PIN : \"" + pcmd.in.get(0) + "\".");*/

		genFilename = CSD.cmdfileout;
		FileWriter stateFw = null;
		preparedCommands.put(cmd.getId(), cmd);
		try {
			stateFw = new FileWriter(statefile);
			lcmdstream.putCmdStream(driverTaskDir + "/" + genFilename + ".xml");
			if (stateFw != null) {
				for (int j = 0; j < lcmdstream.getCmdList().size(); j++) {
					Command lcmd = lcmdstream.getCmdList().get(j);
					stateFw.append(lcmd.getId() + ":" + 10 + "\n");
				}
			}
			putCommand(cmd);
			cmd.setPrepared();
		} catch (IOException e) {
			Logger.warn("Failed \"" + tempdir + "/" + genFilename + "1"
					+ ".xml" + "\".");
		} finally {
			if (stateFw != null)
				try {
					stateFw.close();
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
		}
	}

	private static DocumentBuilder xml;

	public static synchronized Command addCommandFromXML(String xmlcommand)
			throws ParserConfigurationException, SAXException, IOException {
		if (xml == null)
			xml = DocumentBuilderFactory.newInstance().newDocumentBuilder();
		Document doc = xml
				.parse(new ByteArrayInputStream(xmlcommand.getBytes()));
		Element xmlRoot = doc.getDocumentElement();
		NodeList cmdstreamNodeList = xmlRoot.getChildNodes();
		for (int i = 1; i < cmdstreamNodeList.getLength(); i++) {
			if (cmdstreamNodeList.item(i).getNodeType() == Node.ELEMENT_NODE) {
				if (cmdstreamNodeList.item(i).getNodeName().equals(tagCc)) {
					return new CommandCC(cmdstreamNodeList.item(i));
				} else if (cmdstreamNodeList.item(i).getNodeName()
						.equals(tagLd)) {
					return new CommandLD(cmdstreamNodeList.item(i));
				}
			}
		}
		return null;
	}

	// private List<CmdStream> independentCommands;

	private static String genFilename = "cmd_after_deg";

	private boolean relocateDriver(String newDriverDirString, boolean fullcopy) {
		File newDriverDir = new File(newDriverDirString);
		if (newDriverDir.exists()) {
			Logger.warn("Directory \"" + newDriverDirString
					+ "\" - already exists. Try to rewrite it.");
			FSOperationBase.removeDirectoryRecursive(newDriverDir);
		}
		newDriverDir.mkdirs();
		File oldDriverDir = new File(inBasedir);
		if (!oldDriverDir.exists()) {
			Logger.err("Basedir \"" + inBasedir + "\" - not exists.");
			System.exit(1);
		}
		String newDDFullCanPath = newDriverDir.getAbsolutePath();
		String oldDDFullCanPath = oldDriverDir.getAbsolutePath();

		Logger.trace("relocate FULLCOPY: " + fullcopy);
		try {
			if (fullcopy) {
				FSOperationBase.copyDirectory(oldDriverDir, newDriverDir);
			}
		} catch (IOException e) {
			Logger.err("Can't copy directory.");
			System.exit(1);
		}
		List<Command> lCmdList = cmdlist;
		for (int i = 0; i < lCmdList.size(); i++)
			lCmdList.get(i).relocateCommand(oldDDFullCanPath, newDDFullCanPath,
					fullcopy);
		inBasedir = newDDFullCanPath;
		return true;
	}

	private void addCommandsRecursive(List<Command> lcmd, Command command) {
		for (int i = 0; i < command.getObjIn().size(); i++) {
			addCommandsRecursive(lcmd, command.getObjIn().get(i));
			lcmd.add(command.getObjIn().get(i));
		}
	}

	private void copyCommandsRecursive(List<Command> lcmd, Command command) {
		for (int i = 0; i < command.getObjIn().size(); i++) {
			addCommandsRecursive(lcmd, command.getObjIn().get(i));
			//--Command clonedCmd = (Command) command.getObjIn().get(i).clone();
			// clonedCmd.setId();
			//--lcmd.add(clonedCmd);
			// lcmd.add(command.getObjIn().get(i));
			lcmd.add(command.getObjIn().get(i).clone());
			/*
			 * Command cmd = command.getObjIn().get(i); Command ccmd = null;
			 * if(cmd instanceof CommandCC) { ccmd = new CommandCC(); } else
			 * if(cmd instanceof CommandLD){ ccmd = new CommandLD(); }
			 */
			// and copy all fields:

		}
	}
	
	public void putCmdStream(String filename) throws IOException {
		File gfile = new File(filename);
		if (gfile.exists())
			Logger.warn("File: \"" + filename
					+ "\" - already exists. Try to rewrite it...");
		if (CSD.ldv_debug >= 40)
			Logger.norm("Generate xml-file: \"" + filename + "\".");
		FileWriter fw = new FileWriter(filename);
		StringBuffer sb = new StringBuffer();
		sb.append("<?xml version=\"1.0\"?>\n");
		sb.append("<cmdstream>\n");
		sb.append(shift + "<" + tagBasedir + ">" + inBasedir + "</"
				+ tagBasedir + ">\n");
		for (int i = 0; i < cmdlist.size(); i++)
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

	public void putCommand(Command cmd) {
		try {
			Logger.norm("Command added.");
			commandsQueue.put(cmd);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	public String getNextCommand() {
		String cmd = null;
		try {
			/*
			 * if(commandsQueue.isEmpty()) return null;
			 */
			cmd = tempdir + "/" + commandsQueue.take().getId();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		return cmd;
	}

	public boolean isEmpty() {
		return commandsQueue.isEmpty();
	}

	public static void setCheckAndKO(Command cmd) {
		Logger.norm("Set check and KO for command : \"" + cmd.getId() + "\".");
		cmd.setCheck();
		List<String> outCmds = cmd.getOut();
		for (int i = 0; i < outCmds.size(); i++) {
			String outs = outCmds.get(i);
			Logger.norm("Replace extension for file : \"" + outs
					+ "\" with \"ko\".");
			outCmds.set(i, outs.replaceFirst("\\.o$", ".ko"));
			Logger.trace("Now out file is : \"" + outCmds.get(i) + "\".");
		}
	}

	public synchronized void marker(String command) {
		Logger.norm("Set check marker for command \"" + command + "\".");
		if (badCmdHash.containsKey(command)) {
			Logger.norm("This is not full command.");
			// setCheckAndKO(badCmdHash.get(command));
			Logger.norm("Set check for command : \"" + command + "\".");
			// badCmdHash.get(command).setCheck();
			setCheckAndKO(badCmdHash.get(command));
			// badCmdHash.get(command).setCheck();
		} else if (fullCmdHash.containsKey(command)) {
			Logger.norm("This is full command.");
			Command cmd = fullCmdHash.get(command);
			Logger.norm("Set check for command : \"" + command + "\".");
			// cmd.setCheck();
			setCheckAndKO(cmd);
			// setCheckAndKO(cmd);
			prepareTask(cmd);
		}
	}

}
