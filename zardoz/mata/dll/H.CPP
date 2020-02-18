#include "stdio.h"

int main() {
  FILE* ferr = fopen("c:\\csv2.log", "a");
  if (ferr != NULL) {
    fprintf(ferr, "CSV: nElem = %d\n", 10);
    fprintf(ferr, "CSV: offset = %s\n", 0);
    fprintf(ferr, "CSV: fileName = %s\n", "prueba");
    fclose(ferr);
  }
  return 0;
}
