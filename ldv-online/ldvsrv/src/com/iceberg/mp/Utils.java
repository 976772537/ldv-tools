package com.iceberg.mp;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;

public class Utils {
	
	public static String readFile(String filename) {
		String tmp;
		StringBuffer buffer = new StringBuffer();
		BufferedReader fin = null;
		try {
			fin = new BufferedReader(new FileReader(filename));
			while ((tmp = fin.readLine()) != null)
				buffer.append(tmp + "\n");
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				fin.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		return buffer.toString();
	}
	
}
