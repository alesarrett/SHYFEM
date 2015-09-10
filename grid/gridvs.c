
/* $Id: gridvs.c,v 1.24 2009-04-21 10:24:42 georg Exp $ */

/************************************************************************\
 *									*
 * gridvs.c - version description of grid                               *
 *									*
 * Copyright (c) 1992-2009 by Georg Umgiesser				*
 *									*
 * Permission to use, copy, modify, and distribute this software	*
 * and its documentation for any purpose and without fee is hereby	*
 * granted, provided that the above copyright notice appear in all	*
 * copies and that both that copyright notice and this permission	*
 * notice appear in supporting documentation.				*
 *									*
 * This file is provided AS IS with no warranties of any kind.		*
 * The author shall have no liability with respect to the		*
 * infringement of copyrights, trade secrets or any patents by		*
 * this file or any part thereof.  In no event will the author		*
 * be liable for any lost revenue or profits or other special,		*
 * indirect and consequential damages.					*
 *									*
 * Comments and additions should be sent to the author:			*
 *									*
 *			Georg Umgiesser					*
 *			ISMAR-CNR                                       *
 *			S. Polo 1364					*
 *			30125 Venezia					*
 *			Italy						*
 *									*
 *			Tel.   : ++39-041-5216875			*
 *			Fax    : ++39-041-2602340			*
 *			E-Mail : georg.umgiesser@ismar.cnr.it		*
 *									*
 * Revision History:							*
 * 21-Apr-2009: version 3.10                                            *
 * 13-Feb-2009: version 3.09                                            *
 * 14-Jan-2009: version 3.07                                            *
 * 03-Nov-2008: version 3.06                                            *
 * 11-Oct-2004: version 3.05                                            *
 * 24-Sep-2004: version 3.04                                            *
 * 19-Aug-2003: version 3.03                                            *
 * 13-Mar-2003: version 3.02                                            *
 * 07-May-1998: version 3.01                                            *
 * 02-Apr-1998: version 3.00                                            *
 * 30-Mar-1998: version 2.44                                            *
 * 13-Feb-1998: version 2.43                                            *
 * 12-Feb-1998: version 2.42                                            *
 * 11-Feb-1998: version 2.41                                            *
 * 09-Feb-1998: version 2.40                                            *
 * 17-Dec-97: version 2.33                                              *
 * 19-Nov-97: version 2.32                                              *
 * 14-Oct-97: version 2.31                                              *
 * 14-Oct-97: version 2.30                                              *
 * 10-Oct-97: version 2.20a                                             *
 * 10-Oct-97: version 2.20                                              *
 * 19-Sep-97: version 2.12                                              *
 * 07-Dec-95: version 2.11                                              *
 * 07-Dec-95: version 2.10                                              *
 * 25-Mar-95: version 2.05                                              *
 * 15-Mar-95: version 2.04                                              *
 * 12-Mar-95: version 2.03                                              *
 * 11-Mar-95: version 2.02                                              *
 * 09-Mar-95: version 2.01                                              *
 * ..-Feb-95: version 2.00                                              *
 *									*
\************************************************************************/

#include <stdio.h>

char* SCopy  = "Copyright (c) Georg Umgiesser 1992-2009             ";
char* SGrid  = "GRID - Graphic Finite Element Utility  Version 3.10 ";
char* SGeorg = "       1992-2009 (c) Georg Umgiesser - ISMAR-CNR    ";

void Logos( void )

{
        printf("\n");
	printf("%s\n",SGrid);
	printf("%s\n",SGeorg);
	printf("\n");
}

/************************************************************************\

==========================================================
================== version log for grid ==================
==========================================================

version 3.10                            21 Apr 2009

	DIFFS file

==========================================================

version 3.09                            13 Feb 2009

	new linker options

==========================================================
version 3.08                            21 Jan 2009

	new makedepend

==========================================================

version 3.07                            14 Jan 2009

	imported into SHYFEM tree

==========================================================

version 3.06                            03 Nov 2008

	depth in line type

==========================================================

version 3.05                            11 Oct 2004

	compute max depth
	bug in line plotting

==========================================================

version 3.04                            24 Sep 2004

	minor changes
	bigger hash table
	new routines for PostScript (psgraph.[ch])

==========================================================

version 3.03                            19 Aug 2003

	tagged version

==========================================================

version 3.02                            13 Mar 2003

	Eliminated erroneous Makefile (did not compile)

Makefile:
 link with menu, screen, stack
 do not link with gridmu.o gridbu.o
grid_fp.h:
 some more function prototypes
menu.c:
 some more function prototypes
grid.c:
 eliminate compiler warnings

==========================================================

version 3.01                            07 May 1998

	Make type in Node/Elem/Line_type integer

grid_fp.h:
 07-May-1998: type is now integer
grid_ty.h:
 07-May-1998: type is now integer
gridfi.c:
 07-May-1998: type is now integer
gridut.c:
 07-May-1998: type is now integer

==========================================================

version 3.00                            02 Apr 1998

	Major release

	New menu system implemented
	New files menu, screen
	New files stack

grid.c:
 02-Apr-1998: no Button_type, Function_type
 02-Apr-1998: new function MakeGridMenu() (temporarily here)
grid_ex.h:
 02-Apr-1998: no Button_type, Function_type
grid_fp.h:
 02-Apr-1998: no SetNewCommand() & Buttons, new ExitEventLoop()
grid_ty.h:
 02-Apr-1998: no Button_type, Function_type
gridfi.c:
 02-Apr-1998: include of unistd, sys/file commented
gridlo.c:
 02-Apr-1998: new LoopForEvents, ExitEventLoop() (used to exit loop)
 02-Apr-1998: ProcessMenuInput() called for new menu routines
gridma1.c:
 02-Apr-1998: new functio integrated -> no gridmu.h, no ActCommand
                call ExitEventLoop() in GfExit to exit loop
                new GetActFunction(), SetActFunction()
                MenuFieldInput() substituted by ExecuteMenuCommand()
gridma2.c:
 02-Apr-1998: new menu routines integrated -> DisplayMainMenu()
                no MakeButtons()
                set total/menu window dimensions in ResizeWindow()
 02-Apr-1998: call QNewPen(PlotCol) befor plotting in PlotAll()
menu.c:
 02-Apr-1998: version not yet finished but working
 28-Mar-1998: routines adopted from gridmu.c
menu.h:
 02-Apr-1998: version not yet finished but working
 28-Mar-1998: routines adopted from gridmu.c
screen.c:
 02-Apr-1998: version not yet finished but working
 28-Mar-1998: routines adapted from graph.c
screen.h:
 02-Apr-1998: version not yet finished but working
 28-Mar-1998: routines adapted from graph.c

==========================================================

version 2.44                            30 Mar 1998

	some minor fixes
	new general.h
	assert routines added to package

general.h:
 20-Mar-1998: ASSERT_DEBUG introduced
 20-Mar-1998: MIN, MAX, ROUND included in header

==========================================================

version 2.43                            13 Feb 1998

	adjourned to GRX2.0
	minor modifications (compiler warnings)

- general.h:    test automatically if unix or dos
- gevents.c:    adjourned to GRX2.0
- ggraph.c:     adjourned to GRX2.0
- gmouse.c:     adjourned to GRX2.0

==========================================================

version 2.42                            12 Feb 1998

	accept file names with .grd included

- gridfi.c:     New routine stripgrd() -> strips .grd from file name
                  is used in ReadFiles()

==========================================================

version 2.41                            11 Feb 1998

	find now very small elements: instead of calling
	PlotFieldInput() we call TentativeInput() to avoid
	conversion of float to int and back to float

- gridma1.c:    new function TentativeInput(x,y) for keyboard input

==========================================================

version 2.40                            09 Feb 1998

	finds more than one occurence of node/element/line
	(+ minor adjustments -> ActArgument)

- grid.c:       ActArgument eliminated
- grid_ex.h:    ActArgument eliminated
- grid_fp.h:    ActArgument eliminated, new functions GfZoom, GfShow
- gridbu.c:     ActArgument eliminated, new functions GfZoom, GfShow
- gridma1.c:    ActArgument eliminated, new functions GfZoom, GfShow
- gridma2.c:    new algorithms to find node/element/line implemented in
                  FindClosestLine(), FindClosestNode(),
                  FindElemToPoint() -> finds more than one occurence

==========================================================

version 2.33                            17 Dec 1997

	plot nodes and lines in color with option -C

- gridco.c:     new routine GetColorTabSize(), GetTypeColor()
- gridop.c:     OpColor - color nodes and lines (...was compress...)
- gridpl.c:     plots lines with color according to line type
                  uses OpColor to decide if color or not
                  (changed also algorithm for node coloring)
                  new routine SetLineColor()

==========================================================

version 2.32                            19 Nov 1997

	write processed keyboard input to message window (debug)

- gridky.c:     new routines SetKeyboardString(), AppendKeyboardString()
- gridky.h:     new routines SetKeyboardString(), AppendKeyboardString()
- gridma1.c:    write result of keyboard input to message window

==========================================================

version 2.31                            14 Oct 1997

	Bug fix in PlotPoint() -> evidences node again

- grid_fp.h:    new routines GetAct/SetAct... for incapsulation
- gridma1.c:    new routines GetAct/SetAct... for incapsulation
- gridpl.c:     call SetNodeColor() in PlotPoint only if not actual node
                  -> this solves bug (nodes not getting evidenced)

==========================================================

version 2.30                         11-14 Oct 1997

	Administer use of nodes in seperate routines
	Remove Elemenet / Line with nodes
	Bug in use of nodes adjusted in SplitLine, JoinLine
	Bug in SplitLine: do not split at end of line
	Routine to check use consistency
	Color of element is consistent (handle NULLDEPTH)
	Bug fix in hash.c: FreeHashTable used deleted pointer
	Minor bug fixes

- hash.c:	FreeHashTable: bug - using VisitHashTableG used deleted
		  pointer and crashed Linux -> use for-loop

- grid_fp.h:	new routines AddUseN(), DeleteUseN(), GetUseN()
		  DeleteLineWithNodes(), DeleteElemWithNodes()
- grid_ty.h:	New Button_type REMOVE_ELEMENT, REMOVE_LINE
- gridbu.c:	new registered functions GfRemoveElement, GfRemoveLine
- gridco.c:	GetColor() returns PlotCol if value == NULLDEPTH
- gridhs.c:	FreeNumberList() is called only
		  for non-null argument
- gridma1.c:	New routine GfRemoveLine() -> removes line with nodes
		  New routine GfRemoveElement() -> removes elem with nodes
- gridma2.c:	new routines AddUseN(), DeleteUseN(), GetUseN()
		  adjourn use of nodes in SplitLine(), JoinLine()
		  new routine DeleteLineWithNodes()
		  new routine DeleteElemWithNodes()
		  in routine MakeDepthFromNodes() return NULLDEPTH
		  if one of the nodes has no depth
- gridmu.c:	new menu items Remove Element, Remove Line

- grid_fp.h:	new routines GfRemoveElement, GfRemoveLine
- gridhs.c:	Administer use of nodes with routines
		  new routine CheckUseConsistency()
- gridhs.h:	new routine CheckUseConsistency()
- gridma1.c:	Administer use of nodes with routines
- gridma2.c:	Administer use of nodes with routines
		  SplitLine(): do not split at end of line
- gridpl.c:	Administer use of nodes with routines
- gridps.c:	Administer use of nodes with routines
- gridut.c:	do not decrement use of nodes
		  must be done befor routines are called

==========================================================

version 2.20a                           10 Oct 1997

	New color table 7 (with HSB colors)
	Nodes are plotted with colors if -f is given

- color.c:      new routines Hue2RBG(), QAllocHSBColors()
- color.h:      new prototype for QAllocHSBColors()
- gridco.c:     New colortable 7 -> use HSB colors
- gridpl.c:     New static routines PlotNodeForm(), SetNodeColor()
                  PlotPoint() now respects color of nodes to plot

==========================================================

version 2.20                            10 Oct 1997

	New menu item "Save"
	New menu item "Unify Node"
	New (undocumented) feature for Change Depth/Type
		-> can input depth/type from keyboard any time

- grid_fp.h:    new prototypes GfSave, GfUnifyNode, SubstituteNode,
                  SaveFile
- grid_ty.h:    New Button_type SAVE, UNIFY_NODE
- gridbu.c:     new registered functions GfSave, GfUnifyNode
- gridfi.c:     New routine SaveFile()
- gridma1.c:    New global strings StringSave, StringUnifyNode1/2
                  New routine GfUnifyNode()
                  New functionality in GfChangeDepth(), GfChangeType():
                  input depth/type from keyboard any time
- gridma2.c:    new routine SubstituteNode()
- gridmu.c:     new menu items Save, Unify Node

==========================================================

version 2.12                            19 Sep 97

	Check of unique vector numbering introduced

- grid.c:	call to CheckNodes changed -> HCV is passed
- gridhs.c:	call to CheckNodes changed -> HCV is passed
		new routine CheckUniqueVects() -> checks numbering of vectors
- gridhs.h:	prototypes

==========================================================
version 2.11                            07 Dec 95

- hash.c:       MakeHashPointer, VisitHashTableG now defined static (bug)
- psgraph.c:    PPageHeader() now declared and defined static (bug)

==========================================================

version 2.10                            07 Dec 95

- general:

eliminated files removed from distribution
	last distribution containing files is 2.04
	also gridli.c file eliminated (nodelist)
Number list and Coord in extra file gridnl.c/h
	-> moved from gridut.c
error, error2 removed from gridut.c
	-> calls substituted with Error, Error2
Simulation eliminated from distribution
	OpSim, SIMMODE, Simu
	BasData, OutData, OutHead, GeoHead, DepHead
	LMask
	Coord_list_type
Bilinear interpolation eliminated
	AdjustBiLinear, UndoBiLinear
internal number removed (inumber)
Wind routines and variables eliminated
	(OpWind)
Chart routines and variables eliminated
	(CO, CP, ActLevel, Chart_type)
entry level eliminated from Node_type
	-> changed MakeNode()
Fence routines and variables eliminated
	(FENCE_DIM, DelBlock)
old file types 1-7 eliminated

- introduced new type "vector":

changes made to
	- gridbu.c gridmu.c (Buttons, Menus)
	- gridfi.c (new file read)
	- gridop.c (new options)
	- gridma1.c (new commands)
	- gridma2.c (utilities)
	- gridpl.c (plotting for vectors)
	- gridut.c (utilities for plotting for vectors)

- gridge.c :	new routines to compute min/max of rectangle
		IsDegenerateRect()
- *events.c :	handle special keys from keyboard 
		  (arrows, return...)
		TranslateKeyboardEvent for special keys
- xgraph.c :	changes included
		  (Widget, Cursor, Icon ...)
- gridnl.c:     Number list and Coord routines transferred
- fund.h:       Number_list_type cancelled from fundamental types
- grid_ty.h:    Wind_type removed, level from Node_type removed
		  Chart_type removed

==========================================================

version 2.05                            25 Mar 95

- gridco.c:    NULLDEPTH is colored in grey (SetColors())
- gridpl.c:    NULLDEPTH is not interpolated from nodes but
                        colored in grey (PlotElem())

==========================================================

version 2.04				15 Mar 95

- args.c:	Bug fix in readargs -> trailing blanks returned as arg

==========================================================

version 2.03				12 Mar 95

- gridma1.c:	In GfMakeElement -> minimum 3 vertices needed
		In GfMakeLine    -> minimum 2 vertices needed

- gridhs.c:	CheckTwoVertexElems checks for elements with <3 vertices
		CheckOneVertexLines checks for lines with <2 vertices
		CheckIdentVertices checks for non unique nodes in element

==========================================================

version 2.02				11 Mar 95

- grid_fp.h:	CheckConnections local to gridhs.c
- grid_ty.h:	Conn_type local to gridhs.c
- gridut.c:	MakeConn transfered to gridhs.c
		-> Conn... is now completly local to gridhs.c
		AreaElement, InvertIndex from gridut.c
- hash.c:	some comments added
- makefile:	device dependent files seperated
- gridhs.c:	corrected bug in MakeIndexNumber
		-> created negative index number in overflow
		CheckConnections for any number of vertices
		CheckConnections did not free memory of
			allocated Conn structure !!!
		Conn... is local to gridhs.c
		CheckErrorE/N static to file
		restructured organization of file
		-> static routines introduced for local routines
		AreaElement, InvertIndex to gridut.c
		CheckUniqueLines was not called
		-> now called by CheckNodes
- gridhs.h:	consequential changes with gridhs.c
		static routines not listed anymore

==========================================================

version 2.01				09 Mar 95

- gridhs.c:	AreaElement with double
		CheckConnections only for elements with 3 vertices
- gridop.c:	Logos() in gridvs.c
- gridvs.c:	Logos() and version log introduced
	
==========================================================

version 2.0				   Feb 95

- new menu system
- clean interface
- for turbo c, gcc for dos, X11

==========================================================

\************************************************************************/
