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
package org.linuxtesting.ldv.envgen.generators;

import java.io.FileWriter;
import java.io.IOException;

import org.linuxtesting.ldv.envgen.FSOperationsBase;
import org.linuxtesting.ldv.envgen.Logger;

@Deprecated
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
						null, false, new PlainParams(true, true, false, true));
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
