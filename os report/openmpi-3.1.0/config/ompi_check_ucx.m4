# -*- shell-script -*-
#
# Copyright (C) 2015-2017 Mellanox Technologies, Inc.
#                         All rights reserved.
# Copyright (c) 2015      Research Organization for Information Science
#                         and Technology (RIST). All rights reserved.
# Copyright (c) 2016      Los Alamos National Security, LLC. All rights
#                         reserved.
# Copyright (c) 2016 Cisco Systems, Inc.  All rights reserved.
# $COPYRIGHT$
#
# Additional copyrights may follow
#
# $HEADER$
#

# OMPI_CHECK_UCX(prefix, [action-if-found], [action-if-not-found])
# --------------------------------------------------------
# check if UCX support can be found.  sets prefix_{CPPFLAGS,
# LDFLAGS, LIBS} as needed and runs action-if-found if there is
# support, otherwise executes action-if-not-found
AC_DEFUN([OMPI_CHECK_UCX],[
    if test -z "$ompi_check_ucx_happy" ; then
	AC_ARG_WITH([ucx],
		    [AC_HELP_STRING([--with-ucx(=DIR)],
				    [Build with Unified Communication X library support])])
	OPAL_CHECK_WITHDIR([ucx], [$with_ucx], [include/ucp/api/ucp.h])
	AC_ARG_WITH([ucx-libdir],
		    [AC_HELP_STRING([--with-ucx-libdir=DIR],
				    [Search for Unified Communication X libraries in DIR])])
	OPAL_CHECK_WITHDIR([ucx-libdir], [$with_ucx_libdir], [libucp.*])

	AS_IF([test "$with_ucx" != "no"],
              [AS_IF([test ! -z "$with_ucx" && test "$with_ucx" != "yes"],
                     [_x_ac_ucx_dirs="$with_ucx"],
                     [
                        PKG_CHECK_MODULES_STATIC([ucx],[ucx],
                                          [_x_ac_ucx_dirs=`$PKG_CONFIG --variable=prefix ucx`],
                                          [_x_ac_ucx_dirs="/usr /usr/local /opt/ucx"])
                     ])
                for ompi_check_ucx_dir in $_x_ac_ucx_dirs; do
                    AS_IF([test ! -z "$with_ucx_libdir" && test "$with_ucx_libdir" != "yes"],
                          [
                            ompi_check_ucx_libdir="$with_ucx_libdir"
                            ompi_check_ucx_extra_libs="-L$ompi_check_ucx_libdir"
                          ],
                          [AS_IF([test ! -z "$ompi_check_ucx_dir"],
                                 [
                                    ompi_check_ucx_libdir=$ompi_check_ucx_dir/lib
                                    ompi_check_ucx_extra_libs="-L$ompi_check_ucx_libdir"
                                 ])])

                    ompi_check_ucx_$1_save_CPPFLAGS="$CPPFLAGS"
                    ompi_check_ucx_$1_save_LDFLAGS="$LDFLAGS"
                    ompi_check_ucx_$1_save_LIBS="$LIBS"

                    OPAL_CHECK_PACKAGE([ompi_check_ucx],
                                [ucp/api/ucp.h],
                                [ucp],
                                [ucp_cleanup],
                                [$ompi_check_ucx_extra_libs],
                                [$ompi_check_ucx_dir],
                                [$ompi_check_ucx_libdir],
                                [ompi_check_ucx_happy="yes"],
                                [ompi_check_ucx_happy="no"])
                    CPPFLAGS="$ompi_check_ucx_$1_save_CPPFLAGS"
                    LDFLAGS="$ompi_check_ucx_$1_save_LDFLAGS"
                    LIBS="$ompi_check_ucx_$1_save_LIBS"

                    if test "$ompi_check_ucx_happy" = no; then
                        continue
                    fi

                    AC_MSG_CHECKING(for UCX version compatibility)
                    AC_REQUIRE_CPP
                    old_CPPFLAGS="$CPPFLAGS"
                    CPPFLAGS="$CPPFLAGS -I$ompi_check_ucx_dir/include"
                    AC_COMPILE_IFELSE(
                        [AC_LANG_PROGRAM([[#include <uct/api/version.h>]],[[]])],
                        [ompi_ucx_version_ok="yes"],
                        [ompi_ucx_version_ok="no"])

                    AC_MSG_RESULT([$ompi_ucx_version_ok])
                    CPPFLAGS=$old_CPPFLAGS

                    AS_IF([test "$ompi_ucx_version_ok" = "no"], [ompi_check_ucx_happy="no"])

                    if test "$ompi_check_ucx_happy" = yes; then
                        break
                    fi
                done],
            [ompi_check_ucx_happy="no"])

        old_CPPFLAGS="$CPPFLAGS"
        AS_IF([test -n "$ompi_check_ucx_dir"],
              [CPPFLAGS="$CPPFLAGS -I$ompi_check_ucx_dir/include"])
              AC_CHECK_DECLS([ucp_tag_send_nbr],
                             [AC_DEFINE([HAVE_UCP_TAG_SEND_NBR],[1],
                             [have ucp_tag_send_nbr()])], [],
                             [#include <ucp/api/ucp.h>])
        CPPFLAGS=$old_CPPFLAGS

        OPAL_SUMMARY_ADD([[Transports]],[[Open UCX]],[$1],[$ompi_check_ucx_happy])
    fi

    AS_IF([test "$ompi_check_ucx_happy" = "yes"],
          [$1_CPPFLAGS="[$]$1_CPPFLAGS $ompi_check_ucx_CPPFLAGS"
	   $1_LDFLAGS="[$]$1_LDFLAGS $ompi_check_ucx_LDFLAGS"
	   $1_LIBS="[$]$1_LIBS $ompi_check_ucx_LIBS"
	   $2],
          [AS_IF([test ! -z "$with_ucx" && test "$with_ucx" != "no"],
                 [AC_MSG_ERROR([UCX support requested but not found.  Aborting])])
           $3])
])

