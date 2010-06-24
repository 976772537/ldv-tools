package com.iceberg.mp;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;

public class Utils {
	
	public static void runFromFile(String filename) {
		Runtime rt = Runtime.getRuntime();
		Process proc = null;
		PrintWriter pw = null;
		BufferedReader br = null;
		InputStreamReader isr = null;
		try {
			proc = rt.exec("/bin/bash "+filename);
			isr = new InputStreamReader(proc.getInputStream());
			br = new BufferedReader(isr);
			pw = new PrintWriter(new BufferedOutputStream(proc.getOutputStream()));
			String line = null;
			Logger.debug("Start translate commands from "+filename+" to /bin/bash:");
			while((line = br.readLine())!=null) {
				Logger.trace("LDV: "+line);
			}
			//System.out.println("WaitFor");
			proc.waitFor();
			proc.destroy();
			Logger.trace("End translate commands.");
		} catch (IOException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		} finally {
			pw.close();
			try {
				br.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
			try {
				isr.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}	
}
