package org.linuxtesting.ldv.envgen.generators;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.FileWriter;
import java.util.LinkedList;
import java.util.List;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import java.util.TreeMap;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

import org.linuxtesting.ldv.envgen.FSOperationsBase;
import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.parsers.CallbackItem;
import org.linuxtesting.ldv.envgen.cbase.parsers.ExtendedParserFunction;
import org.linuxtesting.ldv.envgen.cbase.parsers.ExtendedParserSimple;
import org.linuxtesting.ldv.envgen.cbase.parsers.ExtendedParserStruct;
import org.linuxtesting.ldv.envgen.cbase.parsers.Item;
import org.linuxtesting.ldv.envgen.cbase.parsers.ParserPPCHelper;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderCCommentsDel;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderWrapper;
import org.linuxtesting.ldv.envgen.cbase.tokens.CallbackCollectionToken;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenStruct;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionCall;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDeclSimple;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenPpcDirective;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFuncCollection;
import org.linuxtesting.ldv.envgen.generators.fungen.FuncGenerator;
import org.linuxtesting.ldv.envgen.generators.fungen.FuncGeneratorFactory;
import org.linuxtesting.ldv.envgen.generators.fungen.GenerateOptions;



/**
 *
 * Changed on Nov 2010: iceberg
 * Pattern for search function parameters was changed to resolve the 
 * issue with "void __user* var". It was recognized as void.
 *
 * @author Alexander Strakh
 * @author Vadim Mutilin
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
	public static final String NONDET_INT = "nondet_int";
	
	public static String getModuleExitLabel() {
		return "ldv_module_exit";
	}

	public static String getCheckFinalLabel() {
		return "ldv_final";
	}

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
		generateByIndex(null, filename, null, null, false, new PlainParams(true,true,false,true));
	}
	
	public static void generate(String source, String destination, EnvParams p) {
		generateByIndex(null, source, null, destination, false, p);
	}
	
	public static DegResult deg(Properties properties, String filename, String indexId, EnvParams... plist) {
		File file = new File(filename);
		if(!file.exists()) {
			Logger.warn("File \""+filename+"\" - not exists."); 
			return new DegResult(false);
		}
		return generateByIndex(properties, filename, indexId, filename, true, plist);
	}

	public static DegResult generateByIndex(Properties properties, String filename, String index, String destFilename, boolean isgenerateIfdefAroundMains, EnvParams... plist) {
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
			
			Map<String, TokenFunctionDecl> parsedFunctions = null;
			if(shouldGenInterruptForSomeParams(plist)) {
				Logger.debug("parseAllFunctions");
				parsedFunctions = parseAllFunctions(wreader);
			} else {
				Logger.debug("do not generate any interrupt... calls");
			}
			/* создадим экземпляр парсера структур */
			ExtendedParserStruct ep = 
				new ExtendedParserStruct(properties, wreader, parsedFunctions);
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
				//this does not work because parsing is done
				//ep.setSortFunctionCalls(p.isSorted());
				String id = index + "_" + p.getStringId();
				FuncGenerator fg = FuncGeneratorFactory.create(GenerateOptions.DRIVER_FUN_STRUCT_FUNCTIONS, p);				
				
				List<TokenFuncCollection> collection = new LinkedList<TokenFuncCollection>(structTokens);
				
				if(p.isGenInterrupt()) {
					assert parsedFunctions!=null;
					//add collection with interrupt calls
					Logger.debug("add collection with interrupt calls");
					TokenFuncCollection interrupts = createInterrupts(parsedFunctions);
					collection.add(interrupts);
				}
				GeneratorContext ctx = new GeneratorContext(p,isgenerateIfdefAroundMains, id, fg, ppcParser, ep, fw, macroTokens, collection);
				
				generateMainHeader(ctx);								
					generateVarDeclSection(ctx);			
					generateVarInitSection(ctx);
					
					generateFunctionCallSectHeader(ctx);			
						generateModuleInitCall(ctx);
						generateDriverCallbacksSection(ctx);
						ctx.fw.write("\n" + ctx.getIndent() + getModuleExitLabel() + ": \n"); 
						generateModuleExitCall(ctx);				
					generateFunctionCallSectFooter(ctx);				
				generateMainFooter(ctx);
				
				mains.add(id);
			}
			fw.close();
			return new DegResult(mains);
		} catch (IllegalArgumentException e) {
			throw e;
		} catch (IOException e) {
			e.printStackTrace();
		}
		return new DegResult(false);
	}

	private static TokenFuncCollection createInterrupts(
			Map<String, TokenFunctionDecl> parsedFunctions) {
		String targetFunction = "request_irq";
		Logger.debug("Create callbacks for " + targetFunction);
		List<TokenFunctionDecl> tokens = new LinkedList<TokenFunctionDecl>();
		//get second parameter
		int callbackParamInd = 1;
		for(Map.Entry<String, TokenFunctionDecl> e : parsedFunctions.entrySet()) {
			TokenFunctionDecl tfd = e.getValue();
			assert tfd.getTokens()!=null;
			for(TokenFunctionCall tcall : tfd.getTokens()) {
				Logger.debug("Process call=" + tcall);
				if(targetFunction.equals(tcall.getName())) {
					Logger.debug("Found " + targetFunction + " call=" + tcall);
					String callbackParam = tcall.getParams().get(callbackParamInd);
					Logger.debug("Get parameter " + callbackParamInd + "=" + callbackParam);
					TokenFunctionDecl callback = parsedFunctions.get(callbackParam);
					if(callback!=null) {
						Logger.debug("callback found " + callback.getName());
						tokens.add(callback);
					} else {
						Logger.debug("callback not found " + callbackParam);
					}
				}
			}
		}
		return new CallbackCollectionToken(targetFunction, 
				"interrupt handler calls", tokens);
	}

	private static boolean shouldGenInterruptForSomeParams(EnvParams[] plist) {
		for(EnvParams p : plist) {
			if(p.isGenInterrupt()) {
				return true;
			}
		}
		return false;
	}

	private static Map<String, TokenFunctionDecl> parseAllFunctions(ReaderInterface reader) {
		Map<String, TokenFunctionDecl> parsedFunctions = new TreeMap<String, TokenFunctionDecl>();
		ExtendedParserFunction innerParserFunctions = new ExtendedParserFunction(reader);
		innerParserFunctions.parseFunctionCallsOn();
		List<TokenFunctionDecl> functions = innerParserFunctions.parse();
		for(TokenFunctionDecl tfd : functions) {
			parsedFunctions.put(tfd.getName(), tfd);
		}
		return parsedFunctions;
	}

	public static class GeneratorContext {
		final EnvParams p;		
		final boolean isgenerateIfdefAroundMains; 
		final String id;
		final FuncGenerator fg;
		final ParserPPCHelper ppcParser; 
		final ExtendedParserStruct ep;
		final FileWriter fw; 
		final List<TokenFunctionDeclSimple> macroTokens;	
		final List<TokenFuncCollection> structTokens; 
		private String indent = "";
		private static final String SHIFT = "\t";
		
		public GeneratorContext(EnvParams p,
				boolean isgenerateIfdefAroundMains, String id,
				FuncGenerator fg, ParserPPCHelper ppcParser, ExtendedParserStruct ep,
				FileWriter fw,
				List<TokenFunctionDeclSimple> macroTokens,
				List<TokenFuncCollection> structTokens) {
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

		public String getIndent() {
			return indent;
		}

		public void incIndent() {
			indent += SHIFT;
		}

		public void decIndent() {
			assert indent.length()>=SHIFT.length();
			indent = indent.substring(0, indent.length()-SHIFT.length());
		}
	}
		
	private static void generateMainFooter(GeneratorContext ctx) throws IOException {
		StringBuffer sb = new StringBuffer();
		sb.append("\n" + ctx.getIndent() + "return;\n");
		ctx.decIndent();
		sb.append("\n" + ctx.getIndent() + "}\n");
		if (ctx.isgenerateIfdefAroundMains) {
			Logger.trace("Append macros: \"#endif\" for our function.");
			sb.append("#endif\n");
		}
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_END+ldvTag_MAIN+" */\n");
		ctx.fw.write(sb.toString());
	}

	private static void generateMainHeader(GeneratorContext ctx) throws IOException {
		StringBuffer sb = new StringBuffer();
		sb.append("\n\n\n\n\n");
		if (ctx.isgenerateIfdefAroundMains) {
			Logger.debug("Option isgenerateIfdefAroundMains - on.");
			assert(ctx.id != null);
			Logger.trace("Append ifdef-macro: \"#ifdef LDV_MAIN"+ctx.id+"\".");
			sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_MAIN+" */\n");
			sb.append("#ifdef LDV_MAIN"+ctx.id+"\n");
		}
		sb.append("\n" + ctx.getIndent() + "/*###########################################################################*/\n");
		sb.append("\n" + ctx.getIndent() + "/*############## Driver Environment Generator 0.2 output ####################*/\n");
		sb.append("\n" + ctx.getIndent() + "/*###########################################################################*/\n");
		sb.append("\n\n");
		Logger.trace("Pre-main code:");
		if(ctx.p.isInit())
			sb.append("#include <linux/slab.h>");
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_DECLARE_LDV+" Special function for LDV verifier. Test if all kernel resources are correctly released by driver before driver will be unloaded. */");
		sb.append("\n" + ctx.getIndent() + "void ldv_check_final_state(void);\n");
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_DECLARE_LDV+" Special function for LDV verifier. Test correct return result. */");
		sb.append("\n" + ctx.getIndent() + "void ldv_check_return_value(int res);\n");
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_DECLARE_LDV+" Special function for LDV verifier. Initializes the model. */");
		sb.append("\n" + ctx.getIndent() + "void ldv_initialize(void);\n");
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_DECLARE_LDV+" Special function for LDV verifier. Returns arbitrary interger value. */");
		sb.append("\n" + ctx.getIndent() + "int " + NONDET_INT + "(void);\n");
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_VAR_DECLARE_LDV+" Special variable for LDV verifier. */");
		
		sb.append("\n" + ctx.getIndent() + CallbackItem.getInterruptVarDecl() + ";\n");

	//	if(index == null)
	//		sb.append("void ldv_main(void) {\n\n\n");
	//	else
		Logger.trace("Start appending main function: \"+void ldv_main"+ctx.id+"(void)\"...");
		sb.append("\n/* "+ldvCommentTag+ldvTag_FUNCTION_MAIN+" Main function for LDV verifier. */");
		sb.append("\n" + ctx.getIndent() + "void ldv_main"+ctx.id+"(void) {\n\n\n");
		ctx.incIndent();
		ctx.fw.write(sb.toString());
	}

	private static void generateFunctionCallSectHeader(GeneratorContext ctx) throws IOException {
		StringBuffer sb = new StringBuffer();
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_FUNCTION_CALL_SECTION+" */");
		Logger.trace("Start appending \"FUNCTION CALL SECTION\"...");
		sb.append("\n" + ctx.getIndent() + "/*============================= FUNCTION CALL SECTION       =============================*/");
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Initialize LDV model. */");
		sb.append("\n" + ctx.getIndent() + "ldv_initialize();\n");		
		ctx.fw.write(sb.toString());
	}

	private static void generateFunctionCallSectFooter(GeneratorContext ctx) throws IOException {
		StringBuffer sb = new StringBuffer();
		Logger.trace("Start appending end section...");
		Logger.trace("Start appending \"FUNCTION CALL SECTION\"...");			
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Checks that all resources and locks are correctly released before the driver will be unloaded. */");
		sb.append("\n" + ctx.getIndent() + getCheckFinalLabel() + ": ldv_check_final_state();\n");
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_END+ldvTag_FUNCTION_CALL_SECTION+" */");		
		ctx.fw.write(sb.toString());
	}

	private static void generateModuleInitCall(GeneratorContext ctx) throws IOException {
		StringBuffer sb = new StringBuffer();
		
		Logger.trace("Append part before standart functions.");
		for(TokenFunctionDeclSimple token : ctx.macroTokens) {
			/* первое, что мы сделаем, так это найдем init функции */
				if(token.getType() != 
					TokenFunctionDeclSimple.SimpleType.ST_MODULE_INIT) 
					continue;
				sb.append("\n" + ctx.getIndent() + "/** INIT: init_type: " + token.getType() + " **/");
				sb.append("\n" + ctx.getIndent() + "/* content: " + token.getContent() + "*/");
				ctx.fg.set(token);
				appendPpcBefore(sb,ctx,token);
				/* добавляем вызовы функций */
				sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Kernel calls driver init function after driver loading to kernel. This function declared as \"MODULE_INIT(function name)\". */");
				sb.append(ctx.fg.generateCheckedFunctionCall(FuncGenerator.CHECK_INIT_MODULE, getCheckFinalLabel(), ctx.getIndent()));
				appendPpcAfter(sb,ctx,token);
				/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
				ctx.fw.write(sb.toString());
				sb = new StringBuffer();
				sb.append("\n");
		}
		ctx.fw.write(sb.toString());
	}

	private static void generateModuleExitCall(GeneratorContext ctx) throws IOException {
		StringBuffer sb = new StringBuffer();
		Logger.trace("Append calls after stndart functions.");
		//sb.append("\n/*============================= FUNCTION CALL SECTION       =============================*/");
		for(TokenFunctionDeclSimple token : ctx.macroTokens) {
			if(token.getType() != 
				TokenFunctionDeclSimple.SimpleType.ST_MODULE_EXIT ) 
				continue;
			sb.append("\n" + ctx.getIndent() + "/** INIT: init_type: " + token.getType() + " **/");
			sb.append("\n" + ctx.getIndent() + "/* content: " + token.getContent() + "*/");
			ctx.fg.set(token);
			appendPpcBefore(sb,ctx,token);
			/* увеличим счетчик, на число параметров*/
			/* добавляем вызовы функций */
			sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" Kernel calls driver release function before driver will be uploaded from kernel. This function declared as \"MODULE_EXIT(function name)\". */");
			sb.append(ctx.fg.generateSimpleFunctionCall(ctx.getIndent()));
			appendPpcAfter(sb,ctx,token);
			/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
			ctx.fw.write(sb.toString());
			sb = new StringBuffer();
			sb.append("\n");
		}
		ctx.fw.write(sb.toString());
	}

	private static void generateVarInitSection(GeneratorContext ctx) throws IOException {

		StringBuffer sb = new StringBuffer();
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_VARIABLE_INITIALIZING_PART+" */");
		Logger.trace("Start appending \"VARIABLE INITIALIZING PART\"...");
		sb.append("\n" + ctx.getIndent() + "/*============================= VARIABLE INITIALIZING PART  =============================*/");
		sb.append("\n" + ctx.getIndent() + CallbackItem.getInterruptInit() + ";\n");
		if(ctx.p.isInit()) {
			for(TokenFuncCollection token : ctx.structTokens) {
				if(token.hasInnerTokens()) {
						Logger.trace("Start appending inittialization for " + token.getDesc() +"\"...");
						sb.append("\n" + ctx.getIndent() + "/** " + token.getDesc() + " **/");
						for(TokenFunctionDecl tfd : token.getTokens()) {
							sb.append("\n" + ctx.getIndent() + "/* content: " + tfd.getContent() + "*/");
							ctx.fg.set(tfd);
							appendPpcBefore(sb,ctx,tfd);
							/* добавляем инициализацию */ 
							List<String> lparams = ctx.fg.generateVarInit();
							Iterator<String> paramIterator = lparams.iterator();
							while(paramIterator.hasNext()) {
								sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_VAR_INIT+" Variable initialization for function \""+tfd.getName()+"\" */");
								sb.append("\n" + ctx.getIndent() + paramIterator.next());
							}
							appendPpcAfter(sb,ctx,tfd);
							/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
							ctx.fw.write(sb.toString());
							sb = new StringBuffer();
						}
						sb.append("\n");
						Logger.trace("Ok. Var initialization for " + token.getDesc() + "\" - successfully finished.");
				}
			}
		}
		sb.append("\n\n\n");
		Logger.trace("Appending for \"VARIABLE INITIALIZING\" successfully finished");
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_END+ldvTag_VARIABLE_INITIALIZING_PART+" */");
		ctx.fw.write(sb.toString());
	}

	private static void generateVarDeclSection(GeneratorContext ctx) throws IOException {
		
		StringBuffer sb = new StringBuffer();
		Logger.trace("Start appending \"VARIABLE DECLARATION PART\"...");
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_VARIABLE_DECLARATION_PART+" */");
		sb.append("\n" + ctx.getIndent() + "/*============================= VARIABLE DECLARATION PART   =============================*/");
		
		for(TokenFuncCollection token : ctx.structTokens) {
			if(token.hasInnerTokens()) {
					Logger.trace("Start appending declarations for " + token.getDesc()+"\"...");
					sb.append("\n" + ctx.getIndent() + "/** " + token.getDesc() + " **/");
					for(TokenFunctionDecl tfd : token.getTokens()) {
						sb.append("\n" + ctx.getIndent() + "/* content: " + tfd.getContent() + "*/");
						ctx.fg.set(tfd);

						appendPpcBefore(sb, ctx, tfd);
						/* добавляем описания параметров */
						List<String> lparams = ctx.fg.generateVarDeclare(ctx.p.isInit());
						Iterator<String> paramIterator = lparams.iterator();
						while(paramIterator.hasNext()) {
							sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_VAR_DECLARE+" Variable declaration for function \""+tfd.getName()+"\" */");
							sb.append("\n" + ctx.getIndent() + paramIterator.next());
						}
						/* проверим - функция имеет проверки - т.е. стандартная ?
						 * если да, то объявим перемнную для результата */
						if(tfd.getTestString()!=null && !tfd.getRetType().contains("void")) {
							
							sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_VAR_DECLARE+" Variable declaration for test return result from function call \""+tfd.getName()+"\" */");
							sb.append("\n" + ctx.getIndent() + ctx.fg.generateRetDecl());
						}
						appendPpcAfter(sb,ctx,tfd);
						/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
						ctx.fw.write(sb.toString());
						sb = new StringBuffer();
					}
					sb.append("\n");
					Logger.trace("Ok. Var declarations for " + token.getDesc()+"\" - successfully finished.");
			}
		}
		sb.append("\n\n\n");
		Logger.trace("Appending for \"VARIABLE DECLARATION PART\" successfully finished");
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_END+ldvTag_VARIABLE_DECLARATION_PART+" */");
		ctx.fw.write(sb.toString());
	}

	private static void generateDriverCallbacksSection(GeneratorContext ctx) throws IOException {
		Logger.trace("Append standart functions calls.");
		if(ctx.p instanceof PlainParams) {
			//generate single sequence of calls
			generatePlainBody(ctx);
		} else if(ctx.p instanceof SequenceParams) {
			SequenceParams sp = (SequenceParams)ctx.p;
			//generate declarations for state counters
			if(sp.isStatefull()) {
				for(TokenFuncCollection token : ctx.structTokens) {
					if(token.hasInnerTokens() && token.isSorted() && sp.isStatefull()) {
						ctx.fw.write(token.getDeclStr(ctx.getIndent())+"\n");				
					}
				}
			}
			switch(sp.getLength()) {
				case one:
					generateSequenceOne(ctx, sp);					
					break;					
				case n:
					generateSequenceN(ctx, sp);					
					break;					
				case infinite:
					generateSequenceInf(ctx, sp);					
					break;
			}
		} else {
			assert false;
		}
	}

	private static void generateSequenceInf(GeneratorContext ctx, SequenceParams sp) throws IOException {
		//check that all sequences are fully completed
		ctx.fw.write("\n" + ctx.getIndent() 
				+ "while(  " + NONDET_INT + "()");
		ctx.incIndent();
		if(sp.isStatefull()) {
			for(TokenFuncCollection token : ctx.structTokens) {
				if(token.hasInnerTokens() && token.isSorted()) {
					String str = token.getCompletionCheckStr();
					if(str!=null && !str.trim().isEmpty()) {
						ctx.fw.write("\n" + ctx.getIndent() + "|| !(" +  str + ")");
					}
				}
			}
		}
		ctx.decIndent();
		ctx.fw.write("\n" + ctx.getIndent() + ") {\n");
		ctx.incIndent();
		generateSequenceOne(ctx, sp);
		ctx.decIndent();
		ctx.fw.write("\n" + ctx.getIndent() + "}\n");
	}

	private static void generateSequenceN(GeneratorContext ctx, SequenceParams sp) throws IOException {
		ctx.fw.write("\n" + ctx.getIndent() + "int i;\n");
		ctx.fw.write("\n" + ctx.getIndent() + "for(i=0; i<" + sp.getN() + "; i++) {\n");
		ctx.incIndent();
		generateSequenceOne(ctx, sp);
		ctx.decIndent();
		ctx.fw.write("\n" + ctx.getIndent() + "}\n");
	}

	private static void generateSequenceOne(GeneratorContext ctx, SequenceParams sp) throws IOException {
		int caseCounter = 0;
		ctx.fw.write("\n" + ctx.getIndent() + "switch(" + NONDET_INT + "()) {\n");		
		for(TokenFuncCollection token : ctx.structTokens) {
			if(token.hasInnerTokens()) {
				ctx.incIndent();
				if(sp.isSorted() && token.isSorted() && sp.isStatefull()) {
					for(Item<TokenFunctionDecl> item : token.getSortedTokens()) {
						TokenFunctionDecl tfd = item.getData();						
						ctx.fw.write("\n" + ctx.getIndent() + "case " + caseCounter + ": {\n");
						ctx.incIndent();
						ctx.fw.write("\n" + ctx.getIndent() + "/** " + token.getDesc() + " **/");
						ctx.fw.write("\n" + ctx.getIndent() + item.getPreconditionStrBegin(token.getId()) + "\n");
						generateFunctionCall(ctx, token, tfd);
						ctx.fw.write("\n" + ctx.getIndent() + item.getUpdateStr(token.getId()) + "\n");						
						ctx.fw.write("\n" + ctx.getIndent() + item.getPreconditionStrEnd(token.getId()) + "\n");
						ctx.decIndent();
						ctx.fw.write("\n" + ctx.getIndent() + "}\n");
						ctx.fw.write("\n" + ctx.getIndent() + "break;");
						caseCounter++;						
					}
				} else {
					for(TokenFunctionDecl tfd : token.getTokens()) {
						ctx.fw.write("\n" + ctx.getIndent() + "case " + caseCounter + ": {\n");
						ctx.incIndent();
						ctx.fw.write("\n" + ctx.getIndent() + "/** " + token.getDesc()+ " **/");
						generateFunctionCall(ctx, token, tfd);
						ctx.decIndent();
						ctx.fw.write("\n" + ctx.getIndent() + "}\n");
						ctx.fw.write("\n" + ctx.getIndent() + "break;");
						caseCounter++;
					}
				}
				ctx.decIndent();
			}
		}
		ctx.incIndent();
		ctx.fw.write("\n" + ctx.getIndent() + "default: break;\n");
		ctx.decIndent();
		ctx.fw.write("\n" + ctx.getIndent() + "}\n");
	}

	private static void generatePlainBody(GeneratorContext ctx) throws IOException {		
		for(TokenFuncCollection token : ctx.structTokens) {
			if(token.hasInnerTokens()) {
				ctx.fw.write("\n" + ctx.getIndent() + "/** " + token.getDesc() + " **/");
				if(ctx.p.isSorted() && token.isSorted()) {
					for(Item<TokenFunctionDecl> item : token.getSortedTokens()) {
						TokenFunctionDecl tfd = item.getData();						
						generateFunctionCall(ctx, token, tfd);
					}					
				} else {
					for(TokenFunctionDecl tfd : token.getTokens()) {
						generateFunctionCall(ctx, token, tfd);
					}					
				}
				ctx.fw.write("\n");
			}
		}
	}

	private static void generateFunctionCall(GeneratorContext ctx,
			TokenFuncCollection token, TokenFunctionDecl tfd) throws IOException {
		StringBuffer sb = new StringBuffer();				
		sb.append("\n" + ctx.getIndent() + "/* content: " + tfd.getContent() + "*/");
		ctx.fg.set(tfd);
		appendPpcBefore(sb,ctx,tfd);
		/* увеличим счетчик, на число параметров*/
		/* добавляем вызовы функций */
		//String gdebug = tfd.getName();
		/* добавляем к ним проверку, если это стандартная функция */
		if (ctx.p.isCheck() && tfd.getTestString()!=null) {
			if(tfd.getLdvCommentContent()!=null) {				
				sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" "+"Function from field \""+tfd.getLdvCommentContent()+"\" from driver structure with callbacks \""+token.getName()+"\". Standart function test for correct return result. */");
			} else {
				sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" */");
			}
			sb.append(ctx.fg.generateCheckedFunctionCall(MainGenerator.getModuleExitLabel(), ctx.getIndent()));
		} else {
			/* иначе просто вызываем */
			if(tfd.getLdvCommentContent()!=null) {				
				sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" "+"Function from field \""+tfd.getLdvCommentContent()+"\" from driver structure with callbacks \""+token.getName()+"\" */");
			} else {
				sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_FUNCTION_CALL+" */");
			}
			sb.append(ctx.fg.generateSimpleFunctionCall(ctx.getIndent()));
		}
		appendPpcAfter(sb,ctx,tfd);
		/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
		ctx.fw.write(sb.toString());
	}


	/**
	 * Close preprocessor directives 
	 * @param sb
	 * @param ppcParser
	 * @param tfd
	 */
	private static void appendPpcAfter(StringBuffer sb, 
			GeneratorContext ctx, TokenFunctionDecl tfd) {
		/* получим директиквы препроцессора, те что до функции */
		List<TokenPpcDirective> ppcAfterTokens = ctx.ppcParser.getPPCWithoutINCLUDEafter(tfd);
		/* добавим их ... */
		Logger.trace("ppcAfterTokens.size()=" + ppcAfterTokens.size());
		if(ppcAfterTokens.size()!=0) {
			sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
			for(TokenPpcDirective ppc : ppcAfterTokens) {
				sb.append("\n" + ctx.getIndent() + ppc.getContent());
				Logger.trace("ppc.getContent().length=" + ppc.getContent().length());
			}
			sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
		}
	}

	/**
	 * Open preprocessor directives 
	 * @param sb
	 * @param ppcParser
	 * @param tfd
	 */
	private static void appendPpcBefore(StringBuffer sb,
			GeneratorContext ctx, TokenFunctionDecl tfd) {
		/* получим директивы препроцессора, те что после функции */
		List<TokenPpcDirective> ppcBeforeTokens = ctx.ppcParser.getPPCWithoutINCLUDEbefore(tfd);
		/* добавим их ... */		
		if(ppcBeforeTokens.size()!=0) {
			sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_BEGIN+ldvTag_PREP+" */");
			for(TokenPpcDirective ppc : ppcBeforeTokens) {
				sb.append("\n" + ctx.getIndent() + ppc.getContent());
			}
		}
		sb.append("\n" + ctx.getIndent() + "/* "+ldvCommentTag+ldvTag_END+ldvTag_PREP+" */");
	}
}
