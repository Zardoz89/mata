/**
 * Procesador simple de ficheros de texto que remplaza textos por valores númericos
 */
module process;
import std.stdio;

/**
 * Remplaza los textos dados por un diccionario, por sus valores, en una cadena.
 */
private string processLine(string line, int[string] constants) {
  import std.regex;
  import std.conv : to;

  foreach(string cte, int value; constants) {
    auto re = regex(cte);
    line = line.replaceAll(re, to!string(value));
  }
  return line;
}

/**
 * Dado unos File de entrada y de salida, y un diccionario string->valor;
 * procesa el fichero de entrada, remplazando los textos por los valores segun el diccionario.
 */
public void processFile(ref File fin, ref File fout, int[string] constants) {
  import std.stdio;
  import std.array;
  import std.algorithm;

  auto lines = fin
    .byLineCopy()
    .array()
    .map!(line => processLine(line, constants))()
    .each!(line => fout.writeln(line));

}

/**
 * Dado una lista de argumentos y diccionario de string->valor , lee un fichero y devuelve uno procesado.
 * Si la lista de argumentos está vacia, usa stdin y stdou.
 * args[1] -> fichero de entrada
 * args[2] -> fichero de salida
 */
public void processArgs(string[] args, int[string] constants) {
  import std.stdio;
  import std.array;
  import std.algorithm;

  auto fin = stdin;
  auto fout = stdout;
  if (args.length >= 2) {
    fin = File(args[1], "r");
  }

  if (args.length >= 3) {
    fout = File(args[2], "w");
  }

  processFile(fin, fout, constants);
}
