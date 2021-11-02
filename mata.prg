COMPILER_OPTIONS _case_sensitive;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// https://divcompo.now.sh
// ****************************************************************************

program mata;

include "src/aux.prg";
include "src/loadData.prg";
include "src/tilemaps.prg";
include "src/gamelevel.prg";
include "src/player.prg";
include "src/shoots.prg";
include "src/enemy.prg";
include "src/enemyGroups.prg";

const
  DEBUG_MODE=1; // Modo debug. Activa la salida rapida, etc.

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

  // **** Enumerados *******************************************************

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
  // struct snd
  //   explosion;
  //   bigExplosion;
  //   pickUp;
  //   eShoot;
  //   vulcan;
  //   laser;
  // end

  // // **** Definici¢n animaciones de explosiones
  // struct exploFx[3]
  //   int frames;
  //   int graph[5]; // Id del grafico de explosion
  // end = 5,     001, 002, 003, 004, 005, 006,
  //       5,     007, 008, 009, 010, 011, 012,
  //       5,     013, 014, 015, 016, 017, 018,
  //       4,     019, 020, 021, 022, 023, 023;

  // **** Usadas por el scroll de fondo de tilemap
  tileMapGraph; // Buffer del tilemap
  word pointer tiles; // Array dinamico con el tilemap

  // **** Control del scroll
  int tilemapMaxX; // Tama¤o horizonal del tilemap/scroll
  int tilemapMaxY; // Tama¤o vertical del tilemap/scroll
  int scrollY; // El valor y0 del scroll multiplicado por PLAYFIELD_RESOLUTION
  int scrollStepY; // La velocidad del scroll vertical

local // Las variables locales a los procesos, se definen "universalmente" aqui
  hull; // Vida o puntos de casco de cosos destruibles
  typeId = -1; // Usada en los procesos acceder a los datos de tipo de lo que sea
  ticksCounter = 0; // Contador de ticks (frames)
  xrel = 0; // Posiciones relativas
  yrel = 0;

  // Se usa para gestionar los grupos de enemigos
  bonusType = -1;
  totalChildrens = 0; // N£mero inicial de procesos hijos
  remaningChildrens = 0; // N£mero de procesos hijos restantes
  killedChildrens = 0; // N£mero de procesos hijos matados por el jugador
  groupProcess = 0; // Id del proceso grupo padre de un enemigo

private
  string _loadingMsg;
  _loadingMsgId;

begin
  logger_set_target(logger_target_console);

  // **** Configuraci¢n pantalla
  mode_set(640,480, 8);
  set_fps(60, 0);
  vsync=1;
  rand_seed(1234);

  // **** Carga de paleta
  logger_log("Cargando paleta");
  load_pal(pathResolve("pal/tyrian.pal"));
  set_color(0, 0, 0 ,0); // Hack para que el color transparente sea el negro
  clear_screen();

  _loadingMsg = "Cargando... 0%";
  _loadingMsgId = write(0, 320, 240, 4, _loadingMsg);
  frame();

  // **** Carga de recursos ****
  // Fuentes
  logger_log("Cargando fuentes");
  fntScore = load_fnt(pathResolve("fnt/score.fnt"));
  fntGameover = load_fnt(pathResolve("fnt/gameover.fnt"));
  _loadingMsg = "Cargando... 10%";
  frame();

  // Gr ficos
  logger_log("Cargando tilemap.fpg");
  fpgTileset = load_fpg(pathResolve("fpg/TILEMAP.FPG"));
  _loadingMsg = "Cargando... 25%";
  frame();

  logger_log("Cargando player.fpg");
  fpgPlayer = load_fpg(pathResolve("fpg/PLAYER.FPG"));
  _loadingMsg = "Cargando... 30%";
  frame();

  logger_log("Cargando shoots.fpg");
  fpgShoots = load_fpg(pathResolve("fpg/shoots.fpg"));
  _loadingMsg = "Cargando... 40%";
  frame();

  logger_log("Cargando enemy.fpg");
  fpgEnemy = load_fpg(pathResolve("fpg/enemy.fpg"));
  _loadingMsg = "Cargando... 50%";
  frame();

  logger_log("Cargando explo.fpg");
  fpgExplosion = load_fpg(pathResolve("fpg/EXPLO.FPG"));
  _loadingMsg = "Cargando... 55%";
  frame();

  logger_log("Cargando hud.fpg");
  fpgHud = load_fpg(pathResolve("fpg/hud.fpg"));
  _loadingMsg = "Cargando... 60%";
  frame();

  // Carga tipos de disparo
  logger_log("Cargando shoots.csv");
  loadShootsData();
  _loadingMsg = "Cargando... 65%";
  frame();

  // Carga las formaciones
  logger_log("Cargando formatio.csv");
  loadFormations();
  // loadData("dat/formatio", offset formations, sizeof(formations));
   _loadingMsg = "Cargando... 70%";
  frame();

  // Carga patrones de movimiento
  logger_log("Cargando movpaths.csv");
  loadPaths();
  // loadData("dat/movpaths", offset paths, sizeof(paths));
  _loadingMsg = "Cargando... 75%";
  frame();

  // Carga tipo de enemigos
  logger_log("Cargando enemtype.csv");
  loadEnemyData();
  // loadData("dat/enemtype", offset enemyType, sizeof(enemyType));
  _loadingMsg = "Cargando... 80%";
  frame();

  logger_log("Cargando pweapons.csv");
  loadWeaponsData();
  // loadData("dat/pweapons", (int32*)&playerWeapons, sizeof(playerWeapons));
  _loadingMsg = "Cargando... 90%";
  frame();

  // TODO Carga de FX de sonido
  //snd.explosion = load_wav(pathResolve("snd/bigexpl0.wav"), 0);
  //snd.bigExplosion = load_wav(pathResolve("snd/bigexpl1.wav"), 0);
  ////snd.pickUp;
  ////snd.eShoot;
  //snd.vulcan = load_wav(pathResolve("snd/vulcan.wav"), 0);
  ////snd.laser;
  //_loadingMsg = "Cargando... 100%";
  frame();

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
  return (file);
end

/**
 * Verifica si un proceso est  dentro del area de juego, que es mas grande que la regi¢n visible
 */
function isOutsidePlayfield(xx, yy)
begin
  if (xx < PLAYFIELD_XMIN || xx > PLAYFIELD_XMAX)
    return(true);
  end
  if (yy < PLAYFIELD_YMIN || yy > PLAYFIELD_YMAX)
    return(true);
  end
  return(false);
end;

/**
 * Conversi¢n coordeandas de scroll a pantalla
 */
function scrollXToScreenX(int xx)
begin
  return(xx - (scroll[0].x0 * PLAYFIELD_RESOLUTION));
end
function scrollYToScreenY(int yy)
begin
  return(yy - scrollY);
end

/**
 * Conversion coordenadas de pantalla a scroll
 */
function screenXToScrollX(int xx)
begin
  return(xx + (scroll[0].x0 * PLAYFIELD_RESOLUTION));
end
function screenYToScrollY(int yy)
begin
  return(yy + scrollY);
end

// /**
//  * Proceso de efecto de explosion
//  *
//  * Usa una tabla global para saber los Ids de la explosi¢n
//  */
// process explosion(explosionId, x, y)
// private
//   int i;
//   int _totalFrames;
// begin
//   file = fpgExplosion;
//   region = PLAYFIELD_REGION;
//   resolution = PLAYFIELD_RESOLUTION;
//   flags = 4; // Transparencia
//   z = min_int + 1;
//   _totalFrames = exploFx[explosionId].frames;
//
//   for (i = 0; i <= _totalFrames; i++)
//     graph = exploFx[explosionId].graph[i];
//     frame(200); // Actualiza a 30fps
//   end
// end
//
//
//
// /**
//  * Item bonus que cambia/mejora el arma del jugador
//  */
// process mainWeaponBonus(playerWeaponId, xrel, yrel)
// private
// begin
//   file = fpgShoots;
//   region = PLAYFIELD_REGION;
//   resolution = PLAYFIELD_RESOLUTION;
//   graph = playerWeapons[playerWeaponId];
//
//   while (! isOutsidePlayfield(x, y))
//     x = scrollXToScreenX(xrel);
//     y = scrollYToScreenY(yrel);
//
//     if (collision(type playerShip))
//       // El jugador ha recogido el item. Mejoramos o cambiamos el arma
//       if (player.mainWeapon.weapon == playerWeaponId)
//         // Aumentamos el tier
//         player.mainWeapon.tier = min(player.mainWeapon + 1, 4);
//       else
//         // Cambiamos el arma
//         player.mainWeapon.weapon = playerWeaponId;
//       end
//       break;
//     end
//     frame;
//   end;
// end;
//
// /**
//  * Muestra el rotulo de game over
//  * TODO Mostrar si el jugador desea volver a jugar el mapa o volver al men£. Retornar valor seg£n la opci¢n.
//  */
// function gameOverScreen()
// private
//   _gameoverId;
// begin
//   _gameoverId = write(fntGameover, 320, 240, 4, "GAME OVER");
//   frame(6000); // Esperamos ~1 segundo
//   loop
//     if (key(_enter) || key(_esc) || mouse.left)
//       break;
//     end;
//     frame;
//   end
//   delete_text(_gameoverId);
//   return(false);
// end


/* vim: set ts=2 sw=2 tw=0 et fileencoding=cp858 :*/
