/*****************************************************************************/
/**                 Lector de ficheros CSV para DIV2                        **/
/**                                                                         **/
/**              Macros para la generación del log de CSV                   **/
/*****************************************************************************/

#ifndef __CSV_H_
#define __CSV_H_

#ifdef CSV_DEBUG
#define CSV_LOG_FILE "csv.log"

#define INIT_LOG() FILE* ferr = NULL
#define OPEN_LOG() ferr = div_fopen(CSV_LOG_FILE, "a")
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
/* vim: set ts=2 sw=2 tw=0 et fileencoding=cp858 :*/
