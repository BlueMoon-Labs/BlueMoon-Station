/obj/item/disk/tech_disk/research
	desc = "A research disk that will unlock a research node when uploaded into a research console."
	var/node_id

/obj/item/disk/tech_disk/research/Initialize()
	. = ..()
	SSorbits.research_disks += src
	if(node_id)
		//Диск содержит узел как «изученный», чтобы copy_research_to() при аплоаде в консоль
		//реально выдал узел (research_node с force), а не только возился с hidden_nodes.
		stored_research.researched_nodes[node_id] = TRUE
		var/datum/techweb_node/node = SSresearch.techweb_node_by_id(node_id)
		if(node)
			name = "research disk ([node.display_name])"

/obj/item/disk/tech_disk/research/Destroy()
	SSorbits.research_disks -= src
	. = ..()

/obj/item/disk/tech_disk/research/random/Initialize()
	//Пул — ВСЕ узлы игры, кроме стартовых и BEPIS (experimental).
	var/list/valid_nodes = list()
	for(var/node_id in SSresearch.techweb_nodes)
		//WHITE-STEEL PORT: служебный узел-заглушка «ERROR» (techweb_node/error_node) не должен
		//выпадать в виде диска — иначе в луте появляется бессмысленный "research disk (ERROR)".
		if(node_id == "ERROR")
			continue
		if(SSresearch.techweb_nodes_starting[node_id])
			continue
		if(SSresearch.techweb_nodes_experimental[node_id])
			continue
		//WHITE-STEEL PORT: уже выпадавший диск не генерируется повторно.
		if(SSorbits.generated_research_nodes[node_id])
			continue
		if(SSresearch.science_tech.isNodeResearchedID(node_id))
			continue
		valid_nodes += node_id
	if(!length(valid_nodes))
		new /obj/effect/spawner/lootdrop/ruinloot/basic(get_turf(src))
		return INITIALIZE_HINT_QDEL
	node_id = pick(valid_nodes)
	SSorbits.generated_research_nodes[node_id] = TRUE
	. = ..()

/obj/item/disk/tech_disk/research/boh
	node_id = "bluespace_holding"

/obj/item/disk/tech_disk/research/wormhole_gun
	node_id = "bluespace_portal"

/obj/item/disk/tech_disk/research/swapper
	node_id = "bluespace_warping"

/obj/item/disk/tech_disk/research/adv_combat_implants
	node_id = "combat_cyber_implants"

/obj/item/disk/tech_disk/research/combat_implants
	node_id = "combat_cyber_implants"

/obj/item/disk/tech_disk/research/radioactive_weapons
	node_id = "radioactive_weapons"

/obj/item/disk/tech_disk/research/beam_weapons
	node_id = "beam_weapons"

/obj/item/disk/tech_disk/research/adv_beam_weapons
	node_id = "adv_beam_weapons"

/obj/item/disk/tech_disk/research/exotic_ammo
	node_id = "exotic_ammo"

/obj/item/disk/tech_disk/research/phazon
	node_id = "mecha_phazon"

/obj/item/disk/tech_disk/research/clusterbang_launcher
	node_id = "clusterbang_launcher"
