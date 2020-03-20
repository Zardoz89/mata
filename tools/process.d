/**
 * Procesador simple de ficheros de texto que remplaza textos por valores númericos
 */
module process;

import std.stdio;

public int[string] readConstantsFile(string path) {
  import std.array;
  import std.algorithm;
  import std.file : readText;
  import std.conv : to;

  int[string] constants;
  auto lines = readText(path).split('\n');
  foreach (string line ; lines) {
    if (line.length <= 0) {
      continue;
    }
    line = line.split("//")[0];
    if (line.length <= 0) {
      continue;
    }
    auto columns = line.split();
    if (columns.length >= 2) {
      constants[columns[0]] = to!int(columns[1]);
    }
  }
  return constants;
}

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
 * Procesa los argumentos y genera los File de entrada y salida
 * Dado una lista de argumentos y diccionario de string->valor , lee un fichero y devuelve uno procesado.
 * Si la lista de argumentos está vacia, usa stdin y stdout.
 */
public auto processArgs(bool binaryOutput = false)(string[] args, string helpText) {
  import std.stdio;
  import std.getopt;

  string inputFile = "";
  string outputFile = "";

  auto options = getopt(
    args,
    "input|i", "Input file", &inputFile,
    "ouput|o", "Output file", &outputFile);

  if (options.helpWanted) {
    defaultGetoptPrinter(helpText ~ "\n" ~ "Options:", options.options);
    return null;
  }

  auto fin = stdin;
  if (inputFile.length != 0) {
    fin = File(inputFile, "r");
  }

  auto fout = stdout;
  if (outputFile.length != 0) {
    static if (binaryOutput) {
      fout = File(outputFile, "wb");
    } else {
      fout = File(outputFile, "w");
    }
  }

  File[string] fileStreams;
  fileStreams["fin"] = fin;
  fileStreams["fout"] = fout;
  return fileStreams;
}
