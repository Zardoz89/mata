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
const RIGHT_V20PX = 16;
const LEFT_V20PX = 18;


// ****************************************************************************
SetScrollSpeed(-5);

WaitScroll(33500);
//          x, y, enemyTypeId, movementPatternId, number, patternId
SpawnEnemyGroup( 1320, 33480 - 840, U-SHIP, DOWN_V20PX, 4, 0);
SpawnEnemyGroup( 4920, 33480 - 840, U-SHIP, DOWN_V20PX, 4, 0);

WaitScroll(33150);
DefineEnemyGroup {
  SetBonusType(1); // Bonus laser
  SpawnEnemy( 3000, 32900, U-SHIP, DOWN_V20PX);
  SpawnEnemy( 3240, 32620, U-SHIP, 6);
  SpawnEnemy( 2760, 32620, U-SHIP, 13);
}

WaitScroll(30750);
//          x, y, enemyTypeId, movementPatternId
SpawnEnemy( 4678, 30661, GREY-TURRET, NO_MOVE);
SpawnEnemy( 5878, 30661, GREY-TURRET, NO_MOVE);

WaitScroll(29200);
SpawnEnemyGroup( 1800, 28696 - 1680 , KAMIKAZE, DOWN_V20PX, 6, 0);

WaitScroll(28900);
SpawnEnemy( 360, 28410, BROWN-TURRET, NO_MOVE);
DefineEnemyGroup {
  SetBonusType(0); // Bonus vulcan
  SpawnEnemy( 4440, 28145, GREY-TURRET, NO_MOVE);
  SpawnEnemy( 5880, 28145, GREY-TURRET, NO_MOVE);
  SpawnEnemy( 4440, 27305, GREY-TURRET, NO_MOVE);
  SpawnEnemy( 5880, 27305, GREY-TURRET, NO_MOVE);
}

WaitScroll(25400);
SpawnEnemyGroup( 2040, 25346 - 1680 , KAMIKAZE, 20, 6, 0);

WaitScroll(26200);
SpawnEnemy( 2510, 26170, BROWN-TURRET, NO_MOVE);
SpawnEnemy( 4200, 25065, GREY-TURRET, NO_MOVE);
SpawnEnemy( 4440, 25065, GREY-TURRET, NO_MOVE);

// Naves cruzando los pilares
WaitScroll(23200);
SpawnEnemyGroup( 0 - 480, 23380, U-SHIP, RIGHT_V20PX, 4, 1);
SpawnEnemyGroup( 5880 + 480, 23380, U-SHIP, LEFT_V20PX, 4, 1);

WaitScroll(21500);
SpawnEnemy( 3470, 21410, BROWN-TURRET, NO_MOVE);

WaitScroll(20110);
SpawnEnemy( 110, 20010, BROWN-TURRET, NO_MOVE);

EndLevel;

