package com.iceberg.generators.cmdstream;

import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import com.sun.org.apache.xalan.internal.xsltc.compiler.util.NodeType;

public class Command {
	private List<String> opts = new ArrayList<String>();
	private List<Command> inObj = new ArrayList<Command>();
	private List<String> in = new ArrayList<String>();
	private List<String> out = new ArrayList<String>();
	private String cwd = null;;
	
	private static int cmd_counter = 0;
	
	private boolean check = false;
	
	public boolean isItForCheck() {
		return check;
	}
	
	public static int getCmdCounter() {
		cmd_counter++;
		return cmd_counter;
	}
	
	public Command(Node item) {
		NodeList nodeList = item.getChildNodes();
		for(int i=0; i<nodeList.getLength(); i++) {
			if(nodeList.item(i).getNodeName().equals(CmdStream.tagOpt)) {
				opts.add(nodeList.item(i).getTextContent());
			} else if(nodeList.item(i).getNodeName().equals(CmdStream.tagIn)) {
				in.add(nodeList.item(i).getTextContent());
			} else if(nodeList.item(i).getNodeName().equals(CmdStream.tagOut)) {
				NamedNodeMap nl = nodeList.item(i).getAttributes();
				if (nl!=null) {
					Node aout = nl.getNamedItem("check");
					if(aout!=null && aout.getNodeName().equals("check") &&
							aout.getTextContent().equals("true"))
						check = true;
				}
				out.add(nodeList.item(i).getTextContent());
			} else if(nodeList.item(i).getNodeName().equals(CmdStream.tagCwd)) {
				cwd = nodeList.item(i).getTextContent();
			}
		}
	}
	
	public void addOpt(String opt) {
		opts.add(opt);
	}
	
	public void addIn(String in) {
		opts.add(in);
	}
	
	public void addOut(String out) {
		opts.add(out);
	}

	public List<String> getOpts() {
		return opts;
	}
	
	public List<String> getIn() {
		return in;
	}
	
	public List<String> getOut() {
		return out;
	}

	public void write(StringBuffer sb) {
		sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagCwd+'>'+cwd+"</"+CmdStream.tagCwd+">\n");
		for(int i=0; i<in.size(); i++)
			sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagIn+'>'+in.get(i)+"</"+CmdStream.tagIn+">\n");
		for(int i=0; i<opts.size(); i++)
			sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagOpt+'>'+opts.get(i)+"</"+CmdStream.tagOpt+">\n");
		for(int i=0; i<out.size(); i++) 
			if(check)
				sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagOut+" check=\"true\">"+out.get(i)+"</"+CmdStream.tagOut+">\n");
			else
				sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagOut+'>'+out.get(i)+"</"+CmdStream.tagOut+">\n");
	}
	
	/*public void createTree() {
		for(create)
	}*/

}
