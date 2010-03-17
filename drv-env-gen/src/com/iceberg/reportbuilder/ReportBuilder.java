package com.iceberg.reportbuilder;

import com.iceberg.reportbuilder.brnodes.BRNodeInterface;
import com.iceberg.reportbuilder.brnodes.BlastTraceParser;

public class ReportBuilder {
	public static void main(String[] args) {
		long startf = System.currentTimeMillis();
		if(args.length != 1 || (args.length == 1 && args[0].equals("--help"))) {
			System.out.println("USAGE: java -ea -jar mgenerator.jar <filename.rep>\n\n" +
					"OPTIONS:\n" +
					"	--help  print this page\n\n" +
					"ReportBuilder parse blast report and create\n" +
					"report  file  <filename.lddvrep> for drupal\n" +
					"lddv project.");
			return;
		}
		BlastTraceParser btp = new BlastTraceParser(args[0]);
		BRNodeInterface errorTraceTree = btp.parse();
		/* рекурсивно распечатаем полученное дерево */

		// распечатаем заголовок
		System.out.print("<table>");
		System.out.print("\n\t<tr>");
		System.out.print("\n\t\t<th>file</th>");
		System.out.print("\n\t\t<th>line</th>");
		System.out.print("\n\t\t<th>source</th>");
		System.out.print("\n\t</tr>");
		errorTraceTree.printRecursive(0, false);
		System.out.print("\n</table>");
		long endf = System.currentTimeMillis();
		System.out.println("\ngenerate time: " + (endf-startf) + "ms");
	}
}
