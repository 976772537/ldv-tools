package com.iceberg;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class FSOperationsBase {
	public static String readFile(String filename)
	{
		return readFile(filename, true);
	}

	public static String readFileCRLF(String filename)
	{
		return readFile(filename, false);
	}

	public static boolean DeleteFile(String filename)
	{
		File pathFile =new File(filename);
		if (pathFile.delete()==true) return true;
		return false;
	}

	public static File CreateFile(String filename)
	{
		File pathFile =new File(filename);
		try {
			if (pathFile.createNewFile()==true) return pathFile;
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
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
				//e.printStackTrace();
			}
		}
		return false;
	}

	public static List<String> getDirContentList(String dirname, final String filter)
	{
		String[] dircontent=getDirContent( dirname, filter);
		if(dircontent!=null && dircontent.length>0)
		{
			List<String> dirlistcontent= new ArrayList<String>();
			for(int i=0; i<dircontent.length; i++)
				dirlistcontent.add(dircontent[i]);
			return dirlistcontent;
		}
		return null;
	}

	public static String[] getDirContent(String dirname, final String filter)
	{
		File pathFile =new File(dirname);
		String[] list = pathFile.list(
			new FilenameFilter()
			{
				public boolean accept (File f, String s)
				{
						return s.endsWith(filter);
				}
			});
		return list;
	}

	public static List<String> getDirContentRecursiveC(String dirname) {
		return getDirContentRecursive(dirname, ".c");
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

	public static String[] getDirs(final String dirname, final String filter)
	{
		File pathFile =new File(dirname);
		String[] list = pathFile.list(
			new FilenameFilter()
			{
				public boolean accept (File f, String s)
				{
						if(new File(dirname+s).isDirectory())
							return s.endsWith(filter);
						else return false;
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

	public static String readFile(String filename, boolean removeNewLine) {
		String tmp;
		StringBuffer buffer=new StringBuffer();
		try {
			BufferedReader fin = new BufferedReader(new FileReader(filename));
			while((tmp=fin.readLine())!=null)
			{
				if(!removeNewLine) buffer.append("\n");
				buffer.append(tmp);
			}
			fin.close();
		} catch (FileNotFoundException e)
		{
			//System.err.print("ldv_err: FSOperations.readFile(\""+filename+"\", "+removeNewLine+")\n");
		} catch (IOException e) {
			//System.err.print("ldv_err: FSOperations.readFile(\""+filename+"\", "+removeNewLine+")\n");
		}
		return buffer.toString();
	}

	public static boolean loadFile(Properties prop, String fileName) {
		InputStream is = null;
		try {
			File f = new File(fileName);
			if (f.exists()) {
				is = new FileInputStream(f);
			} else {

				Class<?> clazz = FSOperationsBase.class;
				is = clazz.getResourceAsStream(fileName);
			}
			if (is != null) {
				prop.load(is);
				is.close();
				return true;
			}
		} catch (IOException iex) {
			return false;
		}
		return false;
	}
}
