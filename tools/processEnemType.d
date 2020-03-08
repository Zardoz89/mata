#!/usr/bin/rdmd -J .
import process;


enum int[string] constants = mixin(import("animationEnum.txt"));

/**
 * Procesa el CSV de tipos de enemigos
 */
void main(string[] args) {
  processArgs(args, constants);
}
