package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.readers.ReaderWrapper;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenPpcDirective;


public class ParserPPCHelper extends Parser<TokenPpcDirective> {

	/*
	 * Если эта переменная установлена в true, то законченные блоки директив препроцессора
	 * фильтруются. Поскольку пока фильтрация не отточена, то для отладки можно отключать
	 * фильтрацию методом disableFilter();
	 *
	 * */
	private boolean filterPpcEndBlocks = false;

	private List<TokenPpcDirective> tokens;

	private enum parserStates {
		BLOCK_NULL,		// мы не находимся в блоке и не в начале и не в конце буффера
		BLOCK_BEGIN_BUFFER,	// мы находимся в начале буффера - если следующий # - то это директива
		BLOCK_TRY_PREP,		// проскочил \n - возможно следующее - директива препроцессора
		BLOCK_PREP,	// пошла директива препроцессора
		BLOCK_TRY_NOT_PREP_END,	// проскочил с-шный перенос строки - следующий символ \n - не конец препроцессорной директивы
		BLOCK_BEGIN_PREP,
		BLOCK_NULL_AFTER_PREP,		// мы не находимся в блоке и не в начале и не в конце буффера
	}

	private parserStates state = parserStates.BLOCK_BEGIN_BUFFER;

	public void disableFilter() {
		filterPpcEndBlocks = false;
	}

	private void updateState(char symbol) {
		switch(state) {
			case BLOCK_BEGIN_BUFFER:
				if(symbol=='#') state=parserStates.BLOCK_PREP; else
					state=parserStates.BLOCK_NULL;
				break;
			case BLOCK_NULL:
				if(symbol=='\n') state=parserStates.BLOCK_TRY_PREP; else
					state=parserStates.BLOCK_NULL;
				break;
			case BLOCK_TRY_PREP:
				if(symbol=='#') state=parserStates.BLOCK_BEGIN_PREP; else
				if(symbol=='\n' || symbol=='\t' || symbol==' ') state=parserStates.BLOCK_TRY_PREP; else
					state=parserStates.BLOCK_NULL;
				break;
			case BLOCK_BEGIN_PREP:
				if(symbol=='\\') state=parserStates.BLOCK_TRY_NOT_PREP_END; else
				if(symbol=='\n') state=parserStates.BLOCK_NULL; else
					state=parserStates.BLOCK_PREP;
				break;
			case BLOCK_PREP:
				if(symbol=='\\') state=parserStates.BLOCK_TRY_NOT_PREP_END; else
				if(symbol=='\n') state=parserStates.BLOCK_NULL_AFTER_PREP; else
						state=parserStates.BLOCK_PREP;
				break;
			case BLOCK_TRY_NOT_PREP_END:
				state=parserStates.BLOCK_PREP;
				break;
			case BLOCK_NULL_AFTER_PREP:
				if(symbol=='\n' || symbol=='\t' || symbol==' ') state=parserStates.BLOCK_TRY_PREP; else
				if(symbol=='#') state=parserStates.BLOCK_BEGIN_PREP; else
					state=parserStates.BLOCK_NULL;
				break;
		}
	}

	private StringBuffer sbuffer = null;
	private int startIndex ;

	public ParserPPCHelper(ReaderWrapper reader) {
		super(reader);
	}

	@Override
	public List<TokenPpcDirective> parse() {
		if(tokens!=null) return tokens;
		tokens = new ArrayList<TokenPpcDirective>();
		char[] buffer = null;
		buffer =  inputReader.readAll().toCharArray();
		for(int i=0; i<buffer.length; i++) {
			updateState(buffer[i]);
			if(state == parserStates.BLOCK_BEGIN_PREP) {
				this.startIndex = i;
				sbuffer = new StringBuffer();
				sbuffer.append(buffer[i]);
			} else
			if( state == parserStates.BLOCK_PREP ||
					state == parserStates.BLOCK_TRY_NOT_PREP_END)
			{
				if(sbuffer == null) { sbuffer = new StringBuffer(""); }
				sbuffer.append(buffer[i]);
			} else
			if(state == parserStates.BLOCK_NULL_AFTER_PREP) {
				String content = sbuffer.toString();
				TokenPpcDirective.PPCType ppctype = getType(content);
				TokenPpcDirective token = new TokenPpcDirective(startIndex,i-1,content,null,ppctype);
				tokens.add(token);
			}
			/*if(tokens.size() == 66 ) {
				System.out.println("DEB?UG");
			}*/
		}
	/*	Iterator<Token> tokenIterator = tokens.iterator();
		while(tokenIterator.hasNext()) 	System.out.println(tokenIterator.next().getContent());*/
		return tokens;
	}

	public static TokenPpcDirective.PPCType getType(String stoken) {
		if(stoken.contains("include")) {
			return TokenPpcDirective.PPCType.PPC_LOCAL_INCLUDE;
		} else
		if(stoken.contains("endif")) {
			return TokenPpcDirective.PPCType.PPC_ENDIF;
		} else
		if(stoken.contains("ifdef")) {
			return TokenPpcDirective.PPCType.PPC_IFDEF;
		} else
		/* опсано! - else может продолжаться как else if и тогда, удаление ifdef'ов ifdef-else-endif, текущем способом
		 * не всегда правильно */
		if(stoken.contains("else")) {
			return TokenPpcDirective.PPCType.PPC_ELSE;
		}
		return TokenPpcDirective.PPCType.PPC_UNKNOWN;
	}

	/* функции для обрамления участков кода директивами препроцессора */
	/* список директив до токена */
	public List<TokenPpcDirective> getPPCWithoutINCLUDEbefore(TokenFunctionDecl token) {
		this.parse();
		List<TokenPpcDirective> ltokens = new ArrayList<TokenPpcDirective>();
		Iterator<TokenPpcDirective> tokenIterator = tokens.iterator();
		while(tokenIterator.hasNext()) {
			TokenPpcDirective ltoken = tokenIterator.next();
			if(ltoken.getEndIndex()>token.getBeginIndex())
				break;
			if(ltoken.getPPCType()!=TokenPpcDirective.PPCType.PPC_LOCAL_INCLUDE &&
					ltoken.getPPCType()!=TokenPpcDirective.PPCType.PPC_GLOBAL_INCLUDE) {
				filteredAdd(ltoken, ltokens);
			}
		}
		return ltokens;
	}

	/* список директив после токена */
	public List<TokenPpcDirective> getPPCWithoutINCLUDEafter(TokenFunctionDecl token) {
		this.parse();
		List<TokenPpcDirective> ltokens = new ArrayList<TokenPpcDirective>();
		Iterator<TokenPpcDirective> tokenIterator = tokens.iterator();
		while(tokenIterator.hasNext()) {
			TokenPpcDirective ltoken = tokenIterator.next();
			if(ltoken.getBeginIndex()>token.getEndIndex() &&
					ltoken.getPPCType() != TokenPpcDirective.PPCType.PPC_LOCAL_INCLUDE &&
					ltoken.getPPCType() != TokenPpcDirective.PPCType.PPC_GLOBAL_INCLUDE) {
				filteredAdd(ltoken, ltokens);
			}
		}
		return ltokens;
	}

	public void filteredAdd(TokenPpcDirective ltoken, List<TokenPpcDirective> ltokens) {
		if(!filterPpcEndBlocks) {
			ltokens.add(ltoken);
			return;
		}
		/* смотрим - если предыдущий был ifdef, а текущий endif - то не добавляем,
		 * так как это законченный блок */
		/*if(ltokens.size()>0 &&
				((TokenPpcDirective)ltokens.get(ltokens.size()-1)).getPPCType() == TokenPpcDirective.PPCType.PPC_IFDEF &&
				ltoken.getPPCType() == TokenPpcDirective.PPCType.PPC_ENDIF)
			ltokens.remove(ltokens.size()-1);
		else*/
		if(ltoken.getPPCType() == TokenPpcDirective.PPCType.PPC_ENDIF) {
			if(ltokens.size()>0 && ((TokenPpcDirective)ltokens.get(ltokens.size()-1)).getPPCType() == TokenPpcDirective.PPCType.PPC_IFDEF) {
				ltokens.remove(ltokens.size()-1);
			} else
			if(ltokens.size()>1 && ((TokenPpcDirective)ltokens.get(ltokens.size()-1)).getPPCType() == TokenPpcDirective.PPCType.PPC_ELSE &&
					((TokenPpcDirective)ltokens.get(ltokens.size()-2)).getPPCType() == TokenPpcDirective.PPCType.PPC_IFDEF ) {
				ltokens.remove(ltokens.size()-1);
				ltokens.remove(ltokens.size()-1);
			}
		} else
			ltokens.add(ltoken);
	}
}
