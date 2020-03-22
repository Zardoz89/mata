// Definición de constantes
const o-ship = 0;
const u-ship = 1;
const kamikaze = 2;
const d-ship = 3;
const grey-turret = 4;

const NO_MOVE = -1;

SetScrollSpeed(-5);

WaitTicks(100);
//          x, y, enemyTypeId, movementPatternId
SpawnEnemy( 3240, 35520, kamikaze, 1);
WaitTicks(100);
SpawnEnemy( 3480, 34290, u-ship, 1);
WaitTicks(10);
SpawnEnemy( 2280, 34020, grey-turret, NO_MOVE);

/*
WaitTicks(100);
SpawnEnemy(4, 5, 6, 0);
SpawnEnemyScreenCoords(4, 5, 6, 0);
*/

EndLevel;

