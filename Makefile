#!/usr/bin/make -f
# Set environment variables

# this makefile follows the below conventions for variables denoting files and directories
# all directory names must end with a terminal '/' character
# file names never end in terminal '/' character


#===================================================

SHELL = /bin/bash

# set this variable to any value to make shared libraries (cleaning existing build files may be necessary)
SHARED =

#===================================================
# Compile commands
#===================================================
CC       = gcc
CLIBS    =
CFLAGS   = -g -O -Wall
ifdef SHARED
CFLAGS  += -fpic -pie
endif
AR       = ar
ARFLAGS  = crs
#===================================================
# Build Directories
#===================================================
override srcdir     = src/
override buildir    = build/
#libtardir and libdirname has no effect!
libdirname = libs
libtardir  = $(buildir)$(libdirname)/
#===================================================
# Install directories
#===================================================
prefix      = /usr/local/
exec_prefix = $(prefix)
bindir      = $(exec_prefix)/bin/
datarootdir = $(prefix)/share/
datadir     = $(datarootdir)
libdir      = $(prefix)/lib/
DESTDIR     =
#===================================================
prog_name = main.out
#===================================================
override INSTALL          = install -D -p
override INSTALL_PROGRAM  = $(INSTALL) -m 755
override INSTALL_DATA     = $(INSTALL) -m 644
#===================================================
# Source and target objects
#===================================================
SRCS      = $(wildcard $(srcdir)*/*.c)
DIRS      = $(addprefix $(buildir),$(subst $(srcdir),,$(SRCDIRS)))
SRCDIRS   = $(sort $(dir $(SRCS)))
OBJS      = $(patsubst %.c,%.o,$(addprefix $(buildir),$(subst $(srcdir),,$(SRCS))))
MKS       = $(patsubst %.c,%.mk,$(addprefix $(buildir),$(subst $(srcdir),,$(SRCS))))
ifndef SHARED
LIBS      = $(addprefix $(buildir),$(addsuffix .a,$(addprefix lib,$(subst /,,$(subst $(buildir),,$(DIRS))))))
else
LIBS      = $(addprefix $(buildir),$(addsuffix .so,$(addprefix lib,$(subst /,,$(subst $(buildir),,$(DIRS))))))
endif
LIBCONFS  = $(addsuffix lib-dep-conf.mk,$(SRCDIRS))
-include $(LIBCONFS)
#=====================================================

build: $(LIBS)
.PHONY:build

.DEFUALT_GOAL:build

install: install-libs install-bin
.PHONY: install

install-libs: build
	@for file in $(addprefix $(DESTDIR)$(libdir),$(notdir $(LIBS))); do \
		[ -f "$$file" ] && { echo -e "\e[31mError\e[32m $$file exists Defualt behavior is not to overwrite...\e[0m Terminating..."; exit 23; } || true; \
	done
ifndef SHARED
	$(INSTALL_DATA) $(LIBS) -t $(DESTDIR)$(libdir)
else
	$(INSTALL_PROGRAM) $(LIBS) -t $(DESTDIR)$(libdir)
endif
.PHONY: install

install-bin: test
	@[ -f "$(DESTDIR)$(bindir)$(prog_name)" ] && { echo -e "\e[31mError\e[32m $$file exists Defualt behavior is not to overwrite...\e[0m Terminating..."; exit 24; } || true
	$(INSTALL_PROGRAM) $(buildir)$(prog_name) -t $(DESTDIR)$(bindir)
.PHONY:install-bin

debug:
	@echo -e "\e[35mBuild Directories \e[0m: $(DIRS)"
	@echo -e "\e[35mSource Directories\e[0m: $(SRCDIRS)"
	@echo -e "\e[35mLibdepconf Files  \e[0m: $(LIBCONFS)"
	@echo -e "\e[35mBuild Files       \e[0m: $(LIBS)"
	@echo    "#-------------------------------------------#"
	@echo -e "\e[35mSource Files     \e[0m: $(SRCS)"
	@echo -e "\e[35mMake Files       \e[0m: $(MKS)"
	@echo -e "\e[35mObject Files     \e[0m: $(OBJS)"
.PHONY:debug

help:
	@echo "The follwing targets may be given..."
	@echo -e "\t...install"
	@echo -e "\t...install-bin"
	@echo -e "\t...install-libs"
	@echo -e "\t...build*"
	@echo -e "\t...test"
	@echo -e "\t...uninstall"
	@echo -e "\t...uninstall-bin"
	@echo -e "\t...uninstall-libs"
	@echo -e "\t...clean"
	@echo -e "\t...clean-all"
	@echo "Other options"
	@echo -e "\t...debug"
	@echo -e "\t...help"
	@echo -e "\t...generate-config-files"
	@echo -e "\t...remove-config-files"
.PHONY: help

test: $(buildir)$(prog_name)
.PHONY:test

build-obj: $(OBJS)
.PHONY:build-obj

-include $(srcdir)libconfig.mk
#=====================================================

$(buildir)$(prog_name) : $(LIBS) $(srcdir)main.c
ifndef SHARED
	$(CC) $(CFLAGS) -o $@ $(INCLUDES) $(srcdir)main.c $(if $(CLIBS), $(CLIBS) $(sort $(CLIBS_DEP)), -L./$(buildir) $(addprefix -l,$(patsubst $(buildir)lib%.a,%,$(LIBS))) $(sort $(CLIBS_DEP)))
else
	$(CC) $(CFLAGS) -o $@ $(INCLUDES) -Wl,-rpath="$(buildir)"  $(srcdir)main.c $(if $(CLIBS), $(CLIBS), -L./$(buildir) $(addprefix -l,$(patsubst $(buildir)lib%.so,%,$(LIBS))))
endif

$(buildir)%.mk : $(srcdir)%.c
	@mkdir -p $(@D)
	@$(CC) -M $< | awk '{ if(/^$(subst .mk,,$(@F))/) { printf("%s%s\n","$(@D)/",$$0) } else { print $$0 } } END { printf("\t$(CC) $(CFLAGS) $(INCLUDES_$(subst /,,$(dir $*))) -c -o $(buildir)$*.o $<\n\ttouch $(@D)/timestamp")}' > $@
	@echo -e "\e[32mCreating Makefile \"$@\"\e[0m..."

ifneq ($(strip $(filter build build-obj test install install-bin install-libs install $(buildir)$(prog_name) $(LIBS) $(OBJS),$(MAKECMDGOALS))),)
include $(MKS)
else ifeq ($(MAKECMDGOALS),)
include $(MKS)
endif

ifndef SHARED
lib%.a: %/timestamp | $(buildir)
	$(AR) $(ARFLAGS) $@ $(filter $*/%.o,$(OBJS)) $(if $(CLIBS_$(notdir $*)),-l"$(strip $(CLIBS_$(notdir $*)))")
else
lib%.so: %/timestamp | $(buildir)
	$(CC) $(subst -pie -fpic,,$(CFLAGS)) --shared $(filter $*/%.o,$(OBJS)) $(strip $(CLIBS_$(notdir $*))) -o $@
endif

%/timestamp: $(buildir) ;

.SECONDARY: $(addsuffix timestamp,$(DIRS))

$(buildir): build-obj ;

#=====================================================

hash = \#

clean:
	rm -rf $(buildir)
.PHONY:clean

clean-all:clean remove-config-files
.PHONY:clean-all

#use with caution!
uninstall-libs:
	rm -f $(addprefix $(DESTDIR)$(libdir),$(notdir $(LIBS)))
.PHONY:uninstall-libs

#use with caution!
uninstall-bin:
	rm -f $(DESTDIR)$(bindir)$(prog_name)
.PHONY:uninstall-bin

#use with caution!
uninstall:uninstall-bin uninstall-libs
.PHONY:uninstall

generate-config-files: generate-libdependancy-config-files generate-testlibconf-file
.PHONY:generate-config-files

remove-config-files: remove-libdependancy-config-files remove-testlibconf-file
.PHONY:remove-config-files

generate-testlibconf-file:
ifndef SHARED
	@echo -e "$(hash)!/usr/bin/make -f"\
	"\n$(hash) Make config file for linker options, do not rename."\
	"\n$(hash) The value of the variable must be LIBS_<libname>, where the libname is the stem of lib*.a, for it to be read by the makefile."\
	"\nCLIBS = -L./$(buildir) $(addprefix -l,$(patsubst $(buildir)lib%.a,%,$(LIBS)))"\
	"\nINCLUDES =" > "$(srcdir)libconfig.mk"
else
	@echo -e "$(hash)!/usr/bin/make -f"\
	"\n$(hash) Make config file for linker options, do not rename."\
	"\n$(hash) The value of the variable must be LIBS_<libname>, where the libname is the stem of lib*.a, for it to be read by the makefile."\
	"\nCLIBS = -L./$(buildir) $(addprefix -l,$(patsubst $(buildir)lib%.so,%,$(LIBS)))"\
	"\nINCLUDES =" > "$(srcdir)libconfig.mk"
endif
.PHONY:generate-testlibconf-file

remove-testlibconf-file:
	rm -f $(srcdir)libconfig.mk
.PHONY:generate-testlibconf-file

generate-libdependancy-config-files:
	@for file in $(LIBCONFS); do \
		stem="$${file%/*}" ; \
		stem="$${stem//$(srcdir)/}" ; \
		stem="$${stem//\//}" ; \
		echo -e "$(hash)!/usr/bin/make -f"\
		"\n$(hash) Make config file for linker options, do not rename."\
		"\n$(hash) The value of the variable must be LIBS_<libname>, where the libname is the stem of lib*.a, for it to be read by the makefile."\
		"\nCLIBS_$${stem} ="\
		"\nINCLUDES_$${stem} ="\
		"\nCLIBS_DEP += \$$(filter-out \$$(CLIBS),\$$(CLIBS_$${stem}))\n" > "$$file"; \
	done
.PHONY:generate-libdependancy-config-files

remove-libdependancy-config-files:
	rm -f $(LIBCONFS)
.PHONY:remove-libdependancy-config-files
