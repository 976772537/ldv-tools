package com.iceberg.csd.cmdstream;

import java.io.File;

import org.w3c.dom.Node;

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
					System.out.println("csd: ERROR: Parent dir is null.");
					return false;
				}
				getOpts().add("-I"+parentDir);
			}
		}
		return super.relocateCommand(basedir,newDriverDirString,iscopy);
	}

	
	
}
