GEMIX_COMPILER_PATH := /opt/gemix/
GEMIX_COMPILER := ./gmxc-linux-x86
EXE_PATH := $(CURDIR)/exe
TOOLS_PATH := tools
SHOOTS_TYPE_PROCESSOR := $(TOOLS_PATH)/processShoots.d
ENEMY_TYPE_PROCESSOR := $(TOOLS_PATH)/processEnemType.d
LEVEL_PROCESSOR := $(TOOLS_PATH)/levelcompiler

all: tools exeFolder datfiles tests mata

exeFolder: ${EXE_PATH}/created.txt

${EXE_PATH}/created.txt:
	mkdir -p ${EXE_PATH}
	cd ${EXE_PATH}
	ln -s ${CURDIR}/dat || true
	ln -s ${CURDIR}/fpg || true
	ln -s ${CURDIR}/fnt || true
	ln -s ${CURDIR}/mus || true
	ln -s ${CURDIR}/snd || true
	ln -s ${CURDIR}/pal || true
	touch ${EXE_PATH}/created.txt

tests: tiletest

tiletest: test/tiletest.prg src/*.prg
	cd ${GEMIX_COMPILER_PATH} && ${GEMIX_COMPILER} ${CURDIR}/$< $@
	mv ${GEMIX_COMPILER_PATH}$@* ${EXE_PATH}

mata: mata.prg src/*.prg
	cd ${GEMIX_COMPILER_PATH} && ${GEMIX_COMPILER} ${CURDIR}/$< $@
	mv ${GEMIX_COMPILER_PATH}$@* ${EXE_PATH}

tools: $(LEVEL_PROCESSOR)

datfiles: dat/shoots.csv dat/enemtype.csv dat/movpaths.csv lvl/level_01/commands.dat

dat/shoots.csv : datsrc/shoots.csv
	$(SHOOTS_TYPE_PROCESSOR) -i $< -o $@

dat/enemtype.csv : datsrc/enemtype.csv
	$(ENEMY_TYPE_PROCESSOR) -i $< -o $@

dat/movpaths.csv : datsrc/movpaths.csv
	cp $< $@

lvl/level_01/commands.dat : lvl/level_01/commands.lpr
	$(LEVEL_PROCESSOR) -i $< -o $@

tools: $(LEVEL_PROCESSOR)

$(LEVEL_PROCESSOR) : $(TOOLS_PATH)/compiler.d $(TOOLS_PATH)/lprGrammar.d $(TOOLS_PATH)/process.d
	cd $(TOOLS_PATH) ; dub build

clean :
	rm dat/shoots.csv
	rm dat/enemtype.csv
	rm dat/movpaths.csv
	rm lvl/level_01/commands.dat
	rm exe/tiletest*
	rm exe/mata*

.PHONY: all exeFolder tools datfiles tests clean

