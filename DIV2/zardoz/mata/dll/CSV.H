/*****************************************************************************/
/**                 Lector de ficheros CSV para DIV2                        **/
/*****************************************************************************/

#ifndef __CSV_H_
#define __CSV_H_

// Descomentar est  linea para activar el modo debug de la DLL
//#define CSV_DEBUG 1

#ifdef CSV_DEBUG
#define CSV_LOG_FILE "csv.log"

#define INIT_LOG() FILE* ferr = NULL
#define OPEN_LOG() ferr = div_fopen(CSV_LOG_FILE, "w")
#define LPRINT(STR) \
  if (ferr != NULL) { \
    fprintf(ferr, STR); \
  }
#define LPRINTF(STR, VAL) \
  if (ferr != NULL) { \
    fprintf(ferr, STR, VAL); \
  }
#define CLOSE_LOG() \
  if (ferr != NULL) { \
    div_fclose(ferr); \
  }

#else

#define INIT_LOG()  
#define OPEN_LOG()  
#define LPRINT(STR)  
#define LPRINTF(STR, VAL)  
#define CLOSE_LOG()  
#endif


#endif
