# make run MODE=ALWAYS     # ALWAYS_READY 모드로 컴파일 + 실행
# make run MODE=RANDOM     # RANDOM_DELAY 모드로 컴파일 + 실행
# make both                # 두 모드를 연달아 실행
# make wave
# make clean

EXT = ext
#CHK
CHK = $(EXT)/apb-checker
CHK_PKG = $(CHK)/pkg/apb_rules_pkg.sv
CHK_INC = $(CHK)/chk/rules
CHK_SRC = $(wildcard $(CHK)/chk/*.sv)

#SLV
SLV = $(EXT)/apb-slvrtl
SLV_PKG = $(wildcard $(SLV)/pkg/*.sv)
SLV_INC =
SLV_SRC = $(wildcard $(SLV)/rtl/*.sv $(SLV)/ext/*.sv)

#AGT
AGT_PKG = $(wildcard pkg/*.sv)
AGT_INC = tb/env tb/seq/ tb/test src/
AGT_SRC = src/apb_if.sv tb/$(TOP).sv

#----------------------------------------------------------------------
# 허용 모드 목록과 모드별 READY_MODE 값 (enum: RANDOM=0, ALWAYS=1)
ALL_MODES    := ALWAYS RANDOM
READY_ALWAYS := 1
READY_RANDOM := 0

MODE   ?= ALWAYS

#----------------------------------------------------------------------
SHELL    := /bin/bash
ROOT     := $(CURDIR)
TOP      := tb_top
TEST     := base_test
BUILD    := build/$(TEST)_$(MODE)

SNAP   := $(TOP)_snap
SIMLOG := xsim.log

SRCS     := $(CHK_PKG) $(SLV_PKG) $(AGT_PKG) $(CHK_SRC) $(SLV_SRC) $(AGT_SRC)
INCDIRS  := $(CHK_INC) $(AGT_INC)

VLG_OPTS := -sv -L uvm -log xvlog.log
ELP_OPTS := -L uvm -generic_top "READY_MODE=$(READY_$(MODE))" -log xelab_$(MODE).log
SIM_OPTS := -testplusarg UVM_TESTNAME=$(TEST) -R -log $(SIMLOG)

.PHONY: all check compile sim run both clean wave
all: run

# MODE가 목록에 없으면 여기서 중단
check:
	$(if $(filter $(MODE),$(ALL_MODES)),,$(error MODE='$(MODE)' 은 허용되지 않음. 가능한 값: $(ALL_MODES)))

compile: check
	mkdir -p $(BUILD)
	cd $(BUILD) && xvlog $(VLG_OPTS) $(addprefix -i ../../, $(INCDIRS)) $(addprefix ../../,$(SRCS)) # > /dev/null
	cd $(BUILD) && xelab $(ELP_OPTS) -debug typical -s $(SNAP) work.$(TOP) # > /dev/null

sim: check
	@echo Simulation Start, TEST: $(TEST) MODE: $(MODE)
	@cd $(BUILD) && xsim $(SNAP) $(SIM_OPTS) > /dev/null
	@grep -E '\[(PASS|FAIL)\]|MISMATCH|ERROR|RESULT|COVER|DEBUG|INFO' $(BUILD)/$(SIMLOG) || true

run: compile sim

both:
	@for m in $(ALL_MODES); do $(MAKE) --no-print-directory run MODE=$$m || exit 1; done

clean:
	rm -rf $(BUILD)/*

wave:
	gtkwave $(BUILD)/*.vcd &
