package com.iceberg.mp;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

public class PClientProto extends PProtocol {

        public void Communicate(BufferedInputStream in, BufferedOutputStream out) {
                try {
                        oos = new ObjectOutputStream(out);
                } catch (IOException e) {
                        System.err.println("MASTER: IOException");
                        return;
                }

                try {
                        Message msgGetTask = new Message(sGetTask);
                        oos.writeObject(msgGetTask);
                        oos.flush();
                        ois = new ObjectInputStream(in);
                        MessageGetTaskOk msg = (MessageGetTaskOk)ois.readObject();
                        if(msg.getText().equals(sGetTaskOk)) {
                                String driver = msg.getDriver();
                                System.out.println("Task successfully getting");
                                System.out.println(driver);
                        }
                } catch (ClassNotFoundException e) {
                        System.err.println("MASTER: IOException");
                        e.printStackTrace();
                } catch (IOException e) {
                		e.printStackTrace();
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
