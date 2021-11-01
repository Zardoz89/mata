COMPILER_OPTIONS _case_sensitive, _extended_conditions, _use_cstyle;
// ****************************************************************************
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// Código para la generación de tilemaps
// ****************************************************************************

const
  // Cte. referentes al tilemap
  TILE_WIDTH=24;
  TILE_HEIGHT=28;

/**
 * Crea el buffer de tilemap
 * @param mapRows Nº de filas del tilemap
 * @param mapColumns Nº de columnas del tilemap
 * @param tileWidth Ancho de una tesela
 * @param tileHeight Alto de una tesela
 * @param keyColor Indice del color de transparencia
 */
function createTileBuffer(int mapRows, int mapColumns, int tileWidth, int tileHeight, uint32 keyColor)
private
  int bufferWidth;
  int bufferHeight;
  int buffer;
begin
  bufferWidth = tileWidth * mapColumns;
  bufferHeight = tileHeight * mapRows;
  //buffer = map_new(bufferHeight, bufferWidth, keyColor);
  //buffer = map_new(bufferHeight, bufferWidth, 
  //bufferWidth >> 1, bufferHeight >> 1, // 0, 0
  //keyColor);
  buffer = new_map(bufferWidth, bufferHeight,
    bufferWidth >> 1, bufferHeight >> 1, // 0, 0
    keyColor); // Color de transparencia
  return(buffer);
end


/**
 * Pinta un tilemap grande en un buffer
 */
function drawTiles(int buffer, int16* tilesPtr, int mapColumns, int mapRows, int tileWidth, int tileHeight)
private
  int tileIndex;
  int tileMap; // Grafico del tilemap a pintar
  int halfTileWidth; // Centro X del tilemap
  int halfTileHeight; // Centro Y del tilemap
  int putY; // Temporal para sacar calculo de Y en el buffer al pintar, del bucle mas interior
begin
  halfTileWidth = tileWidth / 2;
  halfTileHeight = tileHeight / 2;

  for (y = 0; y < mapRows; y++)
    putY = (y * tileHeight) + halfTileHeight;
    for (x = 0; x < mapColumns; x++)
      tileIndex = mapColumns * y + x;
      tileMap = tilesPtr[tileIndex];
      tileMap = max(tileMap, 1);
      map_put(0, buffer, tileMap, (x * tileWidth) + halfTileWidth, putY);
    end
  end
end

/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1 :*/
