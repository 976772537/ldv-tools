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

import java.io.FileReader;

import java.io.IOException;
import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.parsers.ParserPPCHelper;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderCCommentsDel;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderWrapper;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenPpcDirective;


public class CodeReaderPpcTest {
	public static void main(String[] args) {
		FileReader reader = null;
		try {
			reader = new FileReader("/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/usb/storage/usb.c");
			ReaderWrapper wreader = new ReaderCCommentsDel(reader);
			ParserPPCHelper parser = new ParserPPCHelper(wreader);
			List<TokenPpcDirective> ltoken = parser.parse();
			for(TokenPpcDirective token : ltoken) 
				System.out.println(token.getContent());
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
