EXTRA_DIST= 

INCLUDES =                                              \
	@FUSE_CFLAGS@	                                \
	-I. 						\
	-I$(srcdir) -I$(top_srcdir) 			\
	-I$(top_builddir)				\
        -I$(includedir)                                 \
	@XML4C_CFLAGS@                                  \
	@LIBFUSELAGE_CFLAGS@                            \
	@LIBPOPT_CFLAGS@                                \
	-I/usr/local/include                            

bin_PROGRAMS = cafe

cachefs_SOURCES = cafe.cpp
cachefs_CPPFLAGS = -DFUSE_USE_VERSION=25 $(FUSE_CFLAGS)
cachefs_LDADD = $(FUSE_LIBS) @XML4C_LIBS@  @LIBFUSELAGE_LIBS@ @LIBPOPT_LIBS@

