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


	public static void main(String[] args) {

		long startf = System.currentTimeMillis();
		if(args.length != 1) {
			System.out.println("USAGE: java -ea -jar mgenerator.jar <filename.c>");
			return;
		}
		generate(args[0]);
		long endf = System.currentTimeMillis();
		System.out.println("generate time: " + (endf-startf) + "ms");
	}


	public static void generate(String filename) {
		generateByIndex(filename, -1, null, false);
	}
	
	public static void generate(String source, String destionation ) {
		generateByIndex(source, -1, destionation, false);
	}
	
	public static boolean deg(String filename, int counter) {
		File file = new File(filename);
		if(!file.exists())
			return false;
		return generateByIndex(filename, counter, filename, true);
	}

	public static boolean generateByIndex(String filename, int index, String destFilename, boolean isgenerateIfdefAroundMains) {
		Matcher matcher = pattern.matcher(filename);
		if(!matcher.find()) {
			System.out.println("could not match C-extension");
			System.out.println("USAGE: java -ea -jar mgenerator.jar <*>.c");
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
			List<Token> ltoken = ep.parse();
			ltoken.addAll(epSimple.parse());
			if (ltoken.size() == 0)
				return false;
			FileWriter fw = new FileWriter(destFilename);
			fw.write(ccontent);
			StringBuffer sb = new StringBuffer();
			sb.append("\n\n\n\n\n");
			if (isgenerateIfdefAroundMains)
				sb.append("#ifdef LDV_MAIN"+index+"\n");
			sb.append("\t/*###########################################################################*/\n");
			sb.append("\t/*############## Driver Environment Generator 0.1 output ####################*/\n");
			sb.append("\t/*###########################################################################*/\n");
			sb.append("\n\n");

			sb.append("void check_final_state(void);\n");
			sb.append("void check_return_value(int res);\n");
			sb.append("extern int IN_INTERRUPT;\n");

			if(index == -1)
				sb.append("void ldv_main(void) {\n\n\n");
			else
				sb.append("void ldv_main"+index+"(void) {\n\n\n");

			
			/* создадим счетчик */
			int generatorCounter = 0;
			FuncGenerator fg = FuncGeneratorFactory.create(GenerateOptions.DRIVER_FUN_STRUCT_FUNCTIONS);
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
							while(ppcTokenBeforeIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenBeforeIterator.next().getContent());
							/* увеличим счетчик, на число параметров*/
							localCounter+=tfd.getReplacementParams().size();
							/* добавляем описания параметров */
							List<String> lparams = fg.generateVarDeclare();
							Iterator<String> paramIterator = lparams.iterator();
							while(paramIterator.hasNext())
								sb.append("\n\t\t" + paramIterator.next());
							/* проверим - функция имеет проверки - т.е. стандартная ?
							 * если да, то объявим перемнную для результата */
							if(tfd.getTestString()!=null && !tfd.getRetType().contains("void"))
								sb.append("\n\t\t" + tfd.getRetType() + " rtmp" + tmpcounter++ + ";");

							/* получим директивы препроцессора, те что после функции */
							List<Token> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(tfd);
							/* добавим их ... */
							Iterator<Token> ppcTokenAfterIterator = ppcAfterTokens.iterator();
							while(ppcTokenAfterIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
							/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
							fw.write(sb.toString());
							sb = new StringBuffer();
						}
						sb.append("\n");
				}
			}
			sb.append("\n\n\n");

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
							while(ppcTokenBeforeIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenBeforeIterator.next().getContent());
							/* увеличим счетчик, на число параметров*/
							localCounter+=tfd.getReplacementParams().size();
							/* добавляем инициализацию */

							//lanai_proc_read
							//String gdebug = tfd.getName();

							List<String> lparams = fg.generateVarInit();
							Iterator<String> paramIterator = lparams.iterator();
							while(paramIterator.hasNext())
								sb.append("\n\t\t" + paramIterator.next());
							/* получим директивы препроцессора, те что после функции */
							List<Token> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(tfd);
							/* добавим их ... */
							Iterator<Token> ppcTokenAfterIterator = ppcAfterTokens.iterator();
							while(ppcTokenAfterIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
							/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
							fw.write(sb.toString());
							sb = new StringBuffer();
						}
						sb.append("\n");
				}
			}
			sb.append("\n\n\n");

			sb.append("\n/*============================= FUNCTION CALL SECTION       =============================*/");
			tokenIterator = ltoken.iterator();
			localCounter = generatorCounter;
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
					while(ppcTokenBeforeIterator.hasNext())
						sb.append("\n\t\t" + ppcTokenBeforeIterator.next().getContent());
					/* увеличим счетчик, на число не void и не ... параметров*/
					Iterator<String> tokenNeededIter = token.getReplacementParams().iterator();
					while(tokenNeededIter.hasNext()) {
						String tstr = tokenNeededIter.next();
						if(!(tstr.trim().equals("void") || tstr.equals("..."))) localCounter++;
					}
					//localCounter+=token.getReplacementParams().size();
					/* добавляем вызовы функций */
					String lparams = fg.generateFunctionCall();
					sb.append("\n\t\tif ("+lparams.substring(0,lparams.length()-1)+")\n\t\t\treturn;");
					/* получим директивы препроцессора, те что после функции */
					List<Token> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(token);
					/* добавим их ... */
					Iterator<Token> ppcTokenAfterIterator = ppcAfterTokens.iterator();
					while(ppcTokenAfterIterator.hasNext())
						sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
					/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
					fw.write(sb.toString());
					sb = new StringBuffer();
					generatorCounter = localCounter;
					sb.append("\n");
				}
			}

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
							while(ppcTokenBeforeIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenBeforeIterator.next().getContent());
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
								sb.append(tfd.getTestString().replaceAll("\\$counter", Integer.toString(tmpcounter)).replaceAll("\\$fcall", lparams));
								tmpcounter++;
								/*	"int tmp$counter = $fcall \n\t\tcheck_return_value(tmp$counter);\n" +
								"\t\tif(tmp$counter) \n\t\treturn;";*/
							} else
								/* иначе просто вызываем */
								sb.append("\n\t\t" + lparams);
							/* получим диретивы препроцессора, те что после функции */
							List<Token> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(tfd);
							/* добавим их ... */
							Iterator<Token> ppcTokenAfterIterator = ppcAfterTokens.iterator();
							while(ppcTokenAfterIterator.hasNext())
								sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
							/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
							fw.write(sb.toString());
							sb = new StringBuffer();
						}
						generatorCounter = localCounter;
						sb.append("\n");
				}
			}

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
					while(ppcTokenBeforeIterator.hasNext())
						sb.append("\n\t\t" + ppcTokenBeforeIterator.next().getContent());
					/* увеличим счетчик, на число параметров*/
					localCounter+=token.getReplacementParams().size();
					/* добавляем вызовы функций */
					String lparams = fg.generateFunctionCall();
					sb.append("\n\t\t" + lparams);
					/* получим директивы препроцессора, те что после функции */
					List<Token> ppcAfterTokens = ppcParser.getPPCWithoutINCLUDEafter(token);
					/* добавим их ... */
					Iterator<Token> ppcTokenAfterIterator = ppcAfterTokens.iterator();
					while(ppcTokenAfterIterator.hasNext())
						sb.append("\n\t\t" + ppcTokenAfterIterator.next().getContent());
					/* после каждой итерации освобождаем StringBuffer, иначе будет JavaHeapSpace */
					fw.write(sb.toString());
					sb = new StringBuffer();
					generatorCounter = localCounter;
					sb.append("\n");
				}
			}
			
			sb.append("\n\n\n\tcheck_final_state();\n");
			sb.append("\treturn;\n}\n");
			if (isgenerateIfdefAroundMains)
				sb.append("#endif\n");

			fw.write(sb.toString());
			fw.close();
			return true;
		} catch (IOException e) {
			e.printStackTrace();
		}
		return false;
	}

}
