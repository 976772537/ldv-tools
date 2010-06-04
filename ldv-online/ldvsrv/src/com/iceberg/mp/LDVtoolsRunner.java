package com.iceberg.mp;

import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.PrintWriter;

import java.lang.InterruptedException;

public class LDVtoolsRunner {
	public static void main(String[] args) throws IOException, InterruptedException {
		Runtime rt = Runtime.getRuntime();
		String[] commands = {"/bin/bash","/home/iceberg/tst"};
		//String[] envp = {"YEXPR=hello"};
		//File cmddir = new File("/home/iceberg");
		Process proc = rt.exec("/bin/bash /home/iceberg/tst");	
		
		InputStreamReader isr = new InputStreamReader(proc.getInputStream());
		BufferedReader br = new BufferedReader(isr);
		PrintWriter pw = new PrintWriter(new BufferedOutputStream(proc.getOutputStream()));
		String line = null;
		while((line = br.readLine())!=null) {
			System.out.println(line);
		}
		System.out.println("WaitFor");
		proc.waitFor();
	}
}
