
//модельки молек были спи...одолженны от сюда https://github.com/BeeStation/BeeStation-Hornet
/obj/item/toy/plush/mothplushie
    name = "moth plushie"
    icon = 'code/game/objects/items/moff/moff.dmi'
    icon_state = "moffplush"

    var/static/list/moth_plush_list = list(
        "moffplush",
        "moffplush_monarch",
        "moffplush_luna",
        "moffplush_atlas",
        "moffplush_redish",
        "moffplush_royal",
        "moffplush_gothic",
        "moffplush_lovers",
        "moffplush_whitefly",
        "moffplush_punished",
        "moffplush_firewatch",
        "moffplush_deadhead",
        "moffplush_poison",
        "moffplush_ragged",
        "moffplush_snow",
        "moffplush_clockwork",
        "moffplush_moonfly",
        "moffplush_random",
        "moffplush_rainbow",
        "moffplush_witchwing",
        "moffplush_plasmafire",
        "moffplush_bluespace",
        "moffplush_rosy",
        "moffplush_brown"
		"moth_plush_betan"
    )

/obj/item/toy/plush/mothplushie/Initialize(mapload)
    . = ..()
    icon_state = pick(moth_plush_list)
