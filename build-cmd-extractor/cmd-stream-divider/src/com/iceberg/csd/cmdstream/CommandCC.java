package com.iceberg.csd.cmdstream;

import java.io.File;

import org.w3c.dom.Node;

import com.iceberg.csd.utils.Logger;

public class CommandCC extends Command {

	public CommandCC(Node item) {
		super(item);
		// TODO Auto-generated constructor stub
	}

	public void write(StringBuffer sb) {
		sb.append(CmdStream.shift+'<'+CmdStream.tagCc+" id=\""+Id+"\">\n");
		super.write(sb);
		sb.append(CmdStream.shift+"</"+CmdStream.tagCc+">\n");
	}
	
	public boolean relocateCommand(String basedir,String newDriverDirString, boolean iscopy) {
		if(!iscopy) {
			for(int i=0; i<in.size(); i++) {
				File file = new File(in.get(i));
				String parentDir = file.getParent();
				if(parentDir==null) {
					Logger.err("Parent dir is null.");
					return false;
				}
				Opt copt = new Opt("-I"+parentDir);
				getOpts().add(copt);
			}
		}
		return super.relocateCommand(basedir,newDriverDirString,iscopy);
	}

	
	
}
