#!/usr/bin/rdmd
import process;

/**
 * Procesa el CSV de tipos de enemigos
 */
void main(string[] args) {
  import std.path : dirName, buildPath;
  import std.file : thisExePath;

  auto basePath = "../tools/"; //dirName(thisExePath());
  int[string] constants = readConstantsFile(buildPath(basePath, "animationEnum.txt"));
  processArgs(args, constants);
}
