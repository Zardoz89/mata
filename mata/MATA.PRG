COMPILER_OPTIONS _case_sensitive;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// https://divcompo.now.sh
// ****************************************************************************

program mata;

import "csv.dll";

const
  DEBUG_MODE=1; // Modo debug. Activa la salida rapida, etc.

  // cte. para las rutas
  PATH_USER="zardoz";
  PATH_PROG="mata";

  PLAYFIELD_RESOLUTION=10; // Valor de resolution en la zona de juego

  PLAYFIELD_REGION=1; // Region de la zona de juego
  PLAYFIELD_REGION_W=492;
  PLAYFIELD_REGION_H=480;

  PLAYFIELD_MARGIN=17000;
  // TODO Retocar el tama¤o del playfield para poder hace spawn de enemigos fuera del area visible
  PLAYFIELD_XMIN = 0 - PLAYFIELD_MARGIN;
  PLAYFIELD_XMAX = 4920 + PLAYFIELD_MARGIN;
  PLAYFIELD_YMIN = - PLAYFIELD_MARGIN;
  PLAYFIELD_YMAX = 4800 + PLAYFIELD_MARGIN;

  TILE_WIDTH=24;
  TILE_HEIGHT=28;
  TILEMAP_COLUMNS=25;
  TILEMAP_ROWS=26; // TODO Valor temporal, tiene que venir determinado del CSV de nivel
  TILEMAP_MAX_X= 600; // TILEMAP_COLUMNS * TILEMAP_WIDTH - playfield_region_w;
  TILEMAP_MAX_Y= 768; // TILEMAP_ROWS * TILEMAP_HEIGHT;

  STATUS_REGION=2; // Region de la zona con el estado del jugador
  STATUS_X=640-148; // = 492
  STATUS_Y=0;
  STATUS_W=148;
  STATUS_H=480;

  STATUS_HULL_BAR_REGION = 3;
  STATUS_HULL_BAR_X = PLAYFIELD_REGION_W + 22 + 6;
  STATUS_HULL_BAR_Y = 250 - 100; // Parte inf. - la mitad de la altura de la imagen

  STATUS_SHIELD_BAR_REGION = 4;
  STATUS_SHIELD_BAR_X = PLAYFIELD_REGION_W + 70 + 6;
  STATUS_SHIELD_BAR_Y = 250 - 100; // Parte inf. - la mitad de la altura de la imagen

  STATUS_ENERGY_BAR_REGION = 5;
  STATUS_ENERGY_BAR_X = PLAYFIELD_REGION_W + 118 + 6;
  STATUS_ENERGY_BAR_Y = 250 - 100; // Parte inf. - la mitad de la altura de la imagen



  PLAYER_MAX_HULL = 200;
  PLAYER_MAX_SHIELD = 200;
  PLAYER_MAX_ENERGY = 200;
  SHIELD_REGENERATION_RATE = 5;  // Cuanto regenera el escudo
  GENERATOR_RATE = 5; // Cuanto regenera la energia



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
  int fpgTileset;
  int fpgPlayer;
  int fpgShoots;
  int fpgEnemy;
  int fpgHud;
  int fpgBack;

  // **** Definicion de un "nivel"
  struct level
    int tileMapId; // Id del tilemap que se va usar para el fondo
    int bossId;
    int bossSpawnTime;
    int numberOfGroups;
    struct groups[64]
      int x0; int y0; // Posicion inicial del grupo
      int formationType; // Tipo de formacion asignada. -1 es no moverse respecto al scroll.
      int spawnTime; // Tiempo en ticks de cuando hace spawn este grupo
      int bonusType; // Id del tipo de bonus a dar si se destruye toda la oleada. -1 no tiene bonus
      int enemyType[6]; // -1 no hay enemigo
      int pathId[6]; // -1 esta fijo respecto al scroll de fondo
      //byte _destroyed = 0; // Indicador si el grupo ha sido destruido
      //byte _bonusFlag:
    end
  end

  // **** Formaciones de naves enemigas
  struct formations[13]
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
  struct paths[40]
    byte maxSteps; // N§ de pasos
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
  int playerShipShield;
  int playerShipEnergy;
  int score = 0;

  // **** Usadas por el scroll de fondo de tilemap
  int scrollX;
  int scrollY;
  tileMapGraph; // Buffer del tilemap

  // Array temporal
  int tiles[TILEMAP_ROWS, TILEMAP_COLUMNS] =
  // 0    1    2    3    4    5    6    7     8    9   10   11   12   13   14   15    16   17   18   19   20   21   22   23   24
    16,  16,   2,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 0
    16,  16,   2,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 1
     4,   4,   9,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 2
    13,  13,  13,  13,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 3
    13,  13,  13,  21,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 4
    13,  13,  21,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 5
    13,  21,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  20,  13,  13, // 6
    20,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 7
    20,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  20,  21, // 8
    // 9 * 25 =225
    21,  13,  13,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 0
    13,  21,  13,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 1
    13,  13,  21,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 2
    13,  13,  13,  21,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 3
    13,  13,  13,  21,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 4
    13,  13,  21,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 5
    13,  21,  13,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  20,  13,  13, // 6
    21,  13,  13,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 7
    13,  13,  13,  13,  13,  13,  13,  13,   21,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  20,  21, // 8

    21,  13,  13,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 0
    13,  21,  13,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 1
    13,  13,  21,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 2
    13,  13,  13,  21,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 3
    13,  13,  13,  21,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 4
    13,  13,  21,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 5
    13,  21,  13,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  20,  13,  13, // 6
    21,  13,  13,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 7
    13,  13,  13,  13,  13,  13,  13,  13,   21,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  20,  21; // 8



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
  fpgTileset = load_fpg(pathResolve("fpg\tilemap.fpg"));
  fpgPlayer = load_fpg(pathResolve("fpg\player.fpg"));
  fpgShoots = load_fpg(pathResolve("fpg\shoots.fpg"));
  fpgEnemy = load_fpg(pathResolve("fpg\enemy.fpg"));
  fpgBack = load_fpg(pathResolve("fpg\back.fpg"));
  fpgHud = load_fpg(pathResolve("fpg\hud.fpg"));

  // Carga tipos de disparo
  loadData("dat\shoots", offset shootData, sizeof(shootData));
  // Carga las formaciones
  loadData("dat\formatio", offset formations, sizeof(formations));
  // Carga patrones de movimiento
  loadData("dat\movpaths", offset paths, sizeof(paths));
  // Carga tipo de enemigos
  loadData("dat\enemtype", offset enemyType, sizeof(enemyType));

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
 * Lee un fichero CSV con datos de juego
 */
function loadData(dataFile, _offset, size)
private
  int _retVal = 0;
  string _path;
  string _msg;
begin
  _path = dataFile + ".csv";
  _path = pathResolve(_path);
  // Efectivamente rellena un array de structs
  // La razon es que internamente DIV usa un array gigante para todas las variables
  _retVal = readCSVToIntArray(_path, _offset, size);
  if (_retVal <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
    loop
      // abortamos ejecuci¢n
      if (key(_q) || key(_esc))
        let_me_alone();
        break;
      end

      frame;
    end
  end
  return(_retVal);
end

/**
 * Lee el fichero con los datos de nivel
 */
function loadLevelData(string levelName)
private
begin
   return(loadData("lvl\" + levelName, offset level, sizeof(level)));
end;

function isOutsidePlayfield(x, y)
begin
  if (x < PLAYFIELD_XMIN || x > PLAYFIELD_XMAX)
    return(true);
  end
  if (y < PLAYFIELD_YMIN || y > PLAYFIELD_YMAX)
    return(true);
  end
  return(false);
end;

function max(val, maxVal)
begin
  if (val > maxVal)
    return(maxVal);
  end
  return(val);
end

function clamp(val, minVal, maxVal)
begin
  if (val > maxVal)
    return(maxVal);
  end
  if (val < minVal)
    return(minVal);
  end
  return(val);
end


/**
 * Proceso que representa un nivel del juego
 */
process gameLevel()
private
 _destroyedAll = false;
 _actualGroupInd = 0;
begin
  // Inicializaci¢n de las regiones
  define_region(PLAYFIELD_REGION, 0, 0, PLAYFIELD_REGION_W, PLAYFIELD_REGION_H);
  define_region(STATUS_REGION, STATUS_X, STATUS_Y, STATUS_W, STATUS_H);
  xput(fpgHud, 1, PLAYFIELD_REGION_W + 74, 240, 0, 100, 0, STATUS_REGION);

  // Creamos el buffer del tilemap
  tileMapGraph = createTileBuffer(PLAYFIELD_REGION_W, PLAYFIELD_REGION_H);

  // Creamos el proceso de scroll
  backgroundScroll(tileMapGraph, offset tiles);

  // Crear al proceso jugador
  playerShipShield = PLAYER_MAX_SHIELD >> 1;
  playerShipEnergy = 25;
  playerShipId = playerShip(1);
  playerHullStatus();
  playerShieldStatus();
  playerEnergyStatus();

  loop
    // **** Crea los grupos de naves segun ha pasdo una delta de tiempo
    if (_actualGroupInd < level.numberOfGroups)
      if (ticksCounter >= level.groups[_actualGroupInd].spawnTime)
        ticksCounter -= level.groups[_actualGroupInd].spawnTime;

        enemyGroup(_actualGroupInd);
        _actualGroupInd++;
      end
    end

    ticksCounter++;
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
  _formationType = level.groups[groupInd].formationType;

  for (i=0; i <= 6; i++)
    _enemyType = level.groups[groupInd].enemyType[i];
    if (_enemyType <> -1)
      enemy(
        level.groups[groupInd].x0 + formations[_formationType].startPosition[i].x,
        level.groups[groupInd].y0 + formations[_formationType].startPosition[i].y,
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

/**
 * Proceso que muestra el estado del casco del jugador
 */
process playerHullStatus()
private
  int clampHull;
  int regionY;
begin
  region=STATUS_HULL_BAR_REGION;
  x = STATUS_HULL_BAR_X;
  y = STATUS_HULL_BAR_Y;
  file=fpgHud;
  graph=2; // Grafico vida
  loop
    clampHull = clamp(playerShipId.hull, 0, PLAYER_MAX_HULL);
    regionY = STATUS_HULL_BAR_Y - 100 + 200 - clampHull ;
    define_region(STATUS_HULL_BAR_REGION,
      STATUS_HULL_BAR_X - 6,
      regionY,
      12, clampHull);
    frame(200);
  end
end

/**
 * Proceso que muestra el estado del escudo del jugador
 */
process playerShieldStatus()
private
  int clampShield;
  int regionY;
begin
  region=STATUS_SHIELD_BAR_REGION;
  x = STATUS_SHIELD_BAR_X;
  y = STATUS_SHIELD_BAR_Y;
  file=fpgHud;
  graph=3; // Grafico barra escudos
  loop
    clampShield = clamp(playerShipShield, 0, PLAYER_MAX_SHIELD);
    regionY = STATUS_HULL_BAR_Y - 100 + 200 - clampShield;
    define_region(STATUS_SHIELD_BAR_REGION,
      STATUS_SHIELD_BAR_X - 6,
      regionY,
      12, clampShield);

    // Regeneraci¢n escudos
    if (playerShipEnergy > 30 && ticksCounter > 30)
      playerShipShield = clamp(playerShipShield + SHIELD_REGENERATION_RATE, 0, PLAYER_MAX_SHIELD);
      playerShipEnergy -= (SHIELD_REGENERATION_RATE >> 1);
      ticksCounter = 0;
    end

    ticksCounter++;
    frame;
  end
end

/**
 * Proceso que muestra la energia del jugador
 */
process playerEnergyStatus()
private
  int clampEnergy;
  int regionY;
begin
  region=STATUS_ENERGY_BAR_REGION;
  x = STATUS_ENERGY_BAR_X;
  y = STATUS_ENERGY_BAR_Y;
  file=fpgHud;
  graph=4; // Grafico barra escudos
  loop
    clampEnergy = clamp(playerShipEnergy, 0, PLAYER_MAX_ENERGY);
    regionY = STATUS_ENERGY_BAR_Y - 100 + 200 - clampEnergy;
    define_region(STATUS_ENERGY_BAR_REGION,
      STATUS_ENERGY_BAR_X - 6,
      regionY,
      12, clampEnergy);

    // Regeneraci¢n energia
    if (ticksCounter > 4)
      playerShipEnergy = clamp(playerShipEnergy + GENERATOR_RATE, 0, PLAYER_MAX_ENERGY);
      ticksCounter = 0;
    end

    ticksCounter++;
    frame;
  end
end


/**
 * Nave del juegador
 */
process playerShip(graph)
private
  _mainShootCounter = 0; // Utilizamos para meter retardos entre los disparos
  _mainWeapon = 1;
  _dispersionAngle = 0;
begin
  // Asignacion grafico
  file = fpgPlayer;
  graph = graph;
  region = PLAYFIELD_REGION;
  resolution = PLAYFIELD_RESOLUTION;

  hull = 100;

  loop
    if (hull < 0)
      break;
    end;

    // Calcula de nueva posicion
    x = max(mouse.x * PLAYFIELD_RESOLUTION, PLAYFIELD_REGION_W * PLAYFIELD_RESOLUTION);
    y = mouse.y * PLAYFIELD_RESOLUTION;

    if (mouse.left )
      if (_mainShootCounter >= shootData[_mainWeapon].delay)
        if (playerShipEnergy > 2)
          // TODO meter el consumo de energia
          playerShipEnergy = clamp(playerShipEnergy - 2, 0, PLAYER_MAX_ENERGY);

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
    end

    // TODO prueba
    scrollX = x;
    scrollY = y;

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
  region = PLAYFIELD_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  graph = shootData[typeId];
  xrel = 0;
  yrel = 0;

  while (! out_region(id, region))
    if (enemyShoot)
      // Colision con el jugador
      hitId = collision(type playerShip);
      if (hitId)
        playerShipShield -= shootData[typeId].damage;
        if (playerShipShield < 0)
          hitId.hull += playerShipShield;
          playerShipShield = 0;
        end
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
  region = PLAYFIELD_REGION;
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


  //while (! out_region(id, region) && hull > 0)
  while (! isOutsidePlayfield(x, y) && hull > 0)

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

/**
 * Crea el buffer de tilemap
 */
function createTileBuffer(regionWidth, regionHeight)
private
  bufferWidth;
  buffer;
begin

  buffer = new_map(regionWidth, regionHeight,
    0, 0, // regionWidth >> 1, regionHeight >> 1,
    196); // Color negro
  return(buffer);
end

/**
 * Proceso que controla el scroll de fondo en la partida
 * @param graph Buffer del grafico
 * @param tilesPtr Ptr. al array con el tilemap
 */
process backgroundScroll(graph, int pointer tilesPtr)
private
  oldScrollX;
  oldScrollY;
begin
  file = fpgTileset;
  region = PLAYFIELD_REGION;
  z = 512;
  scrollY = TILEMAP_MAX_Y - PLAYFIELD_REGION_H;

  oldScrollX = scrollX;
  oldScrollY = scrollY;

  drawTiles(graph, tilesPtr, TILEMAP_COLUMNS, TILEMAP_ROWS, TILE_WIDTH, TILE_HEIGHT, 0, 0);
  loop
    scrollX = clamp(mouse.x, 0, TILEMAP_MAX_X - PLAYFIELD_REGION_W);
    scrollY = clamp(scrollY - 1, 0, TILEMAP_MAX_Y - PLAYFIELD_REGION_H);
    if (scrollX <> oldScrollX || scrollY <> oldScrollY)
      drawTiles(graph, tilesPtr, TILEMAP_COLUMNS, TILEMAP_ROWS, TILE_WIDTH, TILE_HEIGHT, scrollX, scrollY);
    end
    oldScrollX = scrollX;
    oldScrollY = scrollY;

    frame(200);
  end

end

/**
 * Pinta un tilemap grande en un buffer
 *
 *
 * El funcionamiento es el siguiente, determina las filas y columnas que van a estar dentro del buffer de destino
 * a partir de inputX e inputY como desplazamientos.
 * Recorre el array multidimensional del tileMap, pero solamente las parte visibles y las pinta en el buffer de destino
 */
function drawTiles(buffer, int pointer tilesPtr, mapColumns, mapRows, tileWidth, tileHeight, inputX, inputY)
private
  tileIndex;
  tileMap; // Grafico del tilemap a pintar
  halfTileWidth; // Centro X del tilemap
  halfTileHeight; // Centro Y del tilemap
  x0; // Primera columna que se va a pintar
  y0; // Primera fila que se va a pintar
  xMax; // Ultima columna que se va a pintar
  yMax; // Ultima fila que se va a pintar
  putY; // Temporal para sacar calculo de Y en el buffer al pintar, del bucle mas interior
begin
  y=0; x=0;
  x0 = inputX / tileWidth;
  y0 = inputY / tileHeight;
  xMax = clamp(((inputX + PLAYFIELD_REGION_W) / tileWidth) + 1, 0, mapColumns);
  yMax = clamp(((inputY + PLAYFIELD_REGION_H) / tileHeight) + 1, 0, mapRows);
  halfTileWidth = tileWidth >> 1;
  halfTileHeight = tileHeight >> 1;

  for (y = y0; y <= (mapRows); y++)
    putY = (y * tileHeight) + halfTileHeight - inputY;
    for (x = x0 ; x < xMax; x++)
      tileIndex = mapColumns * y + x;
      tileMap = tilesPtr[tileIndex];
      map_put(0, buffer, tileMap, (x * tileWidth) + halfTileWidth - inputX, putY);
    end
  end
end


