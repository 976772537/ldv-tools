/* SetLogic operations.
 *
 * Full description see at wiki page "SetLogic".
 * Some of these operations are supported only in special setlogic-compliant BLAST version.  Bare BLAST can't check these operations.
 */

#ifndef GUARD__SETLOGIC_H
#define GUARD__SETLOGIC_H

/* Type for sets.  All sets should be declared with it. */
typedef int Set;

/* SetEmpty - returns an empty set.
 * Usage:
 * 	Set s = SetEmpty();
 */
Set SetEmpty();

/* SetAdd(S,x) - returns union of S and {x}.
 * Usage:
 * 	Set s = SetAdd(s,x);
 */
Set SetAdd(Set, ...);

/* SetDel(S,x) - returns difference of S and {x}, i.e. S\{x}
 * Usage:
 * 	Set s = SetDel(s,x);
 */
Set SetDel(Set, ...);

/* SetInTest(S,x) - check if element is in the set
 * Usage:
 * 	if (SetInTest(s,x)) ...
 */
int SetInTest(Set, ...);

/*  SetNotEmptyTest(S) - check if set is not empty.
 * Usage:
 * 	if (SetNotEmptyTest(s,x)) ...
 */
int SetNotEmptyTest();

/* include sentry guard */
#endif

