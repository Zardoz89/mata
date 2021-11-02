COMPILER_OPTIONS _case_sensitive, _extended_conditions, _use_cstyle;
// ****************************************************************************
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// Código para la carga y gestión de niveles
// ****************************************************************************

include "src/levelCommands.prg";

global

  // **** Definicion de un "nivel"
  struct level
    int32 tileMapColumns;
    int32 tileMapRows;
  end


/**
 * Proceso que representa un nivel del juego
 */
process gameLevel(levelName)
private
  _playerEnergyStatusId; // Id del proceso que muestra y regenera la energia
  _playerShieldStatusId; // Id del proceso que muestra y regenera los escudos
  _levelSong;
  int16* _commands;
begin
  // Carga de datos del nivel
  loadLevelData(levelName);
  _commands = loadLevelCommands(levelName);

  // Cargamos la musica del nivel
  _levelSong = song_load(pathResolve("mus/statewar.mod"));

  // Inicialización de las regiones
  define_region(PLAYFIELD_REGION, 0, 0, PLAYFIELD_REGION_W, PLAYFIELD_REGION_H);
  define_region(STATUS_REGION, STATUS_X, STATUS_Y, STATUS_W, STATUS_H);

  // Pintamos el grafico de fondo de la zona de estado
  xput(fpgHud, 1, PLAYFIELD_REGION_W + 74, 240, 0, 100, 0, STATUS_REGION);

  // Creamos el array dinamico del tilemap y lo leemos de un fichero csv
  tiles = malloc(level.tileMapRows * level.tileMapColumns);
  loadData("lvl/" + levelName + "/tilemap", tiles, level.tileMapRows * level.tileMapColumns);

  // Creamos el buffer del tilemap
  tileMapGraph = createTileBuffer(level.tileMapRows, level.tileMapColumns, TILE_WIDTH, TILE_HEIGHT, BLACK_COLOR_PAL_INDEX);

  // Rellenamos el buffer con el tilemap
  drawTiles(tileMapGraph, tiles, level.tileMapColumns, level.tileMapRows, TILE_WIDTH, TILE_HEIGHT);
  free(tiles); // Y liberamos el tilemap

  // Inicializamos el scroll
  scrollStepY = 0;
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
  //song_play(_levelSong);

  // Centramos el cursor del ratón en el centro y forzamos activar la emulación de ratón
  mouse.x = PLAYFIELD_REGION_W >> 1;
  mouse.y = PLAYFIELD_REGION_H >> 1;
  mouse.cursor = 1;

  // // Inicializamos el procesador de comandos
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
    // Mostramos la puntuación
    write_int(fntScore, 0, 480, 6, offset player.score);

    // TODO Romper el bucle cuando
    // * El jugador muere -> Replay ?
    // * El nivel termina (comando endLevel) -> Intermission
    if (player.sId.hull <= 0)
      break;
    end

    // Actualizamos el eje Y del scroll
    if (scrollY > 0) // AND < tamaño maximo
      scrollY = scrollY + scrollStepY; // - 5
    end
    // Hacemos la multiplicacion/division para poder trabajar a una velocidad inferior a 1 pixel por frame
    scroll[0].y0 = scrollY / PLAYFIELD_RESOLUTION;


    frame;
  end

  signal(_playerEnergyStatusId, s_sleep); // Dormimos al proceso para que no regenere
  signal(_playerShieldStatusId, s_sleep); // Dormimos al proceso para que no regenere

  /*
  // El jugador murió. Se muestra la pantalla de game over
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
  */
  unload_map(tileMapGraph); // Liberamos el graph

  if (_commands != 0)
    memory_delete(_commands);
  end
  signal(id, s_kill_tree); // Matamos cualquier proceso descendiente del nivel
end

/**
 * Lee el fichero con los datos de nivel
 */
function loadLevelData(string levelName)
private
  int32* tmpArray;
  int ret;
begin
  tmpArray = memory_new(4 * sizeof(int32));
  ret = loadData("lvl/" + levelName + "/level",  tmpArray, 4 * sizeof(int32));
  level.tileMapColumns = tmpArray[0];
  level.tileMapRows = tmpArray[1];
  memory_delete(tmpArray);
  return(ret);
end


/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1  :*/
