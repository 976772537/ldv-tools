package com.iceberg.mp.vs.server;

import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;

import com.iceberg.mp.Logger;
import com.iceberg.mp.schelduler.MTask;
import com.iceberg.mp.schelduler.Task;
import com.iceberg.mp.schelduler.VerClient;
import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.server.protocol.ServerProtocolInterface;
import com.iceberg.mp.vs.VProtocol;
import com.iceberg.mp.vs.vsm.VSM;
import com.iceberg.mp.vs.vsm.VSMClient;
import com.iceberg.mp.vs.vsm.VSMClientSendResults;
import com.iceberg.mp.vs.vsm.VSMSendResultsFailed;
import com.iceberg.mp.vs.vsm.VSMSendResultsOk;


public class VServerProtocol extends VProtocol implements ServerProtocolInterface {

	private static final long sleeptime = 5000;
	
	@Override
    public void communicate(ServerConfig config, InputStream in, OutputStream out) {
		ObjectInputStream ois = null;
		ObjectOutputStream oos = null;
		try {
			while(in.available() == 0) {Thread.sleep(sleeptime);};
			ois = new ObjectInputStream(in);
			oos = new ObjectOutputStream(out);
            VSM msg = (VSM)ois.readObject();
            if(msg.getText().equals(sGetTask)) {
            	Logger.info("Start \"get task request\"");
            	// проверяем есть ли такой клиент?
            	// если нет, то создаем дескриптор клиента
            	Logger.debug("Get client descriptor.");
            	VerClient vclient = VerClient.create((VSMClient)msg,config);
            	// ждем задачи - проверяем свою очередь
            	// пока в ней не появятся задачи
            	Task task = null;//new Task(null,null);
            	Logger.debug("Thread for verification client wait for task...");
            	while((task = vclient.getTask())==null)
            		Thread.sleep(sleeptime);
            	Logger.debug("Ok - sending task to verification client");
            	// теперь отсылаем задачу клиенту
            	MTask mtask = new MTask(task);
            	oos.writeObject(mtask);
            	oos.flush();
            	mtask = null;
            	Logger.debug("Wait for response - \"get task ok\"");
            	// ожидаем ответа от клиента, что он успешно принял задачу
            	msg = (VSM)ois.readObject();
            	if(msg.getText().equals(sGetTaskOk)) {
            		// и ставим статус задачи - IN_PROGRESS
            		Logger.info("Request \"get task \" - ok");
            		task.setVerificationInProgress();
            	} else { // а вот в этом случае мы не выходим ....
            		Logger.info("Request \"get task \" - failed");
            		task.setResetVerificationInProgressStatus();
            	}
            	// и выходим
            } else if(msg.getText().equals(sSendResults)) {
            	Logger.info("Start \"send results request\"");
            	Logger.debug("Get client descriptor.");
            	VerClient vclient = VerClient.create((VSMClient)msg,config);
            	if(vclient.sendResults((VSMClientSendResults)msg)) {
            		Logger.info("Request \"send results\" - ok");
            		msg = new VSMSendResultsOk();
            	} else {
            		Logger.info("Request \"send results\" - failed");
            		msg = new VSMSendResultsFailed();
            	}
            	oos.writeObject(msg);
            	oos.flush();
            	Logger.info("Request \"send results request\" - ok");
            } else {
            	Logger.info("Unknown request fron verification client.");
            }
		} catch (IOException e) {
			e.printStackTrace();
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			// если сон прерван - то разрываем соединение
			e.printStackTrace();
		/*} catch (SQLException e) {
			e.printStackTrace();*/
		}
	}
}
