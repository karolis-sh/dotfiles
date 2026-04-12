SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help install install-brew install-shell install-git

help:
	@printf '%s\n' \
		'Usage: make [install|install-brew|install-shell|install-git]' \
		'' \
		'Targets:' \
		'  install  Install everything' \
		'  install-brew   Install Homebrew packages' \
		'  install-shell  Install shell config' \
		'  install-git    Install git config'

install:
	./install.sh all

install-brew:
	./install.sh brew

install-shell:
	./install.sh shell

install-git:
	./install.sh git
