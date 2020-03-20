/**
 * Compilador de comandos de nivel a "wordcode"
 */
import pegged.grammar;
import process;

enum ushort[string] COMMAND = [
  "EndLevel"                : 0x0000,
  "SpawnEnemy"              : 0x0001,
  "SpawnEnemyScreenCoords"  : 0x0002,
  "WaitTicks"               : 0x0003
];

string lastIdentifier;
ushort[string] identifiersValues;

/**
 * Guarda temporalmente el nombre del identifier
 */
PT getIdentifierStringAction(PT)(PT p)
{
  lastIdentifier = p.matches[0];
  return p;
}

/**
 * Mete en el diccionario de identificadores, el valor asignado
 */
PT storeIdentifierAction(PT)(PT p)
{
  import std.conv : to, castFrom, parse;
  identifiersValues[lastIdentifier] = castFrom!long.to!ushort(parse!long(p.matches[0]));
  return p;
}

PT verifyIdentifierExistsAction(PT)(PT p)
{
  import std.stdio : writeln;
  import std.conv : to;
  import colored;
  if ( (p.matches[0] in identifiersValues) is null) {
    p.successful = false;

    // Calcula la posición en el texto original (copy&paste del código de pegged)
    Position pos = position(p);
    string left, right;
    if (pos.index < 10) {
      left = p.input[0 .. pos.index];
    } else {
      left = p.input[pos.index - 10 .. pos.index];
    }
    if (pos.index + 10 < p.input.length) {
      right = p.input[pos.index .. pos.index + 10];
    } else {
      right = p.input[pos.index .. $];
    }
    writeln("Identificador no reconocido : ".red , p.matches[0],
      " at line " ~ to!string(pos.line) ~ ", col " ~ to!string(pos.col) );
  }
  return p;
}

enum string g = `
LevelProgram:
  Program     < Constant Commands? EndLevel ';' :Spacing :eoi

  Constants   < Constant+ :Spacing
  Constant    < "const" Identifier{getIdentifierStringAction} '=' Integer{storeIdentifierAction} ';'

  Commands    < Command+ :Spacing
  Command     < SpawnEnemy '(' Integer ',' Integer ',' Id ',' Id ')' ';' /
                SpawnEnemyScreenCoords '(' Integer ',' Integer ',' Id ',' Id ')' ';' /
                WaitTicks '(' Integer ')' ';'


  Id          < Number / Identifier{verifyIdentifierExistsAction}
  Integer     <~ Sign? Number

# Terminals *****************************************************

  Identifier  <~ [a-zA-Z_] [a-zA-Z0-9_\-]*

# Commands
  EndLevel    < "EndLevel"
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
  import std.ascii : isAlpha;
  import std.algorithm.searching : startsWith;
  import std.algorithm.comparison : among;
  import std.stdio;

  ushort[] parseToCode(ParseTree p) {
    switch(p.name) {
      case "LevelProgram":
        return parseToCode(p.children[0]); // The grammar result has only child: the start rule's parse tree
      case "LevelProgram.Program":
      case "LevelProgram.Commands":
      case "LevelProgram.Command":
        ushort[] result;
        foreach( child; p.children) {
          result ~= parseToCode(child);
        }
        return result;

      case "LevelProgram.EndLevel":
      case "LevelProgram.SpawnEnemy":
      case "LevelProgram.SpawnEnemyScreenCoords":
      case "LevelProgram.WaitTicks":
        return [COMMAND[getCommand(p.name)]];

      case "LevelProgram.Id":
        if (p.matches[0].startsWith!isAlpha || p.matches[0].startsWith!(a => a.among('-', '_') != 0)) {
          return [ identifiersValues[p.matches[0]] ];
        }
      case "LevelProgram.Integer":
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
  //writeln(parseTree);
  writeln("Constantes: " , identifiersValues);

  if (parseTree.successful) {
    writeln("Generando 'wordcode'...");

    auto wordCode = toShortArray(parseTree);
    writeln("Total bytes: ", wordCode.length * 2);

    //int arrayDivLength = cast(int) wordCode.length;
    // El fichero generado contiene un int con la longitud, seguido del "wordCode"
    //fileStreams["fout"].rawWrite([arrayDivLength]);
    fileStreams["fout"].rawWrite(wordCode);
  } else {
    import colored;
    writeln("Error al parsear el código fuente".red);
    //toHTML(parseTree, "tree.html");
    writeln(parseTree.failMsg);
  }
}
