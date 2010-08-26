package com.iceberg.generators;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.Reader;
import java.util.Iterator;
import java.util.List;
import java.util.ArrayList;

import com.iceberg.FSOperationsBase;
import com.iceberg.Logger;
import com.iceberg.cbase.parsers.ExtendedParserFunction;
import com.iceberg.cbase.readers.ReaderCCommentsDel;
import com.iceberg.cbase.readers.ReaderInterface;
import com.iceberg.cbase.tokens.Token;
import com.iceberg.cbase.tokens.TokenFunctionDecl;

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
				ep.parseFunctionCallsOn();
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
			List<Token> lftokens = tf.getTokens();
			if (lftokens != null) {
				Logger.info("ASSIGN: " + 100*(double)(ipercent++)/(double)(tokens.size())+"%");
	outcon:		for(int i=0; i<lftokens.size(); i++) {
					Iterator<TokenFunctionDecl> innerFIterator = tokens.iterator();
					while(innerFIterator.hasNext()) {
						TokenFunctionDecl tfd = innerFIterator.next();
						/* если нашли функцию, то заменим ссылку и брейк*/
						if(tfd.getName().equals(lftokens.get(i).getContent())) {
							//replace Token by corresponding TokenFunctionDecl 
							lftokens.set(i, tfd);
							continue outcon;
						}
					}
					/* если не нашли то,
					 *  удалим элемент */
					lftokens.remove(i--);
				}
			}
		}


		Logger.info("EXCEPTION_COUNTER:" + ExtendedParserFunction.parseExceptionCounter);
		List<String> callgToken = new ArrayList<String>(100000);
		List<Token> tlist = new ArrayList<Token>(tokens.size());
		tlist.addAll(tokens);
		callgToken = printGraph(tlist, new ArrayList<Token>(), funname, callgToken);
		/* теперь выведем весь список на консоль */
		for(int i=0; i<callgToken.size(); i++)
			Logger.norm(callgToken.get(i));
	}


	/* собирает ветки, которые оканчиаются вызовом нашей функции */
	public static void runGraph(List<Token> tfdlist, List<Token> tfdstack) {
		/* проходимся по списку tfdlist */
		Iterator<Token> tokenIterator = tfdlist.iterator();
		while(tokenIterator.hasNext()) {
			TokenFunctionDecl tfd = (TokenFunctionDecl) tokenIterator.next();
			/* теперь пройдемся по стэку вызовов и посмотрим -
			 * нет ли там этой функции, и, если есть - то значит это уже
			 * рекурсия...  */
			Iterator<Token> stackIterator = tfdstack.iterator();
			boolean recursiveFlag = false;
			TokenFunctionDecl tfds;
			while(stackIterator.hasNext()) {
				tfds = (TokenFunctionDecl) stackIterator.next();
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
				tfdsl = (TokenFunctionDecl) stackIterator.next();
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
	public static List<String> printGraph(List<Token> tfdlist, List<Token> tfdstack,String funname, List<String> callgToken) {
		/* проходимся по списку tfdlist */
		Iterator<Token> tokenIterator = tfdlist.iterator();
		while(tokenIterator.hasNext()) {
			TokenFunctionDecl tfd = (TokenFunctionDecl) tokenIterator.next();
			/* смотрим - это наша функция ?*/
			if (tfd.getName().equals(funname)) {
				for (int i=0; i < tfdstack.size(); i++) {
					/* сначала убедимся, что такого имени нету в стэке */
					if(!callgToken.contains(((TokenFunctionDecl)tfdstack.get(i)).getName()))
						callgToken.add(((TokenFunctionDecl)tfdstack.get(i)).getName());
				}
			}

			/* теперь пройдемся по стэку вызовов и посмотрим -
			 * нет ли там этой функции, и, если есть - то значит это уже
			 * рекурсия...  */
			Iterator<Token> stackIterator = tfdstack.iterator();
			boolean recursiveFlag = false;
			TokenFunctionDecl tfds;
			while(stackIterator.hasNext()) {
				tfds = (TokenFunctionDecl) stackIterator.next();
				if(tfds.getName().equals(tfd.getName())) {
					recursiveFlag =true;
				}
			}
			stackIterator = tfdstack.iterator();
			if(recursiveFlag==false) {
				tfdstack.add(tfd);
				if(tfd.getTokens()!=null && tfd.getTokens().size()>0)
					callgToken = printGraph(tfd.getTokens(), tfdstack, funname, callgToken);
				tfdstack.remove(tfd);
			}
		}
		return callgToken;
	}
}
