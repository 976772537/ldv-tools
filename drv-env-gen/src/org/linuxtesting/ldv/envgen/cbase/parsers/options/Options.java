package org.linuxtesting.ldv.envgen.cbase.parsers.options;

/**
 * 
 * Принцип работы опции:
 * 
 * Каждая опция - часть паттерна, которая расположена в порядке добавления
 * в стек опций парсера. Соответственно перед началом работы, парсер вызывает
 * методы appenPattern у всех опций последовательно. Тем самым получается 
 * основной паттер для поиска. 
 * 
 * При создании нового парсера нужно знать, что все опции сольются в один паттерн
 * 
 * У опции также должно быть уникальное имя, чтобы можно было обращаться к ней
 * из готового парсера и конфигурировать. Реализация функции applyConfigMsg
 *  должна отвечать за то, как будет воспринято сообщение и как
 *  будет сконфигурирован паттерн.
 *  
 * @author iceberg
 *
 */
public abstract class Options {
	private String name;
	
	public abstract void appendPattern(StringBuffer buffer);
	public abstract void applyConfigMsg(String value);
	
	public Options(String name) {
		this.name = name;
	}
	
	public String getName() {
		return this.name;
	}
}