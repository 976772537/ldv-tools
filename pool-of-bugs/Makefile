#!/bin/bash

bindir = $(prefix)/bin
ppob_dir = $(prefix)/pool-of-bugs
scripts = scripts
db_schema = ppob_db_schema.sql

# Phony targets.
.PHONY: all install test clean

# Default make action.
all:
	@echo The Public Pool of Bugs \(re\)generator doesn\'t require compilation

# Install needed executables to specified path.
install:
	mkdir -p $(bindir)
	cp ${scripts}/* $(bindir)
	mkdir -p $(ppob_dir)
	cp $(db_schema) $(ppob_dir)/$(db_schema)
test:
	@echo The Public Pool of Bugs \(re\)generator doesn\'t have any test

clean:
	@echo The Public Pool of Bugs \(re\)generator doesn\'t require cleaning 
