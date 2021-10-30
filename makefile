GEMIX_COMPILER_PATH := /opt/gemix/
GEMIX_COMPILER := ./gmxc-linux-x86
EXE_PATH := $(CURDIR)/exe/
TOOLS_PATH := tools
SHOOTS_TYPE_PROCESSOR := $(TOOLS_PATH)/processShoots.d
ENEMY_TYPE_PROCESSOR := $(TOOLS_PATH)/processEnemType.d
LEVEL_PROCESSOR := $(TOOLS_PATH)/levelcompiler

all: tiletest dat/*.csv lvl/level_01/commands.dat

tiletest: tiletest.prg src/*.prg
	cd ${GEMIX_COMPILER_PATH} && ${GEMIX_COMPILER} ${CURDIR}/$< $@
	mv ${GEMIX_COMPILER_PATH}$@* ${EXE_PATH}

tools: $(LEVEL_PROCESSOR)

$(LEVEL_PROCESSOR) : $(TOOLS_PATH)/compiler.d $(TOOLS_PATH)/lprGrammar.d $(TOOLS_PATH)/process.d
	cd $(TOOLS_PATH) ; dub build

dat/shoots.csv : datsrc/shoots.csv
	$(SHOOTS_TYPE_PROCESSOR) -i $< -o $@

dat/enemtype.csv : datsrc/enemtype.csv
	$(ENEMY_TYPE_PROCESSOR) -i $< -o $@

dat/movpaths.csv : datsrc/movpaths.csv
	cp $< $@

lvl/level_01/commands.dat : lvl/level_01/commands.lpr
	$(LEVEL_PROCESSOR) -i $< -o $@

clean :
	rm dat/shoots.csv
	rm dat/enemtype.csv
	rm lvl/level_01/*.dat
	rm exe/tiletest*

.PHONY: all tools clean

