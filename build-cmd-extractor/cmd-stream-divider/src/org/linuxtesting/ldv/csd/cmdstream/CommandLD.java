/*
 * Copyright 2010-2012
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

import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

public class CommandLD extends Command implements Cloneable {
	
	private List<String> mains = new ArrayList<String>();
	
	public Command clone() {
	    return super.clone();
	}

	
	public CommandLD(Node item) {
		super(item);
		NodeList nodeList = item.getChildNodes();
		for(int i=0; i<nodeList.getLength(); i++) {
			if(nodeList.item(i).getNodeName().equals(CmdStream.tagMain)) {
				mains.add(nodeList.item(i).getTextContent());
			}
		}
	}
	
	public CommandLD() {
		// TODO Auto-generated constructor stub
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
