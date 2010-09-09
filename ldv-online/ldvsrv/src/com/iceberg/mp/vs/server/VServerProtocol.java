package com.iceberg.mp.vs.server;

import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;

import com.iceberg.mp.Logger;
import com.iceberg.mp.db.SQLRequests;
import com.iceberg.mp.schelduler.MTask;
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
            	Logger.debug("Wait for task...");
            	//try to get task (It may be empty task with 
            	// service message - "no tasks")
            	MTask mtask = SQLRequests.getTaskForClientW((VSMClient)msg,config);
            	/* Print info about client... */
            	VSMClient vsmClient = (VSMClient)msg;
            	Logger.debug("Number of client processors: "+vsmClient.getClientInfo().getAvailableProcessors()+".");
            	Logger.debug("Free memory for client JVM: "+vsmClient.getClientInfo().getFreeMemoryJVM()+" bytes.");
            	Logger.debug("Max of client JVM memory: "+vsmClient.getClientInfo().getMaxMemoryJVM()+" bytes.");
            	Logger.debug("Total JVM memory on client: "+vsmClient.getClientInfo().getTotalMemoryJVM()+" bytes.");
            	
            	//while((	mtask = SQLRequests.getTaskForClientW((VSMClient)msg,config))==null)
            		//Thread.sleep(sleeptime);
            	Logger.debug("Ok - sending task to verification client");
            	oos.writeObject(mtask);
            	oos.flush();
            	Logger.debug("Wait for response - \"get task ok\"");
            	/* Wait for client response successfull status - get task ok. */
            	msg = (VSM)ois.readObject();
            	if(((VSMClient)msg).getName().equals(sGetTaskOk)) {
            		Logger.info("Request \"get task \" - ok");
            	} else { // in this case return status to task - wait_for_verification ....
            		Logger.info("Request \"get task \" - failed");
            		SQLRequests.setSplittedTaskStatusW_WAIT_FOR_VERIFIFCATION(config,mtask);
            	}
            	mtask = null;
            	// and now exit
            } else if(msg.getText().equals(sSendResults)) {
            	Logger.info("Start \"send results request\"");
            	Logger.debug("Get client descriptor.");
            	/* Upload results in database... */
            	VSMClientSendResults resultsMsg = (VSMClientSendResults)msg;
            	//SQLRequests.uploadResults(msg);
            	if(SQLRequests.setSplittedTaskResultW(config,resultsMsg)) {
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
			e.printStackTrace();
		} catch (Throwable e) {
			e.printStackTrace();
		} finally {
			try {
				oos.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
			try {
				ois.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}
}
