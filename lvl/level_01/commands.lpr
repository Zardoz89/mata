// Definición de constantes
const o-ship = 0;
const u-ship = 1;
const kamikaze = 2;
const d-ship = 3;
const grey-turret = 4;

const NO_MOVE = -1;

SetScrollSpeed(-5);

//          x, y, enemyTypeId, movementPatternId
SpawnEnemy( 3240, 35150, kamikaze, 14);

WaitScroll(34440);
SpawnEnemyGroup( 3480, 34290, u-ship, 14, 7, 1);
SpawnEnemy( 2280, 34020, grey-turret, NO_MOVE);

WaitScroll(33150);
DefineEnemyGroup {
  SpawnEnemy( 3480, 32900, u-ship, 14);
  SpawnEnemy( 3720, 32620, u-ship, 6);
  SpawnEnemy( 3240, 32620, u-ship, 13);
}


EndLevel;

