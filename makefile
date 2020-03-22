TOOLS_PATH := tools
SHOOTS_TYPE_PROCESSOR := $(TOOLS_PATH)/processShoots.d
ENEMY_TYPE_PROCESSOR := $(TOOLS_PATH)/processEnemType.d
LEVEL_PROCESSOR := $(TOOLS_PATH)/levelcompiler

all: dat/shoots.csv dat/enemtype.csv lvl/level_01/commands.dat

tools: $(LEVEL_PROCESSOR)

$(LEVEL_PROCESSOR) : $(TOOLS_PATH)/compiler.d $(TOOLS_PATH)/lprGrammar.d $(TOOLS_PATH)/process.d
	cd $(TOOLS_PATH) ; dub build

dat/shoots.csv : datsrc/shoots.csv
	$(SHOOTS_TYPE_PROCESSOR) -i $< -o $@

dat/enemtype.csv : datsrc/enemtype.csv
	$(ENEMY_TYPE_PROCESSOR) -i $< -o $@

lvl/level_01/commands.dat : lvl/level_01/commands.lpr
	$(LEVEL_PROCESSOR) -i $< -o $@

clean :
	rm dat/shoots.csv
	rm dat/enemtype.csv
	rm lvl/level_01/*.dat

.PHONY: all tools clean

