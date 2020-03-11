TOOLS_PATH := ../tools
SHOOTS_TYPE_PROCESSOR := $(TOOLS_PATH)/processShoots.d
ENEMY_TYPE_PROCESSOR := $(TOOLS_PATH)/processEnemType.d

all: dat/shoots.csv dat/enemtype.csv 
.PHONY: all clean

dat/shoots.csv : datsrc/shoots.csv
	$(SHOOTS_TYPE_PROCESSOR) $< $@ 

dat/enemtype.csv : datsrc/enemtype.csv
	$(ENEMY_TYPE_PROCESSOR) $< $@ 

clean :
	rm dat/shoots.csv
	rm dat/enemtype.csv


