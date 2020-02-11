COMPILER_OPTIONS _case_sensitive;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// https://divcompo.now.sh
// ****************************************************************************

program matamarcianos;

import "csv.dll";

const
  DEBUG_MODE=1; // Modo debug. Activa la salida r pida, etc.
  PATH_USER="zardoz";
  PATH_PROG="mata";
  GAME_REGION=0; // Region de la zona de juego
  PLAYFIELD_RESOLUTION=10; // Valor de resolution en la zona de juego
global
  // **** Libreria de graficos
  fpgPlayer;
  fpgShoots;
  fpgEnemy;

  // **** Tipos de disparo
  // Disparos simples
  struct simpleShootData[3]
    graph; // Indice del grafico a usar de fpgShoots
    int damage; // Da¤o del disparo
    int delay; // Retardo entre cada disparo. A 60 fps -> 1 tick ~ 16 centesimas
    int speed; // Velocidad en pixels
  end;

  // **** Patrones de movimiento [Id patr¢n]
  struct paths[10]
    maxSteps; // N§ de pasos
    vx0; // Velocidad inicial eje X
    vy0; // Velocidad inicial eje Y
    struct steps[10]
      ax; // Aceleraci¢n eje x
      ay; // Aceleraci¢n eje y
      ticks; // N§ de ticks que dura este paso
    end;
  end;

local // Las variables locales a los profesos, se definen "universalmente" aqui
  life;
begin
  set_mode(m640x480);
  set_fps(60, 0);
  vsync=1;
  rand_seed(1234);

  // **** Carga de recursos ****
  // Graficos
  fpgPlayer = load_fpg(pathResolve("fpg\player.fpg"));
  fpgShoots = load_fpg(pathResolve("fpg\shoots.fpg"));
  fpgEnemy = load_fpg(pathResolve("fpg\enemy.fpg"));

  // Carga tipos de disparo
  loadShootTypeData();

  // Carga patrones de movimiento
  loadMovPaths();

  // Creaci¢n procesos
  playerShip(1);
  spawnEnemy();

  // Main loop
  loop
    // Salida del juego para modo debug
    if (DEBUG_MODE == 1 && key(_q))
      let_me_alone();
      break;
    end

    frame;
  end
end

function pathResolve(file)
begin
  return (PATH_USER + "\" + PATH_PROG + "\" + file);
end

function loadShootTypeData()
private
  retVal = 0;
begin
  // Efectivamente reyena un array de structs
  // La razon es que internamente DIV usa un array gigante para todas las variables
  retVal = readCSVToIntArray(pathResolve("shoots.csv"),
      offset simpleShootData,
      sizeof(simpleShootData));
end

function loadMovPaths()
private
  retVal = 0;
begin
  retVal = readCSVToIntArray(pathResolve("movpaths.csv"),
      offset paths,
      sizeof(paths));
end;

function spawnEnemy()
private
  i;
begin
  for (i=0; i < 5; i++)
    x = rand(0, 5000);
    y = rand(0, 500);
    enemy(1, x, y, 10, 0);
  end
end

process playerShip(graph)
private
  _health = 100;
  _mainShootCounter = 0; // Utilizamos para meter retardos entre los disparos
  _mainWeapon = 0;
begin
  // Asignaci¢n grafico
  file = fpgPlayer;
  graph = graph;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;

  loop
    if (_health < 0)
      break;
    end;
    // Calcula de nueva posici¢n
    x = mouse.x * PLAYFIELD_RESOLUTION;
    y = mouse.y * PLAYFIELD_RESOLUTION;

    if (mouse.left )
      if (_mainShootCounter >= simpleShootData[_mainWeapon].delay)
        _mainShootCounter = 0;
        shoot(simpleShootData[_mainWeapon].graph,
          x, y,
          simpleShootData[_mainWeapon].damage, 90000,
          simpleShootData[_mainWeapon].speed);
      end
    end

    _mainShootCounter++;
    frame;
  end;
end

/**
 * Disparo enemigo que se mueve en linea recta
 *
 * Par metros:
 * graphIndex
 * x
 * y
 * damage Da¤o
 * direction Direcci¢n del movimiento
 * speed Velocidad del disparo
 */
process enemyShoot(graph, x, y, damage, direction, speed)
private
begin
  // Asignaci¢n de grafico
  file = fpgShoots;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;

  while (! out_region(id, region))
    if (collision(type playerShip))
      // TODO Herir al jugador
    end;

    // Movimiento
    xadvance(direction, speed);

    frame;
  end;
end

/**
 * Disparo que se mueve en linea recta
 *
 * Par metros:
 * graph
 * x
 * y
 * damage Da¤o
 * direction Direcci¢n del movimiento
 * speed Velocidad del disparo
 */
process shoot(graph, x, y, damage, direction, speed)
private
  enemyId;
begin
  file = fpgShoots;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;

  while (! out_region(id, region))
    // Colision con un enemigo
    enemyId = collision(type enemy);
    if (enemyId <> 0)
      enemyId.life = enemyId.life - damage;
      break;
    end

    // Movimiento
    xadvance(direction, speed);

    frame;
  end;
end


// TODO meter un process para spamear naves enemigas

/**
 * Nave o bicho enemigo
 * Par metros:
 * graph : Indice con el sprite a usar
 * x
 * y
 * life : Vida del enemigo
 */
process enemy(graph, x, y, life, pathId)
private
  _pathStep = 0;
  _pathTick = 0; // Utilizamos para contar los ticks que permanece en paso altual de mov.
  _vx = 0;
  _vy = 0;
begin
  file = fpgEnemy;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  // Aplicamos la velocidad inicial si hay un patr¢n de mov.
  if (pathId <> -1)
    _vx = paths[pathId].vx0;
    _vy = paths[pathId].vy0;
  end;


  while (! out_region(id, region) && life > 0)
    // Aplicamos el patr¢n de mov. si hay uno asignado
    if (pathId <> -1 && _pathStep <= 10)
      if (paths[pathId].maxSteps >= _pathStep)
        if (_pathTick >= paths[pathId].steps[_pathStep].ticks)
          _pathStep++;
          _pathTick = 0;
        end;
        _vx = _vx + paths[pathId].steps[_pathStep].ax;
        _vy = _vy + paths[pathId].steps[_pathStep].ay;
        _pathTick++;
      end;
    end;
    x = x + _vx;
    y = y + _vy;

    // TODO Colision con el jugador, le quita vida

    frame;
  end;
end

/**
 * Interpolaci¢n lineal
 * @param p Cuanto se interpola. De 0 a 100
 */
function linear(p, a, b)
begin
  return ((((100 - p) * a) + (p * b)) / 100);
end
