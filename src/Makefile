lint:
	verilator --lint-only -DSIM -Wall -Wno-DECLFILENAME -Wno-MULTITOP *.v

formal_prove:
	sby -f formal_prove.sby

formal_live:
	sby -f formal_live.sby

formal_cover:
	sby -f formal_cover.sby

formal:
	sby -f formal.sby

all: lint formal_prove formal_live formal_cover