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
package org.linuxtesting.ldv.csd.ws;

import java.io.IOException;

import javax.jws.WebMethod;
import javax.jws.WebService;
import javax.naming.NamingException;
import javax.xml.parsers.ParserConfigurationException;

import org.linuxtesting.ldv.csd.cmdstream.CmdStream;
import org.linuxtesting.ldv.csd.utils.Logger;
import org.xml.sax.SAXException;

@WebService
public class CSDWebService {

	private CmdStream cmdstream;

	public CSDWebService(CmdStream cmdstream) {
		this.cmdstream = cmdstream;
	}

	@WebMethod 
	public void marker(String command) {
		cmdstream.marker(command);
	}
	
	@WebMethod
	public void sendCommand(String xmlcommand) {
		Logger.norm(" CSD sendCommand:");
		System.out.println(xmlcommand);
		try {
			cmdstream.processCmdStream(xmlcommand);
		} catch (NamingException e) {
			e.printStackTrace();
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	@WebMethod 
	public boolean isEmpty() {
		return cmdstream.isEmpty();
	}
	
	@WebMethod
	public boolean isExistsLD(String command) {
		return cmdstream.isExistsLD(command);
	}

	@WebMethod
	public String getCommand() {
		Logger.norm("Getting next...");
		String command = cmdstream.getNextCommand();
		Logger.norm("Got command \""+command+"\"...");
		return command;
	}

}
