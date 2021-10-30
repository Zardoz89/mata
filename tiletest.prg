COMPILER_OPTIONS _case_sensitive, _extended_conditions;//, _use_cstyle;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// Tests de tilemaps
//
// https://divcompo.now.sh
// ****************************************************************************
program tiletest;

include "src/loadData.prg";
include "src/tilemaps.prg";

const
  PLAYFIELD_REGION=1; // Region de la zona de juego
  PLAYFIELD_REGION_W=492;
  PLAYFIELD_REGION_H=448; // 28px * 16

  TILE_WIDTH=24;
  TILE_HEIGHT=28;
  TILEMAP_COLUMNS=25;
  TILEMAP_ROWS=145;//26;
  TILEMAP_MAX_X= 600; //TILEMAP_COLUMNS * TILEMAP_WIDTH - playfield_region_w;
  TILEMAP_MAX_Y= 4060; //768; //TILEMAP_ROWS * TILEMAP_HEIGHT;

  BLACK_COLOR_PAL_INDEX = 196; // Indice del color negro en la paleta

global
  real_res_x, real_res_y;

private
  int16* tiles;
  /*int tiles[(TILEMAP_ROWS+1) * TILEMAP_COLUMNS] =
  // 0    1    2    3    4    5    6    7     8    9   10   11   12   13   14   15    16   17   18   19   20   21   22   23   24
    16,  16,   2,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 0
    16,  16,   2,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 1
     4,   4,   9,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 2
    13,  13,  13,  13,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 3
    13,  13,  13,  21,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 4
    13,  13,  21,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 5
    13,  21,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  20,  13,  13, // 6
    20,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 7
    20,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  20,  21, // 8
    // 9 * 25 =225
    21,  13,  13,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 0
    13,  21,  13,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 1
    13,  13,  21,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 2
    13,  13,  13,  21,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 3
    13,  13,  13,  21,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 4
    13,  13,  21,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 5
    13,  21,  13,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  20,  13,  13, // 6
    21,  13,  13,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 7
    13,  13,  13,  13,  13,  13,  13,  13,   21,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  20,  21, // 8

    21,  13,  13,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 0
    13,  21,  13,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 1
    13,  13,  21,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 2
    13,  13,  13,  21,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 3
    13,  13,  13,  21,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 4
    13,  13,  21,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  13, // 5
    13,  21,  13,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  20,  13,  13, // 6
    21,  13,  13,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,  20, // 7
    13,  13,  13,  13,  13,  13,  13,  13,   21,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  20,  21; // 8
  */

  int tileMapGraph;
begin
  //mode_set(640, 480, 32, mode_window, filter_scale_scale2x, filter_scanline_noscanline);
  desktop_get_size(&real_res_x, &real_res_y);
  virtualresolution_set(real_res_x, real_res_y, 1, 0);
  mode_set(640, 480, 8);
  set_fps(60, 0);
  vsync=1;

  fpg_load("fpg/TILEMAP.FPG");

  define_region(PLAYFIELD_REGION, 0, 0, PLAYFIELD_REGION_W, PLAYFIELD_REGION_H);

  debugText();

  tiles = malloc((TILEMAP_ROWS+1) * TILEMAP_COLUMNS);
  loadData("lvl/level_01/tilemap", tiles, (TILEMAP_ROWS+1) * TILEMAP_COLUMNS);

  tileMapGraph = createTileBuffer(TILEMAP_ROWS, TILEMAP_COLUMNS, TILE_WIDTH, TILE_HEIGHT, BLACK_COLOR_PAL_INDEX);
  drawTiles(tileMapGraph, tiles, TILEMAP_COLUMNS, TILEMAP_ROWS, TILE_WIDTH, TILE_HEIGHT);
  free(tiles);

  start_scroll(0, 0, tileMapGraph, 0, PLAYFIELD_REGION, 0);
  scroll[0].y0 = TILEMAP_ROWS * TILE_HEIGHT;

  loop
    if (keydown(_q))
      let_me_alone();
      break;
    end

    scroll[0].x0 = TILEMAP_COLUMNS * TILE_WIDTH * (mouse.x / 640.0); //clamp(mouse.x, 0, TILEMAP_COLUMNS * TILE_WIDTH);
    scroll[0].y0 = TILEMAP_ROWS * TILE_HEIGHT * (mouse.y / 480.0); //clamp(mouse.y, 0, TILEMAP_ROWS * TILE_HEIGHT);

    write(0, 0, 0, 0, &scroll[0].x0);
    write(0, 0, 30, 0, &scroll[0].y0);
    frame;
  end
end

/**
 * Genera la ruta relativa a los ficheros del juego
 */
function string pathResolve(string filename)
begin
  return(filename);
end

/**
 * Proceso que muestra informacion de debug como los FPS
 */
process debugText()
private
  int fpsTxtId = 0;
  string _msg;
begin
  loop
    if (fpsTxtId)
      delete_text(fpsTxtId);
    end
    _msg = "FPS: " + itoa(fps);
    fpsTxtId = write(0, 640, 0, 2, _msg);
    frame(3000); // Actualiza a 2 FPS
  end
end


/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1 :*/
