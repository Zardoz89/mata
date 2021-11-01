COMPILER_OPTIONS _case_sensitive, _extended_conditions, _use_cstyle;
// ****************************************************************************
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
// C�digo que representa al jugador y control por el jugador
// ****************************************************************************


const
  // Cte. valores que afectan al jugador
  PLAYER_MAX_HULL = 200;
  PLAYER_MAX_SHIELD = 200;
  PLAYER_MAX_ENERGY = 200;
  PLAYER_SPEED = 30;
  SHIELD_REGENERATION_RATE = 5;  // Cuanto regenera el escudo
  INTIAL_GENERATOR_RATE = 5; // Cuanto regenera la energia

global
  // **** Generales de la partida
  struct player
    int sId; // Id del proceso de la nave del jugador
    int shield;
    int energy;
    int generatorRate = 5; //INTIAL_GENERATOR_RATE;
    int32 score;
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
  struct playerWeapons[2]
    int32 itemGraph; // Grafico del item que da dicha arma
    int32 weaponId[5];
  end

/**
 * Carga los datos de los distintos tipos de armas y el id de disparo/proyectil
 */
function int loadWeaponsData()
private
  int32* tmpArray;
  int _size;
  int i;
begin
  _size = loadData("dat/pweapons",  tmpArray, max_int32);
  tmpArray = memory_new(_size * sizeof(int32));
  _size = loadData("dat/pweapons",  tmpArray, _size);
  for(i=0; (i < _size) && (i/6 < 2); i++)
    if (i%6 == 0)
      playerWeapons[i/6].itemGraph = tmpArray[i];
    end
    if (i%6 != 0)
      playerWeapons[i/6].weaponId[i%6 - 1] = tmpArray[i];
    end
  end
  memory_delete(tmpArray);
  return(_size);
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

  // Inicializaci�n posici�n y scroll
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

    // // Colision con naves enemigas
    // _hitId = collision(type enemy);
    // if (_hitId)
    //   if (enemyType[_hitId.typeId].canCollide)
    //     damagePlayer(1);
    //     // Hacemos que le cueste penetrar mas en el enemigo
    //     _collisionAngle = get_angle(_hitId);
    //     mouse.x -= cos(_collisionAngle) / 500;
    //     mouse.x -= sin(_collisionAngle) / 500;
    //   end
    // end

    _mainWeaponId = getMainWeaponIdFromPlayerWeapon();

    // Disparo arma principal
    if (keydown(_control) || mouse.left)
      // Si ha pasado suficiente delay...
      if (_mainShootCounter >= shootData[_mainWeaponId].delay)
        // Si tenemos suficiente energia...
        if (player.energy > shootData[_mainWeaponId].energy )
          // Consumismos energia
          player.energy = clamp(player.energy - shootData[_mainWeaponId].energy, 0, PLAYER_MAX_ENERGY);
          _mainShootCounter = 0;

          // Calculo dispersi�n del disparo si aplica
          _dispersionAngle = calcDispersionAngle(shootData[_mainWeaponId].disperseValue,
          shootData[_mainWeaponId].disperseType, ticksCounter);
          if (shootData[_mainWeaponId].disperseType <> DIS_FOLLOW_Y_FATHER)
            shoot(x, y, 90000 + _dispersionAngle , _mainWeaponId, MOVREL_NONE, false);
          else
            shoot(x, y, 90000 + _dispersionAngle , _mainWeaponId,
              MOVREL_SYNC_X || MOVREL_REL_Y, false);
          end

    //       // Y metemos el FX de sonido
    //       //sound(snd.vulcan, 256, 256);
        end
      end
    end

    _mainShootCounter++;
    ticksCounter++;
    frame;
  end

end

// /**
//  * Funci�n auxiliar que aplica da�o a la nave del jugador
//  */
// function damagePlayer(damage)
// private
// begin
//   player.shield -= damage;
//   if (player.shield < 0)
//     player.sId.hull += player.shield;
//     player.shield = 0;
//   else
//     shieldFx(); // Hacemos el efecto del escudo
//   end
// end
//
// /**
//  * Proceso que muestra el efecto de escudos de la nave del jugador
//  */
// process shieldFx()
// private
//   int i;
// begin
//   file = fpgPlayer;
//   region = PLAYFIELD_REGION;
//   resolution = PLAYFIELD_RESOLUTION;
//   flags = 4; // Transparencia
//   graph = 6;
//   z = min_int + 2;
//
//   for (i = 0; i <= 4; i++)
//     x = player.sId.x;
//     y = player.sId.y;
//     frame;
//   end
// end
//
/**
 * Devuelve el ID de la tabla de armas a partir del arma actual del jugador
 */
function getMainWeaponIdFromPlayerWeapon()
begin
  return(playerWeapons[player.mainWeapon.weapon].weaponId[player.mainWeapon.tier]);
end
//
// /**
//  * Devuelve el ID de la tabla de armas a partir del arma secundartia actual del jugador
//  */
// function getSecundaryWeaponIdFromPlayerWeapon()
// begin
//   if (player.secondaryWeapon.weapon == -1)
//     return(-1);
//   end
//   return(playerWeapons[player.secondaryWeapon.weapon].weaponId[player.secondaryWeapon.tier]);
// end


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

    // Regeneraci�n escudos
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

    // Regeneraci�n energia
    if (ticksCounter > 4)
      player.energy = clamp(player.energy + player.generatorRate, 0, PLAYER_MAX_ENERGY);
      ticksCounter = 0;
    end

    ticksCounter++;
    frame;
  end
end


/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1  :*/
