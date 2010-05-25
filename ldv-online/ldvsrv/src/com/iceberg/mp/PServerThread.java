package com.iceberg.mp;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

import java.net.Socket;

public class PServerThread extends Thread {

        private Socket socket;
        private PServerProto protocol;

        public PServerThread(Socket socket, PServerProto protocol) {
                this.socket = socket;
                this.protocol = protocol;
        }

        public void run() {
/*                BufferedInputStream in = null;
                BufferedOutputStream out = null;
                ObjectInputStream ois = null;
                ObjectOutputStream oos = null;*/
                try {
                        /*in = new BufferedInputStream( socket.getInputStream());
                        out = new BufferedOutputStream( socket.getOutputStream());
                        oos = new ObjectOutputStream(out);
                        try {
                            ois = new ObjectInputStream(in);
                            Message msg = (Message)ois.readObject();
                            if(msg.getText().equals(PProtocol.sGetTask)) {
                            	
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
                        
                        
                        //protocol.Communicate(in, out);
                } finally {
                       /* try {
                                in.close();
                                out.close();
                                //socket.close();
                        } catch (IOException e) {
                        }*/
                }
        }

}
