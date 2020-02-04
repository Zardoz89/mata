COMPILER_OPTIONS _case_sensitive;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// https://divcompo.now.sh
// ****************************************************************************

program matamarcianos;
const
  DEBUG_MODE=1; // Modo debug. Activa la salida r pida, etc.
global
  fpgPlayer;

begin
  set_mode(m640x480);
  set_fps(60, 0);
  vsync=1;

  // **** Carga de recursos ****
  // Graficos
  fpgPlayer = load_fpg("zardoz\mata\fpg\player.fpg");

  // Creaci¢n procesos
  playerShip(fpgPlayer, 1);
  loop
    // Salida del juego para modo debug
    if (DEBUG_MODE == 1 && key(_q))
      let_me_alone();
      break;
    end

    frame;
  end
end

process playerShip(graphFile, graphIndex)
begin
  // Asignaci¢n grafico
  file = graphFile;
  graph = graphIndex;

  loop
    // Calcula de nueva posici¢n
    x = mouse.x;
    y = mouse.y;

    if (mouse.left)
      simpleShoot(fpgPlayer, 2, x, y, 1, 90000, 8, false);
    end

    frame;
  end;
end

/**
 * Disparo simple que se mueve en linea recta
 *
 * Par metros:
 * graphFile
 * graphIndex
 * x
 * y
 * damage Da¤o
 * direction Direcci¢n del movimiento
 * speed Velocidad del disparo
 * enemyShoot si es 1, es un disparo enemigo y da¤a al jugador
 */
process simpleShoot(graphFile, graphIndex, x, y, damage, direction, speed, enemyShoot)
private
begin
  // Asignaci¢n de grafico
  file = graphFile;
  graph = graphIndex;

  while (! out_region(id, 0))
    if (enemyShoot == 1 && collision(type playerShip))
      // TODO Herir al jugador
    else
      // TODO Colision con un enemigo
    end;

    // Movimiento
    xadvance(direction, speed);

    frame;
  end;
end

