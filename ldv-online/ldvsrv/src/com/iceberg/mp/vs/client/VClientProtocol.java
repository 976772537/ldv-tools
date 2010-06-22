package com.iceberg.mp.vs.client;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.util.ArrayList;
import java.util.List;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import com.iceberg.mp.Logger;
import com.iceberg.mp.schelduler.MTask;
import com.iceberg.mp.server.ClientConfig;
import com.iceberg.mp.vs.VProtocol;
import com.iceberg.mp.vs.vsm.VSM;
import com.iceberg.mp.vs.vsm.VSMClientGetTask;
import com.iceberg.mp.vs.vsm.VSMClientGetTaskOk;
import com.iceberg.mp.vs.vsm.VSMClientSendResults;

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
                        VSMClientGetTask msgGetTask = new VSMClientGetTask(config.getCientName());
                        oos.writeObject(msgGetTask);
                        oos.flush();
                        // читаем задачу
                        ois = new ObjectInputStream(in);
                        // принимаем задачу
                        task = (MTask)ois.readObject();
                        // говорим что успешно прняли
                        VSMClientGetTaskOk msgGetTaskOk = new VSMClientGetTaskOk(config.getCientName());
                        oos.writeObject(msgGetTaskOk);
                        oos.flush();
                } catch (ClassNotFoundException e) {
                		Logger.err("MASTER: IOException");
                        e.printStackTrace();
                } catch (IOException e) {
                		Logger.err("MASTER: IOException");
                		e.printStackTrace();
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

        public boolean VSSendResults(String report, int id) {
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
            		//1. парсим отчет, в случае любой ошибки возвращаем FAILED серверу
            		VSMClientSendResults msgSendResults = createVSMResults(config.getCientName(),report, id);
            		// после подключения возвращаем серверу результаты
                    oos.writeObject(msgSendResults);
                    oos.flush();
                    // читаем ответ
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
        
    public static VSMClientSendResults createVSMResults(String clientName,
				String report, int id) {
    	VSMClientSendResults vsmmsg = null;
    	File reportFile = new File(report);
    	if(!reportFile.exists()) {
    		vsmmsg =  new VSMClientSendResults(clientName,null,null,null,id,"FAILED");
    		return vsmmsg;
    	}
    	InputStream is;
		try {
			is = new FileInputStream(reportFile);
		} catch (FileNotFoundException e) {
    		vsmmsg =  new VSMClientSendResults(clientName,null,null,null,id,"FAILED");
    		return vsmmsg;
		}
		DocumentBuilder xml;
		try {
			xml = DocumentBuilderFactory.newInstance().newDocumentBuilder();
			Document doc = xml.parse(is);
			// подготовим переменные
			List<Result> results = new ArrayList<Result>();
			String rresult = null;
			// и теперь распарсим наш документ
			NodeList reportNodeList = doc.getDocumentElement().getChildNodes();
			for(int i=0; i<reportNodeList.getLength(); i++) {
				if(reportNodeList.item(i).getNodeName().equals("build")) {
					NodeList buildNodeList = reportNodeList.item(i).getChildNodes();
					for(int j=0; j<buildNodeList.getLength(); j++) {
						if(buildNodeList.item(j).getNodeName().equals("status")) {
							rresult = buildNodeList.item(j).getTextContent();
							break;
						}
					}
				} else if(reportNodeList.item(i).getNodeName().equals("ld")) {
					NodeList ldNodeList = reportNodeList.item(i).getChildNodes();
					String verdict = null;
					String trace = null;
					for(int j=0; j<ldNodeList.getLength(); j++) {
						if(ldNodeList.item(j).getNodeName().equals("verdict")) 
							verdict = ldNodeList.item(j).getTextContent();
						else if(ldNodeList.item(j).getNodeName().equals("trace"))
							trace = ldNodeList.item(j).getTextContent();
					}			
					if(verdict.equals("SAFE") || verdict.equals("UNKNOWN") || verdict.equals("FAILED")) {
						Result result = new Result(verdict,null);
						results.add(result);
					} else if(verdict.equals("UNSAFE")) {
						// читаем трассу если она существует
						File traceFile = new File(trace);
						byte[] traceData = new byte[(int) traceFile.length()];
						FileInputStream fis = new FileInputStream(traceFile);
						try {
							fis.read(traceData);
						} catch (IOException e22) {
							e22.printStackTrace();
						}
						fis.close();
						Result result = new Result(verdict,traceData);
						results.add(result);						
					}
				}
			}
			// если "build/status"!=OK, то
			if(!rresult.equals("OK")) {
				vsmmsg =  new VSMClientSendResults(clientName,null,null,null,id,"FAILED");
			} else {
				// если есть только SAFE, то результат SAFE
				// если есть хотябы один UNSAFE, то общий результат UNSAFE
				// если есть хотябы один UNKNOWN, и нет UNSAFE, то результат UNKNOWN
				rresult = "SAFE";
				for(Result result: results) {
					if(result.getRresult().equals("UNSAFE")) {
						rresult = "UNSAFE";
						break;
					} else if(result.getRresult().equals("UNKNOWN")) {
						rresult = "UNKNOWN";
					}
				}
				// преобразуем наш список в массив
				Object[] array = results.toArray();
				Result[] oresults = new Result[array.length]; 
				for(int i=0; i<array.length; i++) oresults[i]=(Result)array[i];
				vsmmsg = new VSMClientSendResults(clientName,rresult,null,oresults ,id,"OK");
			}
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
    		vsmmsg =  new VSMClientSendResults(clientName,null,null,null,id,"FAILED");
		} catch (SAXException e) {
			// TODO Auto-generated catch block
			vsmmsg =  new VSMClientSendResults(clientName,null,null,null,id,"FAILED");
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			vsmmsg =  new VSMClientSendResults(clientName,null,null,null,id,"FAILED");
			e.printStackTrace();
		} finally {
			try {
				is.close();
			} catch (IOException e1) {
				e1.printStackTrace();
			}			
		}
		return vsmmsg;
	}

}
