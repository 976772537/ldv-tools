package org.linuxtesting.ldv.online.vs.client;

import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.net.Socket;

import org.linuxtesting.ldv.online.Logger;
import org.linuxtesting.ldv.online.schelduler.MTask;
import org.linuxtesting.ldv.online.server.ClientConfig;
import org.linuxtesting.ldv.online.vs.VProtocol;
import org.linuxtesting.ldv.online.vs.vsm.VSM;
import org.linuxtesting.ldv.online.vs.vsm.VSMClientGetTask;
import org.linuxtesting.ldv.online.vs.vsm.VSMClientGetTaskOk;
import org.linuxtesting.ldv.online.vs.vsm.VSMClientSendResults;

public class VClientProtocol {
	
		public static enum Status {
			VS_WAIT_FOR_TASK,
			VS_HAVE_TASKS,
		}
	
		private ClientConfig config;
		
		public VClientProtocol(ClientConfig config) {
			this.config = config;
		}
	
        public MTask VSGetTask() {
    			Socket socket = null;
    			InputStream in  = null;
    			OutputStream out = null;
        		ObjectInputStream ois = null;
        		ObjectOutputStream oos = null;
        		MTask task = null;
                try {
        				socket = new Socket(config.getServerName(), config.getServerPort());
        				in  = socket.getInputStream();
        				out = socket.getOutputStream();
                		oos = new ObjectOutputStream(out);
                		// после подключения говорим серверу о том, что готовы взять задачу
                        VSMClientGetTask msgGetTask = new VSMClientGetTask(socket.getInetAddress()+"");
                        oos.writeObject(msgGetTask);
                        oos.flush();
                        // читаем задачу
                        ois = new ObjectInputStream(in);
                        // принимаем задачу
                        task = (MTask)ois.readObject();
                        // говорим что успешно прняли
                        VSMClientGetTaskOk msgGetTaskOk = new VSMClientGetTaskOk(socket.getInetAddress()+"");
                        oos.writeObject(msgGetTaskOk);
                        oos.flush();
                } catch (ClassNotFoundException e) {
                		Logger.err("VCLIENT: ClassNotFoundException");
                        e.printStackTrace();
                } catch (IOException e) {
                		Logger.err("VCLIENT: Can't connect to server. Is it really running?");
                		e.printStackTrace();
                } finally {
                		try {
							// There is a path where in may be null, so check it.
							if (in != null)
								in.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
            			try {
							if (out != null)
								out.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
                    	try {
							if (ois != null)
								ois.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
                    	try {
							if (oos != null)
								oos.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
                        try {
							if (socket != null)
								socket.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
                }
                return task;
        }

        public boolean VSSendResults(boolean result, int id) {
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
            		//1. в случае любой ошибки возвращаем FAILED серверу
            		VSMClientSendResults msgSendResults =  new VSMClientSendResults(socket.getInetAddress()+"", 
            				id, result ? MTask.Status.TS_VERIFICATION_FINISHED+"" : MTask.Status.TS_VERIFICATION_FAILED+"");
            		// после подключения возвращаем серверу результаты
                    oos.writeObject(msgSendResults);
                    oos.flush();
                    // читаем ответ
                	//Logger.trace("Check msg size: "+ in.available());
                    ois = new ObjectInputStream(in);
                    VSM msgResponse = (VSM)ois.readObject();
                    if(msgResponse.getText().equals(VProtocol.sSendResultsOk)) {
                    	Logger.info("Send results - ok");
                    	return true;
                    } else if(msgResponse.getText().equals(VProtocol.sSendResultsFailed)) {
                    	Logger.err("Failed to sending results");
                    } else {
                    	Logger.err("Unknown response....!");
                    }
                    // говорим что успешно прняли
            } catch (ClassNotFoundException e) {
                    Logger.err("MASTER: IOException");
                    e.printStackTrace();
            } catch (IOException e) {
            		e.printStackTrace();
            		Logger.err("MASTER: IOException");
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
