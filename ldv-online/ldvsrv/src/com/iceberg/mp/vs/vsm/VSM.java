package com.iceberg.mp.vs.vsm;

import java.io.Serializable;

public class VSM implements Serializable {

        private static final long serialVersionUID = 1L;
        private String text;

        public VSM(String text) {
                this.text = text;
        }

        public String getText() {
                return text;
        }

}
