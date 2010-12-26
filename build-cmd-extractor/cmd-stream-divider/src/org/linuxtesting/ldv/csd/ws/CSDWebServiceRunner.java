package org.linuxtesting.ldv.csd.ws;

import javax.xml.ws.Endpoint;

import org.linuxtesting.ldv.csd.CSD;
import org.linuxtesting.ldv.csd.cmdstream.CmdStream;

public class CSDWebServiceRunner implements Runnable {

		private String wsdlAddr;
		private CmdStream cmdstream;
		private CSDWebService ws;

		public CSDWebServiceRunner(CmdStream cmdStream, String wsdlAddr) {
			this.wsdlAddr = wsdlAddr;
			this.cmdstream = cmdStream;
		}
	
		@Override
		public void run() {
			ws = new CSDWebService(cmdstream);
			Endpoint.publish(wsdlAddr, ws);
			CSD.term = true;
		}

		/*public void terminate() throws Throwable {
			ws.terminate();
		}*/
	
}
