package org.linuxtesting.ldv.online.server;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class Config {

	private String serverName;
	protected int serverPort;
	
	public static Map<String,String> readParameters(String filename) {
		Map<String,String> paramMap = new HashMap<String, String>();
		BufferedReader fin = null;
		String tmp = null;
		try {
			fin = new BufferedReader(new FileReader(filename));
			while ((tmp = fin.readLine()) != null) {
				if(tmp.length()>0 && tmp.charAt(0)!='#')  {
					int divIndex = tmp.indexOf('=');
					String paramName = tmp.substring(0, divIndex);
					String paramValue = tmp.substring(divIndex+1, tmp.length());
					System.out.println("OPTIONS: " + paramName + ", " +  paramValue);
					paramMap.put(paramName,paramValue);
				}
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				fin.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return paramMap;
	}

	public Config(Map<String,String> params, ServerThreadEnum serverType) {
		this.serverName = params.get("LDVServerAddress");
		this.serverPort = Integer.valueOf(params.get(serverType+"Port"));
	}
	
	public String getServerName() {
		return serverName;
	}
	
	public int getServerPort() {
		return serverPort;
	}
	
}
