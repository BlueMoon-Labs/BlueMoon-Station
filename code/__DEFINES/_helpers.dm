// Stuff that is relatively "core" and is used in other defines/helpers

//Returns the hex value of a decimal number
//len == length of returned string
// #define num2hex(X, len) num2text(X, len, 16) -- NOT YET

//Returns an integer given a hex input, supports negative values "-ff"
//skips preceding invalid characters
// #define hex2num(X) text2num(X, 16) -- NO

/// Stringifies whatever you put into it.
#define STRINGIFY(argument) #argument

/// subtypesof(), typesof() without the parent path
#define subtypesof(typepath) ( typesof(typepath) - typepath )

/// Until a condition is true, sleep
#define UNTIL(X) while(!(X)) stoplag()

/// Sleep if we haven't been deleted
/// Otherwise, return
#define SLEEP_NOT_DEL(time) \
	if(QDELETED(src)) { \
		return; \
	} \
	sleep(time);

/// Takes a datum as input, returns its ref string
#define text_ref(datum) ref(datum)

// Inline ref - eliminates DM proc-call overhead which dominated /proc/REF self-time in profiles.
// Defined here (very early in the include chain) so it is available before TYPEID expansion in
// later files like __DEFINES/is_helpers.dm:20.
// `:` access on datum_flags is guarded by the istype() check - same idiom as CLIENT_FROM_VAR in misc.dm.
// The literal `1` is the value of DF_USE_TAG (= 1<<0); the named constant lives in _flags/_flags.dm
// which loads after this file, so we can't reference it by name here. The check is sanity-revalidated
// by /proc/__REF_tagged below (it uses the named DF_USE_TAG constant when clearing the flag).
// The DF_USE_TAG branch defers to /proc/__REF_tagged (see __HELPERS/unsorted.dm) to keep this
// expression tight and to preserve the missing-tag fallback (stack_trace + flag clear).
// Caveat: `thing` is evaluated up to 3 times - do not pass exprs with side effects.
#define REF(thing) (istype(thing, /datum) && (thing:datum_flags & 1) ? __REF_tagged(thing) : "\ref[thing]")

// Refs contain a type id within their string that can be used to identify byond types.
// Custom types that we define don't get a unique id, but this is useful for identifying
// types that don't normally have a way to run istype() on them.
#define TYPEID(thing) copytext(REF(thing), 4, 6)

/// A null statement to guard against EmptyBlock lint without necessitating the use of pass()
/// Used to avoid proc-call overhead. But use sparingly. Probably pointless in most places.
#define EMPTY_BLOCK_GUARD ;

/// Use this to set the base and ACTUAL pixel offsets of an object at the same time
/// You should always use this for pixel setting in typepaths, unless you want the map display to look different from in game
#define SET_BASE_PIXEL(x, y) \
	pixel_x = x; \
	base_pixel_x = x; \
	pixel_y = y; \
	base_pixel_y = y;
