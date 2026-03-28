// Overhauled vore system
#define DM_DRAGON "Dragon"
#define DM_DEFAULT								"Default"				// Not a real bellymode, used for handling on 'selective' bellymode prefs.
#define DM_HOLD									"Hold"
#define DM_HOLD_ABSORBED						"Hold Absorbed"			// Not a real bellymode, used for handling different idle messages for absorbed prey.
#define DM_DIGEST								"Digest"
#define DM_ABSORB								"Absorb"
#define DM_UNABSORB								"Unabsorb"
#define DM_DRAIN								"Drain"
#define DM_SHRINK								"Shrink"
#define DM_GROW									"Grow"
#define DM_SIZE_STEAL							"Size Steal"
#define DM_HEAL									"Heal"
#define DM_EGG 									"Encase In Egg"
#define DM_SELECT								"Selective"


#define DM_FLAG_NUMBING			(1<<0)
#define DM_FLAG_STRIPPING		(1<<1)
#define DM_FLAG_LEAVEREMAINS	(1<<2)
#define DM_FLAG_THICKBELLY		(1<<3)
#define DM_FLAG_AFFECTWORN		(1<<4)
#define DM_FLAG_JAMSENSORS		(1<<5)
#define DM_FLAG_FORCEPSAY		(1<<6)
#define DM_FLAG_SPARELIMB		(1<<7)
#define DM_FLAG_SLOWBODY		(1<<8)
#define DM_FLAG_MUFFLEITEMS		(1<<9)
#define DM_FLAG_TURBOMODE		(1<<10)
#define DM_FLAG_ABSORBEDVORE	(1<<11)
#define DM_FLAG_WETTENS			(1<<12)

#define DIGESTABLE 		(1<<0)
#define DEVOURABLE		(1<<1)
#define FEEDING			(1<<2)
#define NO_VORE			(1<<3)
#define ABSORBED		(1<<4)
#define VORE_INIT		(1<<5)
#define VOREPREF_INIT	(1<<6)
#define LICKABLE		(1<<7)
/// Can be smelled?
#define SMELLABLE		(1<<8)
/// Can get absorbed?
#define ABSORBABLE		(1<<9)
/// Can get simplemob vored?
#define MOBVORE			(1<<10)

/// Change this whenever you add a vore flag, must be largest vore flag*2-1
#define MAX_VORE_FLAG	(1<<11)-1

#define isbelly(A) istype(A, /obj/belly)
#define isnewbelly(A) istype(A, /obj/new_belly)

#define QDEL_NULL_LIST(x) if(x) { for(var/y in x) { qdel(y) } ; x = null }
#define VORE_STRUGGLE_EMOTE_CHANCE 40

// Stance for hostile mobs to be in while devouring someone.
#define HOSTILE_STANCE_EATING	99

/* // removing sizeplay again
GLOBAL_LIST_INIT(player_sizes_list, list("Macro" = SIZESCALE_HUGE, "Big" = SIZESCALE_BIG, "Normal" = SIZESCALE_NORMAL, "Small" = SIZESCALE_SMALL, "Tiny" = SIZESCALE_TINY))
// Edited to make the new travis check go away
*/

GLOBAL_LIST_INIT(pred_vore_sounds, list(
		"Gulp" = 'sound/vore/pred/swallow_01.ogg',
		"Swallow" = 'sound/vore/pred/swallow_02.ogg',
		"Insertion1" = 'sound/vore/pred/insertion_01.ogg',
		"Insertion2" = 'sound/vore/pred/insertion_02.ogg',
		"Tauric Swallow" = 'sound/vore/pred/taurswallow.ogg',
		"Stomach Move"		= 'sound/vore/pred/stomachmove.ogg',
		"Schlorp" = 'sound/vore/pred/schlorp.ogg',
		"Squish1" = 'sound/vore/pred/squish_01.ogg',
		"Squish2" = 'sound/vore/pred/squish_02.ogg',
		"Squish3" = 'sound/vore/pred/squish_03.ogg',
		"Squish4" = 'sound/vore/pred/squish_04.ogg',
		"Rustle (cloth)" = 'sound/effects/rustle5.ogg',
		"Rustle 2 (cloth)"	= 'sound/effects/rustle2.ogg',
		"Rustle 3 (cloth)"	= 'sound/effects/rustle3.ogg',
		"Rustle 4 (cloth)"	= 'sound/effects/rustle4.ogg',
		"Rustle 5 (cloth)"	= 'sound/effects/rustle5.ogg',
		//Extreme SPLURT degeneracy starts here
		"Fart" = 'modular_splurt/sound/voice/farts/fart.ogg',
		"Fart 1" = 'modular_splurt/sound/voice/farts/fart1.ogg',
		"Fart 2" = 'modular_splurt/sound/voice/farts/fart2.ogg',
		"Fart 3" = 'modular_splurt/sound/voice/farts/fart3.ogg',
		"Fart 4" = 'modular_splurt/sound/voice/farts/fart4.ogg',
		"Fart 5" = 'modular_splurt/sound/voice/farts/fart5.ogg',
		"Fart 6" = 'modular_splurt/sound/voice/farts/fart6.ogg',
		"Fart 7" = 'modular_splurt/sound/voice/farts/fart7.ogg',
		"Burp 1" = 'modular_splurt/sound/voice/burps/belch1.ogg',
		"Burp 2" = 'modular_splurt/sound/voice/burps/belch2.ogg',
		"Burp 3" = 'modular_splurt/sound/voice/burps/belch3.ogg',
		"Burp 4" = 'modular_splurt/sound/voice/burps/belch4.ogg',
		"Burp 5" = 'modular_splurt/sound/voice/burps/belch5.ogg',
		"Burp 6" = 'modular_splurt/sound/voice/burps/belch6.ogg',
		"Burp 7" = 'modular_splurt/sound/voice/burps/belch7.ogg',
		"Burp 8" = 'modular_splurt/sound/voice/burps/belch8.ogg',
		"Burp 9" = 'modular_splurt/sound/voice/burps/belch9.ogg',
		"Burp 10" = 'modular_splurt/sound/voice/burps/belch10.ogg',
		"Burp 11" = 'modular_splurt/sound/voice/burps/belch11.ogg',
		"Burp 12" = 'modular_splurt/sound/voice/burps/belch12.ogg',
		"Burp 13" = 'modular_splurt/sound/voice/burps/belch13.ogg',
		"Burp 14" = 'modular_splurt/sound/voice/burps/belch14.ogg',
		"Burp 15" = 'modular_splurt/sound/voice/burps/belch15.ogg',
		"None" = null
		))

GLOBAL_LIST_INIT(prey_vore_sounds, list(
		"Gulp" = 'sound/vore/prey/swallow_01.ogg',
		"Swallow" = 'sound/vore/prey/swallow_02.ogg',
		"Insertion1" = 'sound/vore/prey/insertion_01.ogg',
		"Insertion2" = 'sound/vore/prey/insertion_02.ogg',
		"Tauric Swallow" = 'sound/vore/prey/taurswallow.ogg',
		"Stomach Move"		= 'sound/vore/prey/stomachmove.ogg',
		"Schlorp" = 'sound/vore/prey/schlorp.ogg',
		"Squish1" = 'sound/vore/prey/squish_01.ogg',
		"Squish2" = 'sound/vore/prey/squish_02.ogg',
		"Squish3" = 'sound/vore/prey/squish_03.ogg',
		"Squish4" = 'sound/vore/prey/squish_04.ogg',
		"Rustle (cloth)" = 'sound/effects/rustle5.ogg',
		"Rustle 2 (cloth)"	= 'sound/effects/rustle2.ogg',
		"Rustle 3 (cloth)"	= 'sound/effects/rustle3.ogg',
		"Rustle 4 (cloth)"	= 'sound/effects/rustle4.ogg',
		"Rustle 5 (cloth)"	= 'sound/effects/rustle5.ogg',
		//Extreme SPLURT degeneracy starts here
		"Fart" = 'modular_splurt/sound/voice/farts/fart.ogg',
		"Fart 1" = 'modular_splurt/sound/voice/farts/fart1.ogg',
		"Fart 2" = 'modular_splurt/sound/voice/farts/fart2.ogg',
		"Fart 3" = 'modular_splurt/sound/voice/farts/fart3.ogg',
		"Fart 4" = 'modular_splurt/sound/voice/farts/fart4.ogg',
		"Fart 5" = 'modular_splurt/sound/voice/farts/fart5.ogg',
		"Fart 6" = 'modular_splurt/sound/voice/farts/fart6.ogg',
		"Fart 7" = 'modular_splurt/sound/voice/farts/fart7.ogg',
		"Burp 1" = 'modular_splurt/sound/voice/burps/belch1.ogg',
		"Burp 2" = 'modular_splurt/sound/voice/burps/belch2.ogg',
		"Burp 3" = 'modular_splurt/sound/voice/burps/belch3.ogg',
		"Burp 4" = 'modular_splurt/sound/voice/burps/belch4.ogg',
		"Burp 5" = 'modular_splurt/sound/voice/burps/belch5.ogg',
		"Burp 6" = 'modular_splurt/sound/voice/burps/belch6.ogg',
		"Burp 7" = 'modular_splurt/sound/voice/burps/belch7.ogg',
		"Burp 8" = 'modular_splurt/sound/voice/burps/belch8.ogg',
		"Burp 9" = 'modular_splurt/sound/voice/burps/belch9.ogg',
		"Burp 10" = 'modular_splurt/sound/voice/burps/belch10.ogg',
		"Burp 11" = 'modular_splurt/sound/voice/burps/belch11.ogg',
		"Burp 12" = 'modular_splurt/sound/voice/burps/belch12.ogg',
		"Burp 13" = 'modular_splurt/sound/voice/burps/belch13.ogg',
		"Burp 14" = 'modular_splurt/sound/voice/burps/belch14.ogg',
		"Burp 15" = 'modular_splurt/sound/voice/burps/belch15.ogg',
		"None" = null
		))

GLOBAL_LIST_INIT(pred_release_sounds, list(
		"Rustle (cloth)" = 'sound/effects/rustle1.ogg',
		"Rustle 2 (cloth)" = 'sound/effects/rustle2.ogg',
		"Rustle 3 (cloth)" = 'sound/effects/rustle3.ogg',
		"Rustle 4 (cloth)" = 'sound/effects/rustle4.ogg',
		"Rustle 5 (cloth)" = 'sound/effects/rustle5.ogg',
		"Stomach Move" = 'sound/vore/pred/stomachmove.ogg',
		"Pred Escape" = 'sound/vore/pred/escape.ogg',
		"Splatter" = 'sound/effects/splat.ogg',
		//Extreme SPLURT degeneracy starts here
		"Fart" = 'modular_splurt/sound/voice/farts/fart.ogg',
		"Fart 1" = 'modular_splurt/sound/voice/farts/fart1.ogg',
		"Fart 2" = 'modular_splurt/sound/voice/farts/fart2.ogg',
		"Fart 3" = 'modular_splurt/sound/voice/farts/fart3.ogg',
		"Fart 4" = 'modular_splurt/sound/voice/farts/fart4.ogg',
		"Fart 5" = 'modular_splurt/sound/voice/farts/fart5.ogg',
		"Fart 6" = 'modular_splurt/sound/voice/farts/fart6.ogg',
		"Fart 7" = 'modular_splurt/sound/voice/farts/fart7.ogg',
		"Fart 8" = 'modular_splurt/sound/voice/farts/fart8.ogg',
		"Burp 1" = 'modular_splurt/sound/voice/burps/belch1.ogg',
		"Burp 2" = 'modular_splurt/sound/voice/burps/belch2.ogg',
		"Burp 3" = 'modular_splurt/sound/voice/burps/belch3.ogg',
		"Burp 4" = 'modular_splurt/sound/voice/burps/belch4.ogg',
		"Burp 5" = 'modular_splurt/sound/voice/burps/belch5.ogg',
		"Burp 6" = 'modular_splurt/sound/voice/burps/belch6.ogg',
		"Burp 7" = 'modular_splurt/sound/voice/burps/belch7.ogg',
		"Burp 8" = 'modular_splurt/sound/voice/burps/belch8.ogg',
		"Burp 9" = 'modular_splurt/sound/voice/burps/belch9.ogg',
		"Burp 10" = 'modular_splurt/sound/voice/burps/belch10.ogg',
		"Burp 11" = 'modular_splurt/sound/voice/burps/belch11.ogg',
		"Burp 12" = 'modular_splurt/sound/voice/burps/belch12.ogg',
		"Burp 13" = 'modular_splurt/sound/voice/burps/belch13.ogg',
		"Burp 14" = 'modular_splurt/sound/voice/burps/belch14.ogg',
		"Burp 15" = 'modular_splurt/sound/voice/burps/belch15.ogg',
		"None" = null
		))

GLOBAL_LIST_INIT(prey_release_sounds, list(
		"Rustle (cloth)" = 'sound/effects/rustle1.ogg',
		"Rustle 2 (cloth)" = 'sound/effects/rustle2.ogg',
		"Rustle 3 (cloth)" = 'sound/effects/rustle3.ogg',
		"Rustle 4 (cloth)" = 'sound/effects/rustle4.ogg',
		"Rustle 5 (cloth)" = 'sound/effects/rustle5.ogg',
		"Stomach Move" = 'sound/vore/prey/stomachmove.ogg',
		"Pred Escape" = 'sound/vore/prey/escape.ogg',
		"Splatter" = 'sound/effects/splat.ogg',
		//Extreme SPLURT degeneracy starts here
		"Fart" = 'modular_splurt/sound/voice/farts/fart.ogg',
		"Fart 1" = 'modular_splurt/sound/voice/farts/fart1.ogg',
		"Fart 2" = 'modular_splurt/sound/voice/farts/fart2.ogg',
		"Fart 3" = 'modular_splurt/sound/voice/farts/fart3.ogg',
		"Fart 4" = 'modular_splurt/sound/voice/farts/fart4.ogg',
		"Fart 5" = 'modular_splurt/sound/voice/farts/fart5.ogg',
		"Fart 6" = 'modular_splurt/sound/voice/farts/fart6.ogg',
		"Fart 7" = 'modular_splurt/sound/voice/farts/fart7.ogg',
		"Fart 8" = 'modular_splurt/sound/voice/farts/fart8.ogg',
		"Burp 1" = 'modular_splurt/sound/voice/burps/belch1.ogg',
		"Burp 2" = 'modular_splurt/sound/voice/burps/belch2.ogg',
		"Burp 3" = 'modular_splurt/sound/voice/burps/belch3.ogg',
		"Burp 4" = 'modular_splurt/sound/voice/burps/belch4.ogg',
		"Burp 5" = 'modular_splurt/sound/voice/burps/belch5.ogg',
		"Burp 6" = 'modular_splurt/sound/voice/burps/belch6.ogg',
		"Burp 7" = 'modular_splurt/sound/voice/burps/belch7.ogg',
		"Burp 8" = 'modular_splurt/sound/voice/burps/belch8.ogg',
		"Burp 9" = 'modular_splurt/sound/voice/burps/belch9.ogg',
		"Burp 10" = 'modular_splurt/sound/voice/burps/belch10.ogg',
		"Burp 11" = 'modular_splurt/sound/voice/burps/belch11.ogg',
		"Burp 12" = 'modular_splurt/sound/voice/burps/belch12.ogg',
		"Burp 13" = 'modular_splurt/sound/voice/burps/belch13.ogg',
		"Burp 14" = 'modular_splurt/sound/voice/burps/belch14.ogg',
		"Burp 15" = 'modular_splurt/sound/voice/burps/belch15.ogg',
		"None" = null
		))


#define DM_MODIFER_NEED_PROCESS (0 << 1)

#define DIGNAL_DM_MODIFER_PROCESS "modifer_process"

#define TRAIT_DM_REMAINS "remains_prey"

#define TRAIT_DM_DIGEST_STAGE_0 "item_digest_stage_0"
#define TRAIT_DM_DIGEST_STAGE_1 "item_digest_stage_1"
#define TRAIT_DM_DIGEST_STAGE_2 "item_digest_stage_2"
#define TRAIT_DM_DIGEST_STAGE_3 "item_digest_stage_3"
