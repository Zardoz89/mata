#!/usr/bin/rdmd
import process;

/**
 * Procesa el CSV de tipos de disparo
 */
void main(string[] args) {
  import std.path : dirName, buildPath;
  import std.file : thisExePath;

  auto basePath = "./tools/"; //dirName(thisExePath());
  int[string] constants = readConstantsFile(buildPath(basePath, "shootDispersionEnum.txt"));
  auto fileStreams = processArgs(args);
  processFile(fileStreams["fin"], fileStreams["fout"], constants);
}
