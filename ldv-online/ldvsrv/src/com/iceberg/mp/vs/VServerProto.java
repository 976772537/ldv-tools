package com.iceberg.mp.vs;

import java.io.InputStream;
import java.io.OutputStream;

public class VServerProto extends VProtocol {

        public void Communicate(InputStream in, OutputStream out) {
          /*      try {
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
                }*/
        }

}
