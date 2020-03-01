M.A.T.A. (Mobile Assault Tactical Aircraft)
==========================================

Matamarcianos en un mes usando DIV Games Studio 2 para la [DIV Compo 2020](https://divcompo.now.sh/)

## Lore

Año 2274

La Tierra, después de salir de la era oscura, ha vuelto a recuperar en gran
medida el nivel tecnológico que tenia antes de la Gran Crisis y la Tercera
Guerra Mundial. El mundo actual, esta dividido entre ciudades estado, señores de
la guerra que controlan las regiones desoladas por la Tercera Guerra Mundial y
algún que otro estado con aspiraciones de imperio mundial.

Una de las reliquias tecnológicas de la Tercera Guerra Mundial, son los
vehículos móviles de asalto táctico "Mobile Assault Tactical Aircraft" o
"M.A.T.A." . En manos de un experimentado piloto, pueden destruir todo un
ejercito o cambiar el curso de una guerra.

Todo esto es caldo de cultivo perfecto para que un mercenario haga su carrera,
ofreciendo sus dotes de piloto en un M.A.T.A.



## ¿Qué es DIV Games Studio?

Un IDE para desarrollar juegos MS-DOS 2d y falso 3d que salio a finales de los 90.
El lenguaje, interpretado, tiene una mezcla de pascal y C bastante curiosa, amen de usar
fuertemente corutinas para hacer que cada "proceso" se ejecuté de forma paralela.
Tal como está orientado, se presta muy fácilmente a la creación de juegos 2d.

El IDE para la época estaba muy avanzado. Aparte de un entorno de edición de
código con soporte de múltiples ventanas o bufferes, incluye un editor de
gráficos, ficheros FPG (empaqueta gráficos), editor de sonido, editor de
paletas, e incluso un generador de explosiones.

## Inspiración para el matamarcianos

Para esto me influencia bastante estos juegos :

* [Tyrian](http://shorturl.at/mqS79) (probablemente el *mejor* de su genero)
* [Raptor: Call of the shadows](https://es.wikipedia.org/wiki/Raptor:_Call_of_the_Shadows<Paste>)
* [Major Striker](https://es.wikipedia.org/wiki/William_Stryker)
* [19XX The war against destiny](https://en.wikipedia.org/wiki/19XX:_The_War_Against_Destiny)

## Antes de lanzarlo desde DIV2...

El repositorio usa submodulos para las DLLs que usa para extender DIV, con lo
que es importante ejecutar esto después de hacer un clone del repositorio :

```bash
git submodule init
git submodule update
```

## Roadmap

- [ ] Refamiliazar con el lenguaje y el entorno, improvisando algunos conceptos
    de un matamarcianos.
    - [x] Movimiento de un sprite placeholder
    - [x] Disparos usando un arma asignada
    - [x] Control de colisión básico
    - [x] Patrón de movimiento de enemigo
    - [x] Tipos de arma y dispersión de armas
    - [x] Animaciones de enemigos y disparos enemigos
    - [x] Generador de oleadas de enemigos
    - [x] Regiones y zona de juego
    - [x] Items para cambiar/mejorar el arma
    - [x] Tilemap de fondo de pantalla
    - [x] Mecánica de movimiento del scroll de fondo
    - [x] Barra de salud, escudos y energía
    - [x] Mecánica de regeneración escudos, energía y consumo de energía
    - [x] Efecto explosiones y escudos
    - [x] Arma principal
    - [ ] (WIP) Arma secundaria
    - [x] Pantalla de carga inicial
    - [ ] Pantalla de carga y menú
    - [ ] (WIP) Niveles
    - [ ] Gestión efectos sonido
    - [ ] Música
- [ ] Refinar el prototipo hacia un diseño mas elaborado
- [x] Librería DLL para extender el lenguaje y poder cargar datos de un fichero
    CSV. La idea es tener tablas en ficheros editables de texto con las
    características de las armas, enemigos, patrones de movimiento, oleadas y
    tilemaps.
- [x] Ponerle un nombre en condiciones
- [x] Un poco de lore...


## Recursos usados

### Gráficos

- https://lostgarden.home.blog/2007/04/05/free-game-graphics-tyrian-ships-and-tiles/

### Audio

- DeathFlash.flac (CC-BY 3.0) : https://opengameart.org/content/big-explosion
- Chunky Explosion (CC0) : https://opengameart.org/content/chunky-explosion
- Assault Rifle (CC-BY-SA 3.0) : https://opengameart.org/content/futuristic-weapons-assault-rifle

### Música

- State of war Xtd : https://www.youtube.com/watch?v=JPTvkg-NxNo&t=3393s

