COMPILER_OPTIONS _case_sensitive, _extended_conditions, _use_cstyle;
// ****************************************************************************
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// Código de disparós y proyectiles
// ****************************************************************************

const
  // **** Tipos de dispersion del disparo
  DIS_NONE = 0; // No dispersa
  DIS_RAND = 1; // Dispersion aleatoria
  DIS_SIN = 2; // Dispersion senoidal
  DIS_FOLLOW_Y_FATHER = 3; // Se mantiene en el mismo eje Y que el proceso padre

  DIS_TICKS_SIN_MULTIPLIER = 50000; // Multiplicador de ticks para DIS_SIN***

  // **** Tipos de movimientos relativos
  MOVREL_NONE = 0;
  MOVREL_SYNC_X = 1; // Sincroniza eje X con el padre
  MOVREL_SYNC_Y = 2; // Sincroniza eje Y con el padre
  MOVREL_REL_X  = 4; // Movimiento relativo solo eje X
  MOVREL_REL_Y  = 8; // Movimiento relativo solo eje Y
  MOVREL_REL_XY = MOVREL_REL_X || MOVREL_REL_Y; // Ambos ejes

global
  // **** Tipos de disparo
  struct shootData[11]
    int32 graph; // Indice del grafico a usar de fpgShoots
    int32 damage; // Daño del disparo
    int32 energy; // Energia consumida (solo jugador)
    int32 delay; // Retardo entre cada disparo. A 60 fps -> 1 tick ~ 16 centesimas
    int32 speed; // Velocidad en pixels
    int32 disperseValue; // Angulo de dispersion
    int32 disperseType; // Tipo de dispersion del disparo
  end

/**
 * Carga los datos de losdistintos tipos de proyectiles y su forma de dispararse
 */
function int loadShootsData()
private
  int32* tmpArray;
  int _size;
  int i;
begin
  _size = loadData("dat/shoots",  tmpArray, max_int32);
  tmpArray = memory_new(_size * sizeof(int32));
  _size = loadData("dat/shoots",  tmpArray, _size);
  for(i=0; (i < _size) && (i/7 < 10); i++)
    if (i%7 == 0)
      shootData[i/7].graph = tmpArray[i];
    end
    if (i%7 == 1)
      shootData[i/7].damage = tmpArray[i];
    end
    if (i%7 == 2)
      shootData[i/7].energy = tmpArray[i];
    end
    if (i%7 == 3)
      shootData[i/7].delay = tmpArray[i];
    end
    if (i%7 == 4)
      shootData[i/7].speed = tmpArray[i];
    end
    if (i%7 == 5)
      shootData[i/7].disperseValue = tmpArray[i];
    end
    if (i%7 == 6)
      shootData[i/7].disperseType = tmpArray[i];
    end
  end
  memory_delete(tmpArray);
  return(_size);
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
  graph = shootData[typeId].graph;
  if (moveRelativeToFather) // Con mov. relativo al padre, xrel/yrel es respecto al padre
    xrel = 0;
    yrel = 0;
  else // xrel/yrel respecto al tilemap
    xrel = screenXToScrollX(x);
    yrel = screenYToScrollY(y);
  end

  while (! out_region(id, region))
  /*
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
          // Dañamos al enemigo
          hitId.hull = hitId.hull - shootData[typeId].damage;
          if (hitId.hull <= 0) // Si se queda sin vida, contamos la muerte y aumentamos la puntuación
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
*/
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
      xrel += (cos(direction) * shootData[typeId].speed) / 1000;
      yrel -= (sin(direction) * shootData[typeId].speed) / 1000;
      x = scrollXToScreenX(xrel);
      y = scrollYToScreenY(yrel);
    end
    frame;
  end;
end



/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1  :*/
