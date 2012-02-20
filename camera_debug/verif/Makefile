###########################
#          Tools          #
###########################
#! warning require iverilog git repositry version
COMPILER    = iverilog
SIM_ENGINE  = vvp
VIEWER      = gtkwave
COVERAGE    = covered score
LINT        = verilator -Wall --lint-only --error-limit 1000 -D_LINT_WAIVED_

###########################
#       Test Bench        #
###########################
TOP        ?= top
BENCH      ?= ${VERIF_DIR}/TestBench/test_${TOP}.v
EXTRA      ?= 
DEFINE     ?= -DD=1
RTL_FILES   = $(shell cat RTL.list|sed 's/\n/ /g')
RTL_FILES_COV = $(addprefix -v , ${RTL_FILES})

###########################
#  Compile & Simulation   #
###########################
compile      : ${BENCH} ${EXTRA} ${RTL_FILES}
	${COMPILER} -g2005 -Wall -t vvp ${DEFINE} -s test_${TOP} -o run.vvp -f RTL.list ${BENCH} ${EXTRA} 

sim          : compile
	${SIM_ENGINE} run.vvp

all          : sim

view         :
	${VIEWER} test_${TOP}.vcd


coverage     :
	${COVERAGE} -vcd test_${TOP}.vcd -t ${TOP} ${RTL_FILES_COV}

lint         :
	${LINT} ${RTL_FILES}

clean        :
	@rm -f *.vvp
