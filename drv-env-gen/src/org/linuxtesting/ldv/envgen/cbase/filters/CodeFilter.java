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
package org.linuxtesting.ldv.envgen.cbase.filters;

/**
 *  *  * @author Alexander Strakh
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
