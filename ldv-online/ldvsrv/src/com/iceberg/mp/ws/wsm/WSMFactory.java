package com.iceberg.mp.ws.wsm;

import java.util.HashMap;
import java.util.Map;

import org.w3c.dom.NodeList;

public class WSMFactory {
	
	public static final String WSM_LDVSTOWS_TASK_PUT_RESPONSE = "LDVSTOWS_TASK_PUT_RESPONSE";
	public static final String WSM_LDVSTOWS_TASK_DESCR_RESPONSE = "LDVSTOWS_TASK_DESCR_RESPONSE";
	public static final String WSM_WSTOLDVS_TASK_PUT_REQUEST = "WSTOLDVS_TASK_PUT_REQUEST";
	public static final String WSM_WSTOLDVS_TASK_STATUS_GET_REQUEST = "WSTOLDVS_TASK_STATUS_GET_REQUEST";
	public static final String WSM_LDVSTOWS_TASK_STATUS_GET_RESPONSE = "LDVSTOWS_TASK_STATUS_GET_RESPONSE";
	
	protected static Map<String, Class<?>> wsmList= defaultMap(); 
	
	public static WSM create(NodeList nl) {
		String type = WSM.getType(nl);
		if(type == null) 
			return null;
		Class<?> klass = wsmList.get(type);
		if(klass == null) 
			throw new RuntimeException(" was unable to find an FuncGenerator named "+type+".");
		WSM wsm = null;
		try {
			wsm = (WSM)klass.newInstance();
			wsm.parse(nl);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return wsm;
	}
	
	public static WSM create(String type) {
		if(type == null) 
			return null;
		
		Class<?> klass = wsmList.get(type);
		if(klass == null) 
			throw new RuntimeException(" was unable to find an FuncGenerator named "+type+".");
		WSM wsm = null;
		try {
			wsm = (WSM)klass.newInstance();
			wsm.setType(type);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return wsm;
	}
	
	protected static Map<String, Class<?>> defaultMap() {
		Map<String, Class<?>> map = new HashMap<String, Class<?>>();
		map.put(WSM_WSTOLDVS_TASK_PUT_REQUEST, WSMWsmtoldvsTaskPutRequest.class);
		map.put(WSM_LDVSTOWS_TASK_DESCR_RESPONSE, WSMLdvstowsTaskDescrResponse.class);
		map.put(WSM_LDVSTOWS_TASK_PUT_RESPONSE, WSMLdvstowsTaskPutResponse.class);
		map.put(WSM_WSTOLDVS_TASK_STATUS_GET_REQUEST, WSMWstoldvsTaskStatusGetRequest.class);
		map.put(WSM_LDVSTOWS_TASK_STATUS_GET_RESPONSE, WSMLdvstowsTaskGetStatusResponse.class);
		return map;
	}
	
}
