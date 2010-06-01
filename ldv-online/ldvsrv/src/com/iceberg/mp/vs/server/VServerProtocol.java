package com.iceberg.mp.vs.server;

import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.SQLException;

import com.iceberg.mp.schelduler.Task;
import com.iceberg.mp.schelduler.VerClient;
import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.server.protocol.ServerProtocolInterface;
import com.iceberg.mp.vs.VProtocol;
import com.iceberg.mp.vs.vsm.VSM;
import com.iceberg.mp.vs.vsm.VSMClient;


public class VServerProtocol extends VProtocol implements ServerProtocolInterface {

	private static final long sleeptime = 5000;
	
	@Override
    public void communicate(ServerConfig config, InputStream in, OutputStream out) {
		ObjectInputStream ois = null;
		ObjectOutputStream oos = null;
		try {
			// wait for data, and then open ObjectInputStream, in
			// other cases ObjectInputStream receive error;
			while(in.available() == 0) {Thread.sleep(sleeptime);};
			ois = new ObjectInputStream(in);
			oos = new ObjectOutputStream(out);
            VSM msg = (VSM)ois.readObject();
            if(msg.getText().equals(sGetTask)) {
            	// проверяем есть ли такой клиент?
            	// если нет, то создаем дескриптор клиента
            	Connection conn = config.getStorageManager().getConnection();          	
            	
            	// ждем задачи - проверяем свою очередь
            	// пока в ней не появятся задачи
            	Task task = null;//new Task(null,null);
            	while(true) {
            		Thread.sleep(sleeptime);
            		break;
            	}
            	// теперь отсылаем задачу клиенту
            	// ...
            	oos.writeObject(task);
            	oos.flush();
            	// ожидаем ответа от клиента, что он успешно принял задачу
            	msg = (VSM)ois.readObject();
            	if(msg.getText().equals(sGetTaskOk))
            		// и ставим статус задачи - IN_PROGRESS
            		task.setStatus(Task.Status.TS_VERIFICATION_IN_PROGRESS);
            	else // а вот в этом случае мы не выходим ....
            		task.setStatus(Task.Status.TS_WAIT_FOR_VERIFICATION);
            	// и выходим
            }
			
		} catch (IOException e) {
			e.printStackTrace();
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			// если сон прерван - то разрываем соединение
			e.printStackTrace();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
}
