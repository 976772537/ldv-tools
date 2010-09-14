package org.linuxtesting.ldv.envgen.cbase.readers;

import java.io.IOException;
import java.io.Reader;

import org.linuxtesting.ldv.envgen.cbase.filters.CodeFilter;
import org.linuxtesting.ldv.envgen.cbase.filters.CodeFilterCCommentsDel;


/**
 * в списко добавляются фильтры и ридер последовательно по ним проходится
 * -- БАГ в реализации метода read
 * 
 * @author iceberg
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
