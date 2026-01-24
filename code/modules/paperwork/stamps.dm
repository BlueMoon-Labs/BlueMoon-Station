/obj/item/stamp
	name = "\improper GRANTED rubber stamp"
	desc = "A rubber stamp for stamping important documents."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "stamp-ok"
	item_state = "stamp"
	throwforce = 0
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/wood=60)
	pressure_resistance = 2
	attack_verb = list("stamped")

	var/on_paper_icon_state = "stamp-ok"

/obj/item/stamp/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] stamps 'VOID' on [user.ru_ego()] forehead, then promptly falls over, dead.</span>")
	return (OXYLOSS)

/obj/item/stamp/get_writing_implement_details()
	var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
	return list(
		interaction_mode = MODE_STAMPING,
		stamp_icon_state = icon_state,
		stamp_class = sheet.icon_class_name(on_paper_icon_state)
	)

/obj/item/stamp/qm
	name = "quartermaster's rubber stamp"
	icon_state = "stamp-qm"
	on_paper_icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/law
	name = "law office's rubber stamp"
	icon_state = "stamp-law"
	on_paper_icon_state = "stamp-law"
	dye_color = DYE_LAW

/obj/item/stamp/captain
	name = "captain's rubber stamp"
	icon_state = "stamp-cap"
	on_paper_icon_state = "stamp-cap"
	dye_color = DYE_CAPTAIN

/obj/item/stamp/command
	name = "command rubber stamp"
	icon_state = "stamp-com"
	on_paper_icon_state = "stamp-com"
	dye_color = DYE_COMMAND

/obj/item/stamp/hop
	name = "head of personnel's rubber stamp"
	icon_state = "stamp-hop"
	on_paper_icon_state = "stamp-com"
	dye_color = DYE_HOP

/obj/item/stamp/hos
	name = "head of security's rubber stamp"
	icon_state = "stamp-hos"
	on_paper_icon_state = "stamp-hos"
	dye_color = DYE_HOS

/obj/item/stamp/ce
	name = "chief engineer's rubber stamp"
	icon_state = "stamp-ce"
	on_paper_icon_state = "stamp-ce"
	dye_color = DYE_CE

/obj/item/stamp/rd
	name = "research director's rubber stamp"
	icon_state = "stamp-rd"
	on_paper_icon_state = "stamp-rd"
	dye_color = DYE_RD

/obj/item/stamp/cmo
	name = "chief medical officer's rubber stamp"
	icon_state = "stamp-cmo"
	on_paper_icon_state = "stamp-cmo"
	dye_color = DYE_CMO

/obj/item/stamp/denied
	name = "\improper DENIED rubber stamp"
	icon_state = "stamp-deny"
	on_paper_icon_state = "stamp-deny"
	dye_color = DYE_REDCOAT

/obj/item/stamp/clown
	name = "clown's rubber stamp"
	icon_state = "stamp-clown"
	on_paper_icon_state = "stamp-clown"
	dye_color = DYE_CLOWN

/obj/item/stamp/mime
	name = "mime's rubber stamp"
	icon_state = "stamp-mime"
	on_paper_icon_state = "stamp-mime"
	dye_color = DYE_MIME

/obj/item/stamp/chap
	name = "chaplain's rubber stamp"
	icon_state = "stamp-chap"
	on_paper_icon_state = "stamp-chap"
	dye_color = DYE_CHAP

/obj/item/stamp/centcom
	name = "CentCom rubber stamp"
	icon_state = "stamp-centcom"
	on_paper_icon_state = "stamp-centcom"
	dye_color = DYE_CENTCOM

/obj/item/stamp/syndicate
	name = "Syndicate rubber stamp"
	icon_state = "stamp-syndicate"
	on_paper_icon_state = "stamp-syndicate"
	dye_color = DYE_SYNDICATE

/obj/item/stamp/ntr
	name = "NanoTrasen rubber stamp"
	icon_state = "stamp-ntr"
	on_paper_icon_state = "stamp-ntr"
	dye_color = DYE_CENTCOM

/obj/item/stamp/warden
	name = "warden's rubber stamp"
	icon_state = "stamp-warden"
	on_paper_icon_state = "stamp-warden"
	dye_color = DYE_RED

/obj/item/stamp/security
	name = "security rubber stamp"
	icon_state = "stamp-security"
	on_paper_icon_state = "stamp-security"
	dye_color = DYE_RED

// BLUEMOON ADD START - новый штамп для автоматически сгененированных документов
/obj/item/stamp/machine
	name = "Machinery stamping module"
	desc = "И откуда ты это достал, мясной мешок? Положи обратно!"
	icon_state = "stamp-machine"
	on_paper_icon_state = "stamp-machine"
	dye_color = DYE_BLUE
// BLUEMOON ADD END

/obj/item/stamp/attack_paw(mob/user)
	return attack_hand(user)
