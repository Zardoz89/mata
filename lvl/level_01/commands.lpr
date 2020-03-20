const o-ship = 0;
const u-ship = 1;
const kamikaze = 2;
const d-ship = 3;
const grey-turret = 4;

const NO_MOVE = -1;

WaitTicks(100);
//          x, y, enemyTypeId, movementPatternId
SpawnEnemy( 4240, 33466, grey-turret, NO_MOVE); // Foobar2000
WaitTicks(100);
SpawnEnemy( 4240, 33430, u-ship, 1);  // Foobar

//WaitTicks(100);
//SpawnEnemy(4, 5, 6, 0);
//SpawnEnemyScreenCoords(4, 5, 6, 0);

EndLevel;

