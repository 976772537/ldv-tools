package com.iceberg.mp.vs.client;

import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;

import com.iceberg.mp.schelduler.Task;
import com.iceberg.mp.vs.VProtocol;
import com.iceberg.mp.vs.vsm.VSMClientGetTask;
import com.iceberg.mp.vs.vsm.VSMClientGetTaskOk;

public class VClientProtocol extends VProtocol {

        public void communicate(String name, InputStream in, OutputStream out) {
        		ObjectInputStream ois = null;
        		ObjectOutputStream oos = null;
                try {
                		oos = new ObjectOutputStream(out);
                		// после подключения говорим серверу о том, что готовы взять задачу
                        VSMClientGetTask msgGetTask = new VSMClientGetTask(name);
                        oos.writeObject(msgGetTask);
                        oos.flush();
                        // читаем задачу
                        ois = new ObjectInputStream(in);
                        // принимаем задачу
                        Task task = (Task)ois.readObject();
                        // говорим что успешно прняли
                        VSMClientGetTaskOk msgGetTaskOk = new VSMClientGetTaskOk(name);
                        oos.writeObject(msgGetTaskOk);
                        oos.flush();
                } catch (ClassNotFoundException e) {
                        System.err.println("MASTER: IOException");
                        e.printStackTrace();
                } catch (IOException e) {
                		e.printStackTrace();
                        System.err.println("MASTER: IOException");
                } finally {
                        try {
                                oos.close();
                                ois.close();
                        } catch (IOException e) {
                                System.err.println("MASTER: IOException");
                        }
                }
        }
}
