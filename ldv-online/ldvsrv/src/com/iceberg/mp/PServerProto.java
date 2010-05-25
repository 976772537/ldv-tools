package com.iceberg.mp;

import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;

public class PServerProto extends PProtocol {

        public void Communicate(InputStream in, OutputStream out) {
                try {
                        oos = new ObjectOutputStream(out);
                } catch (IOException e) {
                        System.err.println("MASTER: IOException");
                        return;
                }
                try {
                        ois = new ObjectInputStream(in);
                        Message msg = (Message)ois.readObject();
                        if(msg.getText().equals(sGetTask)) {
                        	//1. помещаем в пулл клиентов для вер.
                        		
//                                System.out.println("Get task request");
                                // get task from task-pull or call
                                // method "getTask" in schelduler
//                                Message cmsg = new MessageGetTaskOk(null);
//                                oos.writeObject(cmsg);
//                                oos.flush();
                        }
                } catch (ClassNotFoundException e) {
                        System.err.println("MASTER: Bad message.");
                } catch (IOException e) {
                        System.err.println("MASTER: IOException");
                } finally {
                        try {
                                closeStreams();
                        } catch (IOException e) {
                                System.err.println("MASTER: IOException");
                        }
                }
        }

}
