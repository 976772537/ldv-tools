package com.iceberg.mp.vs.vsm;

import com.iceberg.mp.vs.VProtocol;

public class VSMClientGetTaskOk extends VSMClient {

        private static final long serialVersionUID = 1L;

        public VSMClientGetTaskOk(String name) {
                super(name,VProtocol.sGetTaskOk);
        }
}
