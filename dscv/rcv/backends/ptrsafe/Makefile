
psa_bindir=$(prefix)/bin
to_inst=psa ptrsafe_calc.rb ptrsafe_data.sql

.PHONY: all
all: psa

install: $(to_inst:%=$(psa_bindir)/%)

$(psa_bindir)/%: %
	@mkdir -p $(@D)
	cp -p $^ $@

ocaml_opt_c  = $(shell if which ocamlopt.opt 2>/dev/null >/dev/null ; then echo ocamlopt.opt; else echo ocamlopt; fi)

psa: main.ml
	$(MAKE) -C ../blast
	$(ocaml_opt_c) -dtypes -I ../blast/blast/include/cil -noassert -ccopt -O3 -c main.ml
	$(ocaml_opt_c) -I ../blast/blast/lib  nums.cmxa str.cmxa unix.cmxa libcil.cmxa main.cmx -o $@ -cc g++ -cclib '-L ../blast/blast/lib -lnums -lstr -lunix -lcaddie-c-part -ldddmp -lcudd -lepd -lutil -lst -lmtr -lperfcount -lstdc++'

