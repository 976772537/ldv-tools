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