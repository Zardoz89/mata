/**
 * Compilador de comandos de nivel a "wordcode"
 */
import pegged.grammar;
import process;

enum ushort[string] COMMAND = [
  "SpawnEnemy"              : 0x0001,
  "SpawnEnemyScreenCoords"  : 0x0002,
  "WaitTicks"               : 0x0003
];

enum string g = `
LevelProgram:
  Program     < Command+ :Spacing :eoi
  Command     < SpawnEnemy '(' Integer ',' Integer ',' Id ',' Id ')' ';' /
                SpawnEnemyScreenCoords '(' Integer ',' Integer ',' Id ',' Id ')' ';' /
                WaitTicks '(' Integer ')' ';'


  Id          < Number
  Integer     <~ Sign? Number

# Terminals *****************************************************

# Commands
  SpawnEnemy  < "SpawnEnemy"
  SpawnEnemyScreenCoords  < "SpawnEnemyScreenCoords"
  WaitTicks   < "WaitTicks"

# Numbers
  Number      <~ digit+
  Sign        <- "-" / "+"

# Spacing and comments
  Spacing <~ (space / endOfLine / Comment)*
  Comment <~ "//" (!endOfLine .)* endOfLine

`;

mixin(grammar(g));

/**
 * Recorre el arbol de parseo y genera el "wordcode"
 */
ushort[] toShortArray(ParseTree p)
{
  import std.conv : to, castFrom, parse;
  import std.stdio;

  ushort[] parseToCode(ParseTree p) {
    switch(p.name) {
      case "LevelProgram":
        return parseToCode(p.children[0]); // The grammar result has only child: the start rule's parse tree
      case "LevelProgram.Program":
        ushort[] result;
        foreach( child; p.children) {
          result ~= parseToCode(child);
        }
        return result;

      case "LevelProgram.Command":
        ushort[] result;
        foreach( child; p.children) {
          result ~= parseToCode(child);
        }
        return result;

      case "LevelProgram.SpawnEnemy":
      case "LevelProgram.SpawnEnemyScreenCoords":
      case "LevelProgram.WaitTicks":
        return [COMMAND[getCommand(p.name)]]; // [0x0001];

       // return [0x0002];

      case "LevelProgram.Integer":
      case "LevelProgram.Id":
        ushort tmp = castFrom!long.to!ushort(parse!long(p.matches[0]));
        return [tmp];

      default:
        return [];
    }
  }
  return parseToCode(p);
}

string getCommand(string parseNodeName) {
  import std.array : split;
  return parseNodeName.split(".")[1];
}

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
  //writeln(program);

  // Parseo
  auto parseTree = LevelProgram(program);
  if (parseTree.successful) {
    writeln("Generando 'wordcode'...");

    auto wordCode = toShortArray(parseTree);

    //int arrayDivLength = cast(int) wordCode.length;
    // El fichero generado contiene un int con la longitud, seguido del "wordCode"
    //fileStreams["fout"].rawWrite([arrayDivLength]);
    fileStreams["fout"].rawWrite(wordCode);
  } else {
    //toHTML(parseTree, "tree.html");
    writeln(parseTree);
  }
}
