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
  PLAYFIELD_REGION=1; // Region de la zona de juego
  PLAYFIELD_REGION_W=492;
  PLAYFIELD_REGION_H=448; // 28px * 16

  TILE_WIDTH=24;
  TILE_HEIGHT=28;
  TILEMAP_COLUMNS=25;
  TILEMAP_ROWS=145;//26;
  TILEMAP_MAX_X= 600; //TILEMAP_COLUMNS * TILEMAP_WIDTH - playfield_region_w;
  TILEMAP_MAX_Y= 4060; //768; //TILEMAP_ROWS * TILEMAP_HEIGHT;


global

local
scrollY = 0;
scrollX = 0;

private
  int pointer tiles;
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

  tileMap;
begin
  set_mode(m640x480);
  set_fps(60, 0);
  vsync=1;

  load_fpg("fpg\\TILEMAP.FPG");

  define_region(PLAYFIELD_REGION, 0, 0, PLAYFIELD_REGION_W, PLAYFIELD_REGION_H);

  debugText();

  tiles = malloc((TILEMAP_ROWS+1) * TILEMAP_COLUMNS);
  loadData("lvl\\level_01\\tilemap", tiles, (TILEMAP_ROWS+1) * TILEMAP_COLUMNS);

  tileMap = createTileBuffer(TILEMAP_COLUMNS, TILE_WIDTH, PLAYFIELD_REGION_H);
  backgroundScroll(tileMap, tiles);

  loop
    if (key(_q))
      let_me_alone();
      break;
    end

    frame;
  end
  free(tiles);
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

/**
 * Lee un fichero CSV con datos de juego
 */
function loadData(dataFile, _offset, _size)
private
  int _retVal = 0;
  string _path;
  string _msg;
begin
  _path = dataFile + ".csv";
  // Efectivamente rellena un array de structs
  // La razon es que internamente DIV usa un array gigante para todas las variables
  _retVal = CSV_ReadToArray(_path, _size, _offset);
  if (_retVal <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
    loop
      // abortamos ejecuci¢n
      if (key(_q) || key(_esc))
        let_me_alone();
        break;
      end

      frame;
    end
  end
  return(_retVal);
end


function createTileBuffer(mapColumns, tileWidth, regionHeight)
private
  bufferWidth;
  buffer;
begin
  bufferWidth = tileWidth * mapColumns;

  buffer = new_map(bufferWidth, regionHeight,
    0, 0,//bufferWidth >> 1, regionHeight >> 1,
    196);
  return(buffer);
end


process backgroundScroll(graph, int pointer tilesPtr)
private
  oldScrollX;
  oldScrollY;
begin
  file = 0;
  region = PLAYFIELD_REGION;
  z = 512;
  scrollY = TILEMAP_MAX_Y - PLAYFIELD_REGION_H;

  oldScrollX = scrollX;
  oldScrollY = scrollY;


  drawTiles(graph, tilesPtr, TILEMAP_COLUMNS, TILEMAP_ROWS, TILE_WIDTH, TILE_HEIGHT, 0, 0);
  loop
    scrollX = clamp(mouse.x, 0, TILEMAP_MAX_X - PLAYFIELD_REGION_W);
    scrollY = clamp(scrollY - 1, 0, TILEMAP_MAX_Y - PLAYFIELD_REGION_H);
    if (scrollX <> oldScrollX || scrollY <> oldScrollY)
      drawTiles(graph, tilesPtr, TILEMAP_COLUMNS, TILEMAP_ROWS, TILE_WIDTH, TILE_HEIGHT, scrollX, scrollY);
    end
    oldScrollX = scrollX;
    oldScrollY = scrollY;

    frame(200);
  end

end

function clamp(val, minVal, maxVal)
begin
  if (val > maxVal)
    return(maxVal);
  end
  if (val < minVal)
    return(minVal);
  end
  return(val);
end

function max(val, maxVal)
begin
  if (val < maxVal)
    return(maxVal);
  end
  return(val);
end


/**
 * Pinta un tilemap grande en un buffer
 *
 *
 * El funcionamiento es el siguiente, determina las filas y columnas que van a estar dentro del buffer de destino
 * a partir de inputX e inputY como desplazamientos.
 * Recorre el array multidimensional del tileMap, pero solamente las parte visibles y las pinta en el buffer de destino
 */
function drawTiles(buffer, int pointer tilesPtr, mapColumns, mapRows, tileWidth, tileHeight, inputX, inputY)
private
  tileIndex;
  tileMap; // Grafico del tilemap a pintar
  halfTileWidth; // Centro X del tilemap
  halfTileHeight; // Centro Y del tilemap
  x0; // Primera columna que se va a pintar
  y0; // Primera fila que se va a pintar
  xMax; // Ultima columna que se va a pintar
  yMax; // Ultima fila que se va a pintar
  putY; // Temporal para sacar calculo de Y en el buffer al pintar, del bucle mas interior
begin
  y=0; x=0;
  x0 = inputX / tileWidth;
  y0 = inputY / tileHeight;
  xMax = clamp(((inputX + PLAYFIELD_REGION_W) / tileWidth) + 1, 0, mapColumns);
  yMax = clamp(((inputY + PLAYFIELD_REGION_H) / tileHeight) + 1, 0, mapRows);
  halfTileWidth = tileWidth >> 1;
  halfTileHeight = tileHeight >> 1;

  for (y = y0; y <= (mapRows); y++)
    putY = (y * tileHeight) + halfTileHeight - inputY;
    for (x = x0 ; x < xMax; x++)
      tileIndex = mapColumns * y + x;
      tileMap = tilesPtr[tileIndex];
      tileMap = max(tileMap, 1);
      map_put(0, buffer, tileMap, (x * tileWidth) + halfTileWidth - inputX, putY);
    end
  end
end

/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1 :*/
