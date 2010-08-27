package com.iceberg.generators;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.FileWriter;
import java.util.LinkedList;
import java.util.List;
import java.util.Iterator;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

import com.iceberg.FSOperationsBase;
import com.iceberg.Logger;
import com.iceberg.cbase.parsers.ExtendedParserSimple;
import com.iceberg.cbase.parsers.ExtendedParserStruct;
import com.iceberg.cbase.parsers.Item;
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
		generateByIndex(filename, null, null, false, new PlainParams(true,true));
	}
	
	public static void generate(String source, String destination, EnvParams p) {
		generateByIndex(source, null, destination, false, p);
	}
	
	public static DegResult deg(String filename, String counter, EnvParams... plist) {
		File file = new File(filename);
		if(!file.exists()) {
			Logger.warn("File \""+filename+"\" - not exists."); 
			return new DegResult(false);
		}
		return generateByIndex(filename, counter, filename, true, plist);
	}

	public static DegResult generateByIndex(String filename, String index, String destFilename, boolean isgenerateIfdefAroundMains, EnvParams... plist) {
		Matcher matcher = pattern.matcher(filename);
		if(!matcher.find()) {
			Logger.err("could not match C-extension");
			Logger.norm("USAGE: java -ea -jar mgenerator.jar <*>.c");
			return new DegResult(false);
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
				return new DegResult(false);
			}
			FileWriter fw = new FileWriter(destFilename);
			fw.write(ccontent);
			List<String> mains = new LinkedList<String>();
			for(EnvParams p : plist) {
				ep.setSortFunctionCalls(p.isSorted());
				String id = index + "_" + p.getStringId();
				int generatorCounter = 0;
				FuncGenerator fg = FuncGeneratorFactory.create(GenerateOptions.DRIVER_FUN_STRUCT_FUNCTIONS);				
				
				GeneratorContext ctx = new GeneratorContext(p,isgenerateIfdefAroundMains, id, fg, ppcParser, ep, fw, macroTokens, structTokens);
				
				generateMainHeader(ctx);
								
				int varDeclCnt = generateVarDeclSection(ctx, generatorCounter);			
				int varInitCnt = generateVarInitSection(ctx, generatorCounter);
				assert varDeclCnt==varInitCnt : 
					"the same variables should be declared and initialized: " 
					+ varDeclCnt + "!=" + varInitCnt;
				
				generateFunctionCallSectHeader(fw);			
				int nextCnt = generateModuleInitCall(ctx, varDeclCnt);
				int callCnt = generateFunctionCallSection(ctx, generatorCounter);
				
				assert varDeclCnt==callCnt : "the same variables should be used as parameters: " 
					+ varDeclCnt + "!=" + callCnt;
							
				nextCnt = generateModuleExitCall(ctx, nextCnt);
				
				generateFunctionCallSectFooter(fw);
				
				generateMainFooter(ctx);
				
				mains.add(id);
			}
			fw.close();
			return new DegResult(mains);
		} catch (IOException e) {
			e.printStackTrace();
		}
		return new DegResult(false);
	}


	public static class GeneratorContext {
		EnvParams p;		
		boolean isgenerateIfdefAroundMains; 
		String id;
		FuncGenerator fg;
		ParserPPCHelper ppcParser; 
		ExtendedParserStruct ep;
		FileWriter fw; 
		List<TokenFunctionDeclSimple> macroTokens;	
		List<TokenStruct> structTokens; 
		
		public GeneratorContext(EnvParams p,
				boolean isgenerateIfdefAroundMains, String id,
				FuncGenerator fg, ParserPPCHelper ppcParser, ExtendedParserStruct ep,
				FileWriter fw,
				List<TokenFunctionDeclSimple> macroTokens,
				List<TokenStruct> structTokens) {
			super();
			this.p = p;
			this.isgenerateIfdefAroundMains = isgenerateIfdefAroundMains;
			this.id = id;
			this.fg = fg;
			this.ppcParser = ppcParser;
			this.ep = ep;
			this.fw = fw;
			this.macroTokens = macroTokens;
			this.structTokens = structTokens;
		}
	}
	
	private static void generateFunctionCallSectFooter(FileWriter fw) throws IOException {
		StringBuffer sb = new StringBuffer();
		Logger.trace("Start appending end section...");
		Logger.trace("Start appending \"FUNCTION CALL SECTION\"...");			
		sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Checks that all resources and locks are correctly released before the driver will be unloaded. */");
		sb.append("\n\t\tldv_final: check_final_state();\n");
		sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_FUNCTION_CALL_SECTION+" */");		
		fw.write(sb.toString());
	}

	private static void generateFunctionCallSectHeader(FileWriter fw) throws IOException {
		StringBuffer sb = new StringBuffer();
		sb.append("\n/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_FUNCTION_CALL_SECTION+" */");
		Logger.trace("Start appending \"FUNCTION CALL SECTION\"...");
		sb.append("\n/*============================= FUNCTION CALL SECTION       =============================*/");
		fw.write(sb.toString());
	}


	private static void generateMainFooter(GeneratorContext ctx) throws IOException {
		StringBuffer sb = new StringBuffer();
		sb.append("\n\t\treturn;\n}\n");
		if (ctx.isgenerateIfdefAroundMains) {
			Logger.trace("Append macros: \"#endif\" for our function.");
			sb.append("#endif\n");
		}
		sb.append("/* "+ldvCommentTag+ldvTag_END+ldvTag_MAIN+" */\n");
		ctx.fw.write(sb.toString());
	}


	private static void generateMainHeader(GeneratorContext ctx) throws IOException {
		StringBuffer sb = new StringBuffer();
		sb.append("\n\n\n\n\n");
		if (ctx.isgenerateIfdefAroundMains) {
			Logger.debug("Option isgenerateIfdefAroundMains - on.");
			assert(ctx.id != null);
			Logger.trace("Append ifdef-macro: \"#ifdef LDV_MAIN"+ctx.id+"\".");
			sb.append("/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_MAIN+" */\n");
			sb.append("#ifdef LDV_MAIN"+ctx.id+"\n");
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
		sb.append("\n/* "+ldvCommentTag+ldvTag_FUNCTION_DECLARE_LDV+" Special function for LDV verifier. Returns arbitrary interger value. */");
		sb.append("\nint nondet_int(void);\n");
		sb.append("\n/* "+ldvCommentTag+ldvTag_VAR_DECLARE_LDV+" Special variable for LDV verifier. */");
		sb.append("\nextern int IN_INTERRUPT;\n");

	//	if(index == null)
	//		sb.append("void ldv_main(void) {\n\n\n");
	//	else
		Logger.trace("Start appending main function: \"+void ldv_main"+ctx.id+"(void)\"...");
		sb.append("\n/* "+ldvCommentTag+ldvTag_FUNCTION_MAIN+" Main function for LDV verifier. */");
		sb.append("\nvoid ldv_main"+ctx.id+"(void) {\n\n\n");
		ctx.fw.write(sb.toString());
	}


	private static int generateModuleExitCall(GeneratorContext ctx, int generatorCounter) throws IOException {
		StringBuffer sb = new StringBuffer();
		int localCounter = generatorCounter;
		Logger.trace("Append calls after stndart functions.");
		//sb.append("\n/*============================= FUNCTION CALL SECTION       =============================*/");
		for(TokenFunctionDeclSimple token : ctx.macroTokens) {
			if(token.getType() != 
				TokenFunctionDeclSimple.SimpleType.ST_MODULE_EXIT ) 
				continue;
			sb.append("\n\t/** INIT: init_type: " + token.getType() + " **/");
			sb.append("\n\t\t/* content: " + token.getContent() + "*/");
			ctx.fg.set(token,localCounter);
			appendPpcBefore(sb,ctx.ppcParser,token);
			/* увеличим счетчик, на число параметров*/
			localCounter+=token.getReplacementParams().size();
			/* добавляем вызовы функций */
			String lparams = ctx.fg.generateFunctionCall();
			sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Kernel calls driver release function before driver will be uploaded from kernel. This function declared as \"MODULE_EXIT(function name)\". */");
			sb.append("\n\t\t" + lparams);
			appendPpcAfter(sb,ctx.ppcParser,token);
			/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
			ctx.fw.write(sb.toString());
			sb = new StringBuffer();
			sb.append("\n");
		}
		ctx.fw.write(sb.toString());
		return localCounter;
	}


	private static int generateFunctionCallSection(GeneratorContext ctx, int generatorCounter) throws IOException {
		int localCounter = generatorCounter;
		Logger.trace("Append standart functions calls.");
		if(ctx.p instanceof PlainParams) {
			//generate single sequence of calls
			localCounter = generatePlainBody(ctx, localCounter);
		} else if(ctx.p instanceof SequenceParams) {
			SequenceParams sp = (SequenceParams)ctx.p; 
			switch(sp.getLength()) {
				case one:
					localCounter = generateSequenceOne(ctx, localCounter, sp);					
					break;					
				case n:
					localCounter = generateSequenceN(ctx, localCounter, sp);					
					break;					
				case infinite:
					localCounter = generateSequenceInf(ctx, localCounter, sp);					
					break;
			}
		} else {
			assert false;
		}
		return localCounter;
	}

	private static int generateSequenceInf(GeneratorContext ctx, int generatorCounter, SequenceParams sp) throws IOException {
		ctx.fw.write("\n\twhile(nondet_int()) {\n");
		int localCounter = generateSequenceOne(ctx, generatorCounter, sp);
		ctx.fw.write("\n\t}\n");
		return localCounter;
	}

	private static int generateSequenceN(GeneratorContext ctx, int generatorCounter, SequenceParams sp) throws IOException {
		ctx.fw.write("\n\tint i;\n");
		ctx.fw.write("\n\tfor(i=0; i<" + sp.getN() + "; i++) {\n");
		int localCounter = generateSequenceOne(ctx, generatorCounter, sp);
		ctx.fw.write("\n\t}\n");
		return localCounter;
	}

	private static int generateSequenceOne(GeneratorContext ctx, int generatorCounter, SequenceParams sp) throws IOException {
		int localCounter = generatorCounter;
		int tmpcounter = 0;
		for(TokenStruct token : ctx.structTokens) {
			if(token.hasInnerTokens() && token.isSorted() && sp.isStatefull()) {
				ctx.fw.write(token.getDeclStr("\t")+"\n");				
			}
		}
		ctx.fw.write("\n\tswitch(nondet_int()) {\n");		
		for(TokenStruct token : ctx.structTokens) {
			if(token.hasInnerTokens()) {
				if(token.isSorted() && sp.isStatefull()) {
					for(Item<TokenFunctionDecl> item : token.getSortedTokens()) {
						TokenFunctionDecl tfd = item.getData();						
						ctx.fw.write("\n\tcase " + tmpcounter + ": {\n");
						ctx.fw.write("\n\t\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getName() + " **/");
						ctx.fw.write("\n\t" + item.getPreconditionStrBegin(token.getId()) + "\n");
						localCounter = generateFunctionCall(ctx, token, localCounter, tmpcounter, tfd);
						ctx.fw.write("\n\t\t" + item.getUpdateStr(token.getId()) + "\n");						
						ctx.fw.write("\n\t" + item.getPreconditionStrEnd(token.getId()) + "\n");
						ctx.fw.write("\n\t}\n");
						ctx.fw.write("\n\tbreak;");
						tmpcounter++;						
					}
				} else {
					for(TokenFunctionDecl tfd : token.getTokens()) {
						ctx.fw.write("\n\tcase " + tmpcounter + ": {\n");
						ctx.fw.write("\n\t\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getName() + " **/");
						localCounter = generateFunctionCall(ctx, token, localCounter, tmpcounter, tfd);
						ctx.fw.write("\n\t}\n");
						ctx.fw.write("\n\tbreak;");
						tmpcounter++;
					}
				}
			}
		}
		ctx.fw.write("\n\t\t default: break;\n");
		ctx.fw.write("\n\t}\n");
		return localCounter;
	}


	private static int generatePlainBody(GeneratorContext ctx, int generatorCounter) throws IOException {		
		int localCounter = generatorCounter;
		int tmpcounter = 0;
		for(TokenStruct token : ctx.structTokens) {
			if(token.hasInnerTokens()) {
				ctx.fw.write("\n\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getName() + " **/");
				for(TokenFunctionDecl tfd : token.getTokens()) {
					localCounter = generateFunctionCall(ctx, token, localCounter, tmpcounter, tfd);
					tmpcounter++;
				}
				ctx.fw.write("\n");
			}
		}
		return localCounter;
	}


	private static int generateFunctionCall(GeneratorContext ctx,
			TokenStruct token, int generatorCounter, int tmpcounter, TokenFunctionDecl tfd) throws IOException {
		StringBuffer sb = new StringBuffer();				
		int localCounter = generatorCounter;
		sb.append("\n\t\t/* content: " + tfd.getContent() + "*/");
		ctx.fg.set(tfd,localCounter);
		appendPpcBefore(sb,ctx.ppcParser,tfd);
		/* увеличим счетчик, на число параметров*/
		localCounter+=tfd.getReplacementParams().size();
		/* добавляем вызовы функций */
		//String gdebug = tfd.getName();
		String funcCallStr = ctx.fg.generateFunctionCall();
		/* добавляем к ним проверку, если это стандартная функция */
		if (ctx.p.isCheck() && tfd.getTestString()!=null && !tfd.getRetType().contains("void")) {
			//sb.append("\n\t\tif ("+lparams.substring(0,lparams.length()-1)+tfd.getTestString()+")\n\t\t\treturn;");
			funcCallStr = funcCallStr.substring(0, funcCallStr.length()-1);
			//String debug = tfd.getTestString().replaceAll("\\$counter", Integer.toString(tmpcounter)).replaceAll("\\$fcall", lparams);
			if(tfd.getLdvCommentContent()!=null) {				
				sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" "+"Function from field \""+tfd.getLdvCommentContent()+"\" from driver structure with callbacks \""+token.getName()+"\". Standart function test for correct return result. */");
			} else {
				sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" */");
			}
			sb.append(tfd.getTestString().replaceAll("\\$counter", Integer.toString(tmpcounter)).replaceAll("\\$fcall", funcCallStr));
			/*	"int tmp$counter = $fcall \n\t\tcheck_return_value(tmp$counter);\n" +
			"\t\tif(tmp$counter) \n\t\treturn;";*/
		} else {
			/* иначе просто вызываем */
			if(tfd.getLdvCommentContent()!=null) {				
				sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" "+"Function from field \""+tfd.getLdvCommentContent()+"\" from driver structure with callbacks \""+token.getName()+"\" */");
			} else {
				sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" */");
			}
			sb.append("\n\t\t" + funcCallStr);
		}
		appendPpcAfter(sb,ctx.ppcParser,tfd);
		/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
		ctx.fw.write(sb.toString());
		return localCounter;
	}


	private static int generateModuleInitCall(GeneratorContext ctx, int generatorCounter) throws IOException {
		StringBuffer sb = new StringBuffer();
		int localCounter = generatorCounter;
		
		Logger.trace("Append part before standart functions.");
		for(TokenFunctionDeclSimple token : ctx.macroTokens) {
			/* первое, что мы сделаем, так это найдем init функции */
				if(token.getType() != 
					TokenFunctionDeclSimple.SimpleType.ST_MODULE_INIT) 
					continue;
				sb.append("\n\t/** INIT: init_type: " + token.getType() + " **/");
				sb.append("\n\t\t/* content: " + token.getContent() + "*/");
				ctx.fg.set(token,localCounter);
				appendPpcBefore(sb,ctx.ppcParser,token);
				/* увеличим счетчик, на число не void и не ... параметров*/
				Iterator<String> tokenNeededIter = token.getReplacementParams().iterator();
				while(tokenNeededIter.hasNext()) {
					String tstr = tokenNeededIter.next();
					if(!(tstr.trim().equals("void") || tstr.equals("..."))) localCounter++;
				}
				//localCounter+=token.getReplacementParams().size();
				/* добавляем вызовы функций */
				String lparams = ctx.fg.generateFunctionCall();
				sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Kernel calls driver init function after driver loading to kernel. This function declared as \"MODULE_INIT(function name)\". */");
				sb.append("\n\t\tif ("+lparams.substring(0,lparams.length()-1)+")");
				sb.append("\n\t\t\tgoto ldv_final;");
				appendPpcAfter(sb,ctx.ppcParser,token);
				/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
				ctx.fw.write(sb.toString());
				sb = new StringBuffer();
				sb.append("\n");
		}
		ctx.fw.write(sb.toString());
		return localCounter;
	}


	private static int generateVarInitSection(GeneratorContext ctx, int generatorCounter) throws IOException {
		StringBuffer sb = new StringBuffer();
		int localCounter = generatorCounter;
		sb.append("\n/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_VARIABLE_INITIALIZING_PART+" */");
		Logger.trace("Start appending \"VARIABLE INITIALIZING PART\"...");
		sb.append("\n/*============================= VARIABLE INITIALIZING PART  =============================*/");
		sb.append("IN_INTERRUPT = 1;\n");
		
		for(TokenStruct token : ctx.structTokens) {
			if(token.hasInnerTokens()) {
					Logger.trace("Start appending inittialization for structure type \""+token.getType()+"\" and name \""+token.getType()+"\"...");
					sb.append("\n\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getName() + " **/");
					for(TokenFunctionDecl tfd : token.getTokens()) {
						sb.append("\n\t\t/* content: " + tfd.getContent() + "*/");
						ctx.fg.set(tfd,localCounter);
						appendPpcBefore(sb,ctx.ppcParser,tfd);
						/* увеличим счетчик, на число параметров*/
						localCounter+=tfd.getReplacementParams().size();
						/* добавляем инициализацию */

						//lanai_proc_read
						//String gdebug = tfd.getName();

						List<String> lparams = ctx.fg.generateVarInit();
						Iterator<String> paramIterator = lparams.iterator();
						while(paramIterator.hasNext()) {
							sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_VAR_INIT+" Variable initialization for function \""+tfd.getName()+"\" */");
							sb.append("\n\t\t" + paramIterator.next());
						}
						appendPpcAfter(sb,ctx.ppcParser,tfd);
						/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
						ctx.fw.write(sb.toString());
						sb = new StringBuffer();
					}
					sb.append("\n");
					Logger.trace("Ok. Var initialization for structure type \""+token.getType()+"\" and name \""+token.getType()+"\" - successfully finished.");
			}
		}
		sb.append("\n\n\n");
		Logger.trace("Appending for \"VARIABLE INITIALIZING\" successfully finished");
		sb.append("\n/* "+ldvCommentTag+ldvTag_END+ldvTag_VARIABLE_INITIALIZING_PART+" */");
		ctx.fw.write(sb.toString());
		return localCounter;
	}


	private static int generateVarDeclSection(GeneratorContext ctx, int generatorCounter) throws IOException {
		
		StringBuffer sb = new StringBuffer();
		int tmpcounter = 0;		
		int localCounter = generatorCounter;
		Logger.trace("Start appending \"VARIABLE DECLARATION PART\"...");
		sb.append("\n/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_VARIABLE_DECLARATION_PART+" */");
		sb.append("\n/*============================= VARIABLE DECLARATION PART   =============================*/");
		
		for(TokenStruct token : ctx.structTokens) {
			if(token.hasInnerTokens()) {
					Logger.trace("Start appending declarations for structure type \""+token.getType()+"\" and name \""+token.getType()+"\"...");
					sb.append("\n\t/** STRUCT: struct type: " + token.getType() + ", struct name: " + token.getType() + " **/");
					for(TokenFunctionDecl tfd : token.getTokens()) {
						sb.append("\n\t\t/* content: " + tfd.getContent() + "*/");
						ctx.fg.set(tfd,localCounter);

						appendPpcBefore(sb, ctx.ppcParser, tfd);
						
						/* увеличим счетчик, на число параметров*/
						localCounter+=tfd.getReplacementParams().size();
						/* добавляем описания параметров */
						List<String> lparams = ctx.fg.generateVarDeclare();
						Iterator<String> paramIterator = lparams.iterator();
						while(paramIterator.hasNext()) {
							sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_VAR_DECLARE+" Variable declaration for function \""+tfd.getName()+"\" */");
							sb.append("\n\t\t" + paramIterator.next());
						}
						/* проверим - функция имеет проверки - т.е. стандартная ?
						 * если да, то объявим перемнную для результата */
						if(tfd.getTestString()!=null && !tfd.getRetType().contains("void")) {
							sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_VAR_DECLARE+" Variable declaration for test return result from function call \""+tfd.getName()+"\" */");
							sb.append("\n\t\t" + tfd.getRetType() + " rtmp" + tmpcounter + ";");
						}
						appendPpcAfter(sb,ctx.ppcParser,tfd);
						/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
						ctx.fw.write(sb.toString());
						sb = new StringBuffer();
						tmpcounter++;
					}
					sb.append("\n");
					Logger.trace("Ok. Var declarations for structure type \""+token.getType()+"\" and name \""+token.getType()+"\" - successfully finished.");
			}
		}
		sb.append("\n\n\n");
		Logger.trace("Appending for \"VARIABLE DECLARATION PART\" successfully finished");
		sb.append("\n/* "+ldvCommentTag+ldvTag_END+ldvTag_VARIABLE_DECLARATION_PART+" */");
		ctx.fw.write(sb.toString());
		return localCounter;
	}

	/**
	 * Close preprocessor directives 
	 * @param sb
	 * @param ppcParser
	 * @param tfd
	 */
	private static void appendPpcAfter(StringBuffer sb,
			ParserPPCHelper ppcParser, TokenFunctionDecl tfd) {
		/* получим директиквы препроцессора, те что до функции */
		List<TokenPpcDirective> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(tfd);
		/* добавим их ... */
		Logger.trace("ppcAfterTokens.size()=" + ppcAfterTokens.size());
		if(ppcAfterTokens.size()!=0) {
			sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
			for(TokenPpcDirective ppc : ppcAfterTokens) {
				sb.append("\n\t\t" + ppc.getContent());
				Logger.trace("ppc.getContent().length=" + ppc.getContent().length());
			}
			sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
		}
	}


	/**
	 * Open preprocessor directives 
	 * @param sb
	 * @param ppcParser
	 * @param tfd
	 */
	private static void appendPpcBefore(StringBuffer sb,
			ParserPPCHelper ppcParser, TokenFunctionDecl tfd) {
		/* получим директивы препроцессора, те что после функции */
		List<TokenPpcDirective> ppcBeforeTokens = ppcParser.getPPCWithoutINCLUDEbefore(tfd);
		/* добавим их ... */		
		if(ppcBeforeTokens.size()!=0) {
			sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
			for(TokenPpcDirective ppc : ppcBeforeTokens) {
				sb.append("\n\t\t" + ppc.getContent());
			}
		}
		sb.append("\n\t\t/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
	}
}
