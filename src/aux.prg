COMPILER_OPTIONS _case_sensitive, _extended_conditions, _use_cstyle;
// ****************************************************************************
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// Código para la carga y gestión de niveles
// ****************************************************************************

/**
 * Extiende el signo de un valor word a int
 */
function int sWordToInt(int val)
begin
 if (val >= 32768)
   val = val | 4294901760;
 end
 return(val);
end


/**
 * Proceso que muestra informacion de debug como los FPS
 */
process debugText()
private
  string _msgFps;
  string _msgScrollXY;
  string _msgPlayerXY;
  string _msgMWeapon;
begin
  loop
    _msgFps = "FPS: " + itoa(fps);
    write(0, 640, 0, 2, _msgFps);

    _msgScrollXY = "scrollX: " + itoa(scroll[0].x0) + " scrollY: " + itoa(scroll[0].y0);
    write(0, 640, 15, 5, _msgScrollXY);

    _msgPlayerXY = "x: " + itoa(player.sId.x) + " y: " + itoa(player.sId.y);
    write(0, 640, 25, 5, _msgPlayerXY);

    _msgMWeapon = "w: " + itoa(player.mainWeapon.weapon) + " t: " + itoa(player.mainWeapon.tier);
    write(0, 640, 45, 5, _msgMWeapon);


    frame(3000); // Actualiza a 2 FPS
  end
end


/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1 :*/
