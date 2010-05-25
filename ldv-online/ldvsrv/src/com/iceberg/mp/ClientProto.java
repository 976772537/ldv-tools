package com.iceberg.mp;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;

public class ClientProto extends Protocol {
	
	public void Communicate(BufferedInputStream in, BufferedOutputStream out) {
		try { 
			out.write(sGetTaskRequest);
			out.flush();
			int responseType = in.read();
			if(responseType == sGetTaskResponse) {
				System.out.println("Response ok");
			}
		} catch(IOException e) {
			return;	
		} 
	}
}
