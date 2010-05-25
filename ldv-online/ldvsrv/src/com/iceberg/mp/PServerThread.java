package com.iceberg.mp;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;

import java.net.Socket;

public class PServerThread extends Thread {

        private Socket socket;
        private PServerProto protocol;

        public PServerThread(Socket socket, PServerProto protocol) {
                this.socket = socket;
                this.protocol = protocol;
        }

        public void run() {
                BufferedInputStream in = null;
                BufferedOutputStream out = null;
                try {
                        in = new BufferedInputStream( socket.getInputStream());
                        out = new BufferedOutputStream( socket.getOutputStream());
                        protocol.Communicate(in, out);
                } catch(IOException e) {
                        System.err.println("I/O Exception.");
                } finally {
                        try {
                                in.close();
                                out.close();
                                socket.close();
                        } catch (IOException e) {
                        }
                }
        }

}
