package com.iceberg.cbase.parsers;

import java.util.List;
import java.util.ArrayList;
import  java.util.regex.Pattern;
import  java.util.regex.Matcher;

import com.iceberg.cbase.parsers.options.Options;
import com.iceberg.cbase.parsers.options.ParserOptions;
import com.iceberg.cbase.readers.ReaderInterface;
import com.iceberg.cbase.tokens.Token;


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
		String buffer = inputReader.readAll();
//		System.out.println(buffer);
		Matcher matcher = pattern.matcher(buffer);
		/* матчим контент */
		while(matcher.find()) {
			String imeo = matcher.group();
			T token = null;
			token = parseContent(imeo, matcher.start(),matcher.end());
			if(token!=null) {
				ltoken.add(token);
			}
		}
		return ltoken;
	}

	protected abstract T parseContent(String content, int start, int end);
}
