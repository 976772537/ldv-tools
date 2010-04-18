package com.iceberg.generators.cmdstream;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.Node;

import com.iceberg.generators.MainGenerator;

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
	
	public void generate() throws IOException {
		List<Integer> idList = new ArrayList<Integer>();
		for(int i=0; i<getIn().size(); i++) {
			if(MainGenerator.deg(getIn().get(i),cmd_counter++)) {
				// and copy c-file to new driverdir if it needs
				idList.add(Id);
			}
		}
		// write object file
		FileWriter fw = new FileWriter(getOut().get(0));
		for(int i=0; i<idList.size(); i++) {
			fw.write("LDV_MAIN"+idList.get(i));
		}
		fw.close();
	}
}
