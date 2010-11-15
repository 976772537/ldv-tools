package org.linuxtesting.ldv.csd;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.channels.FileChannel;

import org.linuxtesting.ldv.csd.utils.Logger;


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
			FileInputStream src = null;
			FileOutputStream dest = null;
			FileChannel srcChannel = null;
			FileChannel destChannel = null;
			try
			{
				src = new FileInputStream(srcFilename);
				dest = new FileOutputStream(dstFilename);
				srcChannel = src.getChannel();
				destChannel = dest.getChannel();
				srcChannel.transferTo(0, srcChannel.size(), destChannel);
			} catch (IOException e)
			{
				Logger.err("Can't copy file from \""+srcFilename+"\" to \""+dstFilename+"\".");
			} finally {
				try {
					srcChannel.close();
					destChannel.close();
					src.close();
					dest.close();
				} catch(IOException e) {
					return false;
				}
				
			}
			return true;
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
