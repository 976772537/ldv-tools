package com.iceberg.csd;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.channels.FileChannel;

public class FSOperationBase {
	
	public static void removeDirectoryRecursive(File source) {
    	if (source.exists()) {
    		String[] children = source.list();
    		if(children!=null) {
    			for (int i=0; i<children.length; i++) {
    				String inner = source.getAbsolutePath()+'/'+children[i];
    				removeDirectoryRecursive(new File(inner));
    			}
    		}
    		source.delete();
        } 
    }
	
	public static boolean CopyFile(String srcFilename, String dstFilename)
	{
		if(srcFilename!=null && dstFilename!=null)
		{
			try
			{
				FileInputStream src = new FileInputStream(srcFilename);
				FileOutputStream dest = new FileOutputStream(dstFilename);
				FileChannel srcChannel = src.getChannel();
				FileChannel destChannel = dest.getChannel();
				srcChannel.transferTo(0, srcChannel.size(), destChannel);
				return true;
			} catch (IOException e)
			{
				System.out.println("csd: ERROR: Can't copy file.");
			}
		}
		return false;
	}
	
	public static void copyDirectory(File sourceLocation , File targetLocation) throws IOException {
    	if (sourceLocation.isDirectory()) {
    		if (!targetLocation.exists())
            	targetLocation.mkdir();

    		String[] children = sourceLocation.list();
    		for (int i=0; i<children.length; i++) {
    			copyDirectory(new File(sourceLocation, children[i]), 
    					new File(targetLocation, children[i]));
    		}
        } else {
            InputStream in = new FileInputStream(sourceLocation);
            OutputStream out = new FileOutputStream(targetLocation);
            byte[] buf = new byte[1024];
            int len;
            while ((len = in.read(buf)) > 0) {
                out.write(buf, 0, len);
            }
            in.close();
            out.close();
        }
    }
	
}
