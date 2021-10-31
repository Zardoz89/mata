COMPILER_OPTIONS _case_sensitive, _extended_conditions, _use_cstyle;
// ****************************************************************************
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
// Código que representa al jugador y control por el jugador
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

  // Inicialización posición y scroll
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

    // _mainWeaponId = getMainWeaponIdFromPlayerWeapon();

    // // Disparo arma principal
    // if (key(_control) || mouse.left)
    //   // Si ha pasado suficiente delay...
    //   if (_mainShootCounter >= shootData[_mainWeaponId].delay)
    //     // Si tenemos suficiente energia...
    //     if (player.energy > shootData[_mainWeaponId].energy )
    //       // Consumismos energia
    //       player.energy = clamp(player.energy - shootData[_mainWeaponId].energy, 0, PLAYER_MAX_ENERGY);
    //       _mainShootCounter = 0;

    //       // Calculo dispersión del disparo si aplica
    //       _dispersionAngle = calcDispersionAngle(shootData[_mainWeaponId].disperseValue,
    //         shootData[_mainWeaponId].disperseType, ticksCounter);
    //       if (shootData[_mainWeaponId].disperseType <> DIS_FOLLOW_Y_FATHER)
    //         shoot(x, y, 90000 + _dispersionAngle , _mainWeaponId, MOVREL_NONE, false);
    //       else
    //         shoot(x, y, 90000 + _dispersionAngle , _mainWeaponId,
    //           MOVREL_SYNC_X || MOVREL_REL_Y, false);
    //       end

    //       // Y metemos el FX de sonido
    //       //sound(snd.vulcan, 256, 256);
    //     end
    //   end
    // end

    // _mainShootCounter++;
    // ticksCounter++;
    frame;
  end

end

// /**
//  * Función auxiliar que aplica daño a la nave del jugador
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
// /**
//  * Devuelve el ID de la tabla de armas a partir del arma actual del jugador
//  */
// function getMainWeaponIdFromPlayerWeapon()
// begin
//   return(playerWeapons[player.mainWeapon.weapon].weaponId[player.mainWeapon.tier]);
// end
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

/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1  :*/
