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

import java.io.File;

import org.linuxtesting.ldv.csd.utils.Logger;
import org.w3c.dom.Node;


public class CommandCC extends Command implements Cloneable {

	public Command clone() {
	    return super.clone();
	}

	
	public CommandCC(Node item) {
		super(item);
		// TODO Auto-generated constructor stub
	}

	public CommandCC() {
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
