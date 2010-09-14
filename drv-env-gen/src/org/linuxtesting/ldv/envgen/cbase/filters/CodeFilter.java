package org.linuxtesting.ldv.envgen.cbase.filters;

/**
 *  *  * @author iceberg
 *	классы-фильтры, 
 *	метод filter - возвращает номер действия по символу,
 *  класс может хранить текущее состояние,
 *  чтобы его сбросить - нужно реализовать метод reset.
 *  
 *  сброс состояние может потребоваться если наш ридер
 *  имеет список фильтров, и один из фильтров установил свое состояние???
 *
 */
public interface CodeFilter {
	public String getName();
	public char[] filter(char cbuf);
	public void reset();
}
