package com.iceberg.generators;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.FileWriter;
import java.util.List;
import java.util.Iterator;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

import com.iceberg.FSOperationsBase;
import com.iceberg.Logger;
import com.iceberg.cbase.parsers.ExtendedParser;
import com.iceberg.cbase.parsers.ExtendedParserSimple;
import com.iceberg.cbase.parsers.ExtendedParserStruct;
import com.iceberg.cbase.parsers.ParserPPCHelper;
import com.iceberg.cbase.readers.ReaderCCommentsDel;
import com.iceberg.cbase.readers.ReaderInterface;
import com.iceberg.cbase.readers.ReaderWrapper;
import com.iceberg.cbase.tokens.Token;
import com.iceberg.cbase.tokens.TokenFunctionDecl;
import com.iceberg.cbase.tokens.TokenFunctionDeclSimple;
import com.iceberg.cbase.tokens.TokenStruct;
import com.iceberg.generators.fungen.FuncGenerator;
import com.iceberg.generators.fungen.FuncGeneratorFactory;
import com.iceberg.generators.fungen.GenerateOptions;


/**
 *
 * Было сделано изменение в паттерне поиска параметров функций
 * - там была проблема с определением параметра "void __user* var"
 *  почему-то тип параметра парсился, как void.
 *  Исправление еще не протестировано.
 *
 * @author iceberg
 *
 */
public class MainGenerator {

	private static Pattern pattern = Pattern.compile("^.*\\.c$");
	
	private static final String ldvCommentTag = "LDV_COMMENT";
	
	private static final String ldvTag_BEGIN = "_BEGIN";
	private static final String ldvTag_END = "_END";

	private static final String ldvTag_FUNCTION_CALL = "_FUNCTION_CALL";
	private static final String ldvTag_FUNCTION_MAIN = "_FUNCTION_MAIN";
	private static final String ldvTag_FUNCTION_DECLARE_LDV = "_FUNCTION_DECLARE_LDV";
	private static final String ldvTag_VAR_INIT = "_VAR_INIT";
	private static final String ldvTag_VAR_DECLARE = "_VAR_DECLARE";
	private static final String ldvTag_VAR_DECLARE_LDV = "_VAR_DECLARE_LDV";
	private static final String ldvTag_MAIN = "_MAIN";
	private static final String ldvTag_PREP = "_PREP";
	private static final String ldvTag_VARIABLE_INITIALIZING_PART = "_VARIABLE_INITIALIZING_PART";
	private static final String ldvTag_VARIABLE_DECLARATION_PART = "_VARIABLE_DECLARATION_PART";
	private static final String ldvTag_FUNCTION_CALL_SECTION = "_FUNCTION_CALL_SECTION";


	public static void main(String[] args) {

		long startf = System.currentTimeMillis();
		if(args.length != 1) {
			Logger.norm("USAGE: java -ea -jar mgenerator.jar <filename.c>");
			return;
		}
		generate(args[0]);
		long endf = System.currentTimeMillis();
		Logger.info("generate time: " + (endf-startf) + "ms");
	}


	public static void generate(String filename) {
		generateByIndex(filename, null, null, false);
	}
	
	public static void generate(String source, String destionation ) {
		generateByIndex(source, null, destionation, false);
	}
	
	public static boolean deg(String filename, String counter) {
		File file = new File(filename);
		if(!file.exists()) {
			Logger.warn("File \""+filename+"\" - not exists."); 
			return false;
		}
		return generateByIndex(filename, counter, filename, true);
	}

	public static boolean generateByIndex(String filename, String index, String destFilename, boolean isgenerateIfdefAroundMains) {
		Matcher matcher = pattern.matcher(filename);
		if(!matcher.find()) {
			Logger.err("could not match C-extension");
			Logger.norm("USAGE: java -ea -jar mgenerator.jar <*>.c");
			return false;
		}
		if(destFilename == null)
			destFilename = filename.replaceAll("\\.c$", ".c.ldv.c");
		FileReader reader = null;
		try {
			reader = new FileReader(filename);
			String ccontent = FSOperationsBase.readFileCRLF(filename);
			/* добавим ридер удаления комментариев */
			ReaderInterface wreader = new ReaderCCommentsDel(reader);
			/* сделаем парсер директив препроцессора */
			ParserPPCHelper ppcParser = new ParserPPCHelper((ReaderWrapper)wreader);
			/* создадим экземпляр парсера структур */
			ExtendedParser ep = new ExtendedParserStruct(wreader);
			/* создадим экземпляр парсера функций из макросов module_init и module_exit */
			ExtendedParser epSimple = new ExtendedParserSimple(wreader);
			/* распарсим структуры */
			Logger.debug("Pasring standart kernel driver structures...");
			List<Token> ltoken = ep.parse();
			Logger.debug("Ok. I have taken "+ltoken.size()+" structures.");
			Logger.debug("Pasring standart kernel driver macroses: module_init, module_exit, etc...");
			List<Token> macros_ltoken = epSimple.parse();
			Logger.debug("Ok. I have taken "+macros_ltoken.size()+" structures.");
			ltoken.addAll(macros_ltoken);
			if (ltoken.size() == 0)
				return false;
			FileWriter fw = new FileWriter(destFilename);
			fw.write(ccontent);
			StringBuffer sb = new StringBuffer();
			sb.append("\n\n\n\n\n");
			if (isgenerateIfdefAroundMains) {
				Logger.debug("Option isgenerateIfdefAroundMains - on.");
				assert(index != null);
				Logger.trace("Append ifdef-macro: \"#ifdef LDV_MAIN"+index+"\".");
				sb.append("/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_MAIN+" */\n");
				sb.append("#ifdef LDV_MAIN"+index+"\n");
			}
			sb.append("\t/*###########################################################################*/\n");
			sb.append("\t/*############## Driver Environment Generator 0.1 output ####################*/\n");
			sb.append("\t/*###########################################################################*/\n");
			sb.append("\n\n");
			Logger.trace("Pre-main code:");
			sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_DECLARE_LDV+" Special function for LDV verifier. Test if all kernel resources are correctly released by driver before driver will be unloaded. */");
			sb.append("\nvoid check_final_state(void);\n");
			sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_DECLARE_LDV+" Special function for LDV verifier. Test correct return result. */");
			sb.append("\nvoid check_return_value(int res);\n");
			sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_VAR_DECLARE_LDV+" Special variable for LDV verifier. */");
			sb.append("\nextern int IN_INTERRUPT;\n");

		//	if(index == null)
		//		sb.append("void ldv_main(void) {\n\n\n");
		//	else
			Logger.trace("Start appending main function: \"+void ldv_main"+index+"(void)\"...");
			sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_MAIN+" Main function for LDV verifier. */");
			sb.append("void ldv_main"+index+"(void) {\n\n\n");

			
			/* создадим счетчик */
			int generatorCounter = 0;
			FuncGenerator fg = FuncGeneratorFactory.create(GenerateOptions.DRIVER_FUN_STRUCT_FUNCTIONS);
			Logger.trace("Start appending \"VARIABLE DECLARATION PART\"...");
			sb.append("\n/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_VARIABLE_DECLARATION_PART+" */");
			sb.append("\n/*============================= VARIABLE DECLARATION PART   =============================*/");
			int localCounter = generatorCounter;
			int tmpcounter = 0;
			Iterator<Token> tokenIterator = ltoken.iterator();

			tokenIterator = ltoken.iterator();
			localCounter = generatorCounter;
			while(tokenIterator.hasNext()) {
				Token ptoken = tokenIterator.next();
				if(!(ptoken instanceof TokenStruct))
					continue;
				TokenStruct token = (TokenStruct)ptoken;
				if(token.hasInnerTokens()) {
						Logger.trace("Start appending declarations for structure type \""+token.getType()+"\" and name \""+token.getType()+"\"...");
						sb.append("\n\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getType() + " **/");
						Iterator<Token> innerTokenIterator = token.getTokens().iterator();
						while(innerTokenIterator.hasNext()) {
							TokenFunctionDecl tfd = (TokenFunctionDecl)innerTokenIterator.next();
							sb.append("\n\t\t/* content: " + tfd.getContent() + "*/");
							fg.set(tfd,localCounter);

							/* получим директиквы препроцессора, те что до функции */
							List<Token> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(tfd);
							/* добавим их ... */
							Iterator<Token> ppcTokenBeforeIterator = ppcBeforeTokens.iterator();
							if(ppcBeforeTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
							while(ppcTokenBeforeIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenBeforeIterator.next().getContent());
							if(ppcBeforeTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
							/* увеличим счетчик, на число параметров*/
							localCounter+=tfd.getReplacementParams().size();
							/* добавляем описания параметров */
							List<String> lparams = fg.generateVarDeclare();
							Iterator<String> paramIterator = lparams.iterator();
							while(paramIterator.hasNext()) {
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_VAR_DECLARE+" Variable declaration for function \""+tfd.getName()+"\" */");
								sb.append("\n\t\t" + paramIterator.next());
							}
							/* проверим - функция имеет проверки - т.е. стандартная ?
							 * если да, то объявим перемнную для результата */
							if(tfd.getTestString()!=null && !tfd.getRetType().contains("void")) {
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_VAR_DECLARE+" Variable declaration for test return result from function call \""+tfd.getName()+"\" */");
								sb.append("\n\t\t" + tfd.getRetType() + " rtmp" + tmpcounter++ + ";");
							}

							/* получим директивы препроцессора, те что после функции */
							List<Token> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(tfd);
							/* добавим их ... */
							Iterator<Token> ppcTokenAfterIterator = ppcAfterTokens.iterator();
							if(ppcAfterTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
							while(ppcTokenAfterIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
							if(ppcAfterTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
							/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
							fw.write(sb.toString());
							sb = new StringBuffer();
						}
						sb.append("\n");
						Logger.trace("Ok. Var declarations for structure type \""+token.getType()+"\" and name \""+token.getType()+"\" - successfully finished.");
				}
			}
			sb.append("\n\n\n");
			Logger.trace("Appending for \"VARIABLE DECLARATION PART\" successfully finished");
			sb.append("\n/* "+ldvCommentTag+ldvTag_END+ldvTag_VARIABLE_DECLARATION_PART+" */");
			sb.append("\n/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_VARIABLE_INITIALIZING_PART+" */");
			Logger.trace("Start appending \"VARIABLE INITIALIZING PART\"...");
			sb.append("\n/*============================= VARIABLE INITIALIZING PART  =============================*/");
			sb.append("IN_INTERRUPT = 1;\n");
			tokenIterator = ltoken.iterator();
			localCounter = generatorCounter;
			while(tokenIterator.hasNext()) {
				Token ptoken = tokenIterator.next();
				if(!(ptoken instanceof TokenStruct))
					continue;
				TokenStruct token = (TokenStruct)ptoken;
				if(token.hasInnerTokens()) {
						Logger.trace("Start appending inittialization for structure type \""+token.getType()+"\" and name \""+token.getType()+"\"...");
						sb.append("\n\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getName() + " **/");
						Iterator<Token> innerTokenIterator = token.getTokens().iterator();
						while(innerTokenIterator.hasNext()) {
							TokenFunctionDecl tfd = (TokenFunctionDecl)innerTokenIterator.next();
							sb.append("\n\t\t/* content: " + tfd.getContent() + "*/");
							fg.set(tfd,localCounter);
							/* получим директивы препроцессора, те что до функции */
							List<Token> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(tfd);
							/* добавим их ... */
							Iterator<Token> ppcTokenBeforeIterator = ppcBeforeTokens.iterator();
							if(ppcBeforeTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
							while(ppcTokenBeforeIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenBeforeIterator.next().getContent());
							if(ppcBeforeTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
							/* увеличим счетчик, на число параметров*/
							localCounter+=tfd.getReplacementParams().size();
							/* добавляем инициализацию */

							//lanai_proc_read
							//String gdebug = tfd.getName();

							List<String> lparams = fg.generateVarInit();
							Iterator<String> paramIterator = lparams.iterator();
							while(paramIterator.hasNext()) {
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_VAR_INIT+" Variable initialization for function \""+tfd.getName()+"\" */");
								sb.append("\n\t\t" + paramIterator.next());
							}
							/* получим директивы препроцессора, те что после функции */
							List<Token> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(tfd);
							/* добавим их ... */
							Iterator<Token> ppcTokenAfterIterator = ppcAfterTokens.iterator();
							if(ppcAfterTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
							while(ppcTokenAfterIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
							if(ppcAfterTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
							/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
							fw.write(sb.toString());
							sb = new StringBuffer();
						}
						sb.append("\n");
						Logger.trace("Ok. Var initialization for structure type \""+token.getType()+"\" and name \""+token.getType()+"\" - successfully finished.");
				}
			}
			sb.append("\n\n\n");
			Logger.trace("Appending for \"VARIABLE INITIALIZING\" successfully finished");
			sb.append("\n/* "+ldvCommentTag+ldvTag_END+ldvTag_VARIABLE_INITIALIZING_PART+" */");
			sb.append("\n/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_FUNCTION_CALL_SECTION+" */");
			Logger.trace("Start appending \"FUNCTION CALL SECTION\"...");
			sb.append("\n/*============================= FUNCTION CALL SECTION       =============================*/");
			tokenIterator = ltoken.iterator();
			localCounter = generatorCounter;
			Logger.trace("Append part before standart functions.");
			while(tokenIterator.hasNext()) {
				/* первое, что мы сделаем, так это найдем init функции */
				Token mtoken = tokenIterator.next();
				if(mtoken instanceof TokenFunctionDeclSimple) {
					TokenFunctionDeclSimple token = (TokenFunctionDeclSimple) mtoken;
					if(token.getType() != TokenFunctionDeclSimple.SimpleType.ST_MODULE_INIT ) continue;
					sb.append("\n\t/** INIT: init_type: " + token.getType() + " **/");
					sb.append("\n\t\t/* content: " + token.getContent() + "*/");
					fg.set(token,localCounter);
					/* получим директивы препроцессора, те что до функции */
					List<Token> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(token);
					/* добавим их ... */
					Iterator<Token> ppcTokenBeforeIterator = ppcBeforeTokens.iterator();
					if(ppcBeforeTokens.size()!=0)
						sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
					while(ppcTokenBeforeIterator.hasNext())
						sb.append("\n\t\t" + ppcTokenBeforeIterator.next().getContent());
					if(ppcBeforeTokens.size()!=0)
						sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
					/* увеличим счетчик, на число не void и не ... параметров*/
					Iterator<String> tokenNeededIter = token.getReplacementParams().iterator();
					while(tokenNeededIter.hasNext()) {
						String tstr = tokenNeededIter.next();
						if(!(tstr.trim().equals("void") || tstr.equals("..."))) localCounter++;
					}
					//localCounter+=token.getReplacementParams().size();
					/* добавляем вызовы функций */
					String lparams = fg.generateFunctionCall();
					sb.append("\n\t\tif ("+lparams.substring(0,lparams.length()-1)+") {");
					sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Kernel calls driver init function after driver loading to kernel. This function declared as \"MODULE_INIT(function name)\". */");
					sb.append("\n\t\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" */");
					sb.append("\n\t\t\treturn;");
					sb.append("\n\t\t\t}");
					/* получим директивы препроцессора, те что после функции */
					List<Token> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(token);
					/* добавим их ... */
					Iterator<Token> ppcTokenAfterIterator = ppcAfterTokens.iterator();
					if(ppcAfterTokens.size()!=0)
						sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
					while(ppcTokenAfterIterator.hasNext())
						sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
					if(ppcAfterTokens.size()!=0)
						sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
					/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
					fw.write(sb.toString());
					sb = new StringBuffer();
					generatorCounter = localCounter;
					sb.append("\n");
				}
			}

			Logger.trace("Append standart functions calls.");
			//sb.append("\n/*============================= FUNCTION CALL SECTION       =============================*/");
			tokenIterator = ltoken.iterator();
			localCounter = generatorCounter;
			tmpcounter = 0;
			while(tokenIterator.hasNext()) {
				/* теперь найдем рабочие функции */
				Token mtoken = tokenIterator.next();
				if(mtoken instanceof TokenStruct && mtoken.hasInnerTokens()) {
						TokenStruct token = (TokenStruct) mtoken;
						sb.append("\n\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getName() + " **/");
						Iterator<Token> innerTokenIterator = token.getTokens().iterator();
						while(innerTokenIterator.hasNext()) {
							TokenFunctionDecl tfd = (TokenFunctionDecl)innerTokenIterator.next();
							sb.append("\n\t\t/* content: " + tfd.getContent() + "*/");
							fg.set(tfd,localCounter);
							/* получим диретивы препроцессора, те что до функции */
							List<Token> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(tfd);
							/* добавим их ... */
							Iterator<Token> ppcTokenBeforeIterator = ppcBeforeTokens.iterator();
							if(ppcBeforeTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
							while(ppcTokenBeforeIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenBeforeIterator.next().getContent());
							if(ppcBeforeTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
							/* увеличим счетчик, на число параметров*/
							localCounter+=tfd.getReplacementParams().size();
							/* добавляем вызовы функций */

							//String gdebug = tfd.getName();



							String lparams = fg.generateFunctionCall();
							/* добавляем к ним проверку, если это стандартная функция */
							if (tfd.getTestString()!=null && !tfd.getRetType().contains("void")) {
								//sb.append("\n\t\tif ("+lparams.substring(0,lparams.length()-1)+tfd.getTestString()+")\n\t\t\treturn;");
								lparams = lparams.substring(0, lparams.length()-1);
								//String debug = tfd.getTestString().replaceAll("\\$counter", Integer.toString(tmpcounter)).replaceAll("\\$fcall", lparams);
								if(tfd.getLdvCommentContent()!=null) {				
									sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" "+"Function from field \""+tfd.getLdvCommentContent()+"\" from driver structure with callbacks \""+token.getName()+"\". Standart function test for correct return result. */");
									
								} else {
									sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" */");
								}
								sb.append(tfd.getTestString().replaceAll("\\$counter", Integer.toString(tmpcounter)).replaceAll("\\$fcall", lparams));
								tmpcounter++;
								/*	"int tmp$counter = $fcall \n\t\tcheck_return_value(tmp$counter);\n" +
								"\t\tif(tmp$counter) \n\t\treturn;";*/
							} else {
								/* иначе просто вызываем */
								if(tfd.getLdvCommentContent()!=null) {				
									sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" "+"Function from field \""+tfd.getLdvCommentContent()+"\" from driver structure with callbacks \""+token.getName()+"\" */");
									
								} else {
									sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" */");
								}
								sb.append("\n\t\t" + lparams);
							}
							/* получим диретивы препроцессора, те что после функции */
							List<Token> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(tfd);
							/* добавим их ... */
							Iterator<Token> ppcTokenAfterIterator = ppcAfterTokens.iterator();
							if(ppcAfterTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
							while(ppcTokenAfterIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
							if(ppcAfterTokens.size()!=0)
								sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
							/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
							fw.write(sb.toString());
							sb = new StringBuffer();
						}
						generatorCounter = localCounter;
						sb.append("\n");
				}
			}
			Logger.trace("Append calls after stndart functions.");
			//sb.append("\n/*============================= FUNCTION CALL SECTION       =============================*/");
			tokenIterator = ltoken.iterator();
			localCounter = generatorCounter;
			while(tokenIterator.hasNext()) {
				/* найдем exit функции */
				Token mtoken = tokenIterator.next();
				if(mtoken instanceof TokenFunctionDeclSimple) {
					TokenFunctionDeclSimple token = (TokenFunctionDeclSimple) mtoken;
					if(token.getType() != TokenFunctionDeclSimple.SimpleType.ST_MODULE_EXIT ) continue;
					sb.append("\n\t/** INIT: init_type: " + token.getType() + " **/");
					sb.append("\n\t\t/* content: " + token.getContent() + "*/");
					fg.set(token,localCounter);
					/* получим диретивы препроцессора, те что до функции */
					List<Token> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(token);
					/* добавим их ... */
					Iterator<Token> ppcTokenBeforeIterator = ppcBeforeTokens.iterator();
					if(ppcBeforeTokens.size()!=0)
						sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
					while(ppcTokenBeforeIterator.hasNext())
						sb.append("\n\t\t" + ppcTokenBeforeIterator.next().getContent());
					if(ppcBeforeTokens.size()!=0)
						sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
					while(ppcTokenBeforeIterator.hasNext())
					/* увеличим счетчик, на число параметров*/
					localCounter+=token.getReplacementParams().size();
					/* добавляем вызовы функций */
					String lparams = fg.generateFunctionCall();
					sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Kernel calls driver release function before driver will be uploaded from kernel. This function declared as \"MODULE_EXIT(function name)\". */");
					sb.append("\n\t\t" + lparams);
					/* получим директивы препроцессора, те что после функции */
					List<Token> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(token);
					/* добавим их ... */
					Iterator<Token> ppcTokenAfterIterator = ppcAfterTokens.iterator();
					if(ppcAfterTokens.size()!=0)
						sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
					while(ppcTokenAfterIterator.hasNext())
						sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
					if(ppcAfterTokens.size()!=0)
						sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
					/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
					fw.write(sb.toString());
					sb = new StringBuffer();
					generatorCounter = localCounter;
					sb.append("\n");
				}
			}
			Logger.trace("Start appending end section...");
			Logger.trace("Start appending \"FUNCTION CALL SECTION\"...");			
			sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Checks that all resources and locks are correctly released before the driver will be unloaded. */");
			sb.append("\n\tcheck_final_state();\n");
			sb.append("\n/* "+ldvCommentTag+ldvTag_END+ldvTag_FUNCTION_CALL_SECTION+" */");
			sb.append("\treturn;\n}\n");
			sb.append("/* "+ldvCommentTag+ldvTag_END+ldvTag_MAIN+" */\n");
			if (isgenerateIfdefAroundMains) {
				Logger.trace("Append macros: \"#endif\" for our function.");
				sb.append("#endif\n");
			}
			fw.write(sb.toString());
			fw.close();
			return true;
		} catch (IOException e) {
			e.printStackTrace();
		}
		return false;
	}

}
