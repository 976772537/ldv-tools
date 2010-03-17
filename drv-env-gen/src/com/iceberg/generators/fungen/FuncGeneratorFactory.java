package com.iceberg.generators.fungen;

import java.util.Map;
import java.util.HashMap;

public class FuncGeneratorFactory {
	
	protected static Map<GenerateOptions, Class<?>> map = defaultMap();
	
	public static FuncGenerator create(GenerateOptions gopts) {
		Class<?> klass = map.get(gopts);
		if(klass == null) 
			throw new RuntimeException(" was unable to find an FuncGenerator named "+gopts+".");
		FuncGenerator funcGeneratorInstance = null;
		try {
			funcGeneratorInstance = (FuncGenerator)klass.newInstance(); 
		} catch (Exception e) {
			e.printStackTrace();
		}
		return funcGeneratorInstance;
	}
	
	protected static Map<GenerateOptions, Class<?>> defaultMap() {
		Map<GenerateOptions, Class<?>> map = new HashMap<GenerateOptions, Class<?>>();
		map.put(GenerateOptions.DRIVER_FUN_STRUCT_FUNCTIONS, FuncGeneratorStruct.class);
		return map;
	}
	
}
