package com.iceberg.mp;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

public class PClientProto extends PProtocol {

        public void Communicate(BufferedInputStream in, BufferedOutputStream out) {
        		try {
					ObjectInputStream ois = new ObjectInputStream(in);
					
				} catch (IOException e) {
					e.printStackTrace();
				}
                /*try {
                        oos = new ObjectOutputStream(out);
                } catch (IOException e) {
                        System.err.println("MASTER: IOException");
                        return;
                }

                try {
                		// после подключения говорим серверу о том, что готовы взять задачу
                        Message msgGetTask = new Message(sGetTask);
                        oos.writeObject(msgGetTask);
                        oos.flush();
                        // читаем задачу
                        ois = new ObjectInputStream(in);
                        // принимаем задачу
                        MessageGetTaskOk msg = (MessageGetTaskOk)ois.readObject();
                        // говорим что успешно прняли
                        if(msg.getText().equals(sGetTaskOk)) {
                                String driver = msg.getDriver();
                                System.out.println("Task successfully getting");
                                System.out.println(driver);
                        }
                        // 1. начинаем верификацию, не отключаясь
                        // (список клиентов находится в пуле на сервере постоянно)
                        // 2. обрабатываем задачу
                        // 3. обработав, посылаем пакет, что мол задача обработана
                        // 4. на сервер присылает ответ, что он все понял
                        // 5. отправляем запрос на новую задачу - на основе этого запроса
                        //    сервер переключит текущий клиент в пуле клиентов в состояние 
                       
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
                }*/
        }
}
