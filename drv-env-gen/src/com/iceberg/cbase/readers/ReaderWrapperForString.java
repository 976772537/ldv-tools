package com.iceberg.cbase.readers;

/**
 * поскольку парсеры воспринимают только интерфейс ReaderInterface, то когда нам понадобиьтся
 * раcпарсить не весь файл а часть - которая лежит в String, то этот String потребуется обернуть
 * в  ReaderWrapperForString. чтобы передать в последующий парсер.
 *
 * TODO: сделать фабрику объектов, реализующих интерфейс ReaderInterface, желательно
 * на основе instanceOf
 *
 * @author root
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
