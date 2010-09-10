package org.linuxtesting.ldv.online.vs.vsm;

import org.linuxtesting.ldv.online.vs.VProtocol;

public class VSMClientGetTaskOk extends VSMClient {

        private static final long serialVersionUID = 1L;

        public VSMClientGetTaskOk(String name) {
                super(name,VProtocol.sGetTaskOk);
        }
}
