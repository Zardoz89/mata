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
  "SpawnEnemyGroupScreenCoords" : 0x0007,
  "DefineEnemyGroup"            : 0x0008,
  "EndBlock"                    : 0x0009,
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
  Program     < :Spacing Constants? Statements? EndLevel ';' :Spacing :eoi

  Constants   < Constant+ :Spacing
  Constant    < "const" Identifier{getIdentifierStringAction} '=' Expression{storeConstIdentifierAction} ';'

  Statements    < Statement+ :Spacing
  Statement     < CompoundStatement / SpawnCommands / SpawnSimpleGroupCommands / WaitCommands / ScrollCommands

  SpawnCommands <
                SpawnEnemy '(' Expression ',' Expression ',' Expression ',' Expression ')' ';' /
                SpawnEnemyScreenCoords '(' Expression ',' Expression ',' Expression ',' Expression ')' ';'

  SpawnSimpleGroupCommands <
                SpawnEnemyGroup '(' Expression ',' Expression ',' Expression ',' Expression ',' Expression ',' Expression ')' ';' /
                SpawnEnemyGroupScreenCoords '(' Expression ',' Expression ',' Expression ',' Expression ',' Expression ',' Expression ')' ';'

  WaitCommands <
                WaitTicks '(' Expression ')' ';' /
                WaitScroll '(' Expression ')' ';'

  ScrollCommands <
                SetScrollSpeed '(' Expression ')' ';'

  CompoundStatement < CompoundStatementType '{' SpawnCommands+ :Spacing '}'

  CompoundStatementType < DefineEnemyGroup

# Expressiones
  Expression  < Term
  Term        < Factor ( Add / Sub)*
  Add         < "+" Factor
  Sub         < "-" Factor
  Factor      < Primary (Mul / Div)*
  Mul         < "*" Primary
  Div         < "/" Primary
  Primary     < Parens / Neg / Number / Identifier{verifyIdentifierExistsAction}
  Parens      < :"(" Term :")"
  Neg         < "-" Primary

# Terminals *****************************************************

  Identifier  <~ [a-zA-Z_] [a-zA-Z0-9_\-]*
  Number      <~ digit+

# Statements
  EndLevel                      < "EndLevel"
  SpawnEnemy                    < "SpawnEnemy"
  SpawnEnemyScreenCoords        < "SpawnEnemyScreenCoords"
  SpawnEnemyGroup               < "SpawnEnemyGroup"
  SpawnEnemyGroupScreenCoords   < "SpawnEnemyGroupScreenCoords"
  WaitTicks                     < "WaitTicks"
  WaitScroll                    < "WaitScroll"
  SetScrollSpeed                < "SetScrollSpeed"

# Compound Statements types
  DefineEnemyGroup              < "DefineEnemyGroup"

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
  import std.stdio : writeln;

  /**
   * Parsea el árbol de expresiones matematicas
   */
  long parseExpression(PT)(PT p) {
    const string nodeName = p.name[13..$];
    switch(nodeName) {
      case "Expression":
        return parseExpression(p.children[0]);

      case "Term":
        long val = 0;
        foreach(child; p.children) {
          val += parseExpression(child);
        }
        return val;

      case "Factor":
        long val = 1;
        foreach(child; p.children) {
          if (child.name[13..$] == "Div") {
            val /= parseExpression(child);
          } else {
            val *= parseExpression(child);
          }
        }
        return val;

      case "Primary", "Parens", "Add", "Mul", "Div":
        return parseExpression(p.children[0]);

      case "Sub", "Neg":
        return - parseExpression(p.children[0]);

      case "Number":
        return parse!long(p.matches[0]);

      case "Identifier":
        return identifiersValues[p.matches[0]];

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
      case "Constants":
      case "Statements":
      case "Statement":
      case "SpawnCommands":
      case "SpawnSimpleGroupCommands":
      case "WaitCommands":
      case "ScrollCommands":
      case "CompoundStatementType":
        ushort[] result;
        foreach( child; p.children) {
          result ~= parseToCode(child);
        }
        return result;

      case "Constant":
        const long contantVal = parseExpression(p.children[1]);
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
      case "DefineEnemyGroup":
        writeln(nodeName);
        return [COMMAND[nodeName]];

      case "CompoundStatement":
        // 0 -> Tipo
        // 1..$ -> N Comandos dentro del bloque
        ushort[] result;
        foreach( child; p.children) {
          result ~= parseToCode(child);
        }
        result ~= COMMAND["EndBlock"];
        return result;


      case "Expression":
        long value = parseExpression(p);
        ushort tmp = castFrom!long.to!ushort(value);
        return [tmp];

      default:
        return [];
    }
  }
  return parseToCode(p);
}


