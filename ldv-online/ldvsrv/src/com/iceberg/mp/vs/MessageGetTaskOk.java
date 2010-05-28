package com.iceberg.mp.vs;

import com.iceberg.mp.Task;
import com.iceberg.mp.Utils;

public class MessageGetTaskOk extends Message {

        private static final long serialVersionUID = 1L;

        private String driver;

        public MessageGetTaskOk(Task task) {
                super(VProtocol.sGetTaskOk);
                driver = Utils.readFile("/home/almer/projects/NC/build.xml");
        }

        public String getDriver() {
                return driver;
        }

}
