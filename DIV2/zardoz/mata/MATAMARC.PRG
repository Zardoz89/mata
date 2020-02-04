COMPILER_OPTIONS _case_sensitive;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// https://divcompo.now.sh
// ****************************************************************************

program matamarcianos;
global
  fpgPlayer;
begin
  set_mode(m640x480);
  set_fps(60, 0);
  vsync=1;

  // **** Carga de recursos ****
  // Graficos
  // Shit! Tengo que mover los ficheros
  fpgPlayer = load_fpg("fpg\player.fpg");

  // Creaci¢n procesos
  playerShip(fpgPlayer, 1);
  loop
    if (key(_q)) break; end

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

    frame;
  end;
end

