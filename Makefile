OCAMLOPT=ocamlopt.opt
OCAMLFLAGS= -w +a-4-42-40-9-48 -warn-error +a -bin-annot -I +compiler-libs -I src -I tests
OCAMLDEP=ocamldep.opt
%.cmi : %.mli
	$(OCAMLOPT) $(OCAMLFLAGS) -c $<
%.cmx : %.ml
	$(OCAMLOPT) $(OCAMLFLAGS) -c $<
include .depend
.PHONY: depend
depend:
	$(OCAMLDEP) -native -I tests -I src src/*.ml src/*.mli tests/*.ml tests/*.mli > .depend

FILES = \
	src/napkin_io.cmx\
	src/napkin_minibuffer.cmx\
	src/napkin_doc.cmx\
	src/napkin_character_codes.cmx\
	src/napkin_comment.cmx\
	src/napkin_token.cmx\
	src/napkin_grammar.cmx\
	src/napkin_reporting.cmx\
	src/napkin_diagnostics.cmx\
	src/napkin_parsetree_viewer.cmx\
	src/napkin_parens.cmx\
	src/napkin_comments_table.cmx\
	src/napkin_printer.cmx\
	src/napkin_scanner.cmx\
	src/napkin_js_ffi.cmx\
	src/napkin_parser.cmx\
	src/napkin_core.cmx\
	src/napkin_driver.cmx \
	src/napkin_ast_conversion.cmx \
	src/napkin_driver_ml_parser.cmx \
	src/napkin_driver_reason_binary.cmx \
	src/napkin_driver_binary.cmx \
	src/napkin_ast_debugger.cmx \
	src/napkin_outcome_printer.cmx \
	src/napkin_multi_printer.cmx

TEST_FILES = \
	tests/napkin_diff.cmx

.DEFAULT_GOAL := build-native
build-native: lib/refmt.exe $(FILES) src/napkin_cli.cmx depend
	$(OCAMLOPT) $(OCAMLFLAGS) -O2 -o ./lib/napkinscript.exe -I +compiler-libs ocamlcommon.cmxa  -I src $(FILES) src/napkin_cli.cmx

bootstrap: build-native
	ocaml unix.cma ./scripts/bspack.ml -bs-main Napkin_cli -I src -o ./lib/napkinscript.ml
	./lib/napkinscript.exe -parse ml -print ns ./lib/Napkinscript.ml > ./lib/Napkinscript2.ml
	$(OCAMLOPT) -w a -pp "./lib/napkinscript.exe" -O2 -o ./lib/napkinscript2.exe -I +compiler-libs ocamlcommon.cmxa -I lib ./lib/Napkinscript2.ml
	mv ./lib/napkinscript2.exe ./lib/napkinscript.exe

lib/refmt.exe: vendor/refmt_main3.ml
	$(OCAMLOPT) -w a -O2 -I vendor -I +compiler-libs ocamlcommon.cmxa -o lib/refmt.exe vendor/refmt_main3.ml

bench: lib/bench.exe
	./lib/bench.exe

lib/bench.exe: benchmarks/refmt_main3b.cmx benchmarks/Benchmark.ml $(FILES)
	$(OCAMLOPT) $(OCAMLFLAGS) -O2 -o ./lib/bench.exe -bin-annot -I +compiler-libs ocamlcommon.cmxa benchmarks/mac_osx_time.c -I benchmarks -I src $(FILES) benchmarks/refmt_main3b.cmx benchmarks/Benchmark.ml

benchmarks/refmt_main3b.cmx: benchmarks/refmt_main3b.ml
	$(OCAMLOPT) -c -O2 -I +compiler-libs ocamlcommon.cmxa benchmarks/refmt_main3b.ml

lib/test.exe: $(TEST_FILES) tests/napkin_test.cmx depend
	$(OCAMLOPT) $(OCAMLFLAGS) -O2 -o ./lib/test.exe -bin-annot -I +compiler-libs ocamlcommon.cmxa -I src -I tests $(FILES) $(TEST_FILES) tests/napkin_test.cmx

test: build-native lib/test.exe
	./node_modules/.bin/reanalyze -all-cmt . -suppress tests
	./node_modules/.bin/jest
	./lib/test.exe

roundtrip-test: bootstrap lib/test.exe
	./node_modules/.bin/reanalyze -all-cmt . -suppress tests
	ROUNDTRIP_TEST=1 ./node_modules/.bin/jest
	./lib/test.exe

reanalyze: build-native lib/test.exe
	./node_modules/.bin/reanalyze -all-cmt . -suppress tests

clean:
	rm -rf src/*.cm*
	rm -rf src/*.o
	rm -rf tests/*.cm*
	rm -rf tests/*.o
	rm -rf benchmarks/*.cm*
	rm -rf benchmarks/*.o
	rm -rf lib/bench.exe
	rm -rf lib/napkinscript.exe
	rm -rf tests/test.exe
	git clean -dfx src
.PHONY: clean test roundtrip-test termination dce exception reanalyze bootstrap build-native
