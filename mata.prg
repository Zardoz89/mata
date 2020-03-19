COMPILER_OPTIONS _case_sensitive;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// https://divcompo.now.sh
// ****************************************************************************

program mata;

import "zardoz/mata/csvdll/csv.dll";

const
  DEBUG_MODE=1; // Modo debug. Activa la salida rapida, etc.

  // cte. para las rutas
  PATH_USER="zardoz";
  PATH_PROG="mata";

  BLACK_COLOR_PAL_INDEX = 196; // Indice del color negro en la paleta

  // Cte. referetnes a la regi¢n de juego
  PLAYFIELD_RESOLUTION=10; // Valor de resolution en la zona de juego

  PLAYFIELD_REGION=1; // Region de la zona de juego
  PLAYFIELD_REGION_W=492;
  PLAYFIELD_REGION_H=480;//448;

  PLAYFIELD_MARGIN=17000;
  // TODO Retocar el tama¤o del playfield para poder hace spawn de enemigos fuera del area visible
  PLAYFIELD_XMIN = 0 - PLAYFIELD_MARGIN;
  PLAYFIELD_XMAX = 6000 + PLAYFIELD_MARGIN;
  PLAYFIELD_YMIN = - PLAYFIELD_MARGIN;
  PLAYFIELD_YMAX = 4480 + PLAYFIELD_MARGIN;

  // Cte. referentes al tilemap
  TILE_WIDTH=24;
  TILE_HEIGHT=28;

  // Cte. referentes a la region con el estado del jugador
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

  // Cte. valores que afectan al jugador
  PLAYER_MAX_HULL = 200;
  PLAYER_MAX_SHIELD = 200;
  PLAYER_MAX_ENERGY = 200;
  PLAYER_SPEED = 30;
  SHIELD_REGENERATION_RATE = 5;  // Cuanto regenera el escudo
  INTIAL_GENERATOR_RATE = 5; // Cuanto regenera la energia

  // **** Enumerados **********************************************************
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

  // **** Comandos
  CMD_END_LEVEL        = 0;
  CMD_SPAWN_ENEMY      = 1;
  CMD_SPAWN_ENEMY_SCR  = 2;
  CMD_WAIT_TICKS       = 3;

global
  // **** Libreria de graficos
  int fpgTileset;
  int fpgPlayer;
  int fpgShoots;
  int fpgEnemy;
  int fpgHud;
  int fpgExplosion;

  // **** Fuentes
  int fntScore;
  int fntGameover;

  // **** Efectos de sonido
  struct snd
    explosion;
    bigExplosion;
    pickUp;
    eShoot;
    vulcan;
    laser;
  end

  // **** Definicion de un "nivel"
  struct level
    int numberOfGroups;
    int tileMapColumns;
    int tileMapRows;
  end

  // **** Grupos en un "nivel"
  struct groups[64]
    int x0; int y0; // Posicion inicial del grupo
    int formationType; // Tipo de formacion asignada. -1 es no moverse respecto al scroll.
    int spawnTime; // Tiempo en ticks de cuando hace spawn este grupo
    int bonusType; // Id del tipo de bonus a dar si se destruye toda la oleada. -1 no tiene bonus
    int enemyType[6]; // -1 no hay enemigo
    int pathId[6]; // -1 esta fijo respecto al scroll de fondo
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
    int damage; // Da¤o del disparo
    int energy; // Energia consumida (solo jugador)
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
      int ticks; // N§ de ticks que dura este paso
    end
  end

  // **** Tipos de enemigos del juego
  struct enemyType[10]
    int hull; // Vidia inicial
    int shootTypeId; // Tipo de disparo
    int aggression; // Si es < 0 dispara directamente; > 0 dispara hacia abajo
    // Abs es la frecuencia de disparo -> rand(0, 1000) <= abs(aggresion)
    word score; // Puntos que da al ser destruido
    byte nFrames; // N§ de frames de la animaci¢n
    byte animationType; // 0 al terminar, para; 1 bucle ; 2 avanza-retrocede
    int graphId[10];
  end

  // **** Generales de la partida
  struct player
    int sId; // Id del proceso de la nave del jugador
    int shield;
    int energy;
    int generatorRate = 5;//INTIAL_GENERATOR_RATE;
    int score;
    struct mainWeapon
      int tier = 0;
      int weapon = 0; // Vulcan
    end
    struct secondaryWeapon
      int tier = 0;
      int weapon = -1; // Nada todavia
    end

  end

  // **** Tabla de armas del jugador
  struct playerWeapons[1]
    itemGraph; // Grafico del item que da dicha arma
    weaponId[4];
  end = 109,   2,  3,  4,  5,  6, // Vulcan tier 0 a tier 4
        119,   7,  8,  9, 10, 11; // Laser tier 0 a tier 4

  // **** Definici¢n animaciones de explosiones
  struct exploFx[3]
    int frames;
    int graph[5]; // Id del grafico de explosion
  end = 5,     001, 002, 003, 004, 005, 006,
        5,     007, 008, 009, 010, 011, 012,
        5,     013, 014, 015, 016, 017, 018,
        4,     019, 020, 021, 022, 023, 023;

  // **** Usadas por el scroll de fondo de tilemap
  tileMapGraph; // Buffer del tilemap
  word pointer tiles; // Array dinamico con el tilemap

  // **** Control del scroll
  int tilemapMaxX; // Tama¤o horizonal del tilemap/scroll
  int tilemapMaxY; // Tama¤o vertical del tilemap/scroll
  int scrollY; // El valor y0 del scroll multiplicado por PLAYFIELD_RESOLUTION


local // Las variables locales a los procesos, se definen "universalmente" aqui
  hull; // Vida o puntos de casco de cosos destruibles
  typeId = -1; // Usada en los procesos acceder a los datos de tipo de lo que sea
  ticksCounter = 0; // Contador de ticks (frames)
  xrel = 0; // Posiciones relativas
  yrel = 0;
  remaningChildrens = 0; // Numero de procesos hijos restantes
  killedChildrens = 0; // Numero de procesos hijos matados por el jugador
  groupProcess = 0; // Id del proceso grupo padre de un enemigo

private
  string _loadingMsg;
  _loadingMsgId;

begin
  // **** Configuraci¢n pantalla
  set_mode(m640x480);
  set_fps(60, 0);
  vsync=1;
  rand_seed(1234);

  // **** Carga de paleta
  load_pal(pathResolve("pal\tyrian.pal"));
  set_color(0, 0, 0 ,0); // Hack para que el color transparente sea el negro
  clear_screen();

  _loadingMsg = "Cargando... 0%";
  _loadingMsgId = write(0, 320, 240, 4, _loadingMsg);
  frame();

  // **** Carga de recursos ****
  // Fuentes
  fntScore = load_fnt(pathResolve("fnt\score.fnt"));
  fntGameover = load_fnt(pathResolve("fnt\gameover.fnt"));
  _loadingMsg = "Cargando... 10%";
  frame();

  // Gr ficos
  fpgTileset = load_fpg(pathResolve("fpg\tilemap.fpg"));
  _loadingMsg = "Cargando... 25%";
  frame();

  fpgPlayer = load_fpg(pathResolve("fpg\player.fpg"));
  _loadingMsg = "Cargando... 30%";
  frame();

  fpgShoots = load_fpg(pathResolve("fpg\shoots.fpg"));
  _loadingMsg = "Cargando... 40%";
  frame();

  fpgEnemy = load_fpg(pathResolve("fpg\enemy.fpg"));
  _loadingMsg = "Cargando... 50%";
  frame();

  fpgExplosion = load_fpg(pathResolve("fpg\explo.fpg"));
  _loadingMsg = "Cargando... 55%";
  frame();

  fpgHud = load_fpg(pathResolve("fpg\hud.fpg"));
  _loadingMsg = "Cargando... 60%";
  frame();

  // Carga tipos de disparo
  loadData("dat\shoots", offset shootData, sizeof(shootData));
  _loadingMsg = "Cargando... 65%";
  frame();

  // Carga las formaciones
  loadData("dat\formatio", offset formations, sizeof(formations));
  _loadingMsg = "Cargando... 70%";
  frame();

  // Carga patrones de movimiento
  loadData("dat\movpaths", offset paths, sizeof(paths));
  _loadingMsg = "Cargando... 80%";
  frame();

  // Carga tipo de enemigos
  loadData("dat\enemtype", offset enemyType, sizeof(enemyType));
  _loadingMsg = "Cargando... 90%";
  frame();

  // TODO Carga de FX de sonido
  snd.explosion = load_wav(pathResolve("\snd\bigexpl0.wav"), 0);
  snd.bigExplosion = load_wav(pathResolve("\snd\bigexpl1.wav"), 0);
  //snd.pickUp;
  //snd.eShoot;
  snd.vulcan = load_wav(pathResolve("\snd\vulcan.wav"), 0);
  //snd.laser;
  _loadingMsg = "Cargando... 100%";
  frame();

  // NPI de como va regular el volumen de la m£sica
  //setup.master = 50;
  //setup.sound_fx = 90;
  //setup.cd_audio = 50;
  //set_volume();

  frame(600); // Espera 6 frames -> 1/6 de segundo
  fade_off();
  while(fading)
    frame;
  end
  delete_text(_loadingMsgId);

  // Proceso nivel de juego
  gameLevel("level_01");

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
 * Lee un fichero CSV con datos de juego, rellenando un array de Ints o una estructura
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
 * Lee un fichero CSV con datos de juego, rellenando un array de Words
 */
function loadDataWord(dataFile, _offset, size)
private
  int _retVal = 0;
  string _path;
  string _msg;
begin
  _path = dataFile + ".csv";
  _path = pathResolve(_path);
  // Efectivamente rellena un array de structs
  // La razon es que internamente DIV usa un array gigante para todas las variables
  _retVal = readCSVToWordArray(_path, _offset, size);
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
 * Verifica si un proceso est  dentro del area de juego, que es mas grande que la regi¢n visible
 */
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

function max(val, val2)
begin
  if (val >= val2)
    return(val);
  end
  return(val2);
end

function min(val, val2)
begin
  if (val <= val2)
    return(val);
  end
  return(val2);
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
 * Conversi¢n coordeandas de scroll a pantalla
 */
function scrollXToScreenX(int x)
private
  int _screenX;
begin
  // FIXME Creo que esto esta mal, pero el resultado que da es el correctom, asi que tirando...
  // Regla de tres para convertir el espacio de coordenadas
  _screenX = (x * PLAYFIELD_REGION_W) / tilemapMaxX;
  // Aplicamos el offset
  _screenX = _screenX - (scroll[0].x0 * PLAYFIELD_RESOLUTION);
  return(_screenX);

end
function scrollYToScreenY(int y)
private
  int _screenY;
begin
  // Aplicamos el offset
  _screenY = y - scrollY; // scrollY ya va multiplicado por 10
  // Regla de tres para convertir el espacio de coordenadas
  _screenY = (_screenY * PLAYFIELD_REGION_H  * PLAYFIELD_RESOLUTION ) / tilemapMaxY;
  return(_screenY);
end

/**
 * Conversion coordenadas de pantalla a scroll
 */
function screenXToScrollX(int x)
begin
  // FIXME Creo que esto esta mal, pero el resultado que da es el correctom, asi que tirando...
  return(((x + scroll[0].x0) * tilemapMaxX) / PLAYFIELD_REGION_W );
end
function screenYToScrollY(int y)
private
  int __y;
begin
  // Regla de tes para convetir el espacio de coordenadas
  __y = (y  * tilemapMaxY) / (PLAYFIELD_REGION_H * PLAYFIELD_RESOLUTION);
  // Aplicamos offset
  return(__y + scrollY);
end

/**
 * Proceso que representa un nivel del juego
 */
process gameLevel(levelName)
private
  _actualGroupInd = 0;
  _playerEnergyStatusId; // Id del proceso que muestra y regenera la energia
  _playerShieldStatusId; // Id del proceso que muestra y regenera los escudos
  _levelSong;
  int _commandsArraySize;
  word pointer _commands;
begin
  // Carga de datos del nivel
  loadLevelData(levelName);
  _commands = loadLevelCommands(levelName, offset _commandsArraySize);
  //loadData("lvl\" + levelName + "\enemies", offset groups, sizeof(groups));

  // Cargamos la musica del nivel
  //_levelSong = load_song(pathResolve("\mus\statewar.mod"), 0);

  // Inicializaci¢n de las regiones
  define_region(PLAYFIELD_REGION, 0, 0, PLAYFIELD_REGION_W, PLAYFIELD_REGION_H);
  define_region(STATUS_REGION, STATUS_X, STATUS_Y, STATUS_W, STATUS_H);

  // Pintamos el grafico de fondo de la zona de estado
  xput(fpgHud, 1, PLAYFIELD_REGION_W + 74, 240, 0, 100, 0, STATUS_REGION);

  // Creamos el array dinamico del tilemap y lo leemos de un fichero csv
  tiles = malloc(level.tileMapRows * level.tileMapColumns);
  loadDataWord("lvl\" + levelName + "\tilemap", tiles, level.tileMapRows * level.tileMapColumns);

  // Creamos el buffer del tilemap
  tileMapGraph = createTileBuffer(level.tileMapRows, level.tileMapColumns);

  // Rellenamos el buffer con el tilemap
  drawTiles(tileMapGraph, tiles, level.tileMapColumns, level.tileMapRows, TILE_WIDTH, TILE_HEIGHT);
  free(tiles); // Y liberamos el tilemap

  // Inicializamos el scroll
  start_scroll(0, 0, tileMapGraph, 0, PLAYFIELD_REGION, 0);
  tilemapMaxX = level.tileMapColumns * TILE_WIDTH;
  tilemapMaxY = level.tileMapRows * TILE_HEIGHT;
  scrollY = (tilemapMaxY - PLAYFIELD_REGION_H) * PLAYFIELD_RESOLUTION;
  scroll[0].y0 = scrollY / PLAYFIELD_RESOLUTION;

  // Crear al proceso jugador e inicializamos sus valores
  player.shield = PLAYER_MAX_SHIELD >> 1;
  player.energy = 25;
  player.sId = playerShip(1, 100);
  signal(player.sId, s_sleep); // Dormimos al proceso para que no se pueda mover ni hacer nada

  // Procesos con el estado de casco, escudo y energia
  playerHullStatus();
  _playerShieldStatusId = playerShieldStatus();
  _playerEnergyStatusId = playerEnergyStatus();
  signal(_playerEnergyStatusId, s_sleep); // Dormimos al proceso para que no regenere
  signal(_playerShieldStatusId, s_sleep); // Dormimos al proceso para que no regenere

  // Antes de empezar el bucle y el juego, hacemos un fade
  fade(100, 100, 100, 1);
  while(fading)
    mouse.x = PLAYFIELD_REGION_W >> 1;
    mouse.y = PLAYFIELD_REGION_H >> 1;
    frame;
  end

  // Ponemos la musica
  //song(_levelSong);

  // Centramos el cursor del rat¢n en el centro y forzamos activar la emulaci¢n de rat¢n
  mouse.x = PLAYFIELD_REGION_W >> 1;
  mouse.y = PLAYFIELD_REGION_H >> 1;
  mouse.cursor = 1;

  // Inicializamos el procesador de comandos
  levelCommands(_commands);

  // Y despertamos a los procesos
  signal(player.sId, s_wakeup);
  signal(_playerEnergyStatusId, s_wakeup);
  signal(_playerShieldStatusId, s_wakeup);

  if (DEBUG_MODE == 1)
    debugText();
  end

  // Bucle principal del nivel
  loop
    // Mostramos la puntuaci¢n
    write_int(fntScore, 0, 480, 6, offset player.score);

    // TODO Romper el bucle cuando
    // * El jugador muere -> Replay ?
    // * El jefe muere -> Next level
    if (player.sId.hull <= 0)
      break;
    end

    // En modo debug, mostramos el contador de ticks
    if (DEBUG_MODE == 1)
      write_int(0, 640, 35, 5, offset ticksCounter);
      write_int(0, 590, 35, 5, offset _actualGroupInd);
    end

    // **** Crea los grupos de naves segun ha pasdo una delta de tiempo
    /*
    if (_actualGroupInd < level.numberOfGroups)
      if (ticksCounter >= groups[_actualGroupInd].spawnTime)
        ticksCounter -= groups[_actualGroupInd].spawnTime;

        enemyGroup(_actualGroupInd);
        _actualGroupInd++;
      end
    end
    */

    // Actualizamos el eje Y del scroll
    scrollY = scrollY - 5; // TODO La velocidad de scroll deberia de ser variable
    // Hacemos la multiplicacion/division para poder trabajar a una velocidad inferior a 1 pixel por frame
    scroll[0].y0 = scrollY / PLAYFIELD_RESOLUTION;


    ticksCounter++;
    frame;
  end

  signal(_playerEnergyStatusId, s_sleep); // Dormimos al proceso para que no regenere
  signal(_playerShieldStatusId, s_sleep); // Dormimos al proceso para que no regenere

  // El jugador muri¢. Se muestra la pantalla de game over
  if (player.sId.hull <= 0)
    gameOverScreen();
  end

  // Fade off
  fade_off();
  while(fading)
    frame;
  end

  stop_song();
  unload_song(_levelSong);
  unload_map(tileMapGraph); // Liberamos el graph

  if (_commands != 0)
    free(_commands);
  end

  signal(id, s_kill_tree); // Matamos cualquier proceso descendiente del nivel
end

/**
 * Lee el fichero con los datos de nivel
 */
function loadLevelData(string levelName)
begin
   return(loadData("lvl\" + levelName + "\level", offset level, sizeof(level)));
end

/**
 * Lee los comandos de un fichero de datos binario
 */
function loadLevelCommands(string levelName, int pointer arraySize)
private
  string _path;
  _file;
  word pointer _commands;
begin
  *arraySize = 0;
  _path = "lvl\" + levelName + "\commands.dat";
  _path = pathResolve(_path);
  _file = fopen(_path, "r");
  if (_file == 0)
    return(0);
  end

  fseek(_file, 0, seek_end);
  *arraySize = ftell(_file);
  fclose(_file);
  if (*arraySize <= 0)
    return(0);
  end

  _commands = malloc(*arraySize); // TODO verificar que no devuelve 0 por out of memory
  load(_path, _commands);
  return(_commands);
end

/**
 * Procesa el 'wordcode' y ejecuta los comandos
 */
process levelCommands(word pointer commands)
private
  _finished = false;
  _waitTicks = 0;
  _waitScrollY = 0;
  int _pc = 0;
  word _val, _arg0, _arg1, _arg2, _arg3;
begin
  while (!_finished)
    _val = commands[_pc];

    switch (_val)
      case CMD_END_LEVEL:
        _finished = 1;
      end

      case CMD_SPAWN_ENEMY:
        debug;
        // 4 argumentos
        _arg0 = commands[++_pc];
        _arg1 = commands[++_pc];
        _arg2 = commands[++_pc];
        _arg3 = commands[++_pc];

        enemy(_arg0, _arg1, _arg2, _arg3, 0);
        ticksCounter = 0;
      end

      case CMD_WAIT_TICKS:
        _arg0 = commands[++_pc];
        ticksCounter = 0;
        _waitTicks = _arg0; // Inicializamos el contador de ticks
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

    _pc++;
  end
end;

/**
 * Proceso que muestra informacion de debug como los FPS
 */
process debugText()
private
  string _msgFps;
  string _msgScrollXY;
  string _msgPlayerXY;
  string _msgMWeapon;
begin
  loop
    _msgFps = "FPS: " + itoa(fps);
    write(0, 640, 0, 2, _msgFps);

    _msgScrollXY = "scrollX: " + itoa(scroll[0].x0) + " scrollY: " + itoa(scroll[0].y0);
    write(0, 640, 15, 5, _msgScrollXY);

    _msgPlayerXY = "x: " + itoa(player.sId.x) + " y: " + itoa(player.sId.y);
    write(0, 640, 25, 5, _msgPlayerXY);

    _msgMWeapon = "w: " + itoa(player.mainWeapon.weapon) + " t: " + itoa(player.mainWeapon.tier);
    write(0, 640, 45, 5, _msgMWeapon);


    frame(3000); // Actualiza a 2 FPS
  end
end

/**
 * Crea el buffer de tilemap
 */
function createTileBuffer(rows, columns)
private
  bufferWidth;
  bufferHeight;
  buffer;
begin
  bufferWidth = TILE_WIDTH * columns;
  bufferHeight = TILE_HEIGHT * rows;
  buffer = new_map(bufferWidth, bufferHeight,
    bufferWidth >> 1, bufferHeight >> 1,
    BLACK_COLOR_PAL_INDEX); // Color negro
  return(buffer);
end

/**
 * Pinta un tilemap grande en un buffer
 */
function drawTiles(buffer, word pointer tilesPtr, mapColumns, mapRows, tileWidth, tileHeight)
private
  tileIndex;
  tileMap; // Grafico del tilemap a pintar
  halfTileWidth; // Centro X del tilemap
  halfTileHeight; // Centro Y del tilemap
  putY; // Temporal para sacar calculo de Y en el buffer al pintar, del bucle mas interior
begin
  halfTileWidth = tileWidth >> 1;
  halfTileHeight = tileHeight >> 1;

  for (y = 0; y < mapRows; y++)
    putY = (y * tileHeight) + halfTileHeight;
    for (x = 0; x < mapColumns; x++)
      tileIndex = mapColumns * y + x;
      tileMap = tilesPtr[tileIndex];
      tileMap = max(tileMap, 1);
      map_put(0, buffer, tileMap,
        (x * tileWidth) + halfTileWidth,
        putY);
    end
  end
end

/**
 * Nave del juegador
 */
process playerShip(graph, hull)
private
  _mainShootCounter = 0; // Utilizamos para meter retardos entre los disparos
  _dispersionAngle = 0;
  _hitId;
  _collisionAngle;
  _mainWeaponId;
  _secondaryWeaponId;
begin
  // Asignacion grafico
  file = fpgPlayer;
  graph = graph;
  region = PLAYFIELD_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  z = min_int + 3;

  // Inicializaci¢n posici¢n y scroll
  x = mouse.x * PLAYFIELD_RESOLUTION;
  y = mouse.y * PLAYFIELD_RESOLUTION;
  // scrollX en funcion de X (regla de tres)
  scroll[0].x0 = x * (tilemapMaxX - PLAYFIELD_REGION_W) / (PLAYFIELD_REGION_W * PLAYFIELD_RESOLUTION);

  while(hull > 0)

    // Movimiento
    mouse.x = clamp(mouse.x ,
        0 /* - (ancho_sprite >> 1) */,
        PLAYFIELD_REGION_W /* - ancho_sprite >> 1 */);
    mouse.y = clamp(mouse.y,
        0,
        PLAYFIELD_REGION_H);
    x = mouse.x * PLAYFIELD_RESOLUTION;
    y = mouse.y * PLAYFIELD_RESOLUTION;
    // scrollX en funcion de X (regla de tres)
    scroll[0].x0 = x * (tilemapMaxX - PLAYFIELD_REGION_W) / (PLAYFIELD_REGION_W * PLAYFIELD_RESOLUTION);

    // Colision con naves enemigas
    _hitId = collision(type enemy);
    if (_hitId)
      damagePlayer(1);
      // Hacemos que le cueste penetrar mas en el enemigo
      _collisionAngle = get_angle(_hitId);
      mouse.x -= cos(_collisionAngle) / 500;
      mouse.x -= sin(_collisionAngle) / 500;

    end

    _mainWeaponId = getMainWeaponIdFromPlayerWeapon();

    // Disparo arma principal
    if (key(_control) || mouse.left)
      // Si ha pasado suficiente delay...
      if (_mainShootCounter >= shootData[_mainWeaponId].delay)
        // Si tenemos suficiente energia...
        if (player.energy > shootData[_mainWeaponId].energy )
          // Consumismos energia
          player.energy = clamp(player.energy - shootData[_mainWeaponId].energy, 0, PLAYER_MAX_ENERGY);
          _mainShootCounter = 0;

          // Calculo dispersi¢n del disparo si aplica
          _dispersionAngle = calcDispersionAngle(shootData[_mainWeaponId].disperseValue,
            shootData[_mainWeaponId].disperseType, ticksCounter);
          if (shootData[_mainWeaponId].disperseType <> DIS_FOLLOW_Y_FATHER)
            shoot(x, y, 90000 + _dispersionAngle , _mainWeaponId, MOVREL_NONE, false);
          else
            shoot(x, y, 90000 + _dispersionAngle , _mainWeaponId,
              MOVREL_SYNC_X || MOVREL_REL_Y, false);
          end

          // Y metemos el FX de sonido
          sound(snd.vulcan, 256, 256);
        end
      end
    end

    _mainShootCounter++;
    ticksCounter++;
    frame;
  end

end

/**
 * Funci¢n auxiliar que aplica da¤o a la nave del jugador
 */
function damagePlayer(damage)
private
begin
  player.shield -= damage;
  if (player.shield < 0)
    player.sId.hull += player.shield;
    player.shield = 0;
  else
    shieldFx(); // Hacemos el efecto del escudo
  end
end

/**
 * Proceso que muestra el efecto de escudos de la nave del jugador
 */
process shieldFx()
private
  int i;
begin
  file = fpgPlayer;
  region = PLAYFIELD_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  flags = 4; // Transparencia
  graph = 6;
  z = min_int + 2;

  for (i = 0; i <= 4; i++)
    x = player.sId.x;
    y = player.sId.y;
    frame;
  end
end

/**
 * Devuelve el ID de la tabla de armas a partir del arma actual del jugador
 */
function getMainWeaponIdFromPlayerWeapon()
begin
  return(playerWeapons[player.mainWeapon.weapon].weaponId[player.mainWeapon.tier]);
end

/**
 * Devuelve el ID de la tabla de armas a partir del arma secundartia actual del jugador
 */
function getSecundaryWeaponIdFromPlayerWeapon()
begin
  if (player.secondaryWeapon.weapon == -1)
    return(-1);
  end
  return(playerWeapons[player.secondaryWeapon.weapon].weaponId[player.secondaryWeapon.tier]);
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
      _dispersionAngle = (weaponDispersionAngle / 1000) * sin(ticks * DIS_TICKS_SIN_MULTIPLIER);
    end
    default:
      _dispersionAngle = 0;
    end
  end
  return (_dispersionAngle);
end

/**
 * Proceso que representa un disparo
 *
 * Parametros:
 * x
 * y
 * direction Angulo de movimiento
 * typeId Tipo de disparo
 * moveRelativeToFather Cte. que indica el tipo de movimiento relativo
 * enemyShoot True si es disparado por un enemigo
 */
process shoot(x, y, direction, typeId, moveRelativeToFather, enemyShoot)
private
  hitId;
  tmpScore;
  tmpK;
  tmpR;
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
        explosion(3, x, y); // Mini explosion por impacto

        damagePlayer(shootData[typeId].damage);
        break;
      end

    else
      // Colision con un enemigo
      hitId = collision(type enemy);
      if (hitId)
        if (hitId.hull > 0) // Evitamos que se cuente multiples veces la muerte
          // Da¤amos al enemigo
          hitId.hull = hitId.hull - shootData[typeId].damage;
          if (hitId.hull <= 0) // Si se queda sin vida, contamos la muerte y aumentamos la puntuaci¢n
            player.score += enemyType[hitId.typeId].score;
            if (hitId.groupProcess)
              hitId.groupProcess.killedChildrens++;
              hitId.groupProcess.remaningChildrens--;
              // Asignamos X e Y para que el grupo de enemigos pueda dropear el bonus en donde muere el ultimo miembro del grupo
              hitId.groupProcess.x = x;
              hitId.groupProcess.xrel = hitId.xrel;
              hitId.groupProcess.y = y;
              hitId.groupProcess.yrel = hitId.yrel;
            end
            explosion(rand(0, 2), x, y); // Efecto de explosion
          else
            explosion(3, x, y); // Mini explosion por impacto
          end
        end
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
 * Proceso de efecto de explosion
 *
 * Usa una tabla global para saber los Ids de la explosi¢n
 */
process explosion(explosionId, x, y)
private
  int i;
  int _totalFrames;
begin
  file = fpgExplosion;
  region = PLAYFIELD_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  flags = 4; // Transparencia
  z = min_int + 1;
  _totalFrames = exploFx[explosionId].frames;

  for (i = 0; i <= _totalFrames; i++)
    graph = exploFx[explosionId].graph[i];
    frame(200); // Actualiza a 30fps
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
    clampHull = clamp(player.sId.hull, 0, PLAYER_MAX_HULL);
    regionY = STATUS_HULL_BAR_Y - 100 + 200 - clampHull ;
    define_region(STATUS_HULL_BAR_REGION,
      STATUS_HULL_BAR_X - 6,
      regionY,
      12, clampHull);
    frame(200);
  end
end

/**
 * Proceso que muestra el estado del escudo del jugador y los regenera
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
    clampShield = clamp(player.shield, 0, PLAYER_MAX_SHIELD);
    regionY = STATUS_HULL_BAR_Y - 100 + 200 - clampShield;
    define_region(STATUS_SHIELD_BAR_REGION,
      STATUS_SHIELD_BAR_X - 6,
      regionY,
      12, clampShield);

    // Regeneraci¢n escudos
    if (player.energy > 30 && ticksCounter > 30)
      player.shield = clamp(player.shield + SHIELD_REGENERATION_RATE, 0, PLAYER_MAX_SHIELD);
      player.energy -= (SHIELD_REGENERATION_RATE >> 1);
      ticksCounter = 0;
    end

    ticksCounter++;
    frame;
  end
end

/**
 * Proceso que muestra la energia del jugador y la regenera
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
    clampEnergy = clamp(player.energy, 0, PLAYER_MAX_ENERGY);
    regionY = STATUS_ENERGY_BAR_Y - 100 + 200 - clampEnergy;
    define_region(STATUS_ENERGY_BAR_REGION,
      STATUS_ENERGY_BAR_X - 6,
      regionY,
      12, clampEnergy);

    // Regeneraci¢n energia
    if (ticksCounter > 4)
      player.energy = clamp(player.energy + player.generatorRate, 0, PLAYER_MAX_ENERGY);
      ticksCounter = 0;
    end

    ticksCounter++;
    frame;
  end
end

/**
 * Crea a un grupo de enemigos y gestiona el spawn del bonus si es necesario
 */
process enemyGroup(groupInd)
private
 i;
 _formationType;
 _enemyType;
 _totalChildrens = 0;
begin
  _formationType = groups[groupInd].formationType;

  for (i=0; i <= 6; i++)
    _enemyType = groups[groupInd].enemyType[i];
    if (_enemyType <> -1)
      enemy(
        groups[groupInd].x0 + formations[_formationType].startPosition[i].x,
        groups[groupInd].y0 + formations[_formationType].startPosition[i].y,
        groups[groupInd].pathId[i],
        _enemyType,
        id);
      remaningChildrens++;
    end
  end
  _totalChildrens = remaningChildrens;
  loop
    if (remaningChildrens <= 0)
      if (killedChildrens == _totalChildrens && groups[groupInd].bonusType <> -1)
        // TODO Hacer espan de diferente tipos de bonus
        mainWeaponBonus(groups[groupInd].bonusType, x ,y, xrel);
      end
      break;
    end

    frame;
  end
end

/**
 * Nave o bicho enemigo
 * Parametros:
 * x0 : Coordenadas de tilemap
 * y0 : Coordenadas de tilemap
 * pathId : Patron de movimiento
 * typeId : Tipo de enemigo
 * groupProcess : Id del proceso grupo asociados a este enemigo
 */
process enemy(x0, y0, pathId, typeId, groupProcess)
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

  xrel = x0;
  yrel = y0;
  x = scrollXToScreenX(xrel); //xrel - (scroll[0].x0 * PLAYFIELD_RESOLUTION);
  y = scrollYToScreenY(yrel); //yrel;


  // Aplicamos la velocidad inicial si hay un patron de mov.
  if (pathId <> -1)
    _vx = paths[pathId].vx0;
    _vy = paths[pathId].vy0;
  end;

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
    xrel += _vx;
    yrel += _vy;
    // El movimiento horizontal es respecto al scroll de fondo
    x = scrollXToScreenX(xrel); //xrel - (scroll[0].x0 * PLAYFIELD_RESOLUTION);
    y = scrollYToScreenY(yrel); //yrel;

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
              fget_angle(x, y, player.sId.x, player.sId.y) + _dispersionAngle ,
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

  // Evitamos contar dos veces una muerte
  if (hull > 0 && groupProcess)
    groupProcess.remaningChildrens--;
  end
end

/**
 * Item bonus que cambia/mejora el arma del jugador
 */
process mainWeaponBonus(playerWeaponId, x, y, xrel)
private
begin
  file = fpgShoots;
  region = PLAYFIELD_REGION;
  resolution = PLAYFIELD_RESOLUTION;
  graph = playerWeapons[playerWeaponId];

  while (! isOutsidePlayfield(x, y))
    x = xrel - (scroll[0].x0 * PLAYFIELD_RESOLUTION);


    if (collision(type playerShip))
      // El jugador ha recogido el item. Mejoramos o cambiamos el arma
      if (player.mainWeapon.weapon == playerWeaponId)
        // Aumentamos el tier
        player.mainWeapon.tier = min(player.mainWeapon + 1, 4);
      else
        // Cambiamos el arma
        player.mainWeapon.weapon = playerWeaponId;
      end
      break;
    end
    frame;
  end;
end;

/**
 * Muestra el rotulo de game over
 * TODO Mostrar si el jugador desea volver a jugar el mapa o volver al men£. Retornar valor seg£n la opci¢n.
 */
function gameOverScreen()
private
  _gameoverId;
begin
  _gameoverId = write(fntGameover, 320, 240, 4, "GAME OVER");
  frame(6000); // Esperamos ~1 segundo
  loop
    if (key(_enter) || key(_esc) || mouse.left)
      break;
    end;
    frame;
  end
  delete_text(_gameoverId);
  return(false);
end


/* vim: set ts=2 sw=2 tw=0 et fileencoding=cp858 :*/
