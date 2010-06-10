package com.iceberg.cbase;

import java.io.FileNotFoundException;
import java.io.FileReader;

import com.iceberg.Logger;
import com.iceberg.cbase.readers.ReaderCCommentsDel;
import com.iceberg.cbase.readers.ReaderWrapper;

public class CodeReader {
	public static void main(String[] args) {
		long start = System.currentTimeMillis();
		FileReader reader = null;
		try {
			reader = new FileReader("/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/usb/storage/usb.c");
			ReaderWrapper wreader = new ReaderCCommentsDel(reader);
			String filteredText = wreader.readAll();
			System.out.print(filteredText);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
		long end = System.currentTimeMillis();
		Logger.info("Time: " + (end-start) + "ms");
	}
}
