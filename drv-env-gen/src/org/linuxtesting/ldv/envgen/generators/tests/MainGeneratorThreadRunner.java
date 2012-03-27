/*
 * Copyright 2010-2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.linuxtesting.ldv.envgen.generators.tests;

import java.io.File;
import java.util.Iterator;
import java.io.FilenameFilter;
import java.util.ArrayList;
import java.util.List;

import org.linuxtesting.ldv.envgen.Logger;


public class MainGeneratorThreadRunner {
	
	public static void main(String[] args) {
		final int threadsLimit = 10;
		long startf = System.currentTimeMillis();
		List<Thread> mlist = new ArrayList<Thread>();
		String path = "/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/";
		List<String> files = getDirContentRecursiveCFiles(path);
		Iterator<String> fileIterator = files.iterator();
		/* запускаем по 10 потоков */
		while(fileIterator.hasNext()) {
			String filename = fileIterator.next();
			MainGeneratorThread mgt = new MainGeneratorThread(filename);
			Thread threadin = new Thread(mgt);
			/* смотрим есть ли еще место в списке выполнения */
			if(mlist.size()<(threadsLimit)) {	/* место есть - тогда подготавливаем и запускаем поток */
				mlist.add(threadin);
				threadin.start();
			} else {
			/* если пустых мест нет, то ищем завершившиеся потоки */
				Iterator<Thread> threadIterator = mlist.iterator();
	outfast:	while(true) {
					while(threadIterator.hasNext()) {
						Thread thread = threadIterator.next();
						if(!thread.isAlive()) {
							mlist.remove(thread);
							mlist.add(threadin);
							threadin.start();
							break outfast;
						}
					}
				}
			}
		}
		
		long endf = System.currentTimeMillis();
		Logger.info("generate time: " + (endf-startf) + "ms");		
	}
	
	/* получаем списко с-шников из ядра */
	public static List<String> getDirContentRecursiveCFiles(String path) {
		return getDirContentRecursive(path, ".c");
	}
	
	public static List<String> getDirContentRecursive(String dirname, final String filter)
	{
		String[] highfillevel;
		String[] highdirlevel;
		List<String> filesList=new ArrayList<String>();
		if((highdirlevel=getDirs(dirname, "")).length==0)
		{
			highfillevel=getFiles(dirname, filter);
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
}
