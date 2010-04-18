package com.iceberg.generators.cmdstream;

import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import com.iceberg.FSOperationsBase;
import com.iceberg.generators.MainGenerator;

public class CommandLD extends Command{
	
	private List<String> mains = new ArrayList<String>();
	
	public CommandLD(Node item) {
		super(item);
		NodeList nodeList = item.getChildNodes();
		for(int i=0; i<nodeList.getLength(); i++) {
			if(nodeList.item(i).getNodeName().equals(CmdStream.tagMain)) {
				mains.add(nodeList.item(i).getTextContent());
			}
		}
	}
	
	public void write(StringBuffer sb) {
		sb.append(CmdStream.shift+'<'+CmdStream.tagLd+" id=\""+Command.getCmdCounter()+"\">\n");
		super.write(sb);
		for(int i=0; i<mains.size(); i++)
			sb.append(CmdStream.shift+CmdStream.shift+'<'+CmdStream.tagMain+'>'+mains.get(i)+"</"+CmdStream.tagMain+">\n");
		sb.append(CmdStream.shift+"</"+CmdStream.tagLd+">\n");
	}
	
	public void addMain(String main) {
		mains.add(main);
	}
	
	public List<String> getMains() {
		return mains;
	}
	
	public void generate() throws IOException {
		//List<String> mainList = new ArrayList<String>();
		for(int i=0; i<getIn().size(); i++) {
			// read all id for all in - files
			String buffer = FSOperationsBase.readFileCRLF(getIn().get(i));
			String[] ldvmains = buffer.split("\n");
			for(int j=0; j<ldvmains.length; j++) 
				addOpt("-D"+ldvmains[i]);
		}
		// path resolve if it needs
		
		// write object file
/*		FileWriter fw = new FileWriter(getOut().get(0));
		for(int i=0; i<idList.size(); i++) {
			fw.write("-D"+idList.get(i));
		}
		fw.close();*/
	}
}
