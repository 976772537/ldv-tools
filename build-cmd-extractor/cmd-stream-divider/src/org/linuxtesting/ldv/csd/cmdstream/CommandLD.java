package org.linuxtesting.ldv.csd.cmdstream;

import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

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
		sb.append(CmdStream.shift+'<'+CmdStream.tagLd+" id=\""+Id+"\">\n");
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

	public boolean relocateCommand(String basedir,String newDriverDirString, boolean iscopy) {
		return super.relocateCommand(basedir,newDriverDirString, iscopy);
	}
}
