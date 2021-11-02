COMPILER_OPTIONS _case_sensitive, _extended_conditions, _use_cstyle;
// ****************************************************************************
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// Código grupos de enemigos, trayectorias y formaciones
// ****************************************************************************

global
  // **** Formaciones de naves enemigas
  struct formations[15]
    struct startPosition[7]
      int32 x; int32 y;
    end
  end

  // **** Patrones de movimiento [Id patron]
  struct paths[41]
    int8 maxSteps; // Nº de pasos
    int vx0; // Velocidad inicial eje X
    int vy0; // Velocidad inicial eje Y
    struct steps[11]
      int ax; // Aceleracion eje x
      int ay; // Aceleracion eje y
      int ticks; // Nº de ticks que dura este paso
    end
  end


/**
 * Carga los datos de los distintos tipos de enemigos
 */
function int loadFormations()
private
  int32* tmpArray;
  int _size;
  int i, u, index;
begin
  _size = loadData("dat/formatio",  tmpArray, max_int32);
  tmpArray = memory_new(_size * sizeof(int32));
  _size = loadData("dat/formatio",  tmpArray, _size);

  for (i=0; i < 15; i++)
    for(u=0; u < 7; u++)
      index = i*2*7 + u*2;
      if (index >= _size)
        break;
      end
      formations[i].startPosition[u].x = tmpArray[index];
      formations[i].startPosition[u].y = tmpArray[index+1];
    end
    if (index >= _size)
      break;
    end
  end

  memory_delete(tmpArray);
  return(_size);
end

/**
 * Carga los datos de los patrones de movimiento de los enemigos
 */
function int loadPaths()
private
  int32* tmpArray;
  int _size;
  int i, u, index;
begin
  _size = loadData("dat/movpaths",  tmpArray, max_int32);
  tmpArray = memory_new(_size * sizeof(int32));
  _size = loadData("dat/movpaths",  tmpArray, _size);

  for (i=0; i < 41; i++)
    index = i*36;
    if ((index + 11*3 + 3)>= _size)
      break;
    end
    paths[i].maxSteps = tmpArray[index];
    paths[i].vx0 = tmpArray[index+1];
    paths[i].vy0 = tmpArray[index+2];
    for(u=0; u < 11; u++)
      index = i*36 + u*3 + 3;
      paths[i].steps[u].ax = tmpArray[index];
      paths[i].steps[u].ay = tmpArray[index+1];
      paths[i].steps[u].ticks = tmpArray[index+2];
    end
  end

  memory_delete(tmpArray);
  return(_size);
end

// /**
//  * Crea un grupo de enemigos en formación simple.
//  * Todos son del mismo tipo y siguen el mismo patrón de movimiento
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

/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1 :*/
