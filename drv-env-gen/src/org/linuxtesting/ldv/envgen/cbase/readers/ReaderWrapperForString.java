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

/**
 * поскольку парсеры воспринимают только интерфейс ReaderInterface, то когда нам понадобиьтся
 * раcпарсить не весь файл а часть - которая лежит в String, то этот String потребуется обернуть
 * в  ReaderWrapperForString. чтобы передать в последующий парсер.
 *
 * TODO: сделать фабрику объектов, реализующих интерфейс ReaderInterface, желательно
 * на основе instanceOf
 *
 * @author Alexander Strakh
 *
 */
public class ReaderWrapperForString implements ReaderInterface {

	private String string;

	public ReaderWrapperForString(String string) {
		this.string = string;
	}

	public String readAll() {
		return this.string;
	}

}
