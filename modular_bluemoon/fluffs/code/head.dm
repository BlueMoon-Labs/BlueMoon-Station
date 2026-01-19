/obj/item/clothing/head/donator/bm
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'

/obj/item/clothing/head/donator/bm/pt_crown
	name = "Crown of Pure Tyranny"
	desc = "Корона, выполненная из оникса и обсидиана, украшенная прекрасным зелёным камнем и воплощающая самое потаённое зло и ненависть, заложенные в ней. Должно быть, кто-то действительно постарался ради её создания, как и носитель, сохранивший её. Она кажется до жути знакомой."
	icon_state = "pt_crown"
	item_state = "jackboots"

/obj/item/clothing/head/donator/bm/bishop_mitre
	name = "GPC Mitre"
	desc = "Один из символов Серой Постхристианской церкви. Внушает власть и уважение одним лишь своим видом."
	icon_state = "tall_mitre"
	item_state = "balaclava"

/obj/item/clothing/head/donator/bm/blueflame
	name = "horns of blue flame"
	desc = "It's horns of blue flame. A brightly glowing hologram that looks like fire, as if someone turned on the welding."
	icon_state = "blueflame"
	item_state = "jackboots"

/obj/item/clothing/head/donator/bm/cerberus_helmet
	name = "cerberus helmet"
	desc = "Шлем-маска напоминающая собачью голову с красными глазами. Она кажется вам знакомой и навевает страх. От неё пахнет тухлым мясом, от чего кружится голова. И как её вообще носят на голове..?"
	icon_state = "cerberushelm"
	item_state = "cerberushelm"
	flags_inv = HIDEFACIALHAIR|HIDEFACE|HIDEEYES|HIDEEARS|HIDEHAIR
	actions_types = list(/datum/action/item_action/cerberbark)

/datum/action/item_action/cerberbark
	name = "BARK!"

/obj/item/clothing/head/donator/bm/cerberus_helmet/verb/cerberbark()
	set category = "Object"
	set name = "BARK!"
	set src in usr
	if(iscarbon(usr))
		var/mob/living/carbon/user = usr
		if(!isliving(user) || !can_use(user) || user.head != src)
			return

		var/phrase
		phrase = input("Какую фразу вы хотите сказать через преобразователь в шлеме?","") as text

		if(phrase)
			user.audible_message("[user] barks, <font color='red' size='4'><b>[phrase]</b></font>")
			playsound(user.loc, 'modular_bluemoon/fluffs/sound/bark.ogg', 100, 1)

/obj/item/clothing/head/donator/bm/cerberus_helmet/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/cerberbark))
		cerberbark()

/obj/item/clothing/head/helmet/space/plasmaman/security/reaper
	name = "Security Plasma Envirosuit Helmet"
	desc = "Plasmaman Envirohelmet. Has red markings and reinforced with some composite materials."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	icon_state = "pluto_enviro"

/obj/item/clothing/head/donator/bm/flektarn_beret
	name = "flektarn beret"
	desc = "Five-color, -explosive- beret in camouflage colors with a golden badge."
	icon_state = "flektarn_beret"
	item_state = "flektarn_beret"

/obj/item/clothing/head/donator/bm/nri_drg_head // civil version of nri antagonist beret
	name = "covet ops headgear"
	desc = "A special headger containing unknown fibers and electronics, providing the NVG effect for it's user. Formerly."
	icon_state = "nri_drg_ushanka"
	item_state = "nri_drg_ushanka"
	icon = 'modular_bluemoon/kovac_shitcode/icons/rus/obj_drg.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_drg.dmi'
	unique_reskin = list(
		"Ushanka" = list("icon_state" = "nri_drg_ushanka"),
		"Beret" = list("icon_state" = "nri_drg_beret")
	)

/obj/item/modkit/tagilla
	name = "Tagilla Kit"
	desc = "A modkit for making a Welding helmet into a Tagilla welding helmet."
	product = /obj/item/clothing/head/welding/tagilla
	fromitem = list(/obj/item/clothing/head/welding)

/obj/item/clothing/head/welding/tagilla
	name = "Provocateur welding Helmet"
	desc = "На вид обычная сварочная маска разрисованная с лицевой стороны,особенно выделяется надпись «Убей» под визором."
	icon_state = "provocateur"
	item_state = "provocateur"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'

/obj/item/clothing/head/HoS/dread_helmet
	name = "Шлем Судьи"
	desc = "Стандартный шлем судьи из Мега-Города Солнечной Федерации. Оснащен слоем кевлара и других материалов что защищают голову и визор что защищает от осколков и вспышек. Имеет встроенный микрофон с динамиком в который непонятно почему вам так и хочется сказать Я! ЗАКОН!"
	icon_state = "dread_helmet"
	item_state = "dread_helmet"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/head_muzzled.dmi'
	flags_cover = HEADCOVERSEYES
	flags_inv = HIDEHAIR|HIDEEARS|HIDESNOUT
	mutantrace_variation = STYLE_MUZZLE
	actions_types = list(/datum/action/item_action/dread_lawgiver)

	/// Cooldown between voice lines
	var/voice_cooldown = 0
	/// Cooldown duration (3 seconds)
	var/voice_cooldown_duration = 30

/obj/item/clothing/head/HoS/dread_helmet/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/dread_lawgiver))
		announce_law(user)
	else
		return ..()

/obj/item/clothing/head/HoS/dread_helmet/proc/announce_law(mob/living/user)
	if(!isliving(user))
		return

	// Проверка кулдауна
	if(world.time < voice_cooldown)
		to_chat(user, "<span class='warning'>Системы голосового модуля перезаряжаются...</span>")
		return

	// Объявляем ЗАКОН
	user.audible_message("<font color='red' size='4'><b>Я. ЕСТЬ. ЗАКОН!</b></font>")
	playsound(src.loc, 'sound/voice/complionator/dredd.ogg', 100, FALSE, 4)

	voice_cooldown = world.time + voice_cooldown_duration

// Action button для шлема
/datum/action/item_action/dread_lawgiver
	name = "I AM THE LAW!"
	desc = "Объявить что вы - ЗАКОН."
	button_icon_state = "sechailer"
	background_icon_state = "bg_default"

/obj/item/clothing/head/donator/bm/royal_hunters
	name = "Royal hunters hat"
	desc = "Even Hunters die, but not memories"
	icon_state = "royal_hunters"
	item_state = "royal_hunters"
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/large-worn-icons/32x48/head.dmi'

/obj/item/clothing/head/donator/bm/ushankich
	name = "ushanka"
	desc = "Perfect for winter in Siberia, da?"
	icon_state = "sovietushankadown"
	item_state = "sovietushankadown"
	flags_inv = HIDEEARS
	var/earflaps = TRUE
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = COAT_MAX_TEMP_PROTECT
	///Sprite visible when the ushanka flaps are folded up.
	var/upsprite = "sovietushankaup"
	///Sprite visible when the ushanka flaps are folded down.
	var/downsprite = "sovietushankadown"

/obj/item/clothing/head/donator/bm/ushankich/attack_self(mob/user)
	if(earflaps)
		icon_state = upsprite
		item_state = upsprite
		to_chat(user, "<span class='notice'>You raise the ear flaps on the ushanka.</span>")
	else
		icon_state = downsprite
		item_state = downsprite
		to_chat(user, "<span class='notice'>You lower the ear flaps on the ushanka.</span>")
	earflaps = !earflaps

/obj/item/clothing/head/helmet/chaplain/wh_helmet
	name = "The Helmet of the Dark Apostle"
	desc = "This is the helmet of one of the dark apostles serving the Dark Gods. The face mask is made in the shape of a screaming demon"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	icon_state = "wh_chaplain"

/obj/item/modkit/whhelmet_kit
	name = "The Helmet of the Dark Apostle modkit"
	desc = "A modkit for making an chaplain helmet into The Helmet of the Dark Apostle"
	product = /obj/item/clothing/head/helmet/chaplain/wh_helmet
	fromitem = list(/obj/item/clothing/head/helmet/chaplain, /obj/item/clothing/head/helmet/chaplain/bland/horned, /obj/item/clothing/head/helmet/chaplain/bland/winged, /obj/item/clothing/head/helmet/chaplain/bland)

//////////////////////////////////////////////////

/obj/item/clothing/head/hardhat/weldhat/mengineer
	name = "master engineer's hardhat"
	desc = "A modified piece of welding hardhat with ear cover. White-yellow coloring seems to indicate some engineering mid-rank, not used by Nanotrasen standarts. You can see personal number engraved inside the hat: KVM:829917."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	icon_state = "hardhat0_mengineer"
	item_state = "hardhat0_mengineer"
	hat_type = "mengineer"
	actions_types = list(/datum/action/item_action/toggle_helmet_light, /datum/action/item_action/toggle_welding_screen)
	flags_inv = HIDEEYES | HIDEFACE | HIDEEARS

/obj/item/clothing/head/hardhat/weldhat/mengineer/worn_overlays(isinhands, icon_file, used_state, style_flags = NONE)
	. = list()
	SEND_SIGNAL(src, COMSIG_ITEM_WORN_OVERLAYS, isinhands, icon_file, used_state, style_flags, .)
	if(!isinhands)
		if(damaged_clothes)
			. += mutable_appearance('icons/effects/item_damage.dmi', "damagedhelmet")
		if(blood_DNA)
			. += mutable_appearance('icons/effects/blood.dmi', "helmetblood", color = blood_DNA_to_color(), blend_mode = blood_DNA_to_blend())
		if(!up)
			. += mutable_appearance('icons/mob/clothing/head.dmi', "weldvisor")

/////////////////////////////////////////////////////

/obj/item/clothing/head/hardhat/weldhat/hahun
	name = "welding hood"
	desc = "A part of field technician suit, covers ears of wearer and provide a welding  visor if needed, have a built-in flashlight."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/large-worn-icons/32x48/head.dmi'
	icon_state = "hardhat0_hahun_helmet"
	item_state = "hardhat0_hahun_helmet"
	hat_type = "hahun_helmet"
	actions_types = list(/datum/action/item_action/toggle_helmet_light, /datum/action/item_action/toggle_welding_screen)
	flags_inv = HIDEEYES | HIDEFACE | HIDEEARS | HIDEHAIR

/obj/item/clothing/head/hardhat/weldhat/hahun/worn_overlays(isinhands, icon_file, used_state, style_flags = NONE)
	. = list()
	SEND_SIGNAL(src, COMSIG_ITEM_WORN_OVERLAYS, isinhands, icon_file, used_state, style_flags, .)
	if(!isinhands)
		if(damaged_clothes)
			. += mutable_appearance('icons/effects/item_damage.dmi', "damagedhelmet")
		if(blood_DNA)
			. += mutable_appearance('icons/effects/blood.dmi', "helmetblood", color = blood_DNA_to_color(), blend_mode = blood_DNA_to_blend())
		if(!up)
			. += mutable_appearance('modular_bluemoon/fluffs/icons/mob/large-worn-icons/32x48/head.dmi', "hahun_visor")

/////////////////////////////////////////////////////

/obj/item/clothing/head/HoS/beret/white
	name = "white beret"
	desc = "Armored beret in white colors for good boys and girls of NanoTrasen."
	icon_state = "hos_beret_white"
	item_state = "hos_beret_white"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/////////////////////////////////////////////////////

/obj/item/clothing/head/tricorne
	name = "Tricorne"
	desc = "A simple three cornered hat of a triangular shape."
	icon_state = "tricorne"
	item_state = "tricorne"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/////////////////////////////////////////////////////

/obj/item/clothing/head/ranger_helmet
	name = "Ranger Helmet"
	desc = "Protective equipment for special police personnel, designed to reduce damaging factors in combat and extreme conditions, it uses composite armor plate based on Kevlar and ceramic inserts resistant to shrapnel and small-caliber bullets. Lightweight, wearable and comfortable."
	icon_state = "ranger_helmet"
	item_state = "ranger_helmet"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR

/////////////////////////////////////////////////////

/obj/item/clothing/head/helmet/sec/ipai
	name = "I.P.A.I. helmet Dawn Dome"
	desc = "Уникальная разработка ателье Чёрная Роза в области защиты и маскировки. Данный экземпляр, в виде шлема, является очевидным индивидуальным заказом, однако на шлеме отсутствуют какие-либо инициалы его владельца, только неизвестный штрихкод и логотип производителя, в виде всё той же чёрной розы. Шлем гермитичен, часть корпуса имеет возможность снятия для установки бронепластин, порт для подключения кислородного баллона, а также специально STEAL-s покрытие, которое припятствует считыванию данных о внешности и личности носителя. Во внутренней части имеется маленькая табличка со знаком предупреждения и надписью - ВНИМАНИЕ! В СЛУЧАЕ ВОЗНИКНОВЕНИЯ НЕОПРЕДЕЛЁННЫХ ЗВУКОВ ИЗ ДИНАМИКОВ ПЕРЕДАЧИ ЗВУКОВЫХ ДАННЫХ ВНЕШНЕЙ СРЕДЫ, НАПОМИНАЮЩИЕ ГОЛОСА ИЛИ КРИКИ - СЛЕДУЕТ НЕМЕДЛЕННО ПРЕКРАТИТЬ НОШЕНИЕ И ДОНЕСТИ ИНФОРМАЦИЮ ДО БЛИЖАЙШЕГО ОФИСА АТЕЛЬЕ ЧЁРНАЯ РОЗА"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	icon_state = "ipai"
	item_state = "ipai"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 0)
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	clothing_flags = ALLOWINTERNALS
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	unique_reskin = null

/obj/item/clothing/head/blueshield/mu88_horns
	name = "M.U. 88 New hope horns"
	desc = "Ещё один элемент комплекта 'New hope'. Несмотря на то, что данная вещь скорее носит декоративный характер, имеет в себе скрытые и важные функции. Сами рога выполнены из прочного сплава металлов неизвестного образца. В основную часть встроены антенны для перехвата сигналов с системой датчиков жизнеобеспечения костюмов и скафандров поблизости. Также излучают небольшую сферу сильного магнитного поля, покрывающее пространство головы и 25 сантиметров по радиусу вокруг. Поле имеет защитный функционал, останавливающие все попадающие объекты со скоростью выше выставленного порога, благодаря чему по защитных характеристикам не уступает обычному баллистическому шлему. Не смотря на встроенные механизмы не требует внешней подзарядки. Под креплением расположен небольшой логотип в виде чёрной розы, а также надпись - Black Rose atelier."
	icon_state = "mu88_horns"
	item_state = "mu88_horns"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'

///////////////////////////////////////////////

/obj/item/clothing/head/donator/bm/dm_pzgrnd_helmet
	name = "pionierkorps helmet"
	desc = "A sturdy helmet primarily designed for military engineers. It comes with goggles for protection against dust and debris. Inside, you can see the inscription \"DM Arms\"."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	icon_state = "pz_grenadierhelmet"
	item_state = "pz_grenadierhelmet"
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	armor = null
	flags_inv = HIDEHAIR|HIDEEARS
	var/adjusted = FALSE

/obj/item/clothing/head/donator/bm/dm_pzgrnd_helmet/AltClick(mob/user)
	. = ..()
	adjusted = !adjusted
	flags_inv = adjusted ? (HIDEHAIR) : (HIDEHAIR|HIDEEARS)
	user.update_inv_head()
	to_chat(user, span_info("Вы поправили шлем, изменяя комфорт ваших ушей в нём."))

///////////////////////////////////////////////

/obj/item/clothing/head/donator/bm/gestapo
	name = "Truth Enforcer cap"
	desc = "Bring Justice..!~"
	icon_state = "gestapo_head"
	item_state = "gestapo_head"
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_righthand.dmi'
