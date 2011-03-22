package org.linuxtesting.ldv.envgen.generators;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.Reader;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;

import org.linuxtesting.ldv.envgen.FSOperationsBase;
import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.parsers.ExtendedParserFunction;
import org.linuxtesting.ldv.envgen.cbase.parsers.FunctionCallParser;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderCCommentsDel;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionCall;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;


public class Model0049 {

	public static void main(String[] args) {
		long startf = System.currentTimeMillis();
		if(args.length != 3) {
			Logger.norm("USAGE: java -ea model0049g.jar <dirname> <filename.c> <funcionname>");
			return;
		}
		generate(args[1],args[0], args[2]);
		long endf = System.currentTimeMillis();
		Logger.info("generate time: " + (endf-startf) + "ms");
	}

	public static void generate(String filename, String dirname, String funname) {
		FunctionCallParser callParser = new FunctionCallParser();
		/* получим список всех с-шников директории */
		List<String> cfilenames = FSOperationsBase.getDirContentRecursiveC(dirname);
		/* в цикле будем заполнять список токенов */
		List<TokenFunctionDecl> tokens = new ArrayList<TokenFunctionDecl>();
		Iterator<String> cfilenamesIterator = cfilenames.iterator();
		int ipercent=0;
		while(cfilenamesIterator.hasNext()) {
			String cfilename = cfilenamesIterator.next();
			Logger.info("PARSE: " + cfilename);
			Reader reader;
			try {
				reader = new FileReader(cfilename);
				/* добавим ридер удаления комментариев */
				ReaderInterface wreader = new ReaderCCommentsDel(reader);
				/* создадим экземпляр парсера функций c call-вызовами */
				ExtendedParserFunction ep = new ExtendedParserFunction(wreader);
				/* скажем парсеру, чтобы он выдирал functionCalls */
				ep.addBodyParser(callParser);
				/* распарсим функции и добавим их в список */
				tokens.addAll(ep.parse());
				ipercent++;
				Logger.info("PARSE: " + 100*(double)ipercent/(double)(cfilenames.size())+"%");
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			}
		}

		/* добавим искомый токен */
		tokens.add(new TokenFunctionDecl(funname, "void", null, 0, 0, null, null, null));

		Logger.info("END_OF_PARSE");
		/* связывание функций */
		/* пройдемся по списку описаний функций
		 * */
		ipercent = 1;
		Iterator<TokenFunctionDecl> outFIterator = tokens.iterator();
		while(outFIterator.hasNext()) {
			TokenFunctionDecl tf = outFIterator.next();
			List<TokenFunctionCall> lftokens = FunctionCallParser.getFunctionCalls(tf);
			List<TokenFunctionDecl> resTokens = new LinkedList<TokenFunctionDecl>();
			if (lftokens != null) {
				Logger.info("ASSIGN: " + 100*(double)(ipercent++)/(double)(tokens.size())+"%");
				for(int i=0; i<lftokens.size(); i++) {
					String name = lftokens.get(i).getName();
					TokenFunctionDecl tfd = findDecl(name, tokens);
					if(tfd!=null) {
						//replace Token by corresponding TokenFunctionDecl
						resTokens.add(tfd);
					} else {
						Logger.trace("corresponding decl not found");
					}
				}
				declMap.put(tf.getName(), resTokens);
			}
		}
		//TODO use res tokens to construct the call graph 
		//instead of replacing inner tokens in TokenFunctionDecl

		Logger.info("EXCEPTION_COUNTER:" + callParser.getParseExceptionCounter());
		List<String> callgToken = new ArrayList<String>(100000);
		List<TokenFunctionDecl> tlist = new ArrayList<TokenFunctionDecl>(tokens.size());
		tlist.addAll(tokens);
		callgToken = printGraph(tlist, new ArrayList<TokenFunctionDecl>(), funname, callgToken);
		/* теперь выведем весь список на консоль */
		for(int i=0; i<callgToken.size(); i++)
			Logger.norm(callgToken.get(i));
	}

	private static Map<String, List<TokenFunctionDecl>> declMap = new HashMap<String, List<TokenFunctionDecl>>();
	
	private static TokenFunctionDecl findDecl(
			String name, List<TokenFunctionDecl> tokens) {
		Iterator<TokenFunctionDecl> innerFIterator = tokens.iterator();
		while(innerFIterator.hasNext()) {
			TokenFunctionDecl tfd = innerFIterator.next();
			if(tfd.getName().equals(name)) {
				return tfd;
			}
		}
		return null;
	}

	/* собирает ветки, которые оканчиаются вызовом нашей функции */
	public static void runGraph(List<TokenFunctionDecl> tfdlist, List<TokenFunctionDecl> tfdstack) {
		/* проходимся по списку tfdlist */
		Iterator<TokenFunctionDecl> tokenIterator = tfdlist.iterator();
		while(tokenIterator.hasNext()) {
			TokenFunctionDecl tfd = tokenIterator.next();
			/* теперь пройдемся по стэку вызовов и посмотрим -
			 * нет ли там этой функции, и, если есть - то значит это уже
			 * рекурсия...  */
			Iterator<TokenFunctionDecl> stackIterator = tfdstack.iterator();
			boolean recursiveFlag = false;
			TokenFunctionDecl tfds;
			while(stackIterator.hasNext()) {
				tfds = stackIterator.next();
				if(tfds.getName().equals(tfd.getName())) {
					recursiveFlag =true;
				}
			}

			String afterPath;
			if(recursiveFlag==false) {
				afterPath = tfd.getName();
			} else{
				afterPath = tfd.getName() + " RECURSIVE";
			}

			/* составим строку пути */
			stackIterator = tfdstack.iterator();
			StringBuffer sbs = new StringBuffer("");
			while(stackIterator.hasNext()) {
				TokenFunctionDecl tfdsl;
				tfdsl = stackIterator.next();
				sbs.append(tfdsl.getName()+"->");
			}
			sbs.append(afterPath);

			System.out.println(sbs);

			if(recursiveFlag==false) {
				tfdstack.add(tfd);
				if(tfd.getTokens()!=null && tfd.getTokens().size()>0) {
					//printGraph(new Integer(0), tfdlist, tfdstack, null, null);
				}
				tfdstack.remove(tfd);
			}
		}
	}

	//TODO: apply Java 5 generics
	/* функция распечатки токенов с рекурсией :
	 * ltfd - список для нового прохода
	 * tfd - стэк, для хранения текущего пути (для того, чтобы можно было обнаружить рекурсию)
	 * */
	public static List<String> printGraph(List<TokenFunctionDecl> tfdlist, List<TokenFunctionDecl> tfdstack, String funname, List<String> callgToken) {
		/* проходимся по списку tfdlist */
		Iterator<TokenFunctionDecl> tokenIterator = tfdlist.iterator();
		while(tokenIterator.hasNext()) {
			TokenFunctionDecl tfd = tokenIterator.next();
			/* смотрим - это наша функция ?*/
			if (tfd.getName().equals(funname)) {
				for (int i=0; i < tfdstack.size(); i++) {
					/* сначала убедимся, что такого имени нету в стэке */
					if(!callgToken.contains((tfdstack.get(i)).getName()))
						callgToken.add((tfdstack.get(i)).getName());
				}
			}

			/* теперь пройдемся по стэку вызовов и посмотрим -
			 * нет ли там этой функции, и, если есть - то значит это уже
			 * рекурсия...  */
			Iterator<TokenFunctionDecl> stackIterator = tfdstack.iterator();
			boolean recursiveFlag = false;
			TokenFunctionDecl tfds;
			while(stackIterator.hasNext()) {
				tfds = stackIterator.next();
				if(tfds.getName().equals(tfd.getName())) {
					recursiveFlag =true;
				}
			}
			stackIterator = tfdstack.iterator();
			if(recursiveFlag==false) {
				tfdstack.add(tfd);
				List<TokenFunctionDecl> inner = declMap.get(tfd.getName());
				
				if(tfd.getTokens()!=null && tfd.getTokens().size()>0)
					callgToken = printGraph(inner, tfdstack, funname, callgToken);
				tfdstack.remove(tfd);
			}
		}
		return callgToken;
	}
}
