/obj/item/stamp/replica
	name = "rubber stamp replica"
	icon_state = "stamp-ok"
	var/item = ""
	var/list/quality_number = list(1, 1, 2, 2, 2, 3)
	var/list/quality_list = list("poorly made replica of ", "odd-looking ", "")
	var/list/quality_desc = list("It just hurts to look at.", "The oddly shaped handle looks slightly uncomfortable to hold.", "Something feels off here.")
	var/list/quality_stamps = list("stamp-ok", "stamp-ok", "stamp-ok")

/obj/item/stamp/replica/Initialize(mapload)
	. = ..()
	var/quality = quality_number[rand(1, 6)]
	name = "[quality_list[quality]][item] rubber stamp"
	desc = "A rubber stamp for stamping important documents. [quality_desc[quality]]"
	on_paper_icon_state = quality_stamps[quality]

/obj/item/stamp/replica/qm
	name = "quartermaster's rubber stamp replica"
	item = "quartermaster's"
	quality_stamps = list("fake-gud-stamp-qm", "fake-mid-stamp-qm", "fake-bad-stamp-qm")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/law
	name = "law office rubber stamp replica"
	item = "law office"
	quality_stamps = list("fake-gud-stamp-law", "fake-mid-stamp-law", "fake-bad-stamp-law")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/captain
	name = "captain's rubber stamp replica"
	item = "captain's"
	quality_stamps = list("fake-gud-stamp-cap", "fake-mid-stamp-cap", "fake-bad-stamp-cap")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/command
	name = "command rubber stamp replica"
	item = "command"
	quality_stamps = list("fake-gud-stamp-com", "fake-mid-stamp-com", "fake-bad-stamp-com")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/hop
	name = "head of personnel's rubber stamp replica"
	item = "head of personnel's"
	quality_stamps = list("fake-gud-stamp-hop", "fake-mid-stamp-hop", "fake-bad-stamp-hop")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/hos
	name = "head of security's rubber stamp replica"
	item = "security's"
	quality_stamps = list("fake-gud-stamp-hos", "fake-mid-stamp-hos", "fake-bad-stamp-hos")
	icon_state = "stamp-qm"
	icon = null
	dye_color = DYE_QM

/obj/item/stamp/replica/ce
	name = "chief engineer's rubber stamp replica"
	item = "chief engineer's"
	quality_stamps = list("fake-gud-stamp-ce", "fake-mid-stamp-ce", "fake-bad-stamp-ce")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/rd
	name = "research director's rubber stamp replica"
	item = "research director's"
	quality_stamps = list("fake-gud-stamp-rd", "fake-mid-stamp-rd", "fake-bad-stamp-rd")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/cmo
	name = "chief medical officer's rubber stamp replica"
	item = "chief medical officer's"
	quality_stamps = list("fake-gud-stamp-cmo", "fake-mid-stamp-cmo", "fake-bad-stamp-cmo")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/clown
	name = "clown's rubber stamp replica"
	item = "clown's"
	quality_stamps = list("fake-gud-stamp-clown", "fake-mid-stamp-clown", "fake-bad-stamp-clown")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/syndicate
	name = "syndicate rubber stamp replica"
	item = "syndicate"
	quality_stamps = list("fake-gud-stamp-syndicate", "fake-mid-stamp-syndicate", "fake-bad-stamp-syndicate")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/ntr
	name = "NanoTrasen rubber stamp replica"
	item = "NanoTrasen"
	quality_stamps = list("fake-gud-stamp-ntr", "fake-mid-stamp-ntr", "fake-bad-stamp-ntr")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/warden
	name = "warden's rubber stamp replica"
	item = "warden's"
	quality_stamps = list("fake-gud-stamp-warden", "fake-mid-stamp-warden", "fake-bad-stamp-warden")
	icon_state = "stamp-qm"
	dye_color = DYE_QM

/obj/item/stamp/replica/security
	name = "security rubber stamp replica"
	item = "security"
	quality_stamps = list("fake-gud-stamp-security", "fake-mid-stamp-security", "fake-bad-stamp-security")
	icon_state = "stamp-qm"
	dye_color = DYE_QM
