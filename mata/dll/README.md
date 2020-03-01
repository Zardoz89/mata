DLL para lectura de ficheros CSV simples
----------------------------------------

Esta DLL implementa funciones para parsear ficheros CSV, donde se utiliza el
carácter ';' como elemento separador, y solo contienen valores numéricos. El
carácter '#' marca que el resto de la linea se ignore, siendo útil para agregar
comentarios en los ficheros.

## Como compilar

Se requiere Watcom C 10.6 instalado en un entorno DOS (dosbox, dosemu, maquina virtual
o instalación nativa de MS-DOS/PC-DOS/DR-DOS, FreeDOS o OpenDOS).

Para compilar, usar el make2.bat como si fuese el comando make :

```
make2 all
```

Se puede generar una versión de _debug_ del DLL que genera un fichero CSV.LOG
con información de los CSV que se leen. **En cada invocación o ejecución, se
concatena nuevo contenido al fichero de log.**

## Funciones implementadas

`INT readCSVToIntArray(STRING fileName, OFFSET offset, INT numberOfElements)`

Lee un fichero CSV en la ruta dada por la cadena *fileName*, y guarda los
valores en el array u estructura apuntadas por el offset. Leerá una cantidad
máxima de elementos dados por numberOfElements. El valor retornado por la
función es la cantidad de elementos leídos o -1 en caso de error.
Si offset es 0, entonces no guardará ningún valor en ningún sitio, limitandose
a devolver la cantidad de elementos que hay en el fichero CSV.

## Ejemplo de uso

Uso típico:

```div2
/**
 * Genera la ruta relativa a los ficheros del juego
 */
function pathResolve(file)
begin
  return (/* "\foo\bar\" + */ file);
end

/**
 * Lee un fichero CSV con datos de juego
 */
function loadData(dataFile, _offset, size)
private
  string _path;
  int _retVal = 0;
  string _msg;
begin
  _path = pathResolve(_path);
  _retVal = readCSVToIntArray(_path, _offset, size);
  if (_retVal <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
    loop
      // abortamos ejecución
      if (key(_q) || key(_esc))
        let_me_alone();
        break;
      end

      frame;
    end
  end
  return(_retVal);
end

...

loadData("dat\mydata.dat", offset myArray, sizeof(myArray));
```

Determinar la cantidad de elementos en un fichero antes de cargar el contenido:

```div2
/**
 * Función que carga el contenido de un fichero CSV en un array dinamico
 (generado por malloc)
 * Devuelve un puntero al array dinamico
 */
function loadAndAllocateData(dataFile)
private
  string _path;
  int _retVal = 0;
  int _nElements = 0;
  string _msg;
  int pointer _data;
begin
  _path = pathResolve(_path);
  _nElements = readCSVToIntArray(_path, 0, int_max);
  if (_nElements <= 0)
    _msg = "Error al abrir fichero de datos: " + _path;
    write(0, 0, 0, 0, _msg);
    loop
      // abortamos ejecución
      if (key(_q) || key(_esc))
        let_me_alone();
        break;
      end

      frame;
    end
  end
  _data = malloc(_nElements);
  readCSVToIntArray(_path, _data, _nElements);
  return(_data);
end
```

