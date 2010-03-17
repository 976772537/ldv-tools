package com.iceberg.reportbuilder.brnodes;

public enum BRNodeType {
	BRTYPE_BRNODE,
	BRTYPE_FunctionCall,
	BRTYPE_FunctionCall_BLAST_initialize,
	BRTYPE_Pred,
	BRTYPE_Skip,
	BRTYPE_Block,
	BRTYPE_Block_BRNODERETURN,  // блок, который содержит слово return - говорит нам о том что был выход из функции
	BRTYPE_FunctionCallWithoutBody,
	BRTYPE_FunctionCall_BLAST_mycor // функции вида FunctionCall(blast_must_tmp__240@ldv_main=__kmalloc(blast_must_tmp__238@ldv_main,blast_must_tmp__239@ldv_main)) {
}
