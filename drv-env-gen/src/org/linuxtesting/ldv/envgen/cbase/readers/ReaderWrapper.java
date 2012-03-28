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
package org.linuxtesting.ldv.envgen.cbase.readers;

import java.io.IOException;
import java.io.Reader;
import java.util.ArrayList;
import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.filters.CodeFilter;


/**
 *
 *  * @author Alexander Strakh
 *
 *  Класс служит для того, чтобы парсить входной поток.
 *
 *  При создании класса указывается стандартный ридер,
 *  это может быть как FileReader, BufferedReader так и
 *  любой класс-потомок ReaderWrapper.
 *
 *  пример парсера с -комментариев: наследуемся от данного
 *  класса, переопределяем
 *  метод Read и пишем в этот метод код, который читает
 *  данные из reader, избавляется от комментариев ( конечный
 *  автомат с магазином) и выводит уже чистый Си-код. При этом
 *  мы можем использовать этот класс как стандартный ридер.
 *
 *  Сейчас работает только метод readAll...
 *
 */
public abstract class ReaderWrapper extends Reader implements ReaderInterface{

	/**
	 * список фильтров с названиями
	 *
	 */
	protected List<CodeFilter> filterList = new ArrayList<CodeFilter>();

	/**
	 * сдесь храниться стандартный ридер - это может
	 * быть любой ридер, который наследуется от абстрактного
	 * класса Read
	 *
	 */
	private Reader reader;
	private int max_read_size = 10000000;
	private String buffer;

	public ReaderWrapper(Reader reader) {
		this.reader = reader;
	}

	public boolean addFilter(CodeFilter filter) {
		if(filter!=null) {
			filterList.add(filter);
		}
		return false;
	}

    @Override
	public int read(char cbuf[]) throws IOException {
    	int retsize = reader.read(cbuf);
		if(filterList.size() == 0) return retsize;
		if(retsize == -1) {
			reader.close();
			return -1;
		}
		int newsize = 0;
		char retbuf[];
		for(int i=0; i<retsize; i++) {
			for(CodeFilter filter: filterList) {
				retbuf = filter.filter(cbuf[i]);
				if(retbuf!=null) {
					for(int j=0; j<retbuf.length; j++) cbuf[newsize++]=retbuf[j];
				}
			}
		}
		return newsize;
    }

    public String readAll() {
    	if(buffer!=null) return buffer;
    	char[] cbuf = new char[max_read_size];
    	StringBuffer tmpBuf = new StringBuffer();
      	int retsize = -1;
		try {
			retsize = reader.read(cbuf);
		} catch (IOException e) {
			e.printStackTrace();
		}
		if(filterList.size() == 0 || retsize == -1) {
			try {
				reader.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
			return new String(cbuf);
		}
		char retbuf[];
		for(int i=0; i<retsize; i++) {
			for(CodeFilter filter: filterList) {
				retbuf = filter.filter(cbuf[i]);
				if(retbuf!=null) {
					tmpBuf.append(retbuf);
				}
			}
		}
		this.buffer = tmpBuf.toString();
		return buffer;
    }

	@Override
	public int read(char[] cbuf, int off, int len) throws IOException {
		return reader.read(cbuf, off, len);
	}

	@Override
	public void close() throws IOException {
		reader.close();
	}

}
