SHELL := /bin/bash

VERSION := $(strip $(shell cat VERSION))
BUILD_DIR := build
DIST_DIR := dist
PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man
DOCDIR ?= $(PREFIX)/share/doc/mkscript
BUILD_BIN := $(BUILD_DIR)/bin/mkscript

.PHONY: all build clean install lint package package-deb package-deb-source package-rpm release-artifacts test

all: build

build: $(BUILD_BIN)

$(BUILD_BIN): src/mkscript.sh.in VERSION scripts/render.sh
	mkdir -p $(@D)
	VERSION='$(VERSION)' ./scripts/render.sh src/mkscript.sh.in $@
	chmod 755 $@

test: build
	MKSCRIPT_UNDER_TEST='$(CURDIR)/$(BUILD_BIN)' VERSION='$(VERSION)' ./test/test_mkscript.sh

lint:
	shellcheck src/mkscript.sh.in scripts/*.sh test/test_mkscript.sh

install: build
	mkdir -p $(DESTDIR)$(BINDIR) $(DESTDIR)$(MANDIR)/man1 $(DESTDIR)$(DOCDIR)
	install -m 0755 $(BUILD_BIN) $(DESTDIR)$(BINDIR)/mkscript
	install -m 0644 mkscript.1 $(DESTDIR)$(MANDIR)/man1/mkscript.1
	install -m 0644 README.md $(DESTDIR)$(DOCDIR)/README.md
	install -m 0644 LICENSE $(DESTDIR)$(DOCDIR)/LICENSE

package-deb:
	./scripts/build-deb-docker.sh

package-deb-source:
	ALLOW_UNSIGNED=1 ./scripts/build-deb-source.sh

package-rpm:
	./scripts/build-rpm-docker.sh

package: release-artifacts

release-artifacts:
	./scripts/build-release-artifacts.sh

clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)
