#!/usr/bin/rdmd -J .
import process;


enum int[string] constants = mixin(import("shootDispersionEnum.txt"));

/**
 * Procesa el CSV de tipos de disparo
 */
void main(string[] args) {
  processArgs(args, constants);
}
