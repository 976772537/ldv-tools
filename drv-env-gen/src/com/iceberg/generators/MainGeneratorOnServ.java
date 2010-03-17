package com.iceberg.generators;

import java.io.FileWriter;
import java.io.IOException;

import com.iceberg.FSOperationsBase;

public class MainGeneratorOnServ {
	public static void main(String[] args) {
		long startf = System.currentTimeMillis();
		if(args.length < 2) {
			System.out.println("USAGE: java -ea -jar mgenserv.jar <filename.lst> <first.c> <second.c> ...");
			return;
		}

		try {
			FileWriter fw = new FileWriter(args[0]);
			for(int i=1; i<args.length; i++) {
				System.out.print("generate for "+args[i]);
				if(MainGenerator.generateByIndex(args[i], i)) {
					System.out.print(" generate ldv_main"+i);
					fw.write(args[i]+" ldv_main"+i+"\n");
				} else {
					FSOperationsBase.CopyFile(args[i], args[i]+".ldv.c");
					System.out.print(" write only driver code.");
				}
				System.out.println();	
			}
			fw.close();
		} catch (IOException e) {
			e.printStackTrace();
		}

		long endf = System.currentTimeMillis();
		System.out.println("generate time: " + (endf-startf) + "ms");
	}
}
