package com.iceberg.mp;

public class MessageGetTaskOk extends Message {

        private static final long serialVersionUID = 1L;

        private String driver;

        public MessageGetTaskOk(Task task) {
                super(PProtocol.sGetTaskOk);
                driver = Utils.readFile("/home/almer/projects/NC/build.xml");
        }

        public String getDriver() {
                return driver;
        }

}
