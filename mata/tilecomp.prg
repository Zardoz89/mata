COMPILER_OPTIONS _case_sensitive;
// ****************************************************************************
// Matamarcianos con DIV 2 Games Studio para el DivCompo
//
// Tests de tilemaps
//
// https://divcompo.now.sh
// ****************************************************************************

program tilecompo;

const

  // cte. para las rutas
  PATH_USER="zardoz";
  PATH_PROG="mata";

global

local

private
  int tiles[8, 8] =
  // 0    1    2    3    4    5    6    7
    16,  16,   2,  13,  13,  13,  13,  13, // 0
    16,  16,   2,  13,  13,  13,  13,  13, // 1
     4,   4,   9,  13,  13,  13,  13,  13, // 2
    13,  13,  13,  13,  13,  13,  13,  13, // 3
    13,  13,  13,  13,  13,  13,  13,  13, // 4
    13,  13,  13,  13,  13,  13,  13,  13, // 5
    13,  13,  13,  13,  13,  13,  13,  13, // 6
    13,  13,  13,  13,  13,  13,  13,  13, // 7
    13,  13,  13,  13,  13,  13,  13,  13; // 8

  tileMap;
begin
  set_mode(m640x480);
  set_fps(60, 0);
  vsync=1;

  load_fpg(pathResolve("fpg\tilemap.fpg"));

  ctype=c_scroll;
  scroll.camera = id;
  tileMap = drawTiles(offset tiles, 8, 8, 24, 28);
  start_scroll(0, 0, tileMap, 0, 0, 3);

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
  halfTileWidth;
  halfTileHeight;
begin
  bufferWidth = tileWidth * mapColumns;
  bufferHeight = tileHeight * (mapRows + 1);

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

