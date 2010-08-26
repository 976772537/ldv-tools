package com.iceberg.cbase.parsers;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import com.iceberg.cbase.parsers.ExtendedParserStruct.NameAndType;
import com.iceberg.cbase.tokens.Token;
import com.iceberg.cbase.tokens.TokenFunctionDecl;

/* статический класс с сохраненными и откомпиленными регекспами */
public class PatternSort {

	public static Map<String,String[]> regexprMap = new HashMap<String,String[]>();
	public static Map<String,String[]> resultMap = new HashMap<String,String[]>();
	public static Map<String,String[]> initMap = new HashMap<String,String[]>();

	/* статический инициализатор будет заполнять уже имеющиеся и работающие шаблоны -
	 * откомпиленные регекспы */
	static {
		/* шаблон, который используется по-умолчанию */
		String[] patterna = new String[6];
		patterna[0] = "open";
		patterna[1] = "probe";
		patterna[2] = "connect";
		patterna[3] = "read";
		patterna[4] = "write";
		patterna[5] = "close";
		regexprMap.put("__MAIN__", patterna);

		patterna = new String[9];
		patterna[0] = "probe";
		patterna[1] = "suspend";
		patterna[2] = "resume";
		patterna[3] = "pre_reset";
		patterna[4] = "reset_resume";
		patterna[5] = "post_reset";
		patterna[6] = "disconnect";
		patterna[7] = "remove";
		patterna[8] = "shutdown";
		regexprMap.put("usb_driver", patterna);

		patterna = new String[5];
		patterna[0] = "open";
		patterna[1] = "read";
		patterna[2] = "write";
		patterna[3] = "llseek";
		patterna[4] = "release";
		regexprMap.put("file_operations", patterna);

		patterna = new String[7];
		patterna[0] = "probe";
		patterna[1] = "suspend";
		patterna[2] = "resume";
		patterna[3] = "rescan";
		patterna[4] = "done";
		patterna[5] = "shutdown";
		patterna[6] = "remove";
		regexprMap.put("scsi_driver", patterna);
	}

	/*
	 * структуры для проверок */
	static {
		String[] resulta = new String[6];
		resulta[0] = "\n\t\trtmp$counter = $fcall; \n\t\tcheck_return_value(rtmp$counter);\n" +
				"\t\tif(rtmp$counter) \n\t\t\tgoto ldv_final;";
		resulta[1] = "\n\t\trtmp$counter = $fcall; \n\t\tcheck_return_value(rtmp$counter);\n" +
				"\t\tif(rtmp$counter) \n\t\t\tgoto ldv_final;";
		resulta[2] = "\n\t\trtmp$counter = $fcall; \n\t\tcheck_return_value(rtmp$counter);\n" +
				"\t\tif(rtmp$counter) \n\t\t\tgoto ldv_final;";
		resulta[3] = "\n\t\trtmp$counter = $fcall; \n\t\tcheck_return_value(rtmp$counter);\n" +
				"\t\tif(rtmp$counter < 0) \n\t\t\tgoto ldv_final;";
		resulta[4] = "\n\t\trtmp$counter = $fcall; \n\t\tcheck_return_value(rtmp$counter);\n" +
				"\t\tif(rtmp$counter < 0) \n\t\t\tgoto ldv_final;";
		resulta[5] = null;
		resultMap.put("__MAIN__", resulta);

		resulta = new String[9];
		resulta[0] = "\n\t\trtmp$counter = $fcall; \n\t\tcheck_return_value(rtmp$counter);\n" +
			"\t\tif(rtmp$counter) \n\t\t\tgoto ldv_final;";
		resulta[1] = null;
		resulta[2] = null;
		resulta[3] = null;
		resulta[4] = null;
		resulta[5] = null;
		resulta[6] = null;
		resulta[7] = null;
		resulta[8] = null;
		resultMap.put("usb_driver", resulta);

		resulta = new String[5];
		resulta[0] = "\n\t\trtmp$counter = $fcall; \n\t\tcheck_return_value(rtmp$counter);\n" +
		"\t\tif(rtmp$counter) \n\t\t\tgoto ldv_final;";
		resulta[1] = "\n\t\trtmp$counter = $fcall; \n\t\tcheck_return_value(rtmp$counter);\n" +
		"\t\tif(rtmp$counter < 0) \n\t\t\tgoto ldv_final;";
		resulta[2] = "\n\t\trtmp$counter = $fcall; \n\t\tcheck_return_value(rtmp$counter);\n" +
		"\t\tif(rtmp$counter < 0) \n\t\t\tgoto ldv_final;";
		resulta[3] = null;
		resulta[4] = null;
		resultMap.put("file_operations", resulta);

		resulta = new String[7];
		resulta[0] = "\n\t\trtmp$counter = $fcall; \n\t\tcheck_return_value(rtmp$counter);\n" +
		"\t\tif(rtmp$counter) \n\t\t\tgoto ldv_final;";
		resulta[1] = null;
		resulta[2] = null;
		resulta[3] = null;
		resulta[4] = null;
		resulta[5] = null;
		resulta[6] = null;
		resultMap.put("scsi_driver", resulta);
	}



	/**
	 * 
	 * @param structType structure type name
	 * @param ident list of struct initializers
	 * getName() - function name, right hand side of initializer
	 * getType() - field name in the structure, left side .field  
	 * @param intokens - function declaration tokens 
	 * @return
	 */
	public static List<TokenFunctionDecl> sortByPattern(String structType, List<NameAndType> inident, List<TokenFunctionDecl> intokens) {
		/* рассортируем сначала structType в соответствии с порядком
		 * и почистим от ненужного мусора
		 * ident */

		String tmpEqual;
		List<NameAndType> ident = new ArrayList<NameAndType>();
		for(int i=0; i<intokens.size(); i++) {
			/* получим имя */
			tmpEqual = intokens.get(i).getName();
			/* найдем его в списке идентификаторов
			 * и переместим в новый список */
			for(int j=0; j<inident.size(); j++) {
				if(inident.get(j).getName().equals(tmpEqual)) {
					/*
					 * добавлем только если такого еще нет
					 * */
					if(!contain(ident, inident.get(j).getName()))
						ident.add(inident.get(j));
					inident.remove(j);
					i--;
					break;
				}
			}
		}

		/* ищем сначала шаблон с полным совпадением имени */
		String[] scheme = regexprMap.get(structType);
		String[] tests  = resultMap.get(structType);
		if(scheme==null) {
			scheme = regexprMap.get("__MAIN__");
			tests  = resultMap.get("__MAIN__");
		}
		/* сортируем по выбранной схеме */
		List<TokenFunctionDecl> tokens = new ArrayList<TokenFunctionDecl>();
		for(int i=0; i<scheme.length; i++) {
			for(int j=0; j<intokens.size() && j<ident.size(); j++) {
				// вариант с contains требует, чтобы сначала матчился наибольший паттерн
				//if(ident.get(j)[1].contains(scheme[i])) {
				if(ident.get(j).getType().equals(scheme[i])) {
					/* добавляем проверку */
					((TokenFunctionDecl)intokens.get(j)).setTestString(tests[i]);
					tokens.add(intokens.get(j));
					/* добавляем */
					intokens.remove(j);
					ident.remove(j);
					j--;
					i--;
					break;
				}
			}
		}
		/* оставшиеся добавим в конец */
		for(int i=0; i<intokens.size(); i++)
			tokens.add(intokens.get(i));

		return tokens;
	}


	private static boolean contain(List<NameAndType> ident, String string) {
		Iterator<NameAndType> strIter = ident.iterator();
		while(strIter.hasNext()) {
			if(strIter.next().getName().equals(string))
				return true;
		}
		return false;
	}
}
