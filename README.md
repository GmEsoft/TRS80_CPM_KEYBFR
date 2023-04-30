TRS80_CPM_KEYBFR
================

**French AZERTY keyboard driver for Montezuma Micro CP/M on TRS-80 Model 4/4p**

This driver allows the users of a TRS-80 Model 4/4p with an AZERTY keyboard
to easily use the MM CP/M operating system without having to remember the
QWERTY keyboard layout.


To build the driver (instructions for Windows)
----------------------------------------------

For a Montezuma Micro CP/M v2.2 system with BIOS version 2.22, build `kbfr222`.

For a Montezuma Micro CP/M v2.2 system with BIOS version 2.30+, build `kbfr230`.

The source files are located in the folder `keybfr`.

You'll need to first copy `zmac.exe` from [George Phillips](http://48k.ca/zmac.html) 
into the subfolder `keybfr\zmac`.

Then, depending on your CP/M version, run `a_kbfr222.bat` or `a_kbfr230.bat`.

This will create the driver binary file `KBFR222.COM` or `KBFR230.COM`.

Copy or transfer the binary file to a copy of your CP/M system diskette.

Then insert the CP/M diskette into the TRS-80 drive A: and boot the system.


To install the driver
---------------------

On CP/M 2.22 type `KBFR222` followed by `<ENTER>`. On CP/M 2.30+ type `KBFR230` followed by `<ENTER>`.
This will load and activate the AZERTY keyboard driver. This driver doesn't take additional
memory, as it directly patches the BIOS.

It is possible to SYSGEN the driver so it is immediatly loaded at boot time. To do this 
(replace `nnn` with either `222` or `230` depending on your CP/M version):
- type `KBFRnnn *`: this will load the driver and prepare it for a SYSGEN;
- type `SYSGEN` and follow the instructions to re-write the system to the disk in drive A:.
```
A>KBFR222
French keyboard driver 1.00
for BIOS rel. 2.22
Ready for "SYSGEN"
A>SYSGEN
```
In SYSGEN type `<ENTER>` `A` `<ENTER>` `<ENTER>`.

When the system is rebooted, the welcome message looks shorter (because we needed to borrow 
some bytes from the welcome message in the BIOS for the AZERTY keyboard translation):
```
64k CP/M 2.2
BIOS r2.22Fr (c)'84 MM/JBO
```

To restore the original CP/M BIOS with the QWERTY driver, issue the following commands:
```
A>MOVCPM 64 *
CONSTRUCTING 64k CP/M vers 2.2
READY FOR "SYSGEN' OR
"SAVE 44 CPM64.COM"
A>SYSGEN
```
In SYSGEN type `<ENTER>` `A` `<ENTER>` `<ENTER>`.


Additional notes
----------------

1.	The AZERTY keyboard layout is somewhat different from the layout in TRSDOS/LS-DOS. CP/M
	is unable to handle accented characters because it is limited to 7-bit ASCII.
	So the accented characters **&eacute;**, **&egrave;**, **&agrave;**, **&ccedil;**, **&sect;** and **SHIFT-&uml;** are replaced respectly with
	**[**, **]**, **\`**, **^**, **#** and **~**. Also the keys **^** and **&uml;** are no 'dead keys'. The `CLEAR` key generates ESC (0x1B) and 
	`SHIFT`-`CLEAR` clears the command line. `CTRL`-`CLEAR` generates DEL (0x7F).

2.	The AZERTY keyboard driver can be SYSGENed to a bootable CP/M hard disk. Just add it as the first command in the HDBOOT.SUB file:
	```
	KBFR230
	EXBIOS
	CPMFIX
	HDRS15M H0=AB H1=CD F=EFGH
	```
