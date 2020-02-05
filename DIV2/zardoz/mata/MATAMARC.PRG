COMPILER_OPTIONS _case_sensitive;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// https://divcompo.now.sh
// ****************************************************************************

program matamarcianos;

import "c:\div2\demo2.dll";

const
  DEBUG_MODE=1; // Modo debug. Activa la salida r pida, etc.
global
  num = 16;
  // **** Libreria de graficos
  fpgPlayer;
  fpgShoots;

  // **** Tipos de disparo
  // Disparos simples
  struct simpleShootData[3]
    graphFile;
    graph;
    int damage; // Da¤o del disparo
    int delay; // Retardo entre cada disparo. A 60 fps -> 1 tick ~ 16 centesimas
    int speed; // Velocidad en pixels
  end;

begin
  set_mode(m640x480);
  set_fps(60, 0);
  vsync=1;

  num = ADDSQRT(30, 2);
  // **** Carga de recursos ****
  // Graficos
  fpgPlayer = load_fpg("zardoz\mata\fpg\player.fpg");
  fpgShoots = load_fpg("zardoz\mata\fpg\shoots.fpg");

  // Carga tipos de disparo
  loadShootTypeData();

  // Creaci¢n procesos
  playerShip(fpgPlayer, 1);

  // Main loop
  loop
    // Salida del juego para modo debug
    if (DEBUG_MODE == 1 && key(_q))
      let_me_alone();
      break;
    end

    frame;
  end
end

function loadShootTypeData()
begin
  // TODO Autocargar esto desde un fichero
  simpleShootData[0].damage = 1;
  simpleShootData[0].graphFile = fpgShoots;
  simpleShootData[0].graph = 1;
  simpleShootData[0].delay = 1;
  simpleShootData[0].speed = 8;

  simpleShootData[1].damage = 6;
  simpleShootData[1].graphFile = fpgShoots;
  simpleShootData[1].graph = 2;
  simpleShootData[1].delay = 5;
  simpleShootData[1].speed = 8;

  simpleShootData[2].damage = 20;
  simpleShootData[2].graphFile = fpgShoots;
  simpleShootData[2].graph = 3;
  simpleShootData[2].delay = 10;
  simpleShootData[2].speed = 5;

end

process playerShip(graphFile, graphIndex)
private
  _health = 100;
  _mainShootCounter = 0; // Utilizamos para meter retardos entre los disparos
  _mainWeapon = 0;
begin
  // Asignaci¢n grafico
  file = graphFile;
  graph = graphIndex;

  loop
    if (_health < 0)
      break;
    end;
    // Calcula de nueva posici¢n
    x = mouse.x;
    y = mouse.y;

    if (mouse.left )
      if (_mainShootCounter >= simpleShootData[_mainWeapon].delay)
        _mainShootCounter = 0;
        shoot(simpleShootData[_mainWeapon].graphFile,
          simpleShootData[_mainWeapon].graph, x, y,
          simpleShootData[_mainWeapon].damage, 90000,
          simpleShootData[_mainWeapon].speed, false);
      end
    end

    _mainShootCounter++;
    frame;
  end;
end

/**
 * Disparo que se mueve en linea recta
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
process shoot(graphFile, graphIndex, x, y, damage, direction, speed, enemyShoot)
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

// TODO meter un process para spamear naves enemigas
