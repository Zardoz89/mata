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

  // **** Tipos de animaci¢n
  ANI_SINGLE = 0; // Al terminar los frames, para
  ANI_LOOP = 1; // Hace bucle
  ANI_SPRING = 2; // avanza-retrocede en la animaci¢n

global
  // **** Libreria de graficos
  int fpgPlayer;
  int fpgShoots;
  int fpgEnemy;

  // **** Tipos de disparo
  // Disparos simples
  struct shootData[10]
    int graph; // Indice del grafico a usar de fpgShoots
    int damage; // Da¤o del disparo
    int delay; // Retardo entre cada disparo. A 60 fps -> 1 tick ~ 16 centesimas
    int speed; // Velocidad en pixels
  end;

  // **** Patrones de movimiento [Id patr¢n]
  struct paths[10]
    byte maxSteps; // N§ de pasos
    int vx0; // Velocidad inicial eje X
    int vy0; // Velocidad inicial eje Y
    struct steps[10]
      int ax; // Aceleraci¢n eje x
      int ay; // Aceleraci¢n eje y
      int ticks; // N§ de ticks que dura este paso
    end;
  end;

  // **** Tipos de enemigos del juego
  struct enemyType[10]
    // Sprite y animaci¢n
    byte nFrames;
    byte animationType; // 0 al terminar, para; 1 bucle ; 2 avanza-retrocede
    int graphId[10];
    int hull; // Vidia inicial
    int shootTypeId; // Tipo de disparo
    int aggression; // Si es < 0 dispara directamente; > 0 dispara hacia abajo
    // Abs es la frecuencia de disparo -> rand(0, 1000) <= abs(aggresion)
    word score; // Puntos que da al ser destruido
  end;

  // **** Generales de la partida
  int playerShipId;
  int score = 0;

local // Las variables locales a los procesos, se definen "universalmente" aqui
  hull; // Vida o puntos de casco de cosos destruibles
  typeId = -1; // Usada en los procesos acceder a los datos de tipo de lo que sea
  ticksCounter = 0; // Contador de ticks (frames)
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

  // Carga tipo de enemigos
  loadEnemyType();

  // Creaci¢n procesos
  playerShipId = playerShip(1);
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
      offset shootData,
      sizeof(shootData));
end

function loadMovPaths()
private
  retVal = 0;
begin
  retVal = readCSVToIntArray(pathResolve("movpaths.csv"),
      offset paths,
      sizeof(paths));
end;

function loadEnemyType()
private
  retVal = 0;
begin
  retVal = readCSVToIntArray(pathResolve("enemtype.csv"),
      offset enemyType,
      sizeof(enemyType));
end;

// Funcion temporal para crear enemigos
function spawnEnemy()
private
  i;
begin
  for (i=0; i < 5; i++)
    x = rand(0, 5000);
    y = rand(0, 500);
    enemy(x, y, 0, 0);
  end

  for (i=0; i < 5; i++)
    x = i * 1000;
    y = 0;
    enemy(x, y, 0, 1);
  end

end

process playerShip(graph)
private
  _mainShootCounter = 0; // Utilizamos para meter retardos entre los disparos
  _mainWeapon = 2;
begin
  // Asignaci¢n grafico
  file = fpgPlayer;
  graph = graph;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;

  hull = 100;

  loop
    if (hull < 0)
      break;
    end;
    // Calcula de nueva posici¢n
    x = mouse.x * PLAYFIELD_RESOLUTION;
    y = mouse.y * PLAYFIELD_RESOLUTION;

    if (mouse.left )
      if (_mainShootCounter >= shootData[_mainWeapon].delay)
        _mainShootCounter = 0;
        shoot(x, y, 90000, _mainWeapon);
      end
    end

    _mainShootCounter++;
    ticksCounter++;
    frame;
  end;
end

/**
 * Disparo del jugador
 *
 * Par metros:
 * x
 * y
 * direction Angulo de movimiento
 * typeId Tipo de disparo
 */
process shoot(x, y, direction, typeId)
private
  enemyId;
begin
  file = fpgShoots;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  graph = shootData[typeId];

  while (! out_region(id, region))
    // Colision con un enemigo
    enemyId = collision(type enemy);
    if (enemyId)
      enemyId.hull = enemyId.hull - shootData[typeId].damage;
      score += enemyType[enemyId.typeId].score;
      break;
    end

    // Movimiento
    xadvance(direction, shootData[typeId].speed);

    frame;
  end;
end

/**
 * Disparo de las naves enemigas
 *
 * Par metros:
 * x
 * y
 * direction Angulo de movimiento
 * typeId Tipo de disparo
 */
process enemyShoot(x, y, direction, typeId)
private
  playerId;
begin
  file = fpgShoots;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  graph = shootData[typeId];

  while (! out_region(id, region))
    // Colision con un enemigo
    playerId = collision(type playerShip);
    if (playerId)
      playerId.hull = playerId.hull - shootData[typeId].damage;
      break;
    end

    // Movimiento
    xadvance(direction, shootData[typeId].speed);

    frame;
  end;
end


// TODO meter un process para spamear naves enemigas

/**
 * Nave o bicho enemigo
 * Par metros:
 * x
 * y
 * pathId : Patr¢n de movimiento
 * typeId : Tipo de enemigo
 */
process enemy(x, y, pathId, typeId)
private
  int _pathStep = 0;
  int _pathTick = 0; // Utilizamos para contar los ticks que permanece en paso altual de mov.
  int _vx = 0;
  int _vy = 0;
  int _frame = 0;
  int _frameDir = 1; // Lo utilizamos para las animaciones tipo spring
  int _aggressionAbs;
begin
  file = fpgEnemy;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  graph = enemyType[typeId].graphId[_frame];

  hull = enemyType[typeId].hull;
  _aggressionAbs = abs(enemyType[typeId].aggression);

  // Aplicamos la velocidad inicial si hay un patr¢n de mov.
  if (pathId <> -1)
    _vx = paths[pathId].vx0;
    _vy = paths[pathId].vy0;
  end;


  while (! out_region(id, region) && hull > 0)

    // **** Movimiento
    // Aplicamos el patr¢n de mov. si hay uno asignado
    if (pathId <> -1 && _pathStep <= 10)
      if (paths[pathId].maxSteps >= _pathStep)
        if (_pathTick >= paths[pathId].steps[_pathStep].ticks)
          _pathStep++;
          _pathTick = 0;
        end
        _vx = _vx + paths[pathId].steps[_pathStep].ax;
        _vy = _vy + paths[pathId].steps[_pathStep].ay;
        _pathTick++;
      end
    end
    x = x + _vx;
    y = y + _vy;

    // **** Animaci¢n
    if (!ticksCounter) // Se actualiza la animaci¢n cada 2 frames
      switch (enemyType[typeId].animationType)
      case ANI_SINGLE:
        if (enemyType[typeId].nFrames -1 <= _frame)
        else
          _frame++;
        end
      end
      case ANI_LOOP:
        if (enemyType[typeId].nFrames -1 <= _frame)
          _frame = 0;
        else
          _frame++;
        end
      end
      case ANI_SPRING:
        if (enemyType[typeId].nFrames -1 <= _frame)
          _frameDir = -1;
        else if (_frame <= 0)
          _frameDir = 1;
          end
        end
        _frame = _frame + _frameDir;
      end
    end
    graph = enemyType[typeId].graphId[_frame];
    end

    // **** Disparo
    if (enemyType[typeId].shootTypeId <> -1)
      if (ticksCounter >> 1)
         if (rand(0, 1000) <= _aggressionAbs)
           // Disparamos
           if (enemyType[typeId].aggression >= 0)
            // Dispara hacia el jugador
            enemyShoot(x, y, fget_angle(x, y, playerShipId.x, playerShipId.y),
              enemyType[typeId].shootTypeId);
           else
            // Dispara recto
            enemyShoot(x, y, 270000, enemyType[typeId].shootTypeId);
           end
         end
      end
    end

    ticksCounter++;
    frame;
  end;
end

