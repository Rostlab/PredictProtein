#!/bin/sh
#
# pvmgetarch.sh
#
# Generate PVM architecture string.
#
# This is a heuristic thing that may need to be tuned from time
# to time.  I don't know of a real solution to determining the
# machine type.  Claims to pick one of:
#   AFX8, ALPHA, ALPHAMP, BFLY, BSD386, CM2, CM5, CNVX, CNVXN,
#   CRAY, CRAY2, CRAYSMP, DGAV, E88K, HP300, HPPA, I860, KSR1, LINUX,
#   MASPAR, MIPS, NEXT, PGON, PMAX, POWER4, RS6K, RT, SGI, SGI5, SGIMP,
#   SUN2, SUN3, SUN4, SUN4SOL2, SUNMP, SX3, SYMM, TITN, UVAX, VAX,
#   UNKNOWN
# Need to do:
#   BAL, CSPP, IPSC2, VCM2
#
# Notes:
#   1. Local people mess with things.
#   2. It's good to try a few things for robustness.
#
# 08 Apr 1993  Robert Manchek  manchek@CS.UTK.EDU.
# 24 Aug 1994  last revision
#

#
# begin section that may need to be tuned.
#
ARCH=UNKNOWN

if [ -f /bin/uname -o -f /usr/bin/uname ]; then
	if [ -f /bin/uname ]; then
		os="`/bin/uname -s`"
		ht="`/bin/uname -m`"
	else
		os="`/usr/bin/uname -s`"
		ht="`/usr/bin/uname -m`"
	fi

	case "$os,$ht" in
	SunOS,sun3* )           ARCH=SUN3 ;;
	SunOS,sun4* )           ARCH=SUN4 ;;
	ULTRIX,RISC )           ARCH=PMAX ;;
	ULTRIX,VAX )            ARCH=UVAX ;;
	AIX*,* )                ARCH=RS6K ;;
	*HP*,9000/[2345]* )     ARCH=HP300 ;;
	*HP*,9000/[78]* )       ARCH=HPPA ;;
	IRIX,* )                ARCH=SGI ;;
	*,alpha )               ARCH=ALPHA ;;
	CRSOS,smp )             ARCH=CRAYSMP ;;
	*,paragon )             ARCH=PGON ;;
	dgux,AViiON )           ARCH=DGAV ;;
	*,88k )                 ARCH=E88K ;;
	*,mips )                ARCH=MIPS ;;
	*,CRAY-2 )              ARCH=CRAY2 ;;
	Linux,i[345]86 )        ARCH=LINUX ;;
	SUPER-UX,SX-3 )         ARCH=SX3 ;;
	esac
fi

if [ "$ARCH" = UNKNOWN ]; then
	if [ -f /bin/arch ]; then
		case "`/bin/arch`" in
		ksr1 ) ARCH=KSR1 ;;
		sun2 ) ARCH=SUN2 ;;
		sun3 ) ARCH=SUN3 ;;
		sun4 ) ARCH=SUN4 ;;
		esac
	fi
fi

if [ "$ARCH" = UNKNOWN ]; then

	if [ -f /ultrixboot ]; then
		if [ -f /pcs750.bin ]; then
			ARCH=UVAX
		else
			ARCH=PMAX
		fi
	else
		if [ -f /pcs750.bin ]; then ARCH=VAX; fi
	fi

	if [ -d /usr/alliant ]; then ARCH=AFX8; fi
	if [ -f /usr/bin/cluster ]; then ARCH=BFLY; fi
	if [ -d /usr/convex ]; then ARCH=CNVX; fi
	if [ -f /unicos ]; then ARCH=CRAY; fi
	if [ -f /hp-ux ]; then ARCH=HP300; fi
	if [ -f /usr/bin/getcube ]; then ARCH=I860; fi
	if [ -f /usr/bin/asm56000 ]; then ARCH=NEXT; fi
	if [ -f /etc/vg ]; then ARCH=RS6K; fi
	if [ -d /usr/include/caif ]; then ARCH=RT; fi
	if [ -f /bin/4d ]; then ARCH=SGI; fi
	if [ -f /dynix ]; then ARCH=SYMM; fi
	if [ -f /bin/titan ]; then ARCH=TITN; fi

	if [ -f /usr/bin/machine ]; then
		case "`/usr/bin/machine`" in
		i386 ) ARCH=BSD386 ;;
		esac
	fi
	if [ -f /usr/bin/uxpm ] && /usr/bin/uxpm ; then
		ARCH=UXPM
	fi
fi

if [ "$ARCH" = UNKNOWN ]; then
	if [ -f /bin/uname -o -f /usr/bin/uname ]; then
		if [ -f /bin/uname ]; then
			os="`/bin/uname -s`"
			ht="`/bin/uname -m`"
		else
			os="`/usr/bin/uname -s`"
			ht="`/usr/bin/uname -m`"
		fi

		case "$os,$ht" in
		*,i[345]86 )            ARCH=SCO ;;
		esac
	fi
fi

if [ "$ARCH" = SUN4 ]; then
	rel="`/bin/uname -r`"
	case "$rel" in
	5.* )   ARCH=SUN4SOL2 ;;
	esac
fi
if [ "$ARCH" = SUN4SOL2 ]; then
	nproc="`/bin/mpstat | wc -l`"
	if [ $nproc -gt 2 ]; then ARCH=SUNMP; fi
fi
if [ "$ARCH" = ALPHA ]; then
	rel="`/usr/bin/uname -r`"
	case "$rel" in
	*3.*)
		nproc="`/usr/sbin/sizer -p`"
		if [ $nproc -gt 1 ]; then ARCH=ALPHAMP; fi ;;
	esac
fi
if [ "$ARCH" = SGI ]; then
	rel="`/bin/uname -r`"
	case "$rel" in
	5.* )   ARCH=SGI5 ;;
	6.* )   ARCH=SGI64 ;;
	esac
fi
# --------------------------------------------------
# xx br changed for 32 bit machines
if [ "$ARCH" = SGI64 ]; then
	rel="`/bin/uname -m`"
	case "$rel" in
	IP32 )   ARCH=SGI32 ;;
	esac
fi
# xx end br changed for 32 bit machines
# --------------------------------------------------
if [ "$ARCH" = SGI64 ]; then
	nproc="`mpadmin -n | wc -w`"
	if [ $nproc -gt 1 -a "$SGIMP" = ON ]; then ARCH=SGIMP64; fi
fi
if [ "$ARCH" = SGI5 ]; then
	nproc="`mpadmin -n | wc -w`"
	if [ $nproc -gt 1 -a "$SGIMP" = ON ]; then ARCH=SGIMP; fi
fi
if [ "$ARCH" = SUN4 -a -f /dev/cm ]; then ARCH=CM2; fi
if [ "$ARCH" = SUN4 -a -f /dev/cmni ]; then ARCH=CM5; fi
if [ "$ARCH" = CNVX ]; then
	if /usr/convex/getsysinfo -f native_default; then
		ARCH=CNVXN
	fi
fi
if [ "$ARCH" = PMAX -a -d /usr/maspar ]; then ARCH=MASPAR; fi
if [ "$ARCH" = RS6K -a -d /usr/lpp/power4 ]; then ARCH=POWER4; fi

#
# ugh, done.
#

echo $ARCH
exit

