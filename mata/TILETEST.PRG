COMPILER_OPTIONS _case_sensitive;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// Tests de tilemaps
//
// https://divcompo.now.sh
// ****************************************************************************

program tiletest;

const

  // cte. para las rutas
  PATH_USER="zardoz";
  PATH_PROG="mata";

  PLAYFIELD_REGION=1; // Region de la zona de juego
  PLAYFIELD_REGION_W=492;
  PLAYFIELD_REGION_H=480;

  TILEMAP_ROWS=24;

global

local

private
  int tiles[8, TILEMAP_ROWS] =
  // 0    1    2    3    4    5    6    7     8    9   10   11   12   13   14   15    16   17   18   19   20   21   22   23
    16,  16,   2,  13,  13,  13,  13,  21,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  20,
    16,  16,   2,  13,  13,  13,  21,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,
     4,   4,   9,  13,  13,  21,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,
    13,  13,  13,  13,  21,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,
    13,  13,  13,  21,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,
    13,  13,  21,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,
    13,  21,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,
    20,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  20,
    20,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  13,   13,  13,  13,  13,  13,  13,  13,  20;
    // 9 * 24 =216

  tileMap;
begin
  set_mode(m640x480);
  set_fps(60, 0);
  vsync=1;

  load_fpg(pathResolve("fpg\tilemap.fpg"));

  ctype=c_scroll;
  scroll.camera = id;
  define_region(PLAYFIELD_REGION, 0, 0, PLAYFIELD_REGION_W, PLAYFIELD_REGION_H);

  tileMap = drawTiles(offset tiles, TILEMAP_ROWS, 8, 24, 28);
  start_scroll(0, 0, tileMap, 0, PLAYFIELD_REGION, 3);

  loop
    x = mouse.x;
    y = mouse.y;
    frame;
  end
end

/**
 * Genera la ruta relativa a los ficheros del juego
 */
function pathResolve(file)
begin
  return (PATH_USER + "\" + PATH_PROG + "\" + file);
end

function drawTiles(int pointer tilesPtr, mapColumns, mapRows, tileWidth, tileHeight)
private
  bufferWidth;
  bufferHeight;
  buffer;
  tileIndex;
  tileMap;
begin
  y=0; x=0;
  bufferWidth = tileWidth * mapColumns;
  bufferHeight = tileHeight * (mapRows+1);

  buffer = new_map(bufferWidth, bufferHeight,
    bufferWidth >> 1, bufferHeight >> 1,
    196);

  halfTileWidth = tileWidth >> 1;
  halfTileHeight = tileHeight >> 1;
  for (y = 0; y <= mapRows; y++)
    for (x = 0; x < mapColumns; x++)
      tileIndex = mapColumns * y + x;
      tileMap = tilesPtr[tileIndex];
      map_put(0, buffer, tileMap,
        (x * tileWidth) + halfTileWidth,
        (y * tileHeight) + halfTileHeight);
    end
  end
  return(buffer);
end

