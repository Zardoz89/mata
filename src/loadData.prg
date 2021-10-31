COMPILER_OPTIONS _case_sensitive, _extended_conditions, _use_cstyle;
// ****************************************************************************
// M.A.T.A.                                    Mobile Assault Tactical Aircraft
//
// Código de lecura de ficheros CSV
// Requiere que se defina previamente una función string pathResolve(string)
// para la resolucion de rutas
// ****************************************************************************

/**
 * Lee un fichero CSV con datos de juego, rellenando un array de Ints o una estructura
 * @param dataFile Nombre del fichero CSV a abrir, sin extensión
 * @param data Puntero al array donde volcar los datos leidos
 * @param size Tamaño del array
 * @return Nº de elementos leidos del CSV
 */
function int loadData(string dataFile, int32* data, int sizeOfArray)
private
  int _retVal = 0;
  string _path;
  string _msg;
begin
  _path = dataFile + ".csv";
  _path = pathResolve(_path);
  _retVal = CSV_ReadToArray(_path, sizeOfArray, data);
  if (_retVal <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
    loop
      // abortamos ejecución
      if (keydown(_q) || keydown(_esc))
        let_me_alone();
        break;
      end

      frame;
    end
  end
  return(_retVal);
end

/**
 * Lee un fichero CSV con datos de juego, rellenando un array de Ints o una estructura
 * @param dataFile Nombre del fichero CSV a abrir, sin extensión
 * @param data Puntero al array donde volcar los datos leidos
 * @param size Tamaño del array
 * @return Nº de elementos leidos del CSV
 */
function int loadData(string dataFile, int16* data, int sizeOfArray)
private
  int _retVal = 0;
  string _path;
  string _msg;
begin
  _path = dataFile + ".csv";
  _path = pathResolve(_path);
  _retVal = CSV_ReadToArray(_path, sizeOfArray, data);
  if (_retVal <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
    loop
      // abortamos ejecución
      if (keydown(_q) || keydown(_esc))
        let_me_alone();
        break;
      end

      frame;
    end
  end
  return(_retVal);
end

/* vim: set ts=2 sw=2 tw=0 et fileencoding=iso8859-1 :*/
