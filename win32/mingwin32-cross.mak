# GNU MAKE Makefile for PDCurses library - WIN32 MinGW GCC
#
# Usage: make -f [path\]mingwin32.mak [DEBUG=Y] [DLL=Y] [WIDE=Y] [UTF8=Y] [tgt]
#
# where tgt can be any of:
# [all|demos|libpdcurses.a|testcurs.exe...]
#
# Set environment variables to change build tools
#   CC, AR, STRIP
#

O = o

STRIP = strip

mkfile_path := $(dir $(firstword $(MAKEFILE_LIST)))
ifndef PDCURSES_SRCDIR
	PDCURSES_SRCDIR = $(mkfile_path)..
endif

include $(PDCURSES_SRCDIR)/version.mif
include $(PDCURSES_SRCDIR)/libobjs.mif

osdir		= $(PDCURSES_SRCDIR)/win32

PDCURSES_WIN_H	= $(osdir)/pdcwin.h

ifeq ($(DEBUG),Y)
	override CFLAGS  += -g -Wall -DPDCDEBUG
	override LDFLAGS += -g
else
	override CFLAGS  += -O2 -Wall
	override LDFLAGS +=
endif

override CFLAGS += -I$(PDCURSES_SRCDIR)

BASEDEF		= $(PDCURSES_SRCDIR)/exp-base.def
WIDEDEF		= $(PDCURSES_SRCDIR)/exp-wide.def

DEFDEPS		= $(BASEDEF)

ifeq ($(WIDE),Y)
	override CFLAGS += -DPDC_WIDE
	DEFDEPS += $(WIDEDEF)
endif

ifeq ($(UTF8),Y)
	override CFLAGS += -DPDC_FORCE_UTF8
endif

DEFFILE		= pdcurses.def


ifeq ($(DLL),Y)
	override CFLAGS += -DPDC_DLL_BUILD
	LIBEXE = ${CC} $(DEFFILE)
	LIBFLAGS = -Wl,--out-implib,libpdcurses.a -shared -o
	LIBCURSES = pdcurses.dll
	LIBDEPS = $(LIBOBJS) $(PDCOBJS) $(DEFFILE)
	CLEAN = $(LIBCURSES) *.a $(DEFFILE)
else
	LIBEXE = ${AR}
	LIBFLAGS = rcv
	LIBCURSES = libpdcurses.a
	LIBDEPS = $(LIBOBJS) $(PDCOBJS)
	CLEAN = *.a
endif

.PHONY: all libs clean demos dist

all:	libs demos

libs:	$(LIBCURSES)

install: install-headers install-libs

install-headers:
	install -d $(PREFIX)/include/
	install -m 0644 $(PDCURSES_SRCDIR)/curses.h $(PREFIX)/include/
	install -m 0644 $(PDCURSES_SRCDIR)/term.h $(PREFIX)/include/
	install -m 0644 $(PDCURSES_SRCDIR)/panel.h $(PREFIX)/include/

install-libs: libs
	install -d $(PREFIX)/lib/
	install -m 0644 $(LIBCURSES) $(PREFIX)/lib/

clean:
	-rm *.o
	-rm *.exe
	-rm $(CLEAN)

demos:	$(DEMOS)
	${STRIP} *.exe

$(DEFFILE): $(DEFDEPS)
	echo LIBRARY pdcurses > $@
	echo EXPORTS >> $@
	cat $(BASEDEF) >> $@
ifeq ($(WIDE),Y)
	cat $(WIDEDEF) >> $@
endif

$(LIBCURSES) : $(LIBDEPS)
	$(LIBEXE) $(LIBFLAGS) $@ $?
	-cp libpdcurses.a libpanel.a

$(LIBOBJS) $(PDCOBJS) : $(PDCURSES_HEADERS)
$(PDCOBJS) : $(PDCURSES_WIN_H)
$(DEMOS) : $(PDCURSES_CURSES_H) $(LIBCURSES)
panel.o : $(PANEL_HEADER)
terminfo.o: $(TERM_HEADER)

$(LIBOBJS) : %.o: $(srcdir)/%.c
	$(CC) -c $(CFLAGS) $<

$(PDCOBJS) : %.o: $(osdir)/%.c
	$(CC) -c $(CFLAGS) $<

firework.exe newdemo.exe rain.exe testcurs.exe worm.exe xmas.exe \
ptest.exe: %.exe: $(demodir)/%.c
	$(CC) $(CFLAGS) -o$@ $< $(LIBCURSES)

tuidemo.exe: tuidemo.o tui.o
	$(CC) $(LDFLAGS) -o$@ tuidemo.o tui.o $(LIBCURSES)

tui.o: $(demodir)/tui.c $(demodir)/tui.h $(PDCURSES_CURSES_H)
	$(CC) -c $(CFLAGS) -I$(demodir) -o$@ $<

tuidemo.o: $(demodir)/tuidemo.c $(PDCURSES_CURSES_H)
	$(CC) -c $(CFLAGS) -I$(demodir) -o$@ $<

PLATFORM1 = MinGW Win32
PLATFORM2 = MinGW for Win32
ARCNAME = pdc$(VER)_ming_w32

include $(PDCURSES_SRCDIR)/makedist.mif
