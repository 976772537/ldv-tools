/*
 * Copyright (C) 2010-2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.linuxtesting.ldv.csd.cmdstream;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.linuxtesting.ldv.csd.FSOperationBase;
import org.linuxtesting.ldv.csd.utils.Logger;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;


public class Command implements Cloneable {
	private List<Opt> opts = new ArrayList<Opt>();
	private List<Command> inObj = new ArrayList<Command>();
	protected List<String> in = new ArrayList<String>();
	protected List<String> out = new ArrayList<String>();
	private String cwd = null;;
	
	
	
	public void setOpts(List<Opt> opts) {
		this.opts = opts;
	}

	public void setInObj(List<Command> inObj) {
		this.inObj = inObj;
	}

	public void setIn(List<String> in) {
		this.in = in;
	}

	public void setOut(List<String> out) {
		this.out = out;
	}

	public void setCwd(String cwd) {
		this.cwd = cwd;
	}

	public Command() {
	}
	
	public Command clone() {
	    //shallow copy
	    try {
	      Command clonedCmd = (Command) super.clone();
	      clonedCmd.setCwd(new String(this.cwd));

	  	  List<String> c_in = new ArrayList<String>();
	  	  for(int i=0; i<in.size(); i++)
	  		  c_in.add(new String(in.get(i)));
	  	  in = c_in;
	  	  
	  	  List<String> c_out = new ArrayList<String>();
	  	  for(int i=0; i<out.size(); i++)
	  		  c_out.add(new String(out.get(i)));
	  	  out = c_out;
	      
	      return clonedCmd;
	    } catch (CloneNotSupportedException e) {
	      return null;
	    }
	}
	
	
	protected static int cmd_counter = 0;
	
	protected int Id;
	
	private boolean check = false;

	private boolean prepared = false;

	private String restrict;
	
	public void setPrepared() {
		this.prepared = true;
	}

	public boolean isPrepared() {
		return prepared;
	}

	// TODO add restrict
	public String getRestrict() {
		return restrict;
	}
	
	public boolean isItForCheck() {
		return check;
	}
	
	public static int getCmdCounter() {
		cmd_counter++;
		return cmd_counter;
	}
	
	public Command(Node item) {
		NamedNodeMap nlid = item.getAttributes();
		if (nlid!=null) {
			Node aout = nlid.getNamedItem("id");
			Id = Integer.parseInt(aout.getTextContent());
		}
		NodeList nodeList = item.getChildNodes();
		for(int i=0; i<nodeList.getLength(); i++) {
			if(nodeList.item(i).getNodeName().equals(CmdStream.tagOpt)) {
				Opt copt = new Opt(nodeList.item(i));
				opts.add(copt);
			} else if(nodeList.item(i).getNodeName().equals(CmdStream.tagIn)) {
				NamedNodeMap nl = nodeList.item(i).getAttributes();
				if (nl!=null) {
					Node aout = nl.getNamedItem("restrict");
					if(aout!=null && aout.getNodeName().equals("restrict") &&
							aout.getTextContent().equals("main"))
						restrict = aout.getTextContent();
				}
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
		Opt copt = new Opt(opt);
		opts.add(copt);
	}
	
	public void addIn(String in) {
		this.in.add(in);
	}
	
	public void addObjIn(Command in) {
		inObj.add(in);
	}

	
	public void addOut(String out) {
		this.out.add(out);
	}
	
	public List<Opt> getOpts() {
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
			if(restrict == null)
				sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagIn+'>'+in.get(i)+"</"+CmdStream.tagIn+">\n");
			else
				sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagIn+" restrict=\""+restrict+"\">"+in.get(i)+"</"+CmdStream.tagIn+">\n");					
		for(int i=0; i<opts.size(); i++) {
			// Attention!  Monkey code!
			// Instead of using proper XML printing we escape offensive string in bug #604.
			// Because this whole mess should be rewritten...
			String optionValue = opts.get(i).getValue();
			optionValue = optionValue.replaceAll("&", "&amp;");
			optionValue = optionValue.replaceAll("<", "&lt;");
			optionValue = optionValue.replaceAll(">", "&gt;");
			sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagOpt+opts.get(i).getAttsString()+'>'+optionValue+"</"+CmdStream.tagOpt+">\n");
		}
		for(int i=0; i<out.size(); i++) 
			if(check)
				sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagOut+" check=\"true\">"+out.get(i)+"</"+CmdStream.tagOut+">\n");
			else
				sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagOut+'>'+out.get(i)+"</"+CmdStream.tagOut+">\n");
	}

	public void generate() throws IOException {
		// TODO Auto-generated method stub
		
	}

	public boolean isCheck() {
		return check;
	}
	
	public void setCheck() {
		check = true;
	}

	public List<Command> getObjIn() {
		return inObj;
	}

	public String getCwd() {
		return cwd;
	}

	public boolean relocateCommand(String basedir, String newDriverDirString, boolean iscopy) {
		if(relocateFileList(basedir, newDriverDirString, in,iscopy) &&
				relocateFileList(basedir, newDriverDirString, out,iscopy))
			return true;
		return false;
	}
	
	private boolean relocateFileList(String basedir, String newDriverDirString, List<String> strList, boolean iscopy) {
		for(int i=0; i<strList.size(); i++) {
			String newFilePlaceString = strList.get(i).replace(basedir, newDriverDirString);
			File newFilePlace = new File(newFilePlaceString);
			String parentDirString =  newFilePlace.getParent();
			File parentDir = new File(parentDirString);
			if(!iscopy && !parentDir.exists() && !parentDir.mkdirs()) {
				Logger.err("Can't create dir for in file.");
				return false;
			}
			File infile = new File(strList.get(i));
			if(!iscopy && infile.exists() && !FSOperationBase.CopyFile(in.get(i), newFilePlaceString))
				return false;
			strList.set(i,newFilePlaceString);
		}
		return true;
	}

	public int getId() {
		return Id;
	}

	public void setId(Integer id) {
		this.Id = id;
	}
	
	
}
