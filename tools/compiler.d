/**
 * Compilador de comandos de nivel a "wordcode"
 */
import pegged.grammar;
import process;
import lprGrammar;

void main(string[] args)
{
  import pegged.tohtml;
  import std.stdio;

  auto fileStreams = processArgs!true(args);
  scope(exit) fileStreams["fout"].close();

  string program;
  foreach (line; fileStreams["fin"].byLine) {
    program ~= line ~ '\n';
  }

  // Parseo
  auto parseTree = LevelProgram(program);
  writeln("Constantes: " , identifiersValues);

  if (parseTree.successful) {
    writeln("Generando 'wordcode'...");

    auto wordCode = toShortArray(parseTree);
    writeln("Total bytes: ", wordCode.length * 2);

    fileStreams["fout"].rawWrite(wordCode);
  } else {
    import colored;
    writeln("Error al parsear el código fuente".red);
    debug {
      toHTML(parseTree, "parseTree.html");
    }
    writeln(parseTree.failMsg);
  }
}
