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

import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

public class Opt {
	
	List<String> attNames = new ArrayList<String>();
	List<String> attValues = new ArrayList<String>();
	String value;

	public Opt(Node node) {
		NamedNodeMap nl = node.getAttributes();
		if(nl!=null) {
			for(int i=0; i<nl.getLength(); i++) {
				String attName = nl.item(i).getNodeName();
				if(attName!=null) attNames.add(attName);
				String attValue = nl.item(i).getTextContent();
				if(attValue!=null) attValues.add(attValue);
			}
		}
		value = node.getTextContent();
	}

	public Opt(String content) {
		value = content;
	}

	public String getValue() {
		return value;
	}

	public String getAttsString() {
		if(attNames.size()==0) return "";
		StringBuffer sb = new StringBuffer(" ");
		for(int i=0; i<attNames.size(); i++)
			sb.append(attNames.get(i)+"=\""+attValues.get(i)+"\"");
		return sb.toString();
	}
	
}
