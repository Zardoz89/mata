COMPILER_OPTIONS _case_sensitive, _extended_conditions, _use_cstyle;
// ****************************************************************************
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// Código procesos enemigos
// ****************************************************************************

const

  // **** Tipos de animacion
  ANI_SINGLE = 0; // Al terminar los frames, para
  ANI_LOOP = 1; // Hace bucle
  ANI_SPRING = 2; // avanza-retrocede en la animacion

global

  // **** Tipos de enemigos del juego
  struct enemyType[10]
    int32 hull; // Vidia inicial
    byte canCollide; // Flag que indica si puede colisionar
    int32 shootTypeId; // Tipo de disparo
    int32 aggression; // Si es < 0 dispara directamente; > 0 dispara hacia abajo
    // Abs es la frecuencia de disparo -> rand(0, 1000) <= abs(aggresion)
    word score; // Puntos que da al ser destruido
    byte nFrames; // Nº de frames de la animación
    byte animationType; // 0 al terminar, para; 1 bucle ; 2 avanza-retrocede
    int32 graphId[11];
  end

/**
 * Carga los datos de los distintos tipos de enemigos
 */
function int loadEnemyData()
private
  int32* tmpArray;
  int _size;
  int i;
begin
  _size = loadData("dat/enemtype",  tmpArray, max_int32);
  tmpArray = memory_new(_size * sizeof(int32));
  _size = loadData("dat/enemtype",  tmpArray, _size);
  for(i=0; (i < _size) && (i/17 < 10); i++)
    if (i%17 == 0)
      enemyType[i/17].hull = tmpArray[i];
    end
    if (i%17 == 1)
      enemyType[i/17].canCollide = (byte) tmpArray[i];
    end
    if (i%17 == 2)
      enemyType[i/17].shootTypeId = tmpArray[i];
    end
    if (i%17 == 3)
      enemyType[i/17].aggression = tmpArray[i];
    end
    if (i%17 == 4)
      enemyType[i/17].score = (word) tmpArray[i];
    end
    if (i%17 == 5)
      enemyType[i/17].nFrames = (byte) tmpArray[i];
    end
    if (i%17 == 6)
      enemyType[i/17].animationType = (byte) tmpArray[i];
    end
    if (i%17 >= 7)
      enemyType[i/17].graphId[i%17 -7] = tmpArray[i];
    end
  end
  memory_delete(tmpArray);
  return(_size);
end

/**
 * Nave o bicho enemigo
 * Parametros:
 * x0 : Coordenadas de tilemap
 * y0 : Coordenadas de tilemap
 * typeId : Tipo de enemigo
 * pathId : Patron de movimiento
 * groupProcess : Id del proceso grupo asociados a este enemigo
 */
process enemy(x0, y0, typeId, pathId, groupProcess)
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
  // if (pathId <> -1 )
  //   _vx = paths[pathId].vx0;
  //   _vy = paths[pathId].vy0;
  // end;

  while (! isOutsidePlayfield(x, y) && hull > 0)

    // **** Movimiento
    // Aplicamos el patron de mov. si hay uno asignado
    // if (pathId <> -1 && _pathStep <= 10)
    //   if (paths[pathId].maxSteps >= _pathStep)
    //     if (_pathTick >= paths[pathId].steps[_pathStep].ticks)
    //       _pathStep++;
    //       _pathTick = 0;
    //     end
    //     _vx = _vx + paths[pathId].steps[_pathStep].ax;
    //     _vy = _vy + paths[pathId].steps[_pathStep].ay;
    //     _pathTick++;
    //   end
    // end
    xrel += _vx;
    yrel += _vy;
    // El movimiento horizontal es respecto al scroll de fondo
    x = scrollXToScreenX(xrel);
    y = scrollYToScreenY(yrel);

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



/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1 :*/

