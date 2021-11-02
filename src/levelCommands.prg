COMPILER_OPTIONS _case_sensitive, _extended_conditions, _use_cstyle;
// ****************************************************************************
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// Intrepete de instrucciones del nivel
// ****************************************************************************

const
  // **** Comandos
  CMD_END_LEVEL           = 0;
  CMD_WAIT_TICKS          = 1;
  CMD_WAIT_SCROLL         = 2;
  CMD_SET_SCROLL_SPEED    = 3;
  CMD_SPAWN_ENEMY         = 4;
  CMD_SPAWN_ENEMY_SCR     = 5;
  CMD_SPAWN_ENEMY_GRP     = 6;
  CMD_SPAWN_ENEMY_GRP_SCR = 7;

  CMD_DEFINE_ENEMY_GROUP  = 8;
  CMD_END_BLOCK           = 9;

  CMD_SET_BONUS_TYPE      = 10; // 0x000A

/**
 * Lee los comandos de un fichero de datos binario
 */
function int16* loadLevelCommands(string levelName)
private
  string _path;
  int arraySize = 0;
  _file;
  int16* _commands;
begin
  arraySize = 0;
  _path = "lvl/" + levelName + "/commands.dat";
  _path = pathResolve(_path);
  _file = fopen(_path, "r");

  if (_file == 0)
    errorLoadLevelCommands(_path);
    return(0);
  end

  fseek(_file, 0, seek_end);
  arraySize = ftell(_file); // Tamaño en INTs
  fclose(_file);
  if (arraySize <= 0)
    errorLoadLevelCommands(_path);
    return(0);
  end

  _commands = memory_new(arraySize * sizeof(int16));
  if (_commands == 0)
    errorLoadLevelCommands(_path);
    return(0);
  end

  load(_path, _commands);
  return(_commands);
end

function errorLoadLevelCommands(string path)
private
  string _msg;
begin
  _msg = "Error al abrir fichero de datos: " + path;
  write(0, 0, 0, 0, _msg);
  loop
    // abortamos ejecución
    if (keydown(_q) || keydown(_esc))
      let_me_alone();
      break;
    end
    frame;
  end
end

/**
 * Procesa el 'wordcode' y ejecuta los comandos
 */
process levelCommands(word pointer commands)
private
  _finished = false;
  _waitTicks = 0;
  _waitScrollY = -1;
  _defineEnemyGroupBlock = false;
  _enemyGroupId = 0;
  int _pc = 0;
  word _val, _arg0, _arg1, _arg2, _arg3, _arg4, _arg5;
begin
  while (!_finished)
    _val = commands[_pc];

    switch (_val)
      case CMD_END_LEVEL:
        _finished = 1;
      end

      case CMD_WAIT_TICKS:
        _arg0 = commands[++_pc];
        ticksCounter = 0;
        _waitTicks = _arg0; // Inicializamos el contador de ticks
      end

      case CMD_WAIT_SCROLL:
        _arg0 = commands[++_pc];
        _waitScrollY = _arg0; // Inicializamos la espera hasta que el scrollY valga ese valor
      end

      case CMD_SET_SCROLL_SPEED:
        _arg0 = commands[++_pc];
        scrollStepY = sWordToInt(_arg0);
      end

      case CMD_SPAWN_ENEMY:
        // 4 argumentos
        _arg0 = commands[++_pc]; // X
        _arg1 = commands[++_pc]; // Y
        _arg2 = commands[++_pc]; // Type
        _arg3 = commands[++_pc]; // Patron Mov.

        enemy(sWordToInt(_arg0), _arg1, _arg2, sWordToInt(_arg3), _enemyGroupId);
        // Si estamos definiendo un grupo complejo, tenemos que actualizar el nº de hijos del grupo
        if (_enemyGroupId <> 0)
          _enemyGroupId.totalChildrens += 1;
          _enemyGroupId.remaningChildrens = _enemyGroupId.totalChildrens;
        end
      end

      case CMD_SPAWN_ENEMY_SCR:
        // 4 argumentos
        _arg0 = screenXToScrollX(sWordToInt(commands[++_pc]));
        _arg1 = screenYToScrollY(sWordToInt(commands[++_pc]));
        _arg2 = commands[++_pc]; // Type
        _arg3 = commands[++_pc]; // Patron Mov.

        enemy(_arg0, _arg1, _arg2, sWordToInt(_arg3), _enemyGroupId);
        // Si estamos definiendo un grupo complejo, tenemos que actualizar el nº de hijos del grupo
        if (_enemyGroupId <> 0)
          _enemyGroupId.totalChildrens += 1;
          _enemyGroupId.remaningChildrens = _enemyGroupId.totalChildrens;
        end
      end

      case CMD_SPAWN_ENEMY_GRP:
        // 6 argumentos
        _arg0 = commands[++_pc]; // X
        _arg1 = commands[++_pc]; // Y
        _arg2 = commands[++_pc]; // Type
        _arg3 = commands[++_pc]; // Patron Mov.
        _arg4 = commands[++_pc]; // Nº de enemigos
        _arg5 = commands[++_pc]; // Id Formación
        createSimpleEnemyGroup(sWordToInt(_arg0), _arg1, _arg2, sWordToInt(_arg3), _arg4, _arg5);
      end

      case CMD_SPAWN_ENEMY_GRP_SCR:
        // 6 argumentos
        _arg0 = screenXToScrollX(sWordToInt(commands[++_pc]));
        _arg1 = screenYToScrollY(sWordToInt(commands[++_pc]));
        _arg2 = commands[++_pc]; // Type
        _arg3 = commands[++_pc]; // Patron Mov.
        _arg4 = commands[++_pc]; // Nº de enemigos
        _arg5 = commands[++_pc]; // Id Formación
        createSimpleEnemyGroup(_arg0, _arg1, _arg2, sWordToInt(_arg3), _arg4, _arg5);
      end

      case CMD_SET_BONUS_TYPE:
        // 1 argumento
        _arg0 = commands[++_pc]; // Id de bonus
        // Solo surge efecto si esta dentro de un definición de un grupo complejo
        if (_enemyGroupId <> 0)
          _enemyGroupId.bonusType = _arg0;
        end

      end

      case CMD_DEFINE_ENEMY_GROUP:
        _defineEnemyGroupBlock = 1;
        // _enemyGroupId = enemyGroup(1); // Hack: Le indicamos un hijo, luego se lo restamos
        // Se hace para evitar que se auto-muera hasta crear los hijos de verdad
      end

      case CMD_END_BLOCK:
        _defineEnemyGroupBlock = false;
          _enemyGroupId.totalChildrens -= 1;
          _enemyGroupId.remaningChildrens = _enemyGroupId.totalChildrens;
        _enemyGroupId = 0;
      end

      default:
      end
    end

    // Esperamos a que pase los ticks
    while (_waitTicks != 0)
      ticksCounter++;
      if (ticksCounter >= _waitTicks)
        ticksCounter -= _waitTicks;
        _waitTicks = 0;
      end
      frame;
    end

    // Esperamos a que el scroll alcanze un determinado valor
    if (_waitScrollY <> -1 && scrollStepY <> 0)
      if (scrollStepY < 0)
        // Scroll normal hacia arriba
        while (scrollY >= _waitScrollY)
          frame;
        end
      else
        // Scroll hacia abajo
        while (scrollY <= _waitScrollY)
          frame;
        end
      end
      _waitScrollY = -1;
    end

    _pc++;
  end
end;

/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1 :*/
