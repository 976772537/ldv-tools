package org.linuxtesting.ldv.envgen.generators.tests;

import java.util.Iterator;
import java.util.List;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.generators.MainGenerator;


public class MainGeneratorFull {
	public static void main(String[] args) {
		long startf = System.currentTimeMillis();
		//String path = "/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/usb/storage/";
		//String path = "/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/firmware/";
		//String path = "/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/arch/sh/kernel/cpu/sh4a/";
		//String path = "/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/";
		String path = "/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/";
		//String path = "/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/input/touchscreen/";
		//String path = "/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/";
		//String path = "/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/fs/autofs4/";
		//String path = "/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/macintosh/";
		List<String> files = MainGeneratorThreadRunner.getDirContentRecursiveCFiles(path);
		Iterator<String> fileIterator = files.iterator();

		while(fileIterator.hasNext()) {
			String filename = fileIterator.next();
			Logger.info("GENERATE_RUN: " + filename);
			MainGenerator.generate(filename);
		}

		long endf = System.currentTimeMillis();
		Logger.info("generate time: " + (endf-startf) + "ms");
	}
}
