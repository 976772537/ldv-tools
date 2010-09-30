package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.List;
import java.util.ArrayList;
import  java.util.regex.Pattern;
import  java.util.regex.Matcher;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.parsers.options.Options;
import org.linuxtesting.ldv.envgen.cbase.parsers.options.ParserOptions;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;
import org.linuxtesting.ldv.envgen.cbase.tokens.Token;



/**
 * Парсер, который наследуется от данного,
 * 1. добавляет опции - которые в свою очередь реализуют метод getPattern
 * 	  добавление опций производится в конструкторе
 * 2. реализует функцию парсера контента
 *
 * @author iceberg
 *
 */
public abstract class ExtendedParser<T extends Token> implements ParserInterface<T> {

	protected ReaderInterface inputReader = null;

	protected ParserOptions options = new ParserOptions();
	/**
	 * из ридера вызывается метод readAll и достается строковый буффер,
	 * по которому и проходится парсер
	 * @param reader
	 */
	protected ExtendedParser(ReaderInterface reader) {
		this.inputReader = reader;
	}

	protected ReaderInterface getReader() {
		return this.inputReader;
	}

	protected void addOption(Options options) {
		this.options.addOption(options);
	}

	public void addConfigOption(String optionName, String value) {
		/* вывести лог если опция отсутствует */
		this.options.sendConfigOption(optionName, value);
	}

	public List<T> parse() {
		List<T> ltoken = new ArrayList<T>();
		/* подготавливаем и компилим паттерны */
		Pattern pattern = Pattern.compile(options.getPattern());
		Logger.trace("The pattern is: " + pattern);
		String buffer = inputReader.readAll();
		Matcher matcher = pattern.matcher(buffer);
		/* матчим контент */
		while(matcher.find()) {
			String imeo = matcher.group();			
			T token = parseContent(imeo, matcher.start(),matcher.end());
			if(token!=null) {
				ltoken.add(token);
			} else {
				Logger.debug("Could not parse content for: " +  imeo);				
			}
		}
		if(ltoken.isEmpty()) { 
			Logger.debug("Functions not found");
		}
		return ltoken;
	}

	protected abstract T parseContent(String content, int start, int end);
}
