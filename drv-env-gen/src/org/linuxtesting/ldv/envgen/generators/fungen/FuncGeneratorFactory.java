/*
 * Copyright (C) 2010-2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.linuxtesting.ldv.envgen.generators.fungen;

import java.util.Map;
import java.util.HashMap;

import org.linuxtesting.ldv.envgen.generators.EnvParams;

public class FuncGeneratorFactory {

	protected final static Map<GenerateOptions, Class<?>> map = defaultMap();

	public static FuncGenerator create(GenerateOptions gopts, EnvParams p) {
		Class<?> klass = map.get(gopts);
		if(klass == null)
			throw new RuntimeException(" was unable to find an FuncGenerator named "+gopts+".");
		FuncGenerator funcGeneratorInstance = null;
		try {
			funcGeneratorInstance = (FuncGenerator)klass.newInstance();
			funcGeneratorInstance.setParams(p);
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
