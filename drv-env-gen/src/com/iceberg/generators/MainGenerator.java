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
import com.iceberg.cbase.parsers.ExtendedParserSimple;
import com.iceberg.cbase.parsers.ExtendedParserStruct;
import com.iceberg.cbase.parsers.ParserPPCHelper;
import com.iceberg.cbase.readers.ReaderCCommentsDel;
import com.iceberg.cbase.readers.ReaderInterface;
import com.iceberg.cbase.readers.ReaderWrapper;
import com.iceberg.cbase.tokens.TokenFunctionDecl;
import com.iceberg.cbase.tokens.TokenFunctionDeclSimple;
import com.iceberg.cbase.tokens.TokenPpcDirective;
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
			ExtendedParserStruct ep = new ExtendedParserStruct(wreader);
			/* создадим экземпляр парсера функций из макросов module_init и module_exit */
			ExtendedParserSimple epSimple = new ExtendedParserSimple(wreader);
			/* распарсим структуры */
			Logger.debug("Pasring standart kernel driver structures...");
			List<TokenStruct> structTokens = ep.parse();
			Logger.debug("Ok. I have taken "+structTokens.size()+" structures.");
			Logger.debug("Pasring standart kernel driver macroses: module_init, module_exit, etc...");
			List<TokenFunctionDeclSimple> macroTokens = epSimple.parse();
			Logger.debug("Ok. I have taken "+macroTokens.size()+" structures.");
			if (structTokens.size()+macroTokens.size() == 0) {
				Logger.debug("Nothing to generate.");
				return false;
			}
			FileWriter fw = new FileWriter(destFilename);
			fw.write(ccontent);
			generateMainHeader(fw, isgenerateIfdefAroundMains, index);
			
			/* создадим счетчик */
			int generatorCounter = 0;
			FuncGenerator fg = FuncGeneratorFactory.create(GenerateOptions.DRIVER_FUN_STRUCT_FUNCTIONS);
			
			generateVarDeclSection(fg, ppcParser, generatorCounter, fw, structTokens);
			
			generateVarInitSection(fg, ppcParser, generatorCounter, fw, structTokens);
			
			generatorCounter = generateModuleInitCall(fg, ppcParser, generatorCounter, fw, macroTokens);
			
			generatorCounter = generateFunctionCallSection(fg, ppcParser, generatorCounter, fw, structTokens);
			
			generatorCounter = generateModuleExitCall(fg, ppcParser, generatorCounter, fw, macroTokens);
			
			generateMainFooter(fw, isgenerateIfdefAroundMains, index);
			fw.close();
			return true;
		} catch (IOException e) {
			e.printStackTrace();
		}
		return false;
	}


	private static void generateMainFooter(FileWriter fw,
			boolean isgenerateIfdefAroundMains, String index) throws IOException {
		StringBuffer sb = new StringBuffer();
		Logger.trace("Start appending end section...");
		Logger.trace("Start appending \"FUNCTION CALL SECTION\"...");			
		sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Checks that all resources and locks are correctly released before the driver will be unloaded. */");
		sb.append("\n\t\tldv_final: check_final_state();\n");
		sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_FUNCTION_CALL_SECTION+" */");
		sb.append("\n\t\treturn;\n}\n");
		if (isgenerateIfdefAroundMains) {
			Logger.trace("Append macros: \"#endif\" for our function.");
			sb.append("#endif\n");
		}
		sb.append("/* "+ldvCommentTag+ldvTag_END+ldvTag_MAIN+" */\n");
		fw.write(sb.toString());
	}


	private static void generateMainHeader(FileWriter fw, 
			boolean isgenerateIfdefAroundMains, String index) throws IOException {
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
		sb.append("\n/* "+ldvCommentTag+ldvTag_FUNCTION_DECLARE_LDV+" Special function for LDV verifier. Test if all kernel resources are correctly released by driver before driver will be unloaded. */");
		sb.append("\nvoid check_final_state(void);\n");
		sb.append("\n/* "+ldvCommentTag+ldvTag_FUNCTION_DECLARE_LDV+" Special function for LDV verifier. Test correct return result. */");
		sb.append("\nvoid check_return_value(int res);\n");
		sb.append("\n/* "+ldvCommentTag+ldvTag_VAR_DECLARE_LDV+" Special variable for LDV verifier. */");
		sb.append("\nextern int IN_INTERRUPT;\n");

	//	if(index == null)
	//		sb.append("void ldv_main(void) {\n\n\n");
	//	else
		Logger.trace("Start appending main function: \"+void ldv_main"+index+"(void)\"...");
		sb.append("\n/* "+ldvCommentTag+ldvTag_FUNCTION_MAIN+" Main function for LDV verifier. */");
		sb.append("\nvoid ldv_main"+index+"(void) {\n\n\n");
		fw.write(sb.toString());
	}


	private static int generateModuleExitCall(FuncGenerator fg,
			ParserPPCHelper ppcParser, int generatorCounterOld, 
			FileWriter fw, List<TokenFunctionDeclSimple> macroTokens) throws IOException {
		Logger.trace("Append calls after stndart functions.");
		//sb.append("\n/*============================= FUNCTION CALL SECTION       =============================*/");
		int newGeneratorCounter = generatorCounterOld;
		int localCounter = newGeneratorCounter;
		StringBuffer sb = new StringBuffer();
		for(TokenFunctionDeclSimple token : macroTokens) {
			if(token.getType() != 
				TokenFunctionDeclSimple.SimpleType.ST_MODULE_EXIT ) 
				continue;
			sb.append("\n\t/** INIT: init_type: " + token.getType() + " **/");
			sb.append("\n\t\t/* content: " + token.getContent() + "*/");
			fg.set(token,localCounter);
			/* получим диретивы препроцессора, те что до функции */
			List<TokenPpcDirective> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(token);
			/* добавим их ... */
			Iterator<TokenPpcDirective> ppcTokenBeforeIterator = ppcBeforeTokens.iterator();
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
			List<TokenPpcDirective> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(token);
			/* добавим их ... */
			Iterator<TokenPpcDirective> ppcTokenAfterIterator = ppcAfterTokens.iterator();
			if(ppcAfterTokens.size()!=0)
				sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
			while(ppcTokenAfterIterator.hasNext())
				sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
			if(ppcAfterTokens.size()!=0)
				sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
			/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
			fw.write(sb.toString());
			sb = new StringBuffer();
			newGeneratorCounter = localCounter;
			sb.append("\n");
		}
		fw.write(sb.toString());
		return newGeneratorCounter;
	}


	private static int generateFunctionCallSection(FuncGenerator fg,
			ParserPPCHelper ppcParser, int generatorCounterOld, 
			FileWriter fw, List<TokenStruct> structTokens) throws IOException {
		Logger.trace("Append standart functions calls.");
		//sb.append("\n/*============================= FUNCTION CALL SECTION       =============================*/");
		int tmpcounter = 0;
		int newGeneratorCounter = generatorCounterOld;
		int localCounter = newGeneratorCounter;
		StringBuffer sb = new StringBuffer();
		for(TokenStruct token : structTokens) {
			/* теперь найдем рабочие функции */
			if(token.hasInnerTokens()) {
				sb.append("\n\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getName() + " **/");
				Iterator<TokenFunctionDecl> innerTokenIterator = token.getTokens().iterator();
				while(innerTokenIterator.hasNext()) {
					TokenFunctionDecl tfd = innerTokenIterator.next();
					sb.append("\n\t\t/* content: " + tfd.getContent() + "*/");
					fg.set(tfd,localCounter);
					/* получим диретивы препроцессора, те что до функции */
					List<TokenPpcDirective> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(tfd);
					/* добавим их ... */
					Iterator<TokenPpcDirective> ppcTokenBeforeIterator = ppcBeforeTokens.iterator();
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
					List<TokenPpcDirective> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(tfd);
					/* добавим их ... */
					Iterator<TokenPpcDirective> ppcTokenAfterIterator = ppcAfterTokens.iterator();
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
				newGeneratorCounter = localCounter;
				sb.append("\n");
			}
		}
		fw.write(sb.toString());
		return newGeneratorCounter;
	}


	private static int generateModuleInitCall(FuncGenerator fg,
			ParserPPCHelper ppcParser, int generatorCounterOld,
			FileWriter fw, List<TokenFunctionDeclSimple> macroTokens) throws IOException {
		StringBuffer sb = new StringBuffer();
		sb.append("\n/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_FUNCTION_CALL_SECTION+" */");
		Logger.trace("Start appending \"FUNCTION CALL SECTION\"...");
		sb.append("\n/*============================= FUNCTION CALL SECTION       =============================*/");
		
		int newGeneratorCounter = generatorCounterOld;
		int localCounter = newGeneratorCounter;
		Logger.trace("Append part before standart functions.");
		for(TokenFunctionDeclSimple token : macroTokens) {
			/* первое, что мы сделаем, так это найдем init функции */
				if(token.getType() != 
					TokenFunctionDeclSimple.SimpleType.ST_MODULE_INIT) 
					continue;
				sb.append("\n\t/** INIT: init_type: " + token.getType() + " **/");
				sb.append("\n\t\t/* content: " + token.getContent() + "*/");
				fg.set(token,localCounter);
				/* получим директивы препроцессора, те что до функции */
				List<TokenPpcDirective> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(token);
				/* добавим их ... */
				Iterator<TokenPpcDirective> ppcTokenBeforeIterator = ppcBeforeTokens.iterator();
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
				sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Kernel calls driver init function after driver loading to kernel. This function declared as \"MODULE_INIT(function name)\". */");
				sb.append("\n\t\tif ("+lparams.substring(0,lparams.length()-1)+")");
				sb.append("\n\t\t\tgoto ldv_final;");
				/* получим директивы препроцессора, те что после функции */
				List<TokenPpcDirective> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(token);
				/* добавим их ... */
				Iterator<TokenPpcDirective> ppcTokenAfterIterator = ppcAfterTokens.iterator();
				if(ppcAfterTokens.size()!=0)
					sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
				while(ppcTokenAfterIterator.hasNext())
					sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
				if(ppcAfterTokens.size()!=0)
					sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
				/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
				fw.write(sb.toString());
				sb = new StringBuffer();
				newGeneratorCounter = localCounter;
				sb.append("\n");
		}
		fw.write(sb.toString());
		return newGeneratorCounter;
	}


	private static void generateVarInitSection(FuncGenerator fg,
			ParserPPCHelper ppcParser, int generatorCounterUnchanged, 
			FileWriter fw, List<TokenStruct> structTokens) throws IOException {
		StringBuffer sb = new StringBuffer();
		sb.append("\n/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_VARIABLE_INITIALIZING_PART+" */");
		Logger.trace("Start appending \"VARIABLE INITIALIZING PART\"...");
		sb.append("\n/*============================= VARIABLE INITIALIZING PART  =============================*/");
		sb.append("IN_INTERRUPT = 1;\n");
		
		int localCounter = generatorCounterUnchanged;
		for(TokenStruct token : structTokens) {
			if(token.hasInnerTokens()) {
					Logger.trace("Start appending inittialization for structure type \""+token.getType()+"\" and name \""+token.getType()+"\"...");
					sb.append("\n\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getName() + " **/");
					Iterator<TokenFunctionDecl> innerTokenIterator = token.getTokens().iterator();
					while(innerTokenIterator.hasNext()) {
						TokenFunctionDecl tfd = innerTokenIterator.next();
						sb.append("\n\t\t/* content: " + tfd.getContent() + "*/");
						fg.set(tfd,localCounter);
						/* получим директивы препроцессора, те что до функции */
						List<TokenPpcDirective> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(tfd);
						/* добавим их ... */
						Iterator<TokenPpcDirective> ppcTokenBeforeIterator = ppcBeforeTokens.iterator();
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
						List<TokenPpcDirective> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(tfd);
						/* добавим их ... */
						Iterator<TokenPpcDirective> ppcTokenAfterIterator = ppcAfterTokens.iterator();
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
		fw.write(sb.toString());
	}


	private static void generateVarDeclSection(FuncGenerator fg,
		ParserPPCHelper ppcParser, int generatorCounterUnchanged, 
		FileWriter fw, List<TokenStruct> structTokens) throws IOException {
		
		StringBuffer sb = new StringBuffer();
		Logger.trace("Start appending \"VARIABLE DECLARATION PART\"...");
		sb.append("\n/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_VARIABLE_DECLARATION_PART+" */");
		sb.append("\n/*============================= VARIABLE DECLARATION PART   =============================*/");
		int tmpcounter = 0;
		
		int localCounter = generatorCounterUnchanged;
		
		for(TokenStruct token : structTokens) {
			if(token.hasInnerTokens()) {
					Logger.trace("Start appending declarations for structure type \""+token.getType()+"\" and name \""+token.getType()+"\"...");
					sb.append("\n\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getType() + " **/");
					Iterator<TokenFunctionDecl> innerTokenIterator = token.getTokens().iterator();
					while(innerTokenIterator.hasNext()) {
						TokenFunctionDecl tfd = innerTokenIterator.next();
						sb.append("\n\t\t/* content: " + tfd.getContent() + "*/");
						fg.set(tfd,localCounter);

						/* получим директиквы препроцессора, те что до функции */
						List<TokenPpcDirective> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(tfd);
						/* добавим их ... */
						Iterator<TokenPpcDirective> ppcTokenBeforeIterator = ppcBeforeTokens.iterator();
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
						List<TokenPpcDirective> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(tfd);
						/* добавим их ... */
						Iterator<TokenPpcDirective> ppcTokenAfterIterator = ppcAfterTokens.iterator();
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
		fw.write(sb.toString());
	}

}
