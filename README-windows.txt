Windows (CMD.exe) adaptations to Makefile by XmikeX, 26-APRIL-2026.
	- Tested on a MinGW64 suite from https://winlibs.com/

REQUIREMENTS FOR WINDOWS pertinent to this Makefile:
	- CMD.exe from Windows itself.
	- MinGW32 or 64	: https://winlibs.com/ ... other MinGW suites exist as well.
	- ACME				: https://sourceforge.net/projects/acme-crossass/
	- CC1541			: https://bitbucket.org/ptv_claus/cc1541/src/master/
	- EXOMIZER			: https://bitbucket.org/magli143/exomizer.git
	- GNU SORT			: https://www.gnu.org/software/coreutils/

HOW-TO:
1) Acquire/build a fairly-complete MinGW32 or MinGW64 suite.
2) Acquire/build the Executable Utilities ACME, CC1541, EXOMIZER, GNU SORT and set their Executable PATH(s) in the Makefile-win script.
3) MAKE SURE ALL COMMON PATH(s) are SET to MinGW bins prior to engaging Makefile-win!
	-- MinGW suites are usually packaged with a Batch file (.bat) which sets MinGW path(s).
	-- If you do not have global/common/executable path(s) set, you will have to edit desired path(s) in Makefile.win.
4) DO NOT USE SORT.EXE from Windows itself.  Windows SORT is NOT equivalnt to GNU Sort.
5) cd to modplay directory/folder.
6) make -f Makefile-win

Notable Changes from Makefile-Linux
	- addition of WINDISK_IMG assignment to facilitate a deletion directive
	- delete/rmdir/mkdir refactored/resyntaxed to bettr fit the Windows engvironment.
	- hardcoded paths and exception clauses to assist with command refactoring
	- top level /tmp/sub-dirs re-assigned as local subdirs within modplay dir root folder, to better suit a windows user environment
