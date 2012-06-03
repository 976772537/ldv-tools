/*
 * Copyright (C) 2010-2012
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

public class CodeFilterCCommentsDel implements CodeFilter {

	private String name = "C comments delete filter";

	/**
	 *	Энумератор конечных состоний для поиска и удаления комментариев
	 */
	private static enum commentStates {
		BLOCK_NULL,		// мы не находимся в блоке
		BLOCK_SQUARES,		// мы находимся в блоке кавычек
		BLOCK_SCREEN,		// мы в блоке кавычек + проскочил символ экранирования
		BLOCK_BEFORE_COMMENT,		// проскочил символ / - возможно скоро будет комментарий
		BLOCK_LINE_COMMENT,	// проскочил // - пошел строчный комментарий
		BLOCK_COMMENT,		// проскочил /* - пошел нелинейный коммнентарий
		BLOCK_BEFORE_END_COMMENT,// мы в блоке нелинейного комментария + проскочил *
		BLOCK_NULL_AFTER_BEFORE_COMMENT,
		BLOCK_NULL_AFTER_COMMENT,
	}

	/**
	 * текущее состояние конечного автомата
	 */
	private commentStates state = commentStates.BLOCK_NULL;

	/**
	 * магазин конечного автомата
	 */
	private char stackChar;

	/**
	 *	Конечный автомат для поиска и удаления комментариев
	 *	возвращает новое состояние по входящему символу и
	 *	текущему состоянию.
	 */
	private void updateState(char symbol) {
		switch(state) {
			case BLOCK_SQUARES:
				if(symbol=='\"') state=commentStates.BLOCK_NULL; else
				if(symbol=='\\') state=commentStates.BLOCK_SCREEN; else
					state=commentStates.BLOCK_SQUARES;
				break;
			case BLOCK_SCREEN:
				state=commentStates.BLOCK_SQUARES;
				break;
			case BLOCK_BEFORE_COMMENT:
				if(symbol=='/' && stackChar=='/') state=commentStates.BLOCK_LINE_COMMENT; else
				if(symbol=='*' && stackChar=='/') state=commentStates.BLOCK_COMMENT; else
					state=commentStates.BLOCK_NULL_AFTER_BEFORE_COMMENT;
				break;
			case BLOCK_LINE_COMMENT:
				if(symbol=='\n') state=commentStates.BLOCK_NULL_AFTER_COMMENT; else
					state=commentStates.BLOCK_LINE_COMMENT;
				break;
			case BLOCK_COMMENT:
				if(symbol=='*') state=commentStates.BLOCK_BEFORE_END_COMMENT; else
					state=commentStates.BLOCK_COMMENT;
				break;
			case BLOCK_BEFORE_END_COMMENT:
				if(symbol=='/') state=commentStates.BLOCK_NULL_AFTER_COMMENT; else
				if(symbol=='*') state=commentStates.BLOCK_BEFORE_END_COMMENT; else
					state=commentStates.BLOCK_COMMENT;
				break;
			case BLOCK_NULL:
				if(symbol=='\"') state=commentStates.BLOCK_SQUARES; else
				if(symbol=='/') {
					stackChar = symbol;
					state=commentStates.BLOCK_BEFORE_COMMENT;
				} else
					state=commentStates.BLOCK_NULL;
				break;

			case BLOCK_NULL_AFTER_COMMENT:
				if(symbol=='\"') state=commentStates.BLOCK_SQUARES; else
				if(symbol=='/') {
					stackChar = symbol;
					state=commentStates.BLOCK_BEFORE_COMMENT;
				} else
					state=commentStates.BLOCK_NULL;
				break;

			case BLOCK_NULL_AFTER_BEFORE_COMMENT:
			default:
				state=commentStates.BLOCK_NULL;
		}
	}

	/**
	 * возвращает два или один символ в char[] если это не комментарий
	 * и возвращает null - если это комментарий
	 */
	public char[] filter(char symbol) {
		/*if(symbol=='/') {
			System.out.println("...");
		}*/
		updateState(symbol);

		if(state==commentStates.BLOCK_NULL_AFTER_COMMENT
				/* TODO: разделить этот state на БЛОК_ПОСЛЕ_БОЛШОГО_КОММЕНТАРИЯ
				 *                              и БЛОК_ПОСЛЕ_ОДНОСТРОЧНОГО КОММЕНТАРИЯ
				 * потому как символ после однострочного комментария -'\n'
				 * уже является одновременно симовлом конца комментария и символом,
				 * который принадлжеит коду и может нести какуую-либо смымсловую нагрузкку
				 *                             */
				&& symbol=='\n') {
			char[] achar = {symbol};
			return achar;
		}
		if(state==commentStates.BLOCK_NULL ||
				state==commentStates.BLOCK_SQUARES ||
				state==commentStates.BLOCK_SCREEN )
		{
			char[] achar = {symbol};
			return achar;
		}
		if(state==commentStates.BLOCK_NULL_AFTER_BEFORE_COMMENT) {
			char[] achar = {stackChar,symbol};
			return achar;
		}
		return null; // или дергает метод чтения, в зависимости от метода парсера
	}

	public void reset() {
		state = commentStates.BLOCK_NULL;
	}

	public String getName() {
		return name;
	}
}
