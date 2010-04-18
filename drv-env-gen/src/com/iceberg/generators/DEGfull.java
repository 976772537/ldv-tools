package com.iceberg.generators;

import java.io.File;
import java.io.IOException;

import javax.xml.parsers.ParserConfigurationException;

import org.xml.sax.SAXException;

import com.iceberg.FSOperationsBase;
import com.iceberg.generators.cmdstream.CmdStream;

/*
 * 1. читает work_dir? куда копирует чистые src
 * 2. гадит в исходный драйвердир  
 *    и попутно заменяя сишники в новом драйвердир
 *    на сгенерированные , разрешает зависимости
 *    в любом случае
 * 
 */



/*
 * развязать комманды:
 * 
 * пока нет обертки - драйвер придется копировать
 * 
 * CommandCC - генерирует соответствующий -ошник с выводом
 * CommandLD - читает входящие ошники и добавляет опции
 * 
 */


public class DEGfull {
	
	private static String basedir = null;
	
	private static String cmdfile = null;
	private static String cmdfileout = null;
	
	private static String WORK_DIR = null;
	
	private static final String driverdirname = "driver";
	
	private static final String usageString = "USAGE: WORK_DIR=workdir java -ea -jar drv-env-gen.jar --basedir=basedir --cmdfile=cmdxmlin --cmdfile-out=cmdfileout";
	
	public static void main(String[] args) throws Exception {
		if(!getOpts(args)) 
			System.exit(-1);
		try {

			
			// parse command stream
			CmdStream cmdstream = CmdStream.getCmdStream(cmdfile,basedir);
			cmdstream.generateMains();
			cmdstream.putCmdStream(cmdfileout);
		
	
		} catch (ParserConfigurationException e1) {
			System.out.println("ERROR: parse exception.\n");
			System.exit(-1);
		} catch (SAXException e1) {
			System.out.println("ERROR: SAX exception.\n");
			System.exit(-1);
		} catch (IOException e1) {
			System.out.println("ERROR: IO exception.\n");
			System.exit(-1);
		}
	}
	
	private static boolean getOpts(String[] args) {
		if(args.length != 4 ) {
			System.out.println(usageString);
			return false;
		}	
		
		WORK_DIR = System.getenv("WORK_DIR");
		if(WORK_DIR == null || WORK_DIR.length() == 0) {
			System.out.println("ERROR: setup WORK_DIR var before!");
			System.out.println(usageString);
			return false;
		}
		
		for(int i=0; i<args.length; i++) {
			if(args[i].contains("--basedir=")) {
				basedir = args[i].replace("--basedir=", "").trim();
			} else
			if(args[i].contains("--cmdfile=")) {
				cmdfile = args[i].replace("--cmdfile=", "").trim();
			} else
			if(args[i].contains("--cmdfile-out=")) {
				cmdfileout = args[i].replace("--cmdfile-out=", "").trim();
			} else {
				System.out.println("Unknown parameter: \""+args[i]+"\".");
				System.out.println(usageString);
				return false;
			}
		}
		return true;
	}
}
