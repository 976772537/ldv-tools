package com.iceberg.cbase.tests;

import java.io.FileReader;
import java.io.IOException;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

import com.iceberg.Logger;
import com.iceberg.cbase.parsers.ExtendedParserFunction;
import com.iceberg.cbase.parsers.ExtendedParserStruct;
import com.iceberg.cbase.parsers.ParserInterface;
import com.iceberg.cbase.readers.ReaderCCommentsDel;
import com.iceberg.cbase.readers.ReaderInterface;
import com.iceberg.cbase.tokens.Token;

public class TokenFunctionReaderTest {
	public static void main(String[] args) {
		long start = System.currentTimeMillis();
		
		FileReader reader = null;
		try {
			//reader = new FileReader("/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/usb/storage/usb.c");
			reader = new FileReader("/mnt/second/iceberg/ldv/toolset2/linux-2.6.31/drivers/scsi/fcoe/fcoe.c");
			
			/* добавим ридер удаления комментариев */
			ReaderInterface wreader = new ReaderCCommentsDel(reader);
			
			List<ParserInterface> lparser = new ArrayList<ParserInterface>();
			
			/* добавим необходимые парсеры */
			lparser.add(new ExtendedParserFunction(wreader));
			lparser.add(new ExtendedParserStruct(wreader));
			//lparser.add(new ParserFunctionDecl(wreader));
			//lparser.add(new ParserStructDecl(wreader));
			//lparser.add(new ParserPpcDirective(wreader));

			List<Token> ltoken = new ArrayList<Token>();
			
			/* запустим парсеры последовательно */
			Iterator<ParserInterface> parserIterator = lparser.iterator();
			while(parserIterator.hasNext()) {
				ParserInterface currentParser = parserIterator.next();
				ltoken.addAll(currentParser.parse());
			}
		
			/* распечатаем полученные токены */
			Iterator<Token> tokenIterator = ltoken.iterator();
			while(tokenIterator.hasNext())
				Logger.trace(tokenIterator.next().getContent());
			
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		long end = System.currentTimeMillis();
		Logger.info("Time: " + (end-start) + "ms");
	}
}
