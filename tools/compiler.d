import pegged.grammar;
import process;

enum short[string] COMMAND = [
  "SpawnEnemy"              : 0x0001,
  "SpawnEnemyScreenCoords"  : 0x0002
];

enum string g = `
LevelProgram:
  Program     < Command+ :Spacing
  Command     < SpawnEnemy '(' Integer ',' Integer ',' Id ',' Id ')' /
                SpawnEnemyScreenCoords '(' Integer ',' Integer ',' Id ',' Id ')'


  Id          < Number
  Integer     <~ Sign? Number

# Terminals *****************************************************

# Commands
  SpawnEnemy  < "SpawnEnemy"
  SpawnEnemyScreenCoords  < "SpawnEnemyScreenCoords"

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
  import std.conv : to;

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
        return [0x0001];

      case "LevelProgram.SpawnEnemyScreenCoords":
        return [0x0002];

      case "LevelProgram.Integer":
      case "LevelProgram.Id":
        ushort tmp = to!short(p.matches[0]);
        return [tmp];

      default:
        return [];
    }
  }
  return parseToCode(p);
}

/+
    Term     < Factor (Add / Sub)*
    Add      < "+" Factor
    Sub      < "-" Factor
    Factor   < Primary (Mul / Div)*
    Mul      < "*" Primary
    Div      < "/" Primary
    Primary  < Parens / Neg / Pos / Number / Variable
    Parens   < "(" Term ")"
    Neg      < "-" Primary
    Pos      < "+" Primary
    Number   < ~([0-9]+)

    Variable <- identifier
`));
+/
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
  writeln(program);

  // Parseo
  auto parseTree = LevelProgram(program);

  //toHTML(parseTree, "tree.html");
  writeln(parseTree);
  auto wordCode = toShortArray(parseTree);

  int arrayDivLength = cast(int) wordCode.length;
  // El fichero generado contiene un word con la longitud, seguido del "wordCode"
  fileStreams["fout"].rawWrite([arrayDivLength]);
  fileStreams["fout"].rawWrite(wordCode);

}
