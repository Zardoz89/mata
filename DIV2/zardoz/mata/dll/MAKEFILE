all: csv.dll .SYMBOLIC

csv.dll: csv.cpp csv.h div.h
	wcl386 csv.cpp -ox -s -l=div_dll

.SILENT
clean: .SYMBOLIC
	-del csv.err
	-del csv.dll
	-del csv.obj

install: csv.dll .SYMBOLIC
	copy csv.dll c:\div2\
