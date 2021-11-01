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

  // **** Enumerados **********************************************************
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

  // **** Formaciones de naves enemigas
  // struct formations[13]
  //   struct startPosition[6]
  //     int x; int y;
  //   end
  // end

  // // **** Patrones de movimiento [Id patron]
  // struct paths[40]
  //   byte maxSteps; // N§ de pasos
  //   int vx0; // Velocidad inicial eje X
  //   int vy0; // Velocidad inicial eje Y
  //   struct steps[10]
  //      int ax; // Aceleracion eje x
  //     int ay; // Aceleracion eje y
  //     int ticks; // N§ de ticks que dura este paso
  //   end
  // end

  // // **** Tipos de enemigos del juego
  // struct enemyType[10]
  //   int hull; // Vidia inicial
  //   byte canCollide: // Flag que indica si puede colisionar
  //   int shootTypeId; // Tipo de disparo
  //   int aggression; // Si es < 0 dispara directamente; > 0 dispara hacia abajo
  //   // Abs es la frecuencia de disparo -> rand(0, 1000) <= abs(aggresion)
  //   word score; // Puntos que da al ser destruido
  //   byte nFrames; // N§ de frames de la animaci¢n
  //   byte animationType; // 0 al terminar, para; 1 bucle ; 2 avanza-retrocede
  //   int graphId[10];
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

  // // Carga las formaciones
  // loadData("dat/formatio", offset formations, sizeof(formations));
  // _loadingMsg = "Cargando... 70%";
  // frame();

  // // Carga patrones de movimiento
  // loadData("dat/movpaths", offset paths, sizeof(paths));
  // _loadingMsg = "Cargando... 75%";
  // frame();

  // // Carga tipo de enemigos
  // loadData("dat/enemtype", offset enemyType, sizeof(enemyType));
  // _loadingMsg = "Cargando... 80%";
  // frame();

  logger_log("Cargando pweapons.csv");
  loadWeaponssData();
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

// 
// 
// 
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
// /**
//  * Proceso que muestra el estado del casco del jugador
//  */
// process playerHullStatus()
// private
//   int clampHull;
//   int regionY;
// begin
//   region=STATUS_HULL_BAR_REGION;
//   x = STATUS_HULL_BAR_X;
//   y = STATUS_HULL_BAR_Y;
//   file=fpgHud;
//   graph=2; // Grafico vida
//   loop
//     clampHull = clamp(player.sId.hull, 0, PLAYER_MAX_HULL);
//     regionY = STATUS_HULL_BAR_Y - 100 + 200 - clampHull ;
//     define_region(STATUS_HULL_BAR_REGION,
//       STATUS_HULL_BAR_X - 6,
//       regionY,
//       12, clampHull);
//     frame(200);
//   end
// end
// 
// /**
//  * Proceso que muestra el estado del escudo del jugador y los regenera
//  */
// process playerShieldStatus()
// private
//   int clampShield;
//   int regionY;
// begin
//   region=STATUS_SHIELD_BAR_REGION;
//   x = STATUS_SHIELD_BAR_X;
//   y = STATUS_SHIELD_BAR_Y;
//   file=fpgHud;
//   graph=3; // Grafico barra escudos
//   loop
//     clampShield = clamp(player.shield, 0, PLAYER_MAX_SHIELD);
//     regionY = STATUS_HULL_BAR_Y - 100 + 200 - clampShield;
//     define_region(STATUS_SHIELD_BAR_REGION,
//       STATUS_SHIELD_BAR_X - 6,
//       regionY,
//       12, clampShield);
// 
//     // Regeneraci¢n escudos
//     if (player.energy > 30 && ticksCounter > 30)
//       player.shield = clamp(player.shield + SHIELD_REGENERATION_RATE, 0, PLAYER_MAX_SHIELD);
//       player.energy -= (SHIELD_REGENERATION_RATE >> 1);
//       ticksCounter = 0;
//     end
// 
//     ticksCounter++;
//     frame;
//   end
// end
// 
// /**
//  * Proceso que muestra la energia del jugador y la regenera
//  */
// process playerEnergyStatus()
// private
//   int clampEnergy;
//   int regionY;
// begin
//   region=STATUS_ENERGY_BAR_REGION;
//   x = STATUS_ENERGY_BAR_X;
//   y = STATUS_ENERGY_BAR_Y;
//   file=fpgHud;
//   graph=4; // Grafico barra escudos
//   loop
//     clampEnergy = clamp(player.energy, 0, PLAYER_MAX_ENERGY);
//     regionY = STATUS_ENERGY_BAR_Y - 100 + 200 - clampEnergy;
//     define_region(STATUS_ENERGY_BAR_REGION,
//       STATUS_ENERGY_BAR_X - 6,
//       regionY,
//       12, clampEnergy);
// 
//     // Regeneraci¢n energia
//     if (ticksCounter > 4)
//       player.energy = clamp(player.energy + player.generatorRate, 0, PLAYER_MAX_ENERGY);
//       ticksCounter = 0;
//     end
// 
//     ticksCounter++;
//     frame;
//   end
// end
// 
// 
// /**
//  * Crea un grupo de enemigos en formaci¢n simple.
//  * Todos son del mismo tipo y siguen el mismo patr¢n de movimiento
//  */
// function createSimpleEnemyGroup(x, y, enemyType, pathId, number, formationType)
// private
//   i;
//   _enemyGroupId;
// begin
//   _enemyGroupId = enemyGroup(number);
//   for (i=0; i <= 6 && i < number; i++)
//     enemy(
//       x + formations[formationType].startPosition[i].x,
//       y + formations[formationType].startPosition[i].y,
//       enemyType,
//       pathId,
//       _enemyGroupId);
//     remaningChildrens++;
//   end
//   return(_enemyGroupId);
// end
// 
// /**
//  * Proceso "padre" de un grupo de enemigos
//  * Gestiona el spawn del bonus si es necesario
//  */
// process enemyGroup(totalChildrens)
// private
// begin
//   remaningChildrens = totalChildrens;
//   loop
//     if (remaningChildrens <= 0)
//       if (killedChildrens == totalChildrens && bonusType <> -1)
//         // TODO Hacer spawn de diferente tipos de bonus
//         mainWeaponBonus(bonusType, xrel ,yrel);
//       end
//       break;
//     end
// 
//     frame;
//   end
// end
// 
// /**
//  * Nave o bicho enemigo
//  * Parametros:
//  * x0 : Coordenadas de tilemap
//  * y0 : Coordenadas de tilemap
//  * typeId : Tipo de enemigo
//  * pathId : Patron de movimiento
//  * groupProcess : Id del proceso grupo asociados a este enemigo
//  */
// process enemy(x0, y0, typeId, pathId, groupProcess)
// private
//   int _pathStep = 0;
//   int _pathTick = 0; // Utilizamos para contar los ticks que permanece en paso altual de mov.
//   int _vx = 0;
//   int _vy = 0;
//   int _frame = 0;
//   int _frameDir = 1; // Lo utilizamos para las animaciones tipo spring
//   int _aggressionAbs;
//   int _dispersionAngle;
//   int _shootId;
// begin
//   file = fpgEnemy;
//   region = PLAYFIELD_REGION;
//   resolution = PLAYFIELD_RESOLUTION;
//   graph = enemyType[typeId].graphId[_frame];
//   hull = enemyType[typeId].hull;
//   _aggressionAbs = abs(enemyType[typeId].aggression);
//   _shootId = enemyType[typeId].shootTypeId;
// 
//   xrel = x0;
//   yrel = y0;
//   x = scrollXToScreenX(xrel); //xrel - (scroll[0].x0 * PLAYFIELD_RESOLUTION);
//   y = scrollYToScreenY(yrel); //yrel;
// 
// 
//   // Aplicamos la velocidad inicial si hay un patron de mov.
//   if (pathId <> -1 )
//     _vx = paths[pathId].vx0;
//     _vy = paths[pathId].vy0;
//   end;
// 
//   while (! isOutsidePlayfield(x, y) && hull > 0)
// 
//     // **** Movimiento
//     // Aplicamos el patron de mov. si hay uno asignado
//     if (pathId <> -1 && _pathStep <= 10)
//       if (paths[pathId].maxSteps >= _pathStep)
//         if (_pathTick >= paths[pathId].steps[_pathStep].ticks)
//           _pathStep++;
//           _pathTick = 0;
//         end
//         _vx = _vx + paths[pathId].steps[_pathStep].ax;
//         _vy = _vy + paths[pathId].steps[_pathStep].ay;
//         _pathTick++;
//       end
//     end
//     xrel += _vx;
//     yrel += _vy;
//     // El movimiento horizontal es respecto al scroll de fondo
//     x = scrollXToScreenX(xrel);
//     y = scrollYToScreenY(yrel);
// 
//     // **** Animacion
//     if (!ticksCounter) // Se actualiza la animacion cada 2 frames
//       switch (enemyType[typeId].animationType)
//       case ANI_SINGLE:
//         if (enemyType[typeId].nFrames -1 <= _frame)
//         else
//           _frame++;
//         end
//       end
//       case ANI_LOOP:
//         if (enemyType[typeId].nFrames -1 <= _frame)
//           _frame = 0;
//         else
//           _frame++;
//         end
//       end
//       case ANI_SPRING:
//         if (enemyType[typeId].nFrames -1 <= _frame)
//           _frameDir = -1;
//         else if (_frame <= 0)
//           _frameDir = 1;
//           end
//         end
//         _frame = _frame + _frameDir;
//       end
//     end
//     graph = enemyType[typeId].graphId[_frame];
//     end
// 
//     // **** Disparo
//     if (enemyType[typeId].shootTypeId <> -1)
//       if (ticksCounter >> 1)
//         if (rand(0, 1000) <= _aggressionAbs)
//           // Disparamos
//           _dispersionAngle = calcDispersionAngle(
//             shootData[_shootId].disperseValue,
//             shootData[_shootId].disperseType,
//             ticksCounter);
// 
//           if (enemyType[typeId].aggression >= 0)
//             // Dispara hacia el jugador
// 
//             shoot(x, y,
//               fget_angle(x, y, player.sId.x, player.sId.y) + _dispersionAngle ,
//               enemyType[typeId].shootTypeId, MOVREL_NONE, true);
//           else
//             // Dispara recto
//             shoot(x, y, 270000 + _dispersionAngle,
//               enemyType[typeId].shootTypeId, MOVREL_NONE, true);
// 
//             if (shootData[_shootId].disperseType <> DIS_FOLLOW_Y_FATHER)
//               shoot(x, y, 270000 + _dispersionAngle , _shootId, MOVREL_NONE, true);
//             else
//               shoot(x, y, 270000 + _dispersionAngle , _shootId,
//                 MOVREL_SYNC_X || MOVREL_REL_Y, true);
//             end
// 
//           end
//         end
//       end
//     end
// 
//     ticksCounter++;
//     frame;
//   end;
// 
//   // Evitamos contar dos veces una muerte
//   if (hull > 0 && groupProcess)
//     groupProcess.remaningChildrens--;
//   end
// end
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
