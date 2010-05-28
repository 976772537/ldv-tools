package com.iceberg.mp.vs;

import java.net.Socket;

public class VServerThread extends Thread {

        private Socket socket;
        private VServerProto protocol;

        public VServerThread(Socket socket, VServerProto protocol) {
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
