package com.iceberg.mp.ws.server;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import com.iceberg.mp.Logger;
import com.iceberg.mp.db.SQLRequests;
import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.server.protocol.ServerProtocolInterface;
import com.iceberg.mp.ws.wsm.WSM;
import com.iceberg.mp.ws.wsm.WSMFactory;
import com.iceberg.mp.ws.wsm.WSMLdvtowsResponse;
import com.iceberg.mp.ws.wsm.WSMWsmtoldvsTaskPutRequest;
import com.iceberg.mp.ws.wsm.WSMWstoldvsTaskStatusGetRequest;

public class WServerProtocol implements ServerProtocolInterface {
	
	public static NodeList parseMsg(InputStream in) throws SAXException, IOException, ParserConfigurationException {
		DocumentBuilder xml = DocumentBuilderFactory.newInstance().newDocumentBuilder();
		Logger.debug("Client msg size: "+in.available());
		byte[] content = new byte[in.available()];
		in.read(content);
		Logger.trace("Client msg contains: "+(new String(content)));
		ByteArrayInputStream bais = new ByteArrayInputStream(content);  
		Document doc = xml.parse(bais);
		return doc.getDocumentElement().getChildNodes();
	}
	
	public static WSM getMsg(InputStream in) throws SAXException, IOException, ParserConfigurationException {
		return WSMFactory.create(parseMsg(in));
	}
	
	public static void sendMsg(OutputStream out, WSM wsm) throws IOException {
		String wsmString = wsm.toWSXML();
		out.write(wsmString.getBytes());
		out.flush();
	}
	
	public void communicate(ServerConfig config, InputStream in, OutputStream out) {
		try {			
			Logger.info("WS: Start client protocol.");
			WSM wsmMsg = getMsg(in);
			if(wsmMsg.getType().equals(WSMFactory.WSM_WSTOLDVS_TASK_PUT_REQUEST)) {
				Logger.trace("WS: Client msg type: " + WSMFactory.WSM_WSTOLDVS_TASK_PUT_REQUEST);
				WSM wsmReponse = WSMFactory.create(WSMFactory.WSM_LDVSTOWS_TASK_DESCR_RESPONSE);
				Logger.trace("WS: Send to client msg: " + WSMFactory.WSM_LDVSTOWS_TASK_DESCR_RESPONSE);
				sendMsg(out, wsmReponse);
				Logger.trace("WS: Read binary data from client.");
				byte[] block = new byte[((WSMWsmtoldvsTaskPutRequest)wsmMsg).getSourceLen()];
				Logger.trace("WS: Full size: "+block.length);
				Logger.trace("WS: Put task to task-pull.");
				wsmReponse = WSMFactory.create(WSMFactory.WSM_LDVSTOWS_TASK_PUT_RESPONSE);
				if(!SQLRequests.puTaskC(config,(WSMWsmtoldvsTaskPutRequest)wsmMsg, in)) 
					((WSMLdvtowsResponse)wsmReponse).setResult("FAILED");
				Logger.trace("WS: Send to client msg: " + WSMFactory.WSM_LDVSTOWS_TASK_PUT_RESPONSE);
				sendMsg(out, wsmReponse);
				Logger.trace("WS: Ok - \"task put\"  - transaction finished !");
			} else if (wsmMsg.getType().equals(WSMFactory.WSM_WSTOLDVS_TASK_STATUS_GET_REQUEST)) {
				Logger.trace("WS: Client msg type: " + WSMFactory.WSM_WSTOLDVS_TASK_STATUS_GET_REQUEST);
				WSMWstoldvsTaskStatusGetRequest msgTSGRequest = (WSMWstoldvsTaskStatusGetRequest)wsmMsg; 
				Logger.trace("WS: Client:\""+msgTSGRequest.getUser()+"\" request status for task id: " + msgTSGRequest.getId());
				//WSM wsmReponse = WSMFactory.create(WSMFactory.WSM_LDVSTOWS_TASK_STATUS_GET_RESPONSE);				
				Logger.trace("WS: Ok - \"task status get\" transaction finished !");
			} else {
				Logger.debug("WS: Unknown client msg type: " + wsmMsg.getType());
			}
		// посмотреть порядок Exceptiono
		} catch(IOException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		} finally {
			Logger.info("WS: End client protocol.");
		}
	}

}
