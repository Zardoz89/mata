/*****************************************************************************/
/**                 Lector de ficheros CSV para DIV2                        **/
/*****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define GLOBALS
#include "div.h"

void dropBufferFrom(char *buf,char dropCharacter);
void tokenizeLine(char *buf, int offset, int numberOfElements, int *index);
void putValue(const char *token, int offset, int index);

/**
 * Elimina del buf todo el contenido posterior a un caracter si este est?
 * presente
 * @param buf Ptr. al buf
 * @param dropCharacter Caracter a buscar el punto desde donde eliminar
 */
void dropBufferFrom(char *buf,char dropCharacter)
{
  char* position = strchr(buf, dropCharacter);
  if (position != NULL) {
    // Insertamos un caracter nulo en dicha posici�n para "cortar" la cadena por ahi
    *position = 0;
  }
}

/**
 * Tokeniza el buf usando el separador ';' y procesa cada token
 * @param buf Ptr. al buf
 * @param offset Offset del array de Ints de DIV
 * @param numberOfElements N? maximo de elementos del array
 * @param *index Indice del elemento del array a guardar
 */
void tokenizeLine(char *buf, int offset, int numberOfElements, int *index)
{
  const char* token = strtok(buf, ";");
  while (*index < numberOfElements && token != NULL && *token != 0) {
    putValue(token, offset, *index);
    token = strtok(NULL, ";\r\n");
    // El indice lo aumentamos desde aqui para contar solo los tokens validos
    *index = *index + 1;
  }
}

void putValue(const char *token, int offset, int index)
{
  int val = 0;
  if (token != NULL) {
    val = atoi(token);

    // mem es un array de int32_t con toda la memoria del programa DIV
    // si DIV2 esta compactando cuando el tipo del array es byte o word, entonces
    // habra que hacer magia con punteros
    mem[offset + index] = val;
  }
}

// Importante: Para cada funci?n se debe indicar el retval(int), y hacer
// siempre un getparm() por cada par metro de llamada (el retval() es
// imprescindible incluso si la funci?n no necesita devolver un valor).

// Funci�n DIV readCSVToArray(fileName ,offset array, numberOfElements)
void readCSVToIntArray() {
  char* fileName = NULL;
  FILE *file = NULL;
  char buf[256];
  int error = 0;
  int index = 0;

  // Los par�metros se leen en el orden inverso en que se declaran, al
  // provenir del stack del interprete de DIV
  int numberOfElements = getparm();
  int offset = getparm();
  int offsetFileName = getparm();



  //div_text_out("prueba lectura fichero", 0,0);
  // Obtenermos el texto en el array, a partir del bloque de textos + el offset que nos pasa DIV
  fileName = (char *)&mem[text_offset + offsetFileName];

  bzero(buf, sizeof buf); // Datos basura en el buf? No gracias

  errno = 0; // Limpiamos errno
  file = div_fopen(fileName, "r");
  if (file != NULL) {
    /*while (index < numberOfElements ) { //&& fgets(buf, 255, file ) != NULL) {
      //dropBufferFrom(buf, '\r');
      //dropBufferFrom(buf, '\n'); // Purgar fin de linea CRLF o LF
      //dropBufferFrom(buf, '#'); // Comentarios
      //tokenizeLine(buf, offset, numberOfElements, &index);
      index++;
    }*/
  }
  div_fclose(file);

  error = (int) errno;
  retval(error);
}

void __export divlibrary(LIBRARY_PARAMS) {
  // Nombre en DIV, ptr a funci�n, n� de par�metros
  COM_export("readCSVToIntArray", readCSVToIntArray, 3);
}

void __export divmain(COMMON_PARAMS) {
  GLOBAL_IMPORT();
}
/* vim: set ts=2 sw=2 tw=0 et :*/
