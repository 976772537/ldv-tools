package com.iceberg.generators.cmdstream;

import org.w3c.dom.Node;

public class CommandCC extends Command {

	public CommandCC(Node item) {
		super(item);
		// TODO Auto-generated constructor stub
	}

	public void write(StringBuffer sb) {
		sb.append(CmdStream.shift+'<'+CmdStream.tagCc+" id=\""+Command.getCmdCounter()+"\">\n");
		super.write(sb);
		sb.append(CmdStream.shift+"</"+CmdStream.tagCc+">\n");
	}

}
