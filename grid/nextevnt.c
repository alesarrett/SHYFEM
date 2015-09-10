/** 
 ** NEXTEVNT.C 
 **
 **  Copyright (C) 1992, Csaba Biegl
 **    820 Stirrup Dr, Nashville, TN, 37221
 **    csaba@vuse.vanderbilt.edu
 **
 **  This file is distributed under the terms listed in the document
 **  "copying.cb", available from the author at the address above.
 **  A copy of "copying.cb" should accompany this file; if not, a copy
 **  should be available from where this file was obtained.  This file
 **  may not be distributed without a verbatim copy of "copying.cb".
 **  You should also have received a copy of the GNU General Public
 **  License along with this program (it is in the file "copying");
 **  if not, write to the Free Software Foundation, Inc., 675 Mass Ave,
 **  Cambridge, MA 02139, USA.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **/

#include "eventque.h"

#ifdef __GNUC__
# define disable()  asm volatile("cli");
# define enable()   asm volatile("sti");
#endif

#ifdef __TURBOC__
# include <dos.h>
#endif

int EventQueueNextEvent(EventQueue *q,EventRecord *e)
{
	if(q->evq_cursize > 0) {
	    disable();
	    *e = q->evq_events[q->evq_rdptr];
	    if(++q->evq_rdptr == q->evq_maxsize) q->evq_rdptr = 0;
	    q->evq_cursize--;
	    enable();
	    return(1);
	}
	return(0);
}

