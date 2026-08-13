/*
CONTAINS:
BSRPD
*/

#define ATMOS_CATEGORY 0
#define DISPOSALS_CATEGORY 1
#define TRANSIT_CATEGORY 2

#define BUILD_MODE (1<<0)
#define WRENCH_MODE (1<<1)
#define DESTROY_MODE (1<<2)
#define PAINT_MODE (1<<3)


/// Блюспейс-раздатчик - тот же каталог, что у обычного RPD, плюс собственная
/// труба. Своей копии списка он не держит: каждая новая машинерия попадает сюда
/// вместе с обычным раздатчиком, а не отдельной правкой, про которую забывают.
GLOBAL_LIST_INIT(bsatmos_pipe_recipes, build_atmos_pipe_recipes(list(
	new /datum/pipe_info/pipe("Bluespace Pipe",		/obj/machinery/atmospherics/pipe/bluespace),
)))

// SKYRAT CHANGE: Made BSRPD into a subtype of RPD, additionally made it work at range.
/obj/item/pipe_dispenser/bluespace
	name = "Bluespace Rapid Piping Device (BSRPD)"
	desc = "A device used to rapidly pipe things at a distance."
	icon = /*'modular_sand/icons/obj/tools.dmi'*/ 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'
	icon_state = "bsrpd"
	lefthand_file = /*'modular_sand/icons/mob/inhands/equipment/tools_righthand.dmi'*/ 'modular_bluemoon/icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = /*'modular_sand/icons/mob/inhands/equipment/tools_righthand.dmi'*/ 'modular_bluemoon/icons/mob/inhands/equipment/tools_righthand.dmi'
	custom_materials = list(/datum/material/iron=75000, /datum/material/glass=37500, /datum/material/bluespace=1000)
	has_bluespace_pipe = TRUE

/obj/item/pipe_dispenser/bluespace/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(proximity_flag)
		return // this will be handled in pre_attack in RPD.dm
	user.Beam(target, icon_state = "rped_upgrade", time = 5)
	playsound(src, 'sound/items/pshoom.ogg', 30, TRUE)
	pre_attack(target, user)

// End skyrat edit
#undef ATMOS_CATEGORY
#undef DISPOSALS_CATEGORY
#undef TRANSIT_CATEGORY

#undef BUILD_MODE
#undef DESTROY_MODE
#undef PAINT_MODE
#undef WRENCH_MODE
