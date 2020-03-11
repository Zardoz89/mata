#!/usr/bin/rdmd
import process;

/**
 * Procesa el CSV de tipos de disparo
 */
void main(string[] args) {
  import std.path : dirName, buildPath;
  import std.file : thisExePath;

  auto basePath = "../tools/"; //dirName(thisExePath());
  int[string] constants = readConstantsFile(buildPath(basePath, "shootDispersionEnum.txt"));
  processArgs(args, constants);
}
