// Definición de constantes
// **** Tipos de enemigos
const O-SHIP = 0;
const U-SHIP = 1;
const KAMIKAZE = 2;
const D-SHIP = 3;
const GREY-TURRET = 4;
const BROWN-TURRET = 5;

// **** Patrones movimiento
const NO_MOVE = -1;
const DOWN_V20PX = 14;


// ****************************************************************************
SetScrollSpeed(-5);

//          x, y, enemyTypeId, movementPatternId, number, patternId
SpawnEnemyGroup( 1320, 34310, U-SHIP, DOWN_V20PX, 4, 0);
SpawnEnemyGroup( 4920, 34310, U-SHIP, DOWN_V20PX, 4, 0);

WaitScroll(33150);
DefineEnemyGroup {
  SetBonusType(1); // Bonus laser
  SpawnEnemy( 3000, 32900, U-SHIP, DOWN_V20PX);
  SpawnEnemy( 3240, 32620, U-SHIP, 6);
  SpawnEnemy( 2760, 32620, U-SHIP, DOWN_V20PX);
}

WaitScroll(30750);
//          x, y, enemyTypeId, movementPatternId
SpawnEnemy( 4678, 30661, GREY-TURRET, NO_MOVE);
SpawnEnemy( 5878, 30661, GREY-TURRET, NO_MOVE);

WaitScroll(28900);
SpawnEnemyGroup( 1800, 28696, KAMIKAZE, DOWN_V20PX, 6, 0);
SpawnEnemy( 360, 28410, BROWN-TURRET, NO_MOVE);
DefineEnemyGroup {
  SetBonusType(0); // Bonus vulcan
  SpawnEnemy( 4440, 28145, GREY-TURRET, NO_MOVE);
  SpawnEnemy( 5880, 28145, GREY-TURRET, NO_MOVE);
  SpawnEnemy( 4440, 27305, GREY-TURRET, NO_MOVE);
  SpawnEnemy( 5880, 27305, GREY-TURRET, NO_MOVE);
}


EndLevel;

