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

import com.iceberg.mp.RunLDV;
import com.iceberg.mp.schelduler.Scheduler;
import com.iceberg.mp.schelduler.Task;
import com.iceberg.mp.server.protocol.ServerProtocolInterface;
import com.iceberg.mp.ws.wsm.WSM;
import com.iceberg.mp.ws.wsm.WSMFactory;
import com.iceberg.mp.ws.wsm.WSMWsmtoldvsTaskPutRequest;

public class WServerProtocol implements ServerProtocolInterface {
	
	public static NodeList parseMsg(InputStream in) throws SAXException, IOException, ParserConfigurationException {
		DocumentBuilder xml = DocumentBuilderFactory.newInstance().newDocumentBuilder();
		RunLDV.log.info("Client msg size: "+in.available());
		byte[] content = new byte[in.available()];
		in.read(content);
		RunLDV.log.info("Client msg contains: "+(new String(content)));
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
	
	public void communicate(Scheduler scheduler, InputStream in, OutputStream out) {
		try {			
			RunLDV.log.info("WS: Start client protocol.");
			// Get an client msg
			WSM wsmMsg = getMsg(in);
			if(wsmMsg.getType().equals(WSMFactory.WSM_WSTOLDVS_TASK_PUT_REQUEST)) {
				RunLDV.log.info("WS: Client msg type: " + WSMFactory.WSM_WSTOLDVS_TASK_PUT_REQUEST);
				WSM wsmReponse = WSMFactory.create(WSMFactory.WSM_LDVSTOWS_TASK_DESCR_RESPONSE);
				RunLDV.log.info("WS: Send to client msg: " + WSMFactory.WSM_LDVSTOWS_TASK_DESCR_RESPONSE);
				sendMsg(out, wsmReponse);
				// read binary data
				RunLDV.log.info("WS: Read binary data from client.");
				byte[] block = new byte[((WSMWsmtoldvsTaskPutRequest)wsmMsg).getSourceLen()];
				RunLDV.log.info("WS: Full size: "+block.length);
				in.read(block);
				RunLDV.log.info("WS: Create task.");
				Task task = new Task(block,(WSMWsmtoldvsTaskPutRequest)wsmMsg);
				RunLDV.log.info("WS: Put task to task-pull.");
				scheduler.putTask(task);
				// send response
				RunLDV.log.info("WS: Send to client msg: " + WSMFactory.WSM_LDVSTOWS_TASK_PUT_RESPONSE);
				wsmReponse = WSMFactory.create(WSMFactory.WSM_LDVSTOWS_TASK_PUT_RESPONSE);
				sendMsg(out, wsmReponse);
				RunLDV.log.info("WS: Ok - task transaction finished !");
			} else {
				RunLDV.log.info("WS: Unknown client msg type: " + wsmMsg.getType());
			}
		// посмотреть порядок Exceptiono
		} catch(IOException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		} finally {
			RunLDV.log.info("WS: End client protocol.");
		}
	}

}
