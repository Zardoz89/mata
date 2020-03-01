all: csv.dll .SYMBOLIC

csv_dbg.dll: csv.cpp csv.h myint.h div.h .SYMBOLIC
	wcl386 csv.cpp -ox -zp4 -5 -s -dCSV_DEBUG=1 -l=div_dll

csv.dll: csv.cpp csv.h myint.h div.h
#	wcl386 csv.cpp -ox -s -l=div_dll
	wcl386 csv.cpp -ox -zp4 -5 -s -l=div_dll

.SILENT
clean: .SYMBOLIC
	-del *.err
	-del *.dll
	-del *.obj

install: csv.dll .SYMBOLIC
	copy csv.dll c:\div2\

#  vim: set ts=4 sw=4 tw=0 noet fileencoding=cp858 :
