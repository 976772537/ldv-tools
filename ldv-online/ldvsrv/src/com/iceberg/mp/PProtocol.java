package com.iceberg.mp;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

public class PProtocol {
    public static final String sGetTask = "GETTASK";
    public static final String sGetTaskOk = "GETTASKOK";

    protected ObjectInputStream ois = null;
    protected ObjectOutputStream oos = null;

    protected void closeStreams() throws IOException {
            ois.close();
            oos.close();
    }

}
