/**
 * Compilador de comandos de nivel a "wordcode"
 */
import pegged.grammar;
import process;
import lprGrammar;

int main(string[] args)
{
  import pegged.tohtml;
  import std.stdio;

  auto fileStreams = processArgs!(true)(args, "Compilador de comandos de nivel");
  if (fileStreams is null) {
    return 1;
  }
  scope(exit) fileStreams["fout"].close();

  string program;
  foreach (line; fileStreams["fin"].byLine) {
    program ~= line ~ '\n';
  }

  // Parseo
  auto parseTree = LevelProgram(program);
  //writeln(parseTree);
  writeln("Constantes: " , constIdentifiers.keys);

  if (parseTree.successful) {
    writeln("Generando 'wordcode'...");

    auto wordCode = toShortArray(parseTree);
    writeln("Identificadores: ", identifiersValues);
    writeln("Total bytes: ", wordCode.length * 2);

    fileStreams["fout"].rawWrite(wordCode);
  } else {
    import colored;
    writeln("Error al parsear el código fuente".red);
    writeln(parseTree.failMsg);
    toHTML(parseTree, "error.html");
    return 1;
  }
  return 0;
}
