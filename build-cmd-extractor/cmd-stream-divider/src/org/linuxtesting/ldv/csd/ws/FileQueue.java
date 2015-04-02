/*
 * Copyright (C) 2014-2015
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

import java.io.File;
import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.util.Scanner;
import java.nio.channels.FileChannel;
//import java.nio.channels.FileLock;
import java.nio.charset.Charset;

import javax.naming.NamingException;
import javax.xml.parsers.ParserConfigurationException;

import org.linuxtesting.ldv.csd.cmdstream.CmdStream;
import org.linuxtesting.ldv.csd.utils.Logger;
import org.xml.sax.SAXException;

public class FileQueue {

	private String index_path;
	private String vo_index;
	private CmdStream cmdstream;
	private boolean still_building;

	/*
	 * Constructor
	 */
	public FileQueue(String vo_index, String index, CmdStream ready_cmdstream) {
		this.vo_index = vo_index;
		this.index_path = index;
		this.still_building = true;
		this.cmdstream = ready_cmdstream;
	}
	
	/*
	 * Parse command message and process according to its type
	 */
	private boolean process_message(String msg) {
		// Determine command type and data
		String [] parts = msg.split("::");
		String type;
		String data = "";
		if (parts.length == 1) {
			type = parts[0];
		} 
		else if (parts.length == 2) {
			type = parts[0];
			data = parts[1];
		} 
		else {
			return false;
		}
		
		Logger.trace("Got '" + type + "' message: " + data);
		if(type.equals("ldm")) {
			// Mark LDM messages
			Logger.trace("Mark coammnd " + data);
			cmdstream.marker(data);
		}
		else if (type.equals("bcmd")) {
			Logger.trace("Read XML command from a file " + data);
			try {
				String xmlcommand = new Scanner(new File(data)).useDelimiter("\\A").next();
				Logger.trace("Got the following command \n" + xmlcommand);
				try {
					cmdstream.processCmdStream(xmlcommand);
				} catch (NamingException e) {
					e.printStackTrace();
					return false;
				} catch (ParserConfigurationException e) {
					e.printStackTrace();
					return false;
				} catch (SAXException e) {
					e.printStackTrace();
					return false;
				} catch (IOException e) {
					e.printStackTrace();
					return false;
				}
			} catch (IOException e) {
				e.printStackTrace();
				return false;
			}			
		}
		else if (type.equals("end")) {
			this.still_building = false;
			Logger.trace("Stub end");
		}
		else {
			Logger.err("Unknown message type: " + type);
		}
		
		return true;
	}
	
	/*
	 * Update index file (do not support concurrency)
	 */
	private boolean post_vo_message(String type, String value) {
		String msg = type + "::" + value;
		Logger.trace("Going to print message " + msg);
		Logger.trace("To the file " + this.vo_index);
		PrintWriter out;
		try {
			out = new PrintWriter(new BufferedWriter(new FileWriter(vo_index, true)));
			out.println(msg);
			out.close();
			Logger.trace("File was successfully appended");
			return true;
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		}
	}
	
	/*
	 * Check queue with build commands to divide them into verification objects
	 */
	public boolean wait_on_queue() {
		Logger.norm("Start CSD waiting routine ...");
		Logger.norm("Inspect file : " + this.index_path);
	
		// Initialize starting reading position
		long position = 0;
		String previous_chunk = "";
		
		// Read index file in a fixed periods
		while (this.still_building || !cmdstream.isEmpty()) {
			//FileLock lock = null;
			byte [] summary = {};
			
			// Read in buffer as much as possible
			Logger.trace("Init read iteration");
			RandomAccessFile aFile;
			try {
				// Open
				aFile = new RandomAccessFile
						(this.index_path, "rw");
				FileChannel inChannel = aFile.getChannel();
							
				// Go to position
				inChannel.position(position);
				//lock = inChannel.lock();
				
				// Read with help of a buffer
				ByteBuffer buffer = ByteBuffer.allocate(1024);
				int num = inChannel.read(buffer);
				while(num != -1)
				{
					// Reset buffer position
					buffer.rewind();
					
					// Read new data to the summary byte array
					byte recent[] = buffer.array();
					ByteArrayOutputStream outputStream = new ByteArrayOutputStream( );
					outputStream.write( summary );
					outputStream.write( recent, 0, num);
					byte result[] = outputStream.toByteArray();
					summary = result;
				  
					// Reset buffer position
					buffer.clear();
					
					// Read more
					num = inChannel.read(buffer);
				}
				
				// Save current position
				position = inChannel.position();
								
				// Close file
				//lock.release();
				inChannel.close();
				aFile.close();	        
			} catch (FileNotFoundException e) {
				e.printStackTrace();
				return false;
			} catch (IOException e) {
				e.printStackTrace();
				return false;
			}
					
			// Append data
			Logger.trace("Check what we have read");
			if(summary.length > 0) {
				String chunk = previous_chunk + (new String( summary, Charset.forName("UTF-8")));
				String [] messages = chunk.split("\\n");
				int max;
				
				if(chunk.endsWith("\n")) {				
					previous_chunk = "";
					max = messages.length;
				}
				else {
					previous_chunk = messages[messages.length -1];
					max = messages.length - 1;
				}
				
				// Process each line separately
				Logger.trace("Grab " + max + " messages");
				for(int idx = 0; idx < max; idx++ ) {
					if(!process_message(messages[idx])) {
						Logger.err("Incorrect message format: " + messages[idx]);
						return false;
					}
				}
			}			
			
			// If any commands are ready, then put it for other components
			if(!cmdstream.isEmpty()) {
				while(!cmdstream.isEmpty()) {
					// Fetch command from the stream
					Logger.norm("Going to save verification object...");
					String command = cmdstream.getNextCommand();
					Logger.norm("Got verification object string\""+command+"\"...");
					
					// Put command to vo collection
					if(command.length() > 0 && !command.equals("")) {
						boolean ret = post_vo_message("vo", command);
						if(!ret) {
							return false;
						}
					}
				}
			}
			else {
				// Sleep a second	
				Logger.trace("Finalize iteration, sleep a while ...");
				try {
					Thread.sleep(1000); //1000 milliseconds.
				} catch(InterruptedException ex) {
					Thread.currentThread().interrupt();
				}
			} 			
		}
		Logger.norm("Stop monitoring queues");
		
		Logger.norm("Send message to inform that no verification objects will appear");
		return post_vo_message("end", "");
	}
}
