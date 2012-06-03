/*
 * Copyright (C) 2010-2012
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
package org.linuxtesting.ldv.envgen.cbase.tests;

import java.io.FileNotFoundException;
import java.io.FileReader;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderCCommentsDel;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderWrapper;


public class CodeReaderTest {
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
