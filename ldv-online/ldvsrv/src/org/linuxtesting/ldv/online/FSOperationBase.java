package org.linuxtesting.ldv.online;

import java.util.ArrayList;
import java.util.List;

import java.io.File;
import java.io.FilenameFilter;

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
	
	public static List<String> getDirContentRecursivePax(String dirname) {
		return getDirContentRecursivePrepare(dirname, ".pax");
	}

	public static List<String> getDirContentRecursivePrepare(String dirname, final String filter) {
		File dir = new File(dirname);
		if(!dir.exists()) {
			Logger.err("Directory \""+dirname+"\" does not exists.");
			return null;
		}
		return getDirContentRecursive(dirname+"/", filter);		
	}
	
	public static List<String> getDirContentRecursive(String dirname, final String filter)
	{
		String[] highfillevel;
		String[] highdirlevel;
		List<String> filesList=new ArrayList<String>();
		if((highdirlevel=getDirs(dirname, "")).length == 0)
		{
			highfillevel = getFiles(dirname, filter);
			for(int i=0; i<highfillevel.length; i++)
			{
				filesList.add(dirname+highfillevel[i]);
			}
			return filesList;
		} else
		{
			List<String> filesListtmp=new ArrayList<String>();
			for(int i=0; i<highdirlevel.length; i++)
			{
				filesListtmp=getDirContentRecursive( dirname+highdirlevel[i]+"/", filter);
				filesList.addAll(filesListtmp);
			}
			highfillevel=getFiles(dirname, filter);
			for(int j=0; j<highfillevel.length; j++)
			{
				filesList.add(dirname+highfillevel[j]);
			}
			return filesList;
		}
	}

	public static String[] getDirs(final String dirname) {
		return getDirs(dirname, null);
	}
	
	public static String[] getDirs(final String dirname, final String filter)
	{
		File pathFile =new File(dirname);
		String[] list = pathFile.list(
			new FilenameFilter()
			{
				public boolean accept (File f, String s)
				{
						if(new File(dirname+s).isDirectory()) {
							if(filter!=null)
								return s.endsWith(filter);
							return true;
						} else { 
							return false;
						}
				}
			});
		return list;
	}

	public static String[] getFiles(final String dirname, final String filter)
	{
		File pathFile =new File(dirname);
		String[] list = pathFile.list(
			new FilenameFilter()
			{
				public boolean accept (File f, String s)
				{
						if(new File(dirname+s).isFile())
							return s.endsWith(filter);
						else return false;
				}
			});
		return list;
	}
	
}
