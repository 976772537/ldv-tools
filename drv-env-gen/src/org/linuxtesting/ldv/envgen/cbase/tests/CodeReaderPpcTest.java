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
