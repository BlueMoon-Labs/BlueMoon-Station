// =============================================================================
// TimSort engine for BYOND DM. Originally a port of Java's java.util.TimSort.
//
// Hot-path optimisation strategy
// ------------------------------
// Every comparator dispatch is a `call(cmp)(a, b)` proc-reference call, which is
// the dominant cost in profiles of sortTim/sortInsert. We resolve `cmp` once at
// the top of timSort()/mergeSort() into an integer "cmpKind" and dispatch on it
// inside each hot proc, inlining the comparison expression for the four common
// comparators (cmp_numeric_asc/dsc, cmp_text_asc/dsc) and falling back to the
// generic call() path otherwise. That's a single if/else chain per proc call
// instead of a call(cmp) per comparison inside galloping/binary-search loops.
//
// Bodies are written once as parameterised macros (the comparison primitive is
// passed as a macro name and re-expanded inside the body), so we keep one
// authoritative copy of each algorithm — DM's preprocessor performs chained
// expansion of macro arguments, just like C.
// =============================================================================

	//These are macros used to reduce on proc calls
#define fetchElement(L, i) (associative) ? L[L[i]] : L[i]

	//Minimum sized sequence that will be merged. Anything smaller than this will use binary-insertion sort.
	//Should be a power of 2
#define MIN_MERGE 32

	//When we get into galloping mode, we stay there until both runs win less often than MIN_GALLOP consecutive times.
#define MIN_GALLOP 7

	// Comparator-kind enum. Resolved once per top-level sort entry; consumed by
	// every hot proc that does element comparisons.
#define _SORT_KIND_GEN 0
#define _SORT_KIND_NA  1   // cmp_numeric_asc:  cmp(a,b) = a - b
#define _SORT_KIND_ND  2   // cmp_numeric_dsc:  cmp(a,b) = b - a
#define _SORT_KIND_TA  3   // cmp_text_asc:     cmp(a,b) = sorttext(b, a)
#define _SORT_KIND_TD  4   // cmp_text_dsc:     cmp(a,b) = sorttext(a, b)

	// Per-kind comparison primitives. Each macro is the inlined equivalent of
	//     (call(cmp)(a, b)  <op>  0)
	// for the corresponding comparator. For the generic kind we fall back to the
	// real call() so unknown comparators still work.
	//
	// sorttext semantics in BYOND: sorttext(x, y) returns 1 if x sorts BEFORE y
	// alphabetically (x < y), -1 if x sorts AFTER y (x > y), 0 if equal. That is
	// the opposite sign convention from a "natural" cmp, which is why the text
	// fast paths use sorttext(a, b) > 0 to express "a < b lex".

#define _SK_LT_GEN(a, b) (call(cmp)((a), (b)) < 0)
#define _SK_LE_GEN(a, b) (call(cmp)((a), (b)) <= 0)
#define _SK_GT_GEN(a, b) (call(cmp)((a), (b)) > 0)
#define _SK_GE_GEN(a, b) (call(cmp)((a), (b)) >= 0)

#define _SK_LT_NA(a, b)  ((a) < (b))
#define _SK_LE_NA(a, b)  ((a) <= (b))
#define _SK_GT_NA(a, b)  ((a) > (b))
#define _SK_GE_NA(a, b)  ((a) >= (b))

#define _SK_LT_ND(a, b)  ((a) > (b))
#define _SK_LE_ND(a, b)  ((a) >= (b))
#define _SK_GT_ND(a, b)  ((a) < (b))
#define _SK_GE_ND(a, b)  ((a) <= (b))

#define _SK_LT_TA(a, b)  (sorttext((a), (b)) > 0)
#define _SK_LE_TA(a, b)  (sorttext((a), (b)) >= 0)
#define _SK_GT_TA(a, b)  (sorttext((a), (b)) < 0)
#define _SK_GE_TA(a, b)  (sorttext((a), (b)) <= 0)

#define _SK_LT_TD(a, b)  (sorttext((a), (b)) < 0)
#define _SK_LE_TD(a, b)  (sorttext((a), (b)) <= 0)
#define _SK_GT_TD(a, b)  (sorttext((a), (b)) > 0)
#define _SK_GE_TD(a, b)  (sorttext((a), (b)) >= 0)

	// _DISPATCH_BODY(BODY) expands BODY five times under each fast-path's
	// comparison macros, dispatching on cmpKind. Each branch is a separate
	// `if` block, so vars declared inside BODY are scoped to that branch and
	// don't collide between expansions.
#define _DISPATCH_BODY(BODY) \
	if(cmpKind == _SORT_KIND_NA) { \
		BODY(_SK_LT_NA, _SK_LE_NA, _SK_GT_NA, _SK_GE_NA); \
	} else if(cmpKind == _SORT_KIND_ND) { \
		BODY(_SK_LT_ND, _SK_LE_ND, _SK_GT_ND, _SK_GE_ND); \
	} else if(cmpKind == _SORT_KIND_TA) { \
		BODY(_SK_LT_TA, _SK_LE_TA, _SK_GT_TA, _SK_GE_TA); \
	} else if(cmpKind == _SORT_KIND_TD) { \
		BODY(_SK_LT_TD, _SK_LE_TD, _SK_GT_TD, _SK_GE_TD); \
	} else { \
		BODY(_SK_LT_GEN, _SK_LE_GEN, _SK_GT_GEN, _SK_GE_GEN); \
	}

	//This is a global instance to allow much of this code to be reused. The interfaces are kept separately
GLOBAL_DATUM_INIT(sortInstance, /datum/sortInstance, new())
/datum/sortInstance
	//The array being sorted.
	var/list/L

	//The comparator proc-reference
	var/cmp = GLOBAL_PROC_REF(cmp_numeric_asc)

	//whether we are sorting list keys (0: L[i]) or associated values (1: L[L[i]])
	var/associative = 0

	// Resolved comparator kind. Set once per top-level sort entry by _resolveCmpKind().
	var/cmpKind = _SORT_KIND_GEN

	//This controls when we get *into* galloping mode.  It is initialized	to MIN_GALLOP.
	//The mergeLo and mergeHi methods nudge it higher for random data, and lower for highly structured data.
	var/minGallop = MIN_GALLOP

	//Stores information regarding runs yet to be merged.
	//Run i starts at runBase[i] and extends for runLen[i] elements.
	//runBase[i] + runLen[i] == runBase[i+1]
	var/list/runBases = list()
	var/list/runLens = list()


// Resolve the proc-reference comparator into the cmpKind enum. Called once per
// top-level sort entry; every hot proc reads cmpKind to pick its inlined path.
/datum/sortInstance/proc/_resolveCmpKind()
	if(cmp == GLOBAL_PROC_REF(cmp_numeric_asc))
		cmpKind = _SORT_KIND_NA
	else if(cmp == GLOBAL_PROC_REF(cmp_numeric_dsc))
		cmpKind = _SORT_KIND_ND
	else if(cmp == GLOBAL_PROC_REF(cmp_text_asc))
		cmpKind = _SORT_KIND_TA
	else if(cmp == GLOBAL_PROC_REF(cmp_text_dsc))
		cmpKind = _SORT_KIND_TD
	else
		cmpKind = _SORT_KIND_GEN


/datum/sortInstance/proc/timSort(start, end)
	runBases.Cut()
	runLens.Cut()
	_resolveCmpKind()

	var/remaining = end - start

	//If array is small, do a 'mini-TimSort' with no merges
	if(remaining < MIN_MERGE)
		var/initRunLen = countRunAndMakeAscending(start, end)
		binarySort(start, end, start+initRunLen)
		return

	//March over the array finding natural runs
	//Extend any short natural runs to runs of length minRun
	var/minRun = minRunLength(remaining)

	do
			//identify next run
		var/runLen = countRunAndMakeAscending(start, end)

			//if run is short, extend to min(minRun, remaining)
		if(runLen < minRun)
			var/force = (remaining <= minRun) ? remaining : minRun

			binarySort(start, start+force, start+runLen)
			runLen = force

			//add data about run to queue
		runBases.Add(start)
		runLens.Add(runLen)

			//maybe merge
		mergeCollapse()

			//Advance to find next run
		start += runLen
		remaining -= runLen

	while(remaining > 0)


		//Merge all remaining runs to complete sort
	//ASSERT(start == end)
	mergeForceCollapse();
	//ASSERT(runBases.len == 1)

		//reset minGallop, for successive calls
	minGallop = MIN_GALLOP

	return L

/*
	Sorts the specified portion of the specified array using a binary
	insertion sort.  This is the best method for sorting small numbers
	of elements.  It requires O(n log n) compares, but O(n^2) data
	movement (worst case).

	If the initial part of the specified range is already sorted,
	this method can take advantage of it: the method assumes that the
	elements in range [lo,start) are already sorted

	lo		the index of the first element in the range to be sorted
	hi		the index after the last element in the range to be sorted
	start	the index of the first element in the range that is	not already known to be sorted

	Hot-path optimisation: the inner binary search and pivot insertion is
	written once and dispatched per cmpKind via _DISPATCH_BODY.

	moveElement's body is inlined here (saves a proc call per insert and lets
	us skip the call entirely when the pivot is already in place). We use
	Insert(null) + Swap + Cut, NOT the shorter Cut + Insert(pivot) trick:
	when list elements are themselves lists (e.g. sort_list(list_of_assoc_lists,
	...)) DM's L.Insert(idx, list_value) splats the inner list's contents into
	the outer list. The null-then-swap dance side-steps the splat and is also
	what preserves key->value pairs in the associative case.
*/
#define _BINARYSORT_BODY(LT, LE, GT, GE) \
	while(start < hi) { \
		var/pivot = fetchElement(L, start); \
		var/left = lo; \
		var/right = start; \
		while(left < right) { \
			var/mid = (left + right) >> 1; \
			var/midVal = fetchElement(L, mid); \
			if(GT(midVal, pivot)) { \
				right = mid; \
			} else { \
				left = mid + 1; \
			}; \
		}; \
		if(left < start) { \
			L.Insert(left, null); \
			L.Swap(start + 1, left); \
			L.Cut(start + 1, start + 2); \
		}; \
		++start; \
	}

/datum/sortInstance/proc/binarySort(lo, hi, start)
	//ASSERT(lo <= start && start <= hi)
	if(start <= lo)
		start = lo + 1

	_DISPATCH_BODY(_BINARYSORT_BODY)

#undef _BINARYSORT_BODY

/*
	Returns the length of the run beginning at the specified position and reverses the run if it is back-to-front

	A run is the longest ascending sequence with:
		a[lo] <= a[lo + 1] <= a[lo + 2] <= ...
	or the longest descending sequence with:
		a[lo] >  a[lo + 1] >  a[lo + 2] >  ...

	For its intended use in a stable mergesort, the strictness of the
	definition of "descending" is needed so that the call can safely
	reverse a descending sequence without violating stability.
*/
#define _COUNTRUN_BODY(LT, LE, GT, GE) \
	var/runHi = lo + 1; \
	if(runHi >= hi) { \
		return 1; \
	}; \
	var/last = fetchElement(L,lo); \
	var/current = fetchElement(L,runHi++); \
	if(LT(current, last)) { \
		while(runHi < hi) { \
			last = current; \
			current = fetchElement(L,runHi); \
			if(GE(current, last)) { \
				break; \
			}; \
			++runHi; \
		}; \
		reverseRange(L, lo, runHi); \
	} else { \
		while(runHi < hi) { \
			last = current; \
			current = fetchElement(L,runHi); \
			if(LT(current, last)) { \
				break; \
			}; \
			++runHi; \
		}; \
	}; \
	return runHi - lo;

/datum/sortInstance/proc/countRunAndMakeAscending(lo, hi)
	//ASSERT(lo < hi)
	_DISPATCH_BODY(_COUNTRUN_BODY)

#undef _COUNTRUN_BODY

//Returns the minimum acceptable run length for an array of the specified length.
//Natural runs shorter than this will be extended with binarySort
/datum/sortInstance/proc/minRunLength(n)
	//ASSERT(n >= 0)
	var/r = 0	//becomes 1 if any bits are shifted off
	while(n >= MIN_MERGE)
		r |= (n & 1)
		n >>= 1
	return n + r

//Examines the stack of runs waiting to be merged and merges adjacent runs until the stack invariants are reestablished:
//	runLen[i-3] > runLen[i-2] + runLen[i-1]
//	runLen[i-2] > runLen[i-1]
//This method is called each time a new run is pushed onto the stack.
//So the invariants are guaranteed to hold for i<stackSize upon entry to the method
/datum/sortInstance/proc/mergeCollapse()
	while(runBases.len >= 2)
		var/n = runBases.len - 1
		if(n > 1 && runLens[n-1] <= runLens[n] + runLens[n+1])
			if(runLens[n-1] < runLens[n+1])
				--n
			mergeAt(n)
		else if(runLens[n] <= runLens[n+1])
			mergeAt(n)
		else
			break	//Invariant is established


//Merges all runs on the stack until only one remains.
//Called only once, to finalise the sort
/datum/sortInstance/proc/mergeForceCollapse()
	while(runBases.len >= 2)
		var/n = runBases.len - 1
		if(n > 1 && runLens[n-1] < runLens[n+1])
			--n
		mergeAt(n)


//Merges the two consecutive runs at stack indices i and i+1
//Run i must be the penultimate or antepenultimate run on the stack
//In other words, i must be equal to stackSize-2 or stackSize-3
/datum/sortInstance/proc/mergeAt(i)
	//ASSERT(runBases.len >= 2)
	//ASSERT(i >= 1)
	//ASSERT(i == runBases.len - 1 || i == runBases.len - 2)

	var/base1 = runBases[i]
	var/base2 = runBases[i+1]
	var/len1 = runLens[i]
	var/len2 = runLens[i+1]

	//ASSERT(len1 > 0 && len2 > 0)
	//ASSERT(base1 + len1 == base2)

	//Record the legth of the combined runs. If i is the 3rd last run now, also slide over the last run
	//(which isn't involved in this merge). The current run (i+1) goes away in any case.
	runLens[i] += runLens[i+1]
	runLens.Cut(i+1, i+2)
	runBases.Cut(i+1, i+2)


	//Find where the first element of run2 goes in run1.
	//Prior elements in run1 can be ignored (because they're already in place)
	var/k = gallopRight(fetchElement(L,base2), base1, len1, 0)
	//ASSERT(k >= 0)
	base1 += k
	len1 -= k
	if(len1 == 0)
		return

	//Find where the last element of run1 goes in run2.
	//Subsequent elements in run2 can be ignored (because they're already in place)
	len2 = gallopLeft(fetchElement(L,base1 + len1 - 1), base2, len2, len2-1)
	//ASSERT(len2 >= 0)
	if(len2 == 0)
		return

	//Merge remaining runs, using tmp array with min(len1, len2) elements
	if(len1 <= len2)
		mergeLo(base1, len1, base2, len2)
	else
		mergeHi(base1, len1, base2, len2)


/*
	Locates the position to insert key within the specified sorted range
	If the range contains elements equal to key, this will return the index of the LEFTMOST of those elements

	key		the element to be inserted into the sorted range
	base	the index of the first element of the sorted range
	len		the length of the sorted range, must be greater than 0
	hint	the offset from base at which to begin the search, such that 0 <= hint < len; i.e. base <= hint < base+hint

	Returns the index at which to insert element 'key'
*/
#define _GALLOP_LEFT_BODY(LT, LE, GT, GE) \
	var/lastOffset = 0; \
	var/offset = 1; \
	if(GT(key, fetchElement(L,base+hint))) { \
		var/maxOffset = len - hint; \
		while(offset < maxOffset && GT(key, fetchElement(L,base+hint+offset))) { \
			lastOffset = offset; \
			offset = (offset << 1) + 1; \
		}; \
		if(offset > maxOffset) { \
			offset = maxOffset; \
		}; \
		lastOffset += hint; \
		offset += hint; \
	} else { \
		var/maxOffset = hint + 1; \
		while(offset < maxOffset && LE(key, fetchElement(L,base+hint-offset))) { \
			lastOffset = offset; \
			offset = (offset << 1) + 1; \
		}; \
		if(offset > maxOffset) { \
			offset = maxOffset; \
		}; \
		var/temp = lastOffset; \
		lastOffset = hint - offset; \
		offset = hint - temp; \
	}; \
	++lastOffset; \
	while(lastOffset < offset) { \
		var/m = lastOffset + ((offset - lastOffset) >> 1); \
		if(GT(key, fetchElement(L,base+m))) { \
			lastOffset = m + 1; \
		} else { \
			offset = m; \
		}; \
	}; \
	return offset;

/datum/sortInstance/proc/gallopLeft(key, base, len, hint)
	//ASSERT(len > 0 && hint >= 0 && hint < len)
	_DISPATCH_BODY(_GALLOP_LEFT_BODY)

#undef _GALLOP_LEFT_BODY

/**
  * Like gallopLeft, except that if the range contains an element equal to
  * key, gallopRight returns the index after the rightmost equal element.
  *
  * @param key the key whose insertion point to search for
  * @param a the array in which to search
  * @param base the index of the first element in the range
  * @param len the length of the range; must be > 0
  * @param hint the index at which to begin the search, 0 <= hint < n.
  *	 The closer hint is to the result, the faster this method will run.
  * @param c the comparator used to order the range, and to search
  * @return the int k,  0 <= k <= n such that a[b + k - 1] <= key < a[b + k]
  */
#define _GALLOP_RIGHT_BODY(LT, LE, GT, GE) \
	var/offset = 1; \
	var/lastOffset = 0; \
	if(LT(key, fetchElement(L,base+hint))) { \
		var/maxOffset = hint + 1; \
		while(offset < maxOffset && LT(key, fetchElement(L,base+hint-offset))) { \
			lastOffset = offset; \
			offset = (offset << 1) + 1; \
		}; \
		if(offset > maxOffset) { \
			offset = maxOffset; \
		}; \
		var/temp = lastOffset; \
		lastOffset = hint - offset; \
		offset = hint - temp; \
	} else { \
		var/maxOffset = len - hint; \
		while(offset < maxOffset && GE(key, fetchElement(L,base+hint+offset))) { \
			lastOffset = offset; \
			offset = (offset << 1) + 1; \
		}; \
		if(offset > maxOffset) { \
			offset = maxOffset; \
		}; \
		lastOffset += hint; \
		offset += hint; \
	}; \
	++lastOffset; \
	while(lastOffset < offset) { \
		var/m = lastOffset + ((offset - lastOffset) >> 1); \
		if(LT(key, fetchElement(L,base+m))) { \
			offset = m; \
		} else { \
			lastOffset = m + 1; \
		}; \
	}; \
	return offset;

/datum/sortInstance/proc/gallopRight(key, base, len, hint)
	//ASSERT(len > 0 && hint >= 0 && hint < len)
	_DISPATCH_BODY(_GALLOP_RIGHT_BODY)

#undef _GALLOP_RIGHT_BODY


//Merges two adjacent runs in-place in a stable fashion.
//For performance this method should only be called when len1 <= len2!
//
// Original mergeLo used `outer:` + `break outer` for two-level escape from the
// straightforward and galloping inner loops. We can't use a label inside a
// macro expanded multiple times in the same proc (duplicate label), so the
// outer escape is encoded as a `done` flag tested after each inner loop.
#define _MERGELO_BODY(LT, LE, GT, GE) \
	var/cursor1 = base1; \
	var/cursor2 = base2; \
	if(len2 == 1) { \
		moveElement(L, cursor2, cursor1); \
		return; \
	}; \
	if(len1 == 1) { \
		moveElement(L, cursor1, cursor2+len2); \
		return; \
	}; \
	moveElement(L, cursor2++, cursor1++); \
	--len2; \
	var/done = 0; \
	while(!done) { \
		var/count1 = 0; \
		var/count2 = 0; \
		do { \
			if(LT(fetchElement(L,cursor2), fetchElement(L,cursor1))) { \
				moveElement(L, cursor2++, cursor1++); \
				--len2; \
				++count2; \
				count1 = 0; \
				if(len2 == 0) { \
					done = 1; \
					break; \
				}; \
			} else { \
				++cursor1; \
				++count1; \
				count2 = 0; \
				if(--len1 == 1) { \
					done = 1; \
					break; \
				}; \
			}; \
		} while((count1 | count2) < minGallop); \
		if(done) { \
			break; \
		}; \
		do { \
			count1 = gallopRight(fetchElement(L,cursor2), cursor1, len1, 0); \
			if(count1) { \
				cursor1 += count1; \
				len1 -= count1; \
				if(len1 <= 1) { \
					done = 1; \
					break; \
				}; \
			}; \
			moveElement(L, cursor2, cursor1); \
			++cursor2; \
			++cursor1; \
			if(--len2 == 0) { \
				done = 1; \
				break; \
			}; \
			count2 = gallopLeft(fetchElement(L,cursor1), cursor2, len2, 0); \
			if(count2) { \
				moveRange(L, cursor2, cursor1, count2); \
				cursor2 += count2; \
				cursor1 += count2; \
				len2 -= count2; \
				if(len2 == 0) { \
					done = 1; \
					break; \
				}; \
			}; \
			++cursor1; \
			if(--len1 == 1) { \
				done = 1; \
				break; \
			}; \
			--minGallop; \
		} while((count1|count2) > MIN_GALLOP); \
		if(done) { \
			break; \
		}; \
		if(minGallop < 0) { \
			minGallop = 0; \
		}; \
		minGallop += 2; \
	}; \
	if(len1 == 1) { \
		moveElement(L, cursor1, cursor2+len2); \
	};

/datum/sortInstance/proc/mergeLo(base1, len1, base2, len2)
	//ASSERT(len1 > 0 && len2 > 0 && base1 + len1 == base2)
	_DISPATCH_BODY(_MERGELO_BODY)

#undef _MERGELO_BODY


#define _MERGEHI_BODY(LT, LE, GT, GE) \
	var/cursor1 = base1 + len1 - 1; \
	var/cursor2 = base2 + len2 - 1; \
	if(len2 == 1) { \
		moveElement(L, base2, base1); \
		return; \
	}; \
	if(len1 == 1) { \
		moveElement(L, base1, cursor2+1); \
		return; \
	}; \
	moveElement(L, cursor1--, cursor2-- + 1); \
	--len1; \
	var/done = 0; \
	while(!done) { \
		var/count1 = 0; \
		var/count2 = 0; \
		do { \
			if(LT(fetchElement(L,cursor2), fetchElement(L,cursor1))) { \
				moveElement(L, cursor1--, cursor2-- + 1); \
				--len1; \
				++count1; \
				count2 = 0; \
				if(len1 == 0) { \
					done = 1; \
					break; \
				}; \
			} else { \
				--cursor2; \
				--len2; \
				++count2; \
				count1 = 0; \
				if(len2 == 1) { \
					done = 1; \
					break; \
				}; \
			}; \
		} while((count1 | count2) < minGallop); \
		if(done) { \
			break; \
		}; \
		do { \
			count1 = len1 - gallopRight(fetchElement(L,cursor2), base1, len1, len1-1); \
			if(count1) { \
				cursor1 -= count1; \
				moveRange(L, cursor1+1, cursor2+1, count1); \
				cursor2 -= count1; \
				len1 -= count1; \
				if(len1 == 0) { \
					done = 1; \
					break; \
				}; \
			}; \
			--cursor2; \
			if(--len2 == 1) { \
				done = 1; \
				break; \
			}; \
			count2 = len2 - gallopLeft(fetchElement(L,cursor1), cursor1+1, len2, len2-1); \
			if(count2) { \
				cursor2 -= count2; \
				len2 -= count2; \
				if(len2 <= 1) { \
					done = 1; \
					break; \
				}; \
			}; \
			moveElement(L, cursor1--, cursor2-- + 1); \
			--len1; \
			if(len1 == 0) { \
				done = 1; \
				break; \
			}; \
			--minGallop; \
		} while((count1|count2) > MIN_GALLOP); \
		if(done) { \
			break; \
		}; \
		if(minGallop < 0) { \
			minGallop = 0; \
		}; \
		minGallop += 2; \
	}; \
	if(len2 == 1) { \
		cursor1 -= len1; \
		moveRange(L, cursor1+1, cursor2+1, len1); \
	};

/datum/sortInstance/proc/mergeHi(base1, len1, base2, len2)
	//ASSERT(len1 > 0 && len2 > 0 && base1 + len1 == base2)
	_DISPATCH_BODY(_MERGEHI_BODY)

#undef _MERGEHI_BODY


/datum/sortInstance/proc/mergeSort(start, end)
	// timSort leaves runBases with one entry from the previous sort; drain it
	// here so mergeSort always starts on an empty run-stack. The stale entry
	// otherwise gets merged as if it were part of the current input and the
	// result drifts out of range (and out of order).
	runBases.Cut()
	runLens.Cut()
	_resolveCmpKind()

	var/remaining = end - start

	//If array is small, do an insertion sort
	if(remaining < MIN_MERGE)
		binarySort(start, end, start/*+initRunLen*/)
		return

	var/minRun = minRunLength(remaining)

	do
		var/runLen = (remaining <= minRun) ? remaining : minRun

		binarySort(start, start+runLen, start)

		//add data about run to queue
		runBases.Add(start)
		runLens.Add(runLen)

		//Advance to find next run
		start += runLen
		remaining -= runLen

	while(remaining > 0)

	while(runBases.len >= 2)
		var/n = runBases.len - 1
		if(n > 1 && runLens[n-1] <= runLens[n] + runLens[n+1])
			if(runLens[n-1] < runLens[n+1])
				--n
			mergeAt2(n)
		else if(runLens[n] <= runLens[n+1])
			mergeAt2(n)
		else
			break	//Invariant is established

	while(runBases.len >= 2)
		var/n = runBases.len - 1
		if(n > 1 && runLens[n-1] < runLens[n+1])
			--n
		mergeAt2(n)

	return L

#define _MERGEAT2_BODY(LT, LE, GT, GE) \
	var/cursor1 = runBases[i]; \
	var/cursor2 = runBases[i+1]; \
	var/end1 = cursor1+runLens[i]; \
	var/end2 = cursor2+runLens[i+1]; \
	var/val1 = fetchElement(L,cursor1); \
	var/val2 = fetchElement(L,cursor2); \
	while(1) { \
		if(LE(val1, val2)) { \
			if(++cursor1 >= end1) { \
				break; \
			}; \
			val1 = fetchElement(L,cursor1); \
		} else { \
			moveElement(L,cursor2,cursor1); \
			if(++cursor2 >= end2) { \
				break; \
			}; \
			++end1; \
			++cursor1; \
			val2 = fetchElement(L,cursor2); \
		}; \
	}; \
	runLens[i] += runLens[i+1]; \
	runLens.Cut(i+1, i+2); \
	runBases.Cut(i+1, i+2);

/datum/sortInstance/proc/mergeAt2(i)
	_DISPATCH_BODY(_MERGEAT2_BODY)

#undef _MERGEAT2_BODY


// =============================================================================
// Cleanup of file-private macros. fetchElement is intentionally re-undef'd here
// to match the previous behaviour; the kind enum and per-kind comparison
// macros are likewise scoped to this file.
// =============================================================================
#undef _DISPATCH_BODY

#undef _SK_LT_GEN
#undef _SK_LE_GEN
#undef _SK_GT_GEN
#undef _SK_GE_GEN
#undef _SK_LT_NA
#undef _SK_LE_NA
#undef _SK_GT_NA
#undef _SK_GE_NA
#undef _SK_LT_ND
#undef _SK_LE_ND
#undef _SK_GT_ND
#undef _SK_GE_ND
#undef _SK_LT_TA
#undef _SK_LE_TA
#undef _SK_GT_TA
#undef _SK_GE_TA
#undef _SK_LT_TD
#undef _SK_LE_TD
#undef _SK_GT_TD
#undef _SK_GE_TD

#undef _SORT_KIND_GEN
#undef _SORT_KIND_NA
#undef _SORT_KIND_ND
#undef _SORT_KIND_TA
#undef _SORT_KIND_TD

#undef MIN_GALLOP
#undef MIN_MERGE

#undef fetchElement
