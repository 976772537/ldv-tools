package org.linuxtesting.ldv.online.ws.wsm;

public class WSMLdvstowsTaskPutResponse extends WSMLdvtowsResponse {

	private final static String tagB_id = "<id>";
	//private final static String tag_id = "id";
	private final static String tagE_id = "</id>";	
	
	private int id;
	
	public String toWSXML() {
		return super.toWSXML(tagB_id + id +tagE_id);
	}

	public void setId(int id) {
		this.id = id;		
	}
	
}
