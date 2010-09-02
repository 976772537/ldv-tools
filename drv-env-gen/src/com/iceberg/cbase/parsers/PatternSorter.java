package com.iceberg.cbase.parsers;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.iceberg.cbase.parsers.ExtendedParserStruct.NameAndType;
import com.iceberg.cbase.tokens.TokenFunctionDecl;
import com.iceberg.generators.MainGenerator;

/* статический класс с сохраненными и откомпиленными регекспами */
public class PatternSorter {

	public static class FuncInfo {
		String regexpr;
		String checkExpr;
		
		/**
		 * @return the pattern to find a field in the structure
		 */
		public String getRegexpr() {
			return regexpr;
		}
		
		/**
		 * @return expression which checks the result of the function 
		 */
		public String getCheckExpr() {
			return checkExpr;
		}
		
		public FuncInfo(String regexpr, String result) {
			super();
			this.regexpr = regexpr;
			this.checkExpr = result;
		}
	}
	
	private final Map<String,List<FuncInfo>> patterns = new HashMap<String, List<FuncInfo>>();
	
	/* шаблон, который используется по-умолчанию */
	private final String DEFAULT_STRUCT = "__MAIN__";
	
	/* инициализатор будет заполнять уже имеющиеся и работающие шаблоны -
	 * откомпиленные регекспы */
	private void initPatterns() {
		List<FuncInfo> mainPtrs = new ArrayList<FuncInfo>();
		mainPtrs.add(new FuncInfo(
				"open",
				"\n\t\t$retvar = $fcall; \n\t\tcheck_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto " + MainGenerator.getModuleExitLabel() + ";"));
		mainPtrs.add(new FuncInfo(
				"probe",
				"\n\t\t$retvar = $fcall; \n\t\tcheck_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto " + MainGenerator.getModuleExitLabel() + ";"));
		mainPtrs.add(new FuncInfo(
				"connect",
				"\n\t\t$retvar = $fcall; \n\t\tcheck_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto " + MainGenerator.getModuleExitLabel() + ";"));
		mainPtrs.add(new FuncInfo(
				"read",
				"\n\t\t$retvar = $fcall; \n\t\tcheck_return_value($retvar);\n" +
				"\t\tif($retvar < 0) \n\t\t\tgoto " + MainGenerator.getModuleExitLabel() + ";"));
		mainPtrs.add(new FuncInfo(
				"write",
				"\n\t\t$retvar = $fcall; \n\t\tcheck_return_value($retvar);\n" +
				"\t\tif($retvar < 0) \n\t\t\tgoto " + MainGenerator.getModuleExitLabel() + ";"));
		mainPtrs.add(new FuncInfo(
				"close",
				null));
		patterns.put(DEFAULT_STRUCT, mainPtrs);
		
		
		List<FuncInfo> usbPtrs = new ArrayList<FuncInfo>();
		usbPtrs.add(new FuncInfo(
				"probe",
				"\n\t\t$retvar = $fcall; \n\t\tcheck_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto " + MainGenerator.getModuleExitLabel() + ";"));
		usbPtrs.add(new FuncInfo(
				"suspend", null));
		usbPtrs.add(new FuncInfo(
				"resume", null));
		usbPtrs.add(new FuncInfo(
				"pre_reset", null));
		usbPtrs.add(new FuncInfo(
				"reset_resume", null));
		usbPtrs.add(new FuncInfo(
				"post_reset", null));
		usbPtrs.add(new FuncInfo(
				"disconnect", null));
		usbPtrs.add(new FuncInfo(
				"remove", null));
		usbPtrs.add(new FuncInfo(
				"shutdown", null));
		patterns.put("usb_driver", usbPtrs);
		
		List<FuncInfo> filePtrs = new ArrayList<FuncInfo>();
		filePtrs.add(new FuncInfo(
				"open",
				"\n\t\t$retvar = $fcall; \n\t\tcheck_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto " + MainGenerator.getModuleExitLabel() + ";"));
		filePtrs.add(new FuncInfo(
				"read",
				"\n\t\t$retvar = $fcall; \n\t\tcheck_return_value($retvar);\n" +
				"\t\tif($retvar < 0) \n\t\t\tgoto " + MainGenerator.getModuleExitLabel() + ";"));
		filePtrs.add(new FuncInfo(
				"write",
				"\n\t\t$retvar = $fcall; \n\t\tcheck_return_value($retvar);\n" +
				"\t\tif($retvar < 0) \n\t\t\tgoto " + MainGenerator.getModuleExitLabel() + ";"));
		filePtrs.add(new FuncInfo(
				"llseek", null));
		filePtrs.add(new FuncInfo(
				"release", null));
		patterns.put("file_operations", filePtrs);

		List<FuncInfo> scsiPtrs = new ArrayList<FuncInfo>();
		scsiPtrs.add(new FuncInfo(
				"probe",
				"\n\t\t$retvar = $fcall; \n\t\tcheck_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto " + MainGenerator.getModuleExitLabel() + ";"));
		scsiPtrs.add(new FuncInfo(
				"suspend", null));
		scsiPtrs.add(new FuncInfo(
				"resume", null));
		scsiPtrs.add(new FuncInfo(
				"rescan", null));
		scsiPtrs.add(new FuncInfo(
				"done", null));
		scsiPtrs.add(new FuncInfo(
				"shutdown", null));
		scsiPtrs.add(new FuncInfo(
				"remove", null));
		patterns.put("scsi_driver", scsiPtrs);
	}
	
	public PatternSorter() {
		initPatterns();
	}

	/**
	 * 
	 * @param structType - structure type name
	 * @param initializers - list of struct initializers
	 * getName() - function name, right hand side of initializer
	 * getType() - field name in the structure, left side .field  
	 * @param decls - function declaration tokens 
	 * @return
	 */
	public List<Item<TokenFunctionDecl>> sortByPattern(String structType, List<NameAndType> initializers, List<TokenFunctionDecl> decls) {
		/* рассортируем сначала structType в соответствии с порядком
		 * и почистим от ненужного мусора
		 * ident */
		List<NameAndType> filteredInitializers = new ArrayList<NameAndType>();
		for(int i=0; i<decls.size(); i++) {
			/* получим имя */
			String iName = decls.get(i).getName();
			/* найдем его в списке идентификаторов
			 * и переместим в новый список */
			for(int j=0; j<initializers.size(); j++) {
				if(initializers.get(j).getName().equals(iName)) {
					/*
					 * добавлем только если такого еще нет
					 * */
					if(!containsName(filteredInitializers, initializers.get(j).getName()))
						filteredInitializers.add(initializers.get(j));
					initializers.remove(j);
					i--;
					break;
				}
			}
		}

		/* ищем сначала шаблон с полным совпадением имени */
		List<FuncInfo> pttr = patterns.get(structType);
		if(pttr==null) {
			pttr = patterns.get(DEFAULT_STRUCT);
		}
		/* сортируем по выбранной схеме */
		List<Item<TokenFunctionDecl>> items = new ArrayList<Item<TokenFunctionDecl>>(decls.size());
		
		//List<TokenFunctionDecl> tokens = new ArrayList<TokenFunctionDecl>();
		int itemsIndex = 0;
		for(FuncInfo f : pttr) {
			for(int j=0; j<decls.size() && j<filteredInitializers.size(); j++) {
				// вариант с contains требует, чтобы сначала матчился наибольший паттерн
				//if(ident.get(j)[1].contains(scheme[i])) {
				if(filteredInitializers.get(j).getType().equals(f.getRegexpr())) {
					/* добавляем проверку */
					decls.get(j).setTestString(f.getCheckExpr());
					items.add(new OrderedItem<TokenFunctionDecl>(decls.get(j), false, itemsIndex));
					itemsIndex++;
					/* добавляем */
					decls.remove(j);
					filteredInitializers.remove(j);
					j--;
					//i--;??? do we need it 
					break;
				}
			}
		}
		if(!items.isEmpty()) {
			OrderedItem<TokenFunctionDecl> item = 
				(OrderedItem<TokenFunctionDecl>)items.get(items.size()-1);
			item.setLast(true);
		}
		/* оставшиеся добавим в конец */
		for(TokenFunctionDecl f : decls) {
			items.add(new UnorderedItem<TokenFunctionDecl>(f));
		}
		return items;
	}

	private static boolean containsName(List<NameAndType> list, String string) {
		for(NameAndType str : list) {
			if(str.getName().equals(string))
				return true;
		}
		return false;
	}
}
