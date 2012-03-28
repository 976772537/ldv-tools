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

import org.linuxtesting.ldv.envgen.cbase.filters.CodeFilter;
import org.linuxtesting.ldv.envgen.cbase.filters.CodeFilterCCommentsDel;


/**
 * в списко добавляются фильтры и ридер последовательно по ним проходится
 * -- БАГ в реализации метода read
 * 
 * @author Alexander Strakh
 *
 */
public class ReaderCCommentsDel extends ReaderWrapper {

	public ReaderCCommentsDel(Reader reader) {
		super(reader);
		CodeFilter filter = new CodeFilterCCommentsDel(); 
		addFilter(filter);
	}

	/* метод, который читает из стандартного ридера и 
	 * парсит все необходимое  */
    @Override
	public int read(char cbuf[]) throws IOException {
        return super.read(cbuf);
    }
}
