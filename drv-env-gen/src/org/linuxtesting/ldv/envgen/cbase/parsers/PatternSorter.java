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
package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.HashMap;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.parsers.ExtendedParserStruct.NameAndType;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;


/* статический класс с сохраненными и откомпиленными регекспами */
public class PatternSorter {

	public static class FuncInfo {
		String name;
		String check;
		
		/**
		 * @return the pattern to find a field in the structure
		 */
		public String getName() {
			return name;
		}
		
		/**
		 * @return expression which checks the result of the function 
		 */
		public String getCheckExpr() {
			return check;
		}
		
		public FuncInfo(String regexpr, String result) {
			super();
			this.name = regexpr;
			this.check = result;
		}

		@Override
		public String toString() {
			return "FuncInfo [name=" + name + ", check=" + check + "]";
		}		
	}
	
	private final Map<String,List<FuncInfo>> patterns = new HashMap<String, List<FuncInfo>>();
	
	/* struct name which is used as default key*/
	private final String DEFAULT_STRUCT = "default_main";

	final static String STRUCT_LIST = "struct_patterns";
	final static String PREFIX = "pattern";
	
	private String getCheckKey(String key, int index) {
		return PREFIX + "." + key + "." + index + "." + "check";	
	}

	private String getNameKey(String key, int index) {
		return PREFIX + "." + key + "." + index + "." + "name";	
	}

	/**
	 * @param properties 
	 */
	private void initPatterns(Properties props) throws IllegalArgumentException {
		String val = props.getProperty(STRUCT_LIST);
		if(val==null || val.trim().isEmpty()) {
			Logger.warn("Struct patterns list is empty " + val);
			throw new IllegalArgumentException("Struct patterns list is empty " + val);
		}
		String[] plist = val.split(",");		
		for(String ptr : plist) {			
			String key = ptr.trim();
			if(!key.isEmpty()) {
				int index = 0;			
				List<FuncInfo> ptrs = new ArrayList<FuncInfo>();
				
				String funcName = props.getProperty(getNameKey(key,index));			
				while(funcName!=null && !funcName.trim().isEmpty()) {
					funcName = funcName.trim();
					String funcCheck = props.getProperty(getCheckKey(key,index));
					if(funcCheck!=null) {
						funcCheck = funcCheck.trim();
						if(funcCheck.isEmpty()) {
							funcCheck = null;
						}
					}
					FuncInfo f = new FuncInfo(funcName, funcCheck);
					Logger.trace("Adding " + f);
					ptrs.add(f);
					index++;
					funcName = props.getProperty(getNameKey(key,index));			
				}
				Logger.debug("Loaded pattern " + key + " with " + ptrs.size() + " functions");
				patterns.put(key, ptrs);
			} else {
				Logger.warn("Skip pattern " + ptr);
			}
		}
		if(patterns.get(DEFAULT_STRUCT)==null) {
			throw new IllegalArgumentException("Default patterns " + DEFAULT_STRUCT + "should be always defined");
		}
	}
	
	@Deprecated
	private void initDefaultPatterns() {
		List<FuncInfo> mainPtrs = new ArrayList<FuncInfo>();
		mainPtrs.add(new FuncInfo(
				"open",
				"\n\t\t$retvar = $fcall; \n\t\tldv_check_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto $check_label;"));
		mainPtrs.add(new FuncInfo(
				"probe",
				"\n\t\t$retvar = $fcall; \n\t\tldv_check_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto $check_label;"));
		mainPtrs.add(new FuncInfo(
				"connect",
				"\n\t\t$retvar = $fcall; \n\t\tldv_check_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto $check_label;"));
		mainPtrs.add(new FuncInfo(
				"read",
				"\n\t\t$retvar = $fcall; \n\t\tldv_check_return_value($retvar);\n" +
				"\t\tif($retvar < 0) \n\t\t\tgoto $check_label;"));
		mainPtrs.add(new FuncInfo(
				"write",
				"\n\t\t$retvar = $fcall; \n\t\tldv_check_return_value($retvar);\n" +
				"\t\tif($retvar < 0) \n\t\t\tgoto $check_label;"));
		mainPtrs.add(new FuncInfo(
				"close",
				null));
		patterns.put(DEFAULT_STRUCT, mainPtrs);
		
		
		List<FuncInfo> usbPtrs = new ArrayList<FuncInfo>();
		usbPtrs.add(new FuncInfo(
				"probe",
				"\n\t\t$retvar = $fcall; \n\t\tldv_check_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto $check_label;"));
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
				"\n\t\t$retvar = $fcall; \n\t\tldv_check_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto $check_label;"));
		filePtrs.add(new FuncInfo(
				"read",
				"\n\t\t$retvar = $fcall; \n\t\tldv_check_return_value($retvar);\n" +
				"\t\tif($retvar < 0) \n\t\t\tgoto $check_label;"));
		filePtrs.add(new FuncInfo(
				"write",
				"\n\t\t$retvar = $fcall; \n\t\tldv_check_return_value($retvar);\n" +
				"\t\tif($retvar < 0) \n\t\t\tgoto $check_label;"));
		filePtrs.add(new FuncInfo(
				"llseek", null));
		filePtrs.add(new FuncInfo(
				"release", null));
		patterns.put("file_operations", filePtrs);

		List<FuncInfo> scsiPtrs = new ArrayList<FuncInfo>();
		scsiPtrs.add(new FuncInfo(
				"probe",
				"\n\t\t$retvar = $fcall; \n\t\tldv_check_return_value($retvar);\n" +
				"\t\tif($retvar) \n\t\t\tgoto $check_label;"));
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
	
	public PatternSorter(Properties properties) throws IllegalArgumentException {
		initPatterns(properties);
	}

	public PatternSorter() {
		initDefaultPatterns();
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
			assert pttr!=null : "Default patterns " + DEFAULT_STRUCT + "should be always defined";
		}
		/* сортируем по выбранной схеме */
		List<Item<TokenFunctionDecl>> items = new ArrayList<Item<TokenFunctionDecl>>(decls.size());
		
		//List<TokenFunctionDecl> tokens = new ArrayList<TokenFunctionDecl>();
		int itemsIndex = 0;
		for(FuncInfo f : pttr) {
			for(int j=0; j<decls.size() && j<filteredInitializers.size(); j++) {
				// вариант с contains требует, чтобы сначала матчился наибольший паттерн
				//if(ident.get(j)[1].contains(scheme[i])) {
				if(filteredInitializers.get(j).getType().equals(f.getName())) {
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
