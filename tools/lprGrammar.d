/**
 * Gramtica de comandos de nivel
 */
module lprGrammar;

import pegged.grammar;

/**
 * Tabla de Comandos a word
 */
enum ushort[string] COMMAND = [
  "EndLevel"                    : 0x0000,
  "WaitTicks"                   : 0x0001,
  "WaitScroll"                  : 0x0002,
  "SetScrollSpeed"              : 0x0003,
  "SpawnEnemy"                  : 0x0004,
  "SpawnEnemyScreenCoords"      : 0x0005,
  "SpawnEnemyGroup"             : 0x0006,
  "SpawnEnemyGroupScreenCoords" : 0x0007
];

/**
 * Global donde guarda el ultimo idenficador al procesar el bloque de constantes
 */
private string lastIdentifier;

/**
 * 'HashSet' con los identificadores ya inicializados
 */
bool[string] constIdentifiers;
/**
 * Diccionario de identificadores con sus valores
 */
long[string] identifiersValues;

/**
 * Genera la coletilla con la posición del nodo con error
 */
string generateErrorPossition(PT)(PT p)
{
  import std.conv : to;
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
  return " at line " ~ to!string(pos.line) ~ ", col " ~ to!string(pos.col);
}

/**
 * Guarda temporalmente el nombre del identifier
 */
PT getIdentifierStringAction(PT)(PT p)
{
  lastIdentifier = p.matches[0];
  return p;
}

/**
 * Mete en el set de identificadores constante, un identificador constante o genera un error si ya existe previamente
 */
PT storeConstIdentifierAction(PT)(PT p)
{
  if ((lastIdentifier in constIdentifiers) !is null) {
    import std.stdio : writeln;
    import colored;
    p.successful = false;
    writeln("Constante ya definida previamente : ".red , p.matches[0], generateErrorPossition(p));

  } else {
    constIdentifiers[lastIdentifier] = true;
  }
  return p;
}

/**
 * Verifica que un identificador se ha declarado previamente al usarlo como valor en un comando
 */
PT verifyIdentifierExistsAction(PT)(PT p)
{
  if ( (p.matches[0] in constIdentifiers) is null) {
    import std.stdio : writeln;
    import colored;
    p.successful = false;
    writeln("Identificador no reconocido : ".red , p.matches[0], generateErrorPossition(p));
  }
  return p;
}

enum string g = `
LevelProgram:
  Program     < :Spacing Constants? Commands? EndLevel ';' :Spacing :eoi

  Constants   < Constant+ :Spacing
  Constant    < "const" Identifier{getIdentifierStringAction} '=' Integer{storeConstIdentifierAction} ';'

  Commands    < Command+ :Spacing
  Command     < SpawnEnemy '(' Integer ',' Integer ',' Id ',' Id ')' ';' /
                SpawnEnemyScreenCoords '(' Integer ',' Integer ',' Id ',' Id ')' ';' /
                SpawnEnemyGroup '(' Integer ',' Integer ',' Id ',' Id ',' Integer ',' Id ')' ';' /
                SpawnEnemyGroupScreenCoords '(' Integer ',' Integer ',' Id ',' Id ',' Integer ',' Id ')' ';' /
                WaitTicks '(' Integer ')' ';' /
                WaitScroll '(' Integer ')' ';' /
                SetScrollSpeed '(' Integer ')' ';'


  Id          < Number / Identifier{verifyIdentifierExistsAction}
  Integer     <~ Sign? Number

# Terminals *****************************************************

  Identifier  <~ [a-zA-Z_] [a-zA-Z0-9_\-]*

# Commands
  EndLevel                      < "EndLevel"
  SpawnEnemy                    < "SpawnEnemy"
  SpawnEnemyScreenCoords        < "SpawnEnemyScreenCoords"
  SpawnEnemyGroup               < "SpawnEnemyGroup"
  SpawnEnemyGroupScreenCoords   < "SpawnEnemyGroupScreenCoords"
  WaitTicks                     < "WaitTicks"
  WaitScroll                    < "WaitScroll"
  SetScrollSpeed                < "SetScrollSpeed"

# Numbers
  Number      <~ digit+
  Sign        <- "-" / "+"

# Spacing and comments
  Spacing <~ (space / endOfLine / BlockComment / Comment)*
  Comment <~ "//" (!endOfLine .)* endOfLine
  BlockComment <~ "/*" (!(eoi | "*/") .)* "*/"

`;

mixin(grammar(g));

/**
 * Recorre el AST para generar el "wordcode"
 */
ushort[] toShortArray(ParseTree p)
{
  import std.conv : to, castFrom, parse;
  import std.ascii : isAlpha;
  import std.algorithm.searching : startsWith;
  import std.algorithm.comparison : among;
  import std.stdio;

  /**
   * Parsea el árbol de expresiones matematicas
   */
  long parseExpression(PT)(PT p) {
    string nodeName = p.name[13..$];
    switch(nodeName) {
      case "Integer":
        return parse!long(p.matches[0]);

      case "Id":
        if (p.matches[0].startsWith!isAlpha || p.matches[0].startsWith!(a => a.among('-', '_') != 0)) {
          return identifiersValues[p.matches[0]];
        }
        return parse!long(p.matches[0]);

      default:
        return 0;
    }
  }

  /**
   * Recorre el AST para generar el "wordcode"
   */
  ushort[] parseToCode(ParseTree p) {
    if (p.name == "LevelProgram") {
      return parseToCode(p.children[0]); // The grammar result has only child: the start rule's parse tree
    }
    string nodeName = p.name[13..$];
    switch(nodeName) {
      case "Program":
      case "Commands":
      case "Constants":
      case "Command":
        ushort[] result;
        foreach( child; p.children) {
          result ~= parseToCode(child);
        }
        return result;

      case "Constant":
        long contantVal = parseExpression(p.children[1]);
        string identifier = p.children[0].matches[0];
        identifiersValues[identifier] = contantVal;
        return [];

      case "EndLevel":
      case "SpawnEnemy":
      case "SpawnEnemyScreenCoords":
      case "SpawnEnemyGroup":
      case "SpawnEnemyGroupScreenCoords":
      case "WaitTicks":
      case "WaitScroll":
      case "SetScrollSpeed":
        return [COMMAND[nodeName]];

      case "Id":
        if (p.matches[0].startsWith!isAlpha || p.matches[0].startsWith!(a => a.among('-', '_') != 0)) {
          return [ castFrom!long.to!ushort(identifiersValues[p.matches[0]]) ];
        }

      case "Integer":
        long value = parseExpression(p);
        ushort tmp = castFrom!long.to!ushort(value);
        return [tmp];

      default:
        return [];
    }
  }
  return parseToCode(p);
}


