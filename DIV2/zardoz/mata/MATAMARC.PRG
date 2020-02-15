COMPILER_OPTIONS _case_sensitive;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// https://divcompo.now.sh
// ****************************************************************************

program matamarcianos;

import "csv.dll";

const
  DEBUG_MODE=1; // Modo debug. Activa la salida rapida, etc.

  // cte. para las rutas
  PATH_USER="zardoz";
  PATH_PROG="mata";

  GAME_REGION=0; // Region de la zona de juego
  PLAYFIELD_RESOLUTION=10; // Valor de resolution en la zona de juego

  // **** Tipos de dispersion del disparo
  DIS_NONE = 0; // No dispersa
  DIS_RAND = 1; // Dispersion aleatoria
  DIS_SIN = 2; // Dispersion senoidal
  DIS_FOLLOW_Y_FATHER = 3; // Se mantiene en el mismo eje Y que el proceso padre

  DIS_TICKS_SIN_MULTIPLIER = 50000; // Multiplicador de ticks para DIS_SIN

  // **** Tipos de movimientos relativos
  MOVREL_NONE = 0;
  MOVREL_SYNC_X = 1; // Sincroniza eje X con el padre
  MOVREL_SYNC_Y = 2; // Sincroniza eje Y con el padre
  MOVREL_REL_X  = 4; // Movimiento relativo solo eje X
  MOVREL_REL_Y  = 8; // Movimiento relativo solo eje Y
  MOVREL_REL_XY = MOVREL_REL_X || MOVREL_REL_Y; // Ambos ejes

  // **** Tipos de animacion
  ANI_SINGLE = 0; // Al terminar los frames, para
  ANI_LOOP = 1; // Hace bucle
  ANI_SPRING = 2; // avanza-retrocede en la animacion

global
  // **** Libreria de graficos
  int fpgPlayer;
  int fpgShoots;
  int fpgEnemy;

  // **** Definicion de un "nivel"
  struct level
    int tileMapId; // Id del tilemap que se va usar para el fondo
    int bossId;
    int bossSpawnTime;
    int numberOfGroups;
    struct groups[64]
      int x0; int y0; // Posicion inicial del grupo
      int formationType; // Tipo de formacion asignada. -1 es no moverse respecto al scroll.
      int spawnTime; // Tiempo en ms de cuando hace spawn este grupo
      int bonusType; // Id del tipo de bonus a dar si se destruye toda la oleada. -1 no tiene bonus
      int enemyType[6]; // -1 no hay enemigo
      int pathId[6]; // -1 esta fijo respecto al scroll de fondo
      /*
      struct enemy[6] // Array con los enemigos que representan esta oleada
        int enemyType; // -1 no hay enemigo
        int pathId; // -1 esta fijo respecto al scroll de fondo
      end
      */
      //byte _destroyed = 0; // Indicador si el grupo ha sido destruido
      //byte _bonusFlag:
    end
  end

  // **** Formaciones de naves enemigas
  struct formations[16]
    struct startPosition[6]
      int x; int y;
    end
  end

  // **** Tipos de disparo
  struct shootData[10]
    int graph; // Indice del grafico a usar de fpgShoots
    int damage; // Daño del disparo
    int delay; // Retardo entre cada disparo. A 60 fps -> 1 tick ~ 16 centesimas
    int speed; // Velocidad en pixels
    int disperseValue; // Angulo de dispersion
    int disperseType; // Tipo de dispersion del disparo
  end

  // **** Patrones de movimiento [Id patron]
  struct paths[10]
    byte maxSteps; // Nº de pasos
    int vx0; // Velocidad inicial eje X
    int vy0; // Velocidad inicial eje Y
    struct steps[10]
      int ax; // Aceleracion eje x
      int ay; // Aceleracion eje y
      int ticks; // Nº de ticks que dura este paso
    end
  end

  // **** Tipos de enemigos del juego
  struct enemyType[10]
    // Sprite y animacion
    byte nFrames;
    byte animationType; // 0 al terminar, para; 1 bucle ; 2 avanza-retrocede
    int graphId[10];
    int hull; // Vidia inicial
    int shootTypeId; // Tipo de disparo
    int aggression; // Si es < 0 dispara directamente; > 0 dispara hacia abajo
    // Abs es la frecuencia de disparo -> rand(0, 1000) <= abs(aggresion)
    word score; // Puntos que da al ser destruido
  end

  // **** Generales de la partida
  int playerShipId;
  int score = 0;

local // Las variables locales a los procesos, se definen "universalmente" aqui
  hull; // Vida o puntos de casco de cosos destruibles
  typeId = -1; // Usada en los procesos acceder a los datos de tipo de lo que sea
  ticksCounter = 0; // Contador de ticks (frames)
  xrel; // Posiciones relativas
  yrel;
  remaningChildrens = 0; // Numero de procesos hijos restantes
  killedChildrens = 0; // Numero de procesos hijos matados por el jugador
private

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

  // Carga tipo de enemigos
  loadFormations();

  // Carga de datos del nivel 1
  loadLevelData("level_01");

  // Proceso nivel de juego
  gameLevel();

  if (DEBUG_MODE == 1)
    debugText();
  end

  // Main loop
  loop
    // Salida del juego para modo debug
    if (DEBUG_MODE == 1 && key(_q))
      let_me_alone();
      break;
    end

    frame(200);
  end
end

/**
 * Genera la ruta relativa a los ficheros del juego
 */
function pathResolve(file)
begin
  return (PATH_USER + "\" + PATH_PROG + "\" + file);
end

/**
 * Lee el fichero con los tipos de disparo
 */
function loadShootTypeData()
private
  _retVal = 0;
  _path;
  string _msg;
begin
  // Efectivamente reyena un array de structs
  // La razon es que internamente DIV usa un array gigante para todas las variables
  _path = pathResolve("shoots.csv");
  _retVal = readCSVToIntArray(_path,
      offset shootData,
      sizeof(shootData));
  if (DEBUG_MODE == 1 && _retVal <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
  end
  return(_retVal);
end

/**
 * Lee el fichero con los patrones de movimiento
 */
function loadMovPaths()
private
  _retVal = 0;
  _path;
  string _msg;
begin
  _path = pathResolve("movpaths.csv");
  _retVal = readCSVToIntArray(_path,
      offset paths,
      sizeof(paths));
  if (DEBUG_MODE == 1 && _retVal <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
  end
  return(_retVal);
end;

/**
 * Lee el fichero con los tipos de enemigo
 */
function loadEnemyType()
private
  _retVal = 0;
  _path;
  string _msg;
begin
  _path = pathResolve("enemtype.csv");
  _retVal = readCSVToIntArray(_path,
      offset enemyType,
      sizeof(enemyType));
  if (DEBUG_MODE == 1 && _retVal <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
  end
  return(_retVal);
end;

/**
 * Lee el fichero con las formaciones de enemigos
 */
function loadFormations()
private
  _retVal = 0;
  _path;
  string _msg;
begin
  _path = pathResolve("formatio.csv");
  _retVal = readCSVToIntArray(_path,
      offset formations,
      sizeof(formations));
  if (DEBUG_MODE == 1 && _retVal <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
  end
  return(_retVal);
end;


/**
 * Lee el fichero con los datos de nivel
 */
function loadLevelData(string levelName)
private
  _retVal = 0;
  _path;
  string _msg;
begin
  // WTF TODO mirar por que no le gusta a div que haga esto
  //_path = levelName + ".csv";
  _path = pathResolve("lvl\level_01.csv");
  _retVal = readCSVToIntArray(_path,
      offset level,
      sizeof(level));
  if (DEBUG_MODE == 1 && _retVal <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
  end
  return(_retVal);
end;

/**
 * Proceso que representa un nivel del juego
 */
process gameLevel()
private
 _destroyedAll = false;
 _actualGroupInd = 0;
begin
  // Inicializar el timer[0]
  timer[0] = 0;

  // TODO procesar tilemapId y crear el scroll de fondo

  // Crear al proceso jugador
  playerShipId = playerShip(1);

  loop
    // **** Crea los grupos de naves segun ha pasdo una delta de tiempo
    if (_actualGroupInd < level.numberOfGroups)
      if (timer[0] >= level.groups[_actualGroupInd].spawnTime)
        timer[0] -= level.groups[_actualGroupInd].spawnTime;

        enemyGroup(_actualGroupInd);
        _actualGroupInd++;
      end
    end

    frame;
  end
end

/**
 * Crea a u ngrupo de enemigos y gestiona el spawn del bonus si es necesario
 */
process enemyGroup(groupInd)
private
 i;
 _formationType;
 _enemyType;
 _totalChildrens = 0;
begin
  _formationType = formations[level.groups[groupInd].formationType];

  for (i=0; i <= 6; i++)
    debug;
    _enemyType = level.groups[groupInd].enemyType[i];
    if (_enemyType <> -1)
      enemy(
        formations[_formationType].startPosition[i].x,
        formations[_formationType].startPosition[i].y,
        level.groups[groupInd].pathId[i],
        _enemyType);
      remaningChildrens++;
    end
  end
  _totalChildrens = remaningChildrens;

  loop
    if (remaningChildrens <= 0)
      if (killedChildrens == _totalChildrens)
        // TODO Hacer aparece el bonus si es necesario
        write(0, 0, 0, 0, "Eliminado grupo");
      end
      break;
    end

    frame;
  end
end


/**
 * Proceso que muestra informacion de debug como los FPS
 */
process debugText()
private
  int fpsTxtId = 0;
  string _msg;
begin
  loop
    if (fpsTxtId)
      delete_text(fpsTxtId);
    end
    _msg = "FPS: " + itoa(fps);
    fpsTxtId = write(0, 640, 0, 2, _msg);
    frame(3000); // Actualiza a 2 FPS
  end
end

process playerShip(graph)
private
  _mainShootCounter = 0; // Utilizamos para meter retardos entre los disparos
  _mainWeapon = 5;
  _dispersionAngle = 0;
begin
  // Asignacion grafico
  file = fpgPlayer;
  graph = graph;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;

  hull = 100;

  loop
    if (hull < 0)
      break;
    end;
    // Calcula de nueva posicion
    x = mouse.x * PLAYFIELD_RESOLUTION;
    y = mouse.y * PLAYFIELD_RESOLUTION;

    if (mouse.left )
      if (_mainShootCounter >= shootData[_mainWeapon].delay)
        _mainShootCounter = 0;
        _dispersionAngle = calcDispersionAngle(shootData[_mainWeapon].disperseValue,
          shootData[_mainWeapon].disperseType, ticksCounter);
        if (shootData[_mainWeapon].disperseType <> DIS_FOLLOW_Y_FATHER)
          shoot(x, y, 90000 + _dispersionAngle , _mainWeapon, MOVREL_NONE, false);
        else
          shoot(x, y, 90000 + _dispersionAngle , _mainWeapon,
            MOVREL_SYNC_X || MOVREL_REL_Y, false);
        end
      end
    end

    _mainShootCounter++;
    ticksCounter++;
    frame;
  end
end

/**
 * Calcula el nuevo angulo de dispersion a partir del tipo, angulo maximo y ticks
 */
function calcDispersionAngle(weaponDispersionAngle, dispersionType, ticks)
private
  int _dispersionAngle;
begin
  switch (dispersionType)
    case DIS_RAND:
      _dispersionAngle = rand(- weaponDispersionAngle, weaponDispersionAngle);
    end
    case DIS_SIN:
      _dispersionAngle = (weaponDispersionAngle / 1000)
              * sin(ticks * DIS_TICKS_SIN_MULTIPLIER);
    end
    default:
      _dispersionAngle = 0;
    end
  end
  return (_dispersionAngle);
end

/**
 * Disparo del jugador
 *
 * Parametros:
 * x
 * y
 * direction Angulo de movimiento
 * typeId Tipo de disparo
 * moveRelativeToFather Cte. que indica el tipo de movimiento relativo
 * enemyshoot True si es disparado por un enemigo
 */
process shoot(x, y, direction, typeId, moveRelativeToFather, enemyShoot)
private
  hitId;
begin
  file = fpgShoots;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  graph = shootData[typeId];
  xrel = 0;
  yrel = 0;

  while (! out_region(id, region))
    if (enemyShoot)
      // Colision con el jugador
      hitId = collision(type playerShip);
      if (hitId)
        hitId.hull = hitId.hull - shootData[typeId].damage;
        break;
      end
    else
      // Colision con un enemigo
      hitId = collision(type enemy);
      if (hitId)
        hitId.hull = hitId.hull - shootData[typeId].damage;
        score += enemyType[hitId.typeId].score;
        hitId.father.killedChildrens++;
        hitId.father.remaningChildrens--;
        break;
      end
    end

    // Movimiento
    // Si es movimiento relativo
    if ((moveRelativeToFather && MOVREL_SYNC_X) == MOVREL_SYNC_X)
      x = father.x;
      if (direction == 270000 || direction == -90000)
        yrel += shootData[typeId].speed;
      else
        yrel -= shootData[typeId].speed;
      end
      if ((moveRelativeToFather && MOVREL_REL_Y) == MOVREL_REL_Y)
        y = father.y + yrel;
      else
        y = yrel;
      end
    else
      xadvance(direction, shootData[typeId].speed);
    end
    frame;
  end;
end

/**
 * Nave o bicho enemigo
 * Parametros:
 * x
 * y
 * pathId : Patron de movimiento
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
  int _dispersionAngle;
  int _shootId;
begin
  file = fpgEnemy;
  region = GAME_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  graph = enemyType[typeId].graphId[_frame];

  hull = enemyType[typeId].hull;
  _aggressionAbs = abs(enemyType[typeId].aggression);
  _shootId = enemyType[typeId].shootTypeId;

  // Aplicamos la velocidad inicial si hay un patron de mov.
  if (pathId <> -1)
    _vx = paths[pathId].vx0;
    _vy = paths[pathId].vy0;
  end;


  while (! out_region(id, region) && hull > 0)

    // **** Movimiento
    // Aplicamos el patron de mov. si hay uno asignado
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
    x += _vx;
    y += _vy;

    // **** Animacion
    if (!ticksCounter) // Se actualiza la animacion cada 2 frames
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
          _dispersionAngle = calcDispersionAngle(
            shootData[_shootId].disperseValue,
            shootData[_shootId].disperseType,
            ticksCounter);

          if (enemyType[typeId].aggression >= 0)
            // Dispara hacia el jugador

            shoot(x, y,
              fget_angle(x, y, playerShipId.x, playerShipId.y) + _dispersionAngle ,
              enemyType[typeId].shootTypeId, MOVREL_NONE, true);
          else
            // Dispara recto
            shoot(x, y, 270000 + _dispersionAngle,
              enemyType[typeId].shootTypeId, MOVREL_NONE, true);

            if (shootData[_shootId].disperseType <> DIS_FOLLOW_Y_FATHER)
              shoot(x, y, 270000 + _dispersionAngle , _shootId, MOVREL_NONE, true);
            else
              shoot(x, y, 270000 + _dispersionAngle , _shootId,
                MOVREL_SYNC_X || MOVREL_REL_Y, true);
            end

          end
        end
      end
    end

    ticksCounter++;
    frame;
  end;
  father.remaningChildrens--;
end

