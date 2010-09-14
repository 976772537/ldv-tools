package org.linuxtesting.ldv.envgen.generators;

import java.io.FileWriter;
import java.io.IOException;

import org.linuxtesting.ldv.envgen.FSOperationsBase;
import org.linuxtesting.ldv.envgen.Logger;


public class MainGeneratorOnServ {
	public static void main(String[] args) {
		long startf = System.currentTimeMillis();
		if(args.length < 2) {
			Logger.norm("USAGE: java -ea -jar mgenserv.jar <filename.lst> <first.c> <second.c> ...");
			return;
		}

		try {
			FileWriter fw = new FileWriter(args[0]);
			for(int i=1; i<args.length; i++) {
				Logger.info("generate for "+args[i]);
				DegResult res = MainGenerator.generateByIndex(null, args[i], String.valueOf(i), 
						null, false, new PlainParams(true, true));
				if(res.isSuccess()) {
					Logger.info(" generate ldv_main"+i);
					fw.write(args[i]+" ldv_main"+i+"\n");
				} else {
					FSOperationsBase.CopyFile(args[i], args[i]+".ldv.c");
					Logger.info(" write only driver code.");
				}	
			}
			fw.close();
		} catch (IOException e) {
			e.printStackTrace();
		}

		long endf = System.currentTimeMillis();
		Logger.info("generate time: " + (endf-startf) + "ms");
	}
}
