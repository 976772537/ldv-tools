package com.iceberg.mp.vs.client;

import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.net.Socket;

import com.iceberg.mp.schelduler.Task;
import com.iceberg.mp.server.ClientConfig;
import com.iceberg.mp.vs.VProtocol;
import com.iceberg.mp.vs.vsm.VSM;
import com.iceberg.mp.vs.vsm.VSMClientGetTask;
import com.iceberg.mp.vs.vsm.VSMClientGetTaskOk;
import com.iceberg.mp.vs.vsm.VSMClientSendResults;

public class VClientProtocol {
	
		private ClientConfig config;
		
		public VClientProtocol(ClientConfig config) {
			this.config = config;
		}
	
        public Task VSGetTask() {
    			Socket socket = null;
    			InputStream in  = null;
    			OutputStream out = null;
        		ObjectInputStream ois = null;
        		ObjectOutputStream oos = null;
        		Task task = null;
                try {
        				socket = new Socket(config.getServerName(), config.getServerPort());
        				in  = socket.getInputStream();
        				out = socket.getOutputStream();
                		oos = new ObjectOutputStream(out);
                		// после подключения говорим серверу о том, что готовы взять задачу
                        VSMClientGetTask msgGetTask = new VSMClientGetTask(config.getCientName());
                        oos.writeObject(msgGetTask);
                        oos.flush();
                        // читаем задачу
                        ois = new ObjectInputStream(in);
                        // принимаем задачу
                        task = (Task)ois.readObject();
                        // говорим что успешно прняли
                        VSMClientGetTaskOk msgGetTaskOk = new VSMClientGetTaskOk(config.getCientName());
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
							in.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
            			try {
							out.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
                    	try {
							ois.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
                    	try {
							oos.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
                        try {
							socket.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
                }
                return task;
        }

        public boolean VSSendResults() {
			Socket socket = null;
			InputStream in  = null;
			OutputStream out = null;
    		ObjectInputStream ois = null;
    		ObjectOutputStream oos = null;
            try {
    				socket = new Socket(config.getServerName(), config.getServerPort());
    				in  = socket.getInputStream();
    				out = socket.getOutputStream();
            		oos = new ObjectOutputStream(out);
            		// после подключения возвращаем серверу результаты
                    VSMClientSendResults msgSendResults = new VSMClientSendResults(config.getCientName());
                    oos.writeObject(msgSendResults);
                    oos.flush();
                    // читаем ответ
                    ois = new ObjectInputStream(in);
                    VSM msgResponse = (VSM)ois.readObject();
                    if(msgResponse.getText().equals(VProtocol.sSendResultsOk)) {
                    	System.err.println("Send results - ok");
                    	return true;
                    } else if(msgResponse.getText().equals(VProtocol.sSendResultsFailed)) {
                    	System.err.println("Failed to sending results");
                    } else {
                    	System.err.println("Unknown response....!");
                    }
                    // говорим что успешно прняли
            } catch (ClassNotFoundException e) {
                    System.err.println("MASTER: IOException");
                    e.printStackTrace();
            } catch (IOException e) {
            		e.printStackTrace();
                    System.err.println("MASTER: IOException");
            } finally {
            		try {
						in.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
        			try {
						out.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
                	try {
						ois.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
                	try {
						oos.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
                    try {
						socket.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
            }
            return false;
    }
}
