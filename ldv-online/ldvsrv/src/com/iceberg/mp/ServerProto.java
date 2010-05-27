package com.iceberg.mp;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class ServerProto extends Protocol {
	
	
	
	public void Communicate(InputStream in, OutputStream out, Scheduler scheduler) {
		try { 
			System.out.println("START CLIENT CONNECTION:");
			System.out.println(in.available());
			int responseType = in.read();
			if(responseType == sGetTaskRequest) {
					StringBuffer sb = new StringBuffer();					
					while(in.available()!=0) 
						sb.append((char)in.read());
					out.write(sGetTaskFile);
					out.flush();					
					byte[] block = new byte[Task.getSizeFromString(sb.toString())];
					in.read(block);
					Task task = new Task(sb.toString(),block);
					scheduler.putTask(task);
					/*FileOutputStream fw = new FileOutputStream("/home/iceberg/ldvtest/drivers/reports_bad_out.tar.bz2");
					fw.write(task.getData());
					fw.flush();
					fw.close();*/
					// теперь говорим что задача успешно отослана
					out.write(sGetTaskResponse);
					out.flush();
					System.out.println("Task get - ok.");
			}
			System.out.println("END CLIENT CONNECTION");
		} catch(IOException e) {
			return;	
		} 
	}	

}
