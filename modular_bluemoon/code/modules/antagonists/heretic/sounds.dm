// Удары клинков: у каждого пути свой набор, вариант выбирается случайно через ключ hitsound.
// Клинок без пути и нож для рун звучат общим набором (eldritch_items.dm).

/obj/item/melee/sickly_blade/ash
	hitsound = "heretic_blade_hit_ash"

/obj/item/melee/sickly_blade/rust
	hitsound = "heretic_blade_hit_rust"

/obj/item/melee/sickly_blade/flesh
	hitsound = "heretic_blade_hit_flesh"

/obj/item/melee/sickly_blade/void
	hitsound = "heretic_blade_hit_void"

/obj/item/melee/sickly_blade/duelist
	hitsound = "heretic_blade_hit_blade"

/obj/item/melee/sickly_blade/blood
	hitsound = "heretic_blade_hit_blood"

/obj/item/melee/sickly_blade/cosmic
	hitsound = "heretic_blade_hit_cosmic"

/obj/item/melee/sickly_blade/dance
	hitsound = "heretic_blade_hit_dance"

/obj/item/melee/sickly_blade/echo
	hitsound = "heretic_blade_hit_echo"

/obj/item/melee/sickly_blade/glass
	hitsound = "heretic_blade_hit_glass"

/obj/item/melee/sickly_blade/lock
	hitsound = "heretic_blade_hit_lock"

/obj/item/melee/sickly_blade/moon
	hitsound = "heretic_blade_hit_moon"

/obj/item/melee/sickly_blade/sand
	hitsound = "heretic_blade_hit_sand"

/obj/item/melee/sickly_blade/spirit
	hitsound = "heretic_blade_hit_spirit"

/obj/item/melee/sickly_blade/tide
	hitsound = "heretic_blade_hit_tide"

/obj/item/melee/sickly_blade/wax
	hitsound = "heretic_blade_hit_wax"

/datum/sound_effect/heretic_blade_hit/common
	key = "heretic_blade_hit_common"
	file_paths = list(
		'modular_bluemoon/sound/heretic/common/blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/common/blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/common/blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/ash
	key = "heretic_blade_hit_ash"
	file_paths = list(
		'modular_bluemoon/sound/heretic/ash_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/ash_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/ash_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/rust
	key = "heretic_blade_hit_rust"
	file_paths = list(
		'modular_bluemoon/sound/heretic/rust_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/rust_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/rust_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/flesh
	key = "heretic_blade_hit_flesh"
	file_paths = list(
		'modular_bluemoon/sound/heretic/flesh_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/flesh_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/flesh_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/void
	key = "heretic_blade_hit_void"
	file_paths = list(
		'modular_bluemoon/sound/heretic/void_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/void_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/void_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/blade
	key = "heretic_blade_hit_blade"
	file_paths = list(
		'modular_bluemoon/sound/heretic/blade_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/blade_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/blade_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/blood
	key = "heretic_blade_hit_blood"
	file_paths = list(
		'modular_bluemoon/sound/heretic/blood_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/blood_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/blood_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/cosmic
	key = "heretic_blade_hit_cosmic"
	file_paths = list(
		'modular_bluemoon/sound/heretic/cosmic_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/cosmic_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/cosmic_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/dance
	key = "heretic_blade_hit_dance"
	file_paths = list(
		'modular_bluemoon/sound/heretic/dance_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/dance_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/dance_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/echo
	key = "heretic_blade_hit_echo"
	file_paths = list(
		'modular_bluemoon/sound/heretic/echo_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/echo_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/echo_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/glass
	key = "heretic_blade_hit_glass"
	file_paths = list(
		'modular_bluemoon/sound/heretic/glass_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/glass_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/glass_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/lock
	key = "heretic_blade_hit_lock"
	file_paths = list(
		'modular_bluemoon/sound/heretic/lock_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/lock_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/lock_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/moon
	key = "heretic_blade_hit_moon"
	file_paths = list(
		'modular_bluemoon/sound/heretic/moon_hit_1.ogg',
		'modular_bluemoon/sound/heretic/moon_hit_2.ogg',
	)

/datum/sound_effect/heretic_blade_hit/sand
	key = "heretic_blade_hit_sand"
	file_paths = list(
		'modular_bluemoon/sound/heretic/sand_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/sand_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/sand_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/spirit
	key = "heretic_blade_hit_spirit"
	file_paths = list(
		'modular_bluemoon/sound/heretic/spirit_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/spirit_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/spirit_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/tide
	key = "heretic_blade_hit_tide"
	file_paths = list(
		'modular_bluemoon/sound/heretic/tide_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/tide_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/tide_blade_hit_3.ogg',
	)

/datum/sound_effect/heretic_blade_hit/wax
	key = "heretic_blade_hit_wax"
	file_paths = list(
		'modular_bluemoon/sound/heretic/wax_blade_hit_1.ogg',
		'modular_bluemoon/sound/heretic/wax_blade_hit_2.ogg',
		'modular_bluemoon/sound/heretic/wax_blade_hit_3.ogg',
	)

// Общие события еретика.

/datum/sound_effect/heretic_codex_learn
	key = HERETIC_CODEX_LEARN_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/common/codex_learn_1.ogg',
		'modular_bluemoon/sound/heretic/common/codex_learn_2.ogg',
	)

/datum/sound_effect/heretic_codex_upgrade
	key = HERETIC_CODEX_UPGRADE_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/common/codex_upgrade_1.ogg',
		'modular_bluemoon/sound/heretic/common/codex_upgrade_2.ogg',
	)

/datum/sound_effect/heretic_heart_summon
	key = HERETIC_HEART_SUMMON_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/common/heart_summon_1.ogg',
		'modular_bluemoon/sound/heretic/common/heart_summon_2.ogg',
	)

/datum/sound_effect/heretic_heart_hide
	key = HERETIC_HEART_HIDE_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/common/heart_hide_1.ogg',
		'modular_bluemoon/sound/heretic/common/heart_hide_2.ogg',
	)

/datum/sound_effect/heretic_emergence_hit
	key = HERETIC_EMERGENCE_HIT_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/common/emergence_hit_1.ogg',
		'modular_bluemoon/sound/heretic/common/emergence_hit_2.ogg',
		'modular_bluemoon/sound/heretic/common/emergence_hit_3.ogg',
	)

/datum/sound_effect/heretic_crucible_bubble
	key = HERETIC_CRUCIBLE_BUBBLE_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/common/crucible_bubble_1.ogg',
		'modular_bluemoon/sound/heretic/common/crucible_bubble_2.ogg',
	)

/datum/sound_effect/heretic_trap_grasp
	key = HERETIC_TRAP_GRASP_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/common/trap_grasp_1.ogg',
		'modular_bluemoon/sound/heretic/common/trap_grasp_2.ogg',
	)

/datum/sound_effect/heretic_siphon
	key = HERETIC_SIPHON_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/common/siphon_1.ogg',
		'modular_bluemoon/sound/heretic/common/siphon_2.ogg',
	)

/datum/sound_effect/heretic_void_blink_out
	key = HERETIC_VOID_BLINK_OUT_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/void_blink_out_1.ogg',
		'modular_bluemoon/sound/heretic/void_blink_out_2.ogg',
	)

/datum/sound_effect/heretic_void_blink_in
	key = HERETIC_VOID_BLINK_IN_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/void_blink_in_1.ogg',
		'modular_bluemoon/sound/heretic/void_blink_in_2.ogg',
	)

/datum/sound_effect/heretic_ash_print_flare
	key = HERETIC_ASH_PRINT_FLARE_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/ash_print_flare_1.ogg',
		'modular_bluemoon/sound/heretic/ash_print_flare_2.ogg',
	)
