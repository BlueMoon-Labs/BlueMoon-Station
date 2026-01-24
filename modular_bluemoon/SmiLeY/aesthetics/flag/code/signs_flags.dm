/obj/structure/sign/flag
	name = "blank flag"
	desc = "The flag of nothing. It has nothing on it. Magnificient."
	icon = 'modular_bluemoon/SmiLeY/aesthetics/flag/icons/flags.dmi'
	icon_state = "flag_coder"
	buildable_sign = FALSE
	custom_materials = null
	var/item_flag = /obj/item/sign/flag

/obj/structure/sign/flag/wrench_act(mob/living/user, obj/item/wrench/I)
	return

/obj/structure/sign/flag/welder_act(mob/living/user, obj/item/I)
	return

/obj/structure/sign/flag/MouseDrop(over_object, src_location, over_location)
	. = ..()
	if(over_object == usr && Adjacent(usr))
		if(!item_flag || src.flags_1 & NODECONSTRUCT_1)
			return
		if(!usr.canUseTopic(src, be_close = TRUE, no_dextery = TRUE))
			return
		usr.visible_message(span_notice("[usr] grabs and folds \the [src.name]."), span_notice("You grab and fold \the [src.name]."))
		var/obj/item/flag_item = new item_flag(loc)
		TransferComponents(flag_item)
		usr.put_in_hands(flag_item)
		qdel(src)

/obj/structure/sign/flag/ssc
	name = "flag of the Kingdom of Agurkrral"
	desc = "The flag of the Kingdom of Agurkrral."
	icon_state = "flag_agurk"
	item_flag = /obj/item/sign/flag/ssc

/obj/structure/sign/flag/nanotrasen
	name = "flag of Nanotrasen"
	desc = "The official corporate flag of Nanotrasen. Mostly flown as a ceremonial piece, or to mark land on a new frontier."
	icon_state = "flag_nt"
	item_flag = /obj/item/sign/flag/nanotrasen

/obj/structure/sign/flag/tizira
	name = "flag of the Republic of Northern Moghes"
	desc = "The flag of the Great Republic of Northern Moghes. Depending on who you ask, it represents strength or being an ant in the hive."
	icon_state = "flag_tizira"
	item_flag = /obj/item/sign/flag/tizira

/obj/structure/sign/flag/mothic
	name = "flag of the Grand Nomad Fleet"
	desc = "The flag of the Mothic Grand Nomad Fleet. A classic naval ensign, its use has superceded the old national flag which can be seen in its canton."
	icon_state = "flag_mothic"
	item_flag = /obj/item/sign/flag/mothic

/obj/structure/sign/flag/mars
	name = "flag of the Teshari League for Self-Determination"
	desc = "The flag of the Teshari League for Self-Determination. Originally a revolutionary flag during the time of the Republic of the Golden Feather, it has since been adopted as the official flag of the planet, as a reminder of how Teshari fought for representation and independence."
	icon_state = "flag_mars"
	item_flag = /obj/item/sign/flag/mars

/obj/structure/sign/flag/mars_sol
	name = "flag of the Mars"
	desc = "The flag of Mars. Originally a revolutionary flag during the Martian Rebellions, it has since been adopted as the official flag of the planet controlled by the Solar Federation."
	icon_state = "flag_mars_sol"
	item_flag = /obj/item/sign/flag/mars_sol

/obj/structure/sign/flag/ger_sol
	name = "flag of the FRG"
	desc = "The flag of the Federal Republic of Germany, known as one of the many Solar Federation regions located on Terra."
	icon_state = "flag_ger_sol"
	item_flag = /obj/item/sign/flag/ger_sol

/obj/structure/sign/flag/humancommonwealth
	name = "flag of Human Commonwealth Association"
	desc = "The official flag of the political party Human Commonwealth, which proudly flies over the soul of every human. If you have this flag, then you most likely belong to this association."
	icon_state = "flag_hca"
	item_flag = /obj/item/sign/flag/humancommonwealth

/obj/structure/sign/flag/terragov
	name = "flag of Sol Federation"
	desc = "The flag of Sol Federation. It's a symbol of humanity no matter where they go, or how much they wish it wasn't."
	icon_state = "flag_solfed"
	item_flag = /obj/item/sign/flag/terragov

/obj/structure/sign/flag/nri
	name = "flag of the Novaya Rossiyskaya Imperiya"
	desc = "The flag of the Novaya Rossiyskaya Imperiya. The yellow, black and white colours represent its sovereignity, spirituality and pureness."
	icon_state = "flag_nri"
	item_flag = /obj/item/sign/flag/nri

/// Please, for the love of God, use this in Black Mesa ONLY. NOWHERE ELSE. It's the only reason it was allowed in the game.
/obj/structure/sign/flag/usa
	name = "flag of the United States of America"
	desc = "'Stars and Stripes', the flag of the United States of America. Its red color represents endurance and valor; blue one shows diligence, vigilance and justice, and the white one signs at pureness. Its thirteen red-and-white stripes show the initial thirteen founding colonies, and fifty stars designate the current fifty states."
	icon_state = "flag_usa"
	item_flag = /obj/item/sign/flag/usa

/obj/structure/sign/flag/syndicate
	name = "flag of the Syndicate"
	desc = "The flag of the Sothran Syndicate. Previously used by the Sothran people as a way of declaring opposition against the Nanotrasen, now it became an intergalactic symbol of the same, yet way more skewed purpose, as more groups of interest have joined the rebellion's side for their own gain."
	icon_state = "flag_syndi"
	item_flag = /obj/item/sign/flag/syndicate

/obj/structure/sign/flag/vulp
	name = "flag of Vulpkanins"
	desc = "Flag of humanoid dog-like organisms from the Vazzend system. Now they live on the Kellun and Dalhstadt, although their original homeland was known as Altam."
	icon_state = "flag_vulp"
	item_flag = /obj/item/sign/flag/vulp

/obj/structure/sign/flag/syndicate/directional/north //Pixel offsets get overwritten on New()
	dir = SOUTH
	pixel_y = 32

/obj/structure/sign/flag/syndicate/directional/south
	dir = NORTH
	pixel_y = -32

/obj/structure/sign/flag/syndicate/directional/east
	dir = WEST
	pixel_x = 32

/obj/structure/sign/flag/syndicate/directional/west
	dir = EAST
	pixel_x = -32

/obj/structure/sign/flag/rus
	name = "флаг Старой Российской Федерации"
	desc = "Флаг некогда великого Государства, обладающего огромными землями, возможностями, а также огромным Советским Наследством, всё из чего по итогу было уничтожено политическими махинациями политиков этого же самого Государства."
	icon_state = "flag_rus"
	item_flag = /obj/item/sign/flag/rus

/obj/structure/sign/flag/soviet
	name = "флаг Союза Советских Социалистических Республик"
	desc = "Флаг некогда великого Государства, которое максимально сильно приблизилось к значению Утопичной Диктатуры. От флага ощущается сильный запах... железа. Или крови? Из чего сделана эта красная краска?"
	icon_state = "flag_soviet"
	item_flag = /obj/item/sign/flag/soviet

/obj/structure/sign/flag/germany
	name = "flag of the Germany"
	desc = "Die Flagge eines einst aufstrebenden Staates, der heute irgendwo in der Geschichte verloren ist. Aus irgendeinem Grund riecht sie nach Asche..."
	icon_state = "flag_ger"

/obj/structure/sign/flag/ukraine
	name = "flag of the Ukraine"
	desc = "Прапор колись особливо героїчної держави, яку було загублено в попелищі Земної Історії..."
	icon_state = "flag_ua"

/obj/structure/sign/flag/belarus
	name = "сцяг Беларусі"
	desc = "Сцяг некалі самай лепшай дзяржавы на планеце з наймацнейшым лідэрам, вядомым як Дужы Арэшак"
	icon_state = "flag_bel"


/obj/structure/sign/flag/chechnya
	name = "flag of the Chechnya"
	desc = "Круто!!!"
	icon_state = "flag_chechen"

/obj/item/sign/flag
	name = "folded blank flag"
	desc = "The folded flag of nothing. It has nothing on it. Beautiful. {CTRL+SHIFT+LMB}"
	icon = 'modular_bluemoon/SmiLeY/aesthetics/flag/icons/flags.dmi'
	icon_state = "folded_coder"
	w_class = WEIGHT_CLASS_SMALL
	sign_path = /obj/structure/sign/flag
	unique_reskin = list(
		"NanoTrasen" = list(
			RESKIN_ICON_STATE = "folded_nt",
			RESKIN_ITEM_STATE = "folded_nt",
			sign_path = /obj/structure/sign/flag/nanotrasen
		),
		"Syndicate" = list(
			RESKIN_ICON_STATE = "folded_syndi",
			RESKIN_ITEM_STATE = "folded_syndi",
			sign_path = /obj/structure/sign/flag/syndicate
		),
		"Solar Federation" = list(
			RESKIN_ICON_STATE = "folded_solfed",
			RESKIN_ITEM_STATE = "folded_solfed",
			sign_path = /obj/structure/sign/flag/terragov
		),
		"Sol Mars" = list(
			RESKIN_ICON_STATE = "folded_mars_sol",
			RESKIN_ITEM_STATE = "folded_mars_sol",
			sign_path = /obj/structure/sign/flag/mars_sol
		),
		"Sol FRG" = list(
			RESKIN_ICON_STATE = "folded_ger_sol",
			RESKIN_ITEM_STATE = "folded_ger_sol",
			sign_path = /obj/structure/sign/flag/ger_sol
		),
		"New Russian Empire" = list(
			RESKIN_ICON_STATE = "folded_nri",
			RESKIN_ITEM_STATE = "folded_nri",
			sign_path = /obj/structure/sign/flag/nri
		),
		"Vulpkanin" = list(
			RESKIN_ICON_STATE = "folded_vulp",
			RESKIN_ITEM_STATE = "folded_vulp",
			sign_path = /obj/structure/sign/flag/vulp
		),
		"Human Commonwealth Association" = list(
			RESKIN_ICON_STATE = "folded_flag_hca",
			RESKIN_ITEM_STATE = "folded_flag_hca",
			sign_path = /obj/item/sign/flag/humancommonwealth
		),
		"Independent Mars" = list(
			RESKIN_ICON_STATE = "folded_mars",
			RESKIN_ITEM_STATE = "folded_mars",
			sign_path = /obj/structure/sign/flag/mars
		),
		"Shigu" = list(
			RESKIN_ICON_STATE = "folded_shigu",
			RESKIN_ITEM_STATE = "folded_shigu",
			sign_path = /obj/structure/sign/flag/shigu
		),
		"Goldring" = list(
			RESKIN_ICON_STATE = "folded_goldring",
			RESKIN_ITEM_STATE = "folded_goldring",
			sign_path = /obj/structure/sign/flag/goldring
		),
	)

///Since all of the signs rotate themselves on initialisation, this made folded flags look ugly (and more importantly rotated).
///And thus, it gets removed to make them aesthetically pleasing once again.
/obj/item/sign/flag/Initialize(mapload)
	. = ..()
	var/matrix/rotation_reset = matrix()
	rotation_reset.Turn(0)
	transform = rotation_reset

/obj/item/sign/flag/welder_act(mob/living/user, obj/item/I)
	return

/obj/item/sign/flag/nanotrasen
	name = "folded flag of the Nanotrasen"
	desc = "The folded flag of the Nanotrasen."
	icon_state = "folded_nt"
	sign_path = /obj/structure/sign/flag/nanotrasen

/obj/item/sign/flag/syndicate
	name = "folded flag of the Syndicate"
	desc = "The folded flag of the Sothran Syndicate."
	icon_state = "folded_syndi"
	sign_path = /obj/structure/sign/flag/syndicate

/obj/item/sign/flag/ssc
	name = "folded flag of the Kingdom of Agurkrral"
	desc = "The folded flag of the Kingdom of Agurkrral."
	icon_state = "folded_agurk"
	sign_path = /obj/structure/sign/flag/ssc

/obj/item/sign/flag/terragov
	name = "folded flag of the Sol Federation"
	desc = "The folded flag of Sol Federation."
	icon_state = "folded_solfed"
	sign_path = /obj/structure/sign/flag/terragov

/obj/item/sign/flag/tizira
	name = "folded flag of the Republic of Northern Moghes"
	desc = "The folded flag of the Republic of Northern Moghes."
	icon_state = "folded_tizira"
	sign_path = /obj/structure/sign/flag/tizira

/obj/item/sign/flag/mothic
	name = "folded flag of the Grand Nomad Fleet"
	desc = "The folded flag of the Grand Nomad Fleet."
	icon_state = "folded_mothic"
	sign_path = /obj/structure/sign/flag/mothic

/obj/item/sign/flag/mars
	name = "folded flag of the Teshari League for Self-Determination"
	desc = "The folded flag of the Teshari League for Self-Determination."
	icon_state = "folded_mars"
	sign_path = /obj/structure/sign/flag/mars

/obj/item/sign/flag/nri
	name = "folded flag of the Novaya Rossiyskaya Imperiya"
	desc = "The folded flag of the Novaya Rossiyskaya Imperiya."
	icon_state = "folded_nri"
	sign_path = /obj/structure/sign/flag/nri

/// Please, for the love of God, use this in Black Mesa ONLY. NOWHERE ELSE. It's the only reason it was allowed in the game.
/obj/item/sign/flag/usa
	name = "folded flag of the United States of America"
	desc = "The folded flag of the United States of America."
	icon_state = "folded_usa"
	sign_path = /obj/structure/sign/flag/usa

/obj/item/sign/flag/rus
	name = "folded flag of the Russian Federation"
	desc = "The folded flag of the Russian Federation."
	icon_state = "folded_coder"
	sign_path = /obj/structure/sign/flag/rus

/obj/item/sign/flag/soviet
	name = "folded flag of the Soviet Union"
	desc = "The folded flag of the Soviet Union."
	icon_state = "folded_coder"
	sign_path = /obj/structure/sign/flag/soviet

/// Flags related to the sergals canon
/obj/item/sign/flag/shigu
	name = "folded flag of the Shigu Empire"
	desc = "The folded flag of the Shigu Empire."
	icon_state = "folded_shigu"
	sign_path = /obj/structure/sign/flag/shigu

/// Flags related to the sergals canon
/obj/structure/sign/flag/shigu
	name = "flag of the Shigu Empire"
	desc = "This is the flag of the Shigu Empire. The Shigu Empire was once just an association of northern tribes that feared and revered wildlife. However, with the arrival of General Rain, Shigu became the largest empire, which seized a huge amount of land, but returned some of it when her son ascended to the throne."
	icon_state = "flag_shigu"
	item_flag = /obj/item/sign/flag/shigu

/// Flags related to the sergals canon
/obj/item/sign/flag/goldring
	name = "folded flag of the Gold Ring"
	desc = "The folded flag of the Gold Ring."
	icon_state = "folded_goldring"
	sign_path = /obj/structure/sign/flag/goldring

/// Flags related to the sergals canon
/obj/structure/sign/flag/goldring
	name = "flag of the Gold Ring"
	desc = "This is the flag of the Gold Ring. The Golden Ring is a megalopolis in the southern part of Tal that has grown to the size of a full-fledged state. Being located around the ColVilous salt Lake, the Golden Ring has become an oasis in the boundless desert where trade and culture flourish"
	icon_state = "flag_goldring"
	item_flag = /obj/item/sign/flag/goldring

/obj/item/sign/flag/vulp
	name = "folded flag of Vulpkanins"
	desc = "The folded flag of Vulps."
	icon_state = "folded_vulp"
	sign_path = /obj/structure/sign/flag/vulp

/obj/item/sign/flag/mars_sol
	name = "folded flag of the Mars"
	desc = "The folded flag of the Sol Mars."
	icon_state = "folded_mars_sol"
	sign_path = /obj/structure/sign/flag/mars_sol

/obj/item/sign/flag/ger_sol
	name = "folded flag of the FRG"
	desc = "The folded flag of the Sol FRG."
	icon_state = "folded_ger_sol"
	sign_path = /obj/structure/sign/flag/ger_sol

/obj/item/sign/flag/humancommonwealth
	name = "folded flag of the Human Commonwealth Association"
	desc = "The folded flag of the Human Commonwealth Association. Humanity above all!"
	icon_state = "folded_flag_hca"
	sign_path = /obj/structure/sign/flag/humancommonwealth

/obj/structure/sign/flag/ravenheart
	name = "flag of Ravenheart"
	desc = "Красный флаг с изображением вороны."
	icon_state = "full"
	item_flag = /obj/item/sign/flag/ravenheart

/obj/item/sign/flag/ravenheart
	name = "folded flag of the Ravenheart"
	desc = "Сложенный флаг графства \"Воронье Сердце\"."
	icon_state = "mini"
	sign_path = /obj/structure/sign/flag/ravenheart

/obj/structure/sign/flag/ravenheart/alt
	name = "banner of Ravenheart"
	desc = "Красный баннер с изображением вороны."
	icon_state = "full_alt"
	item_flag = /obj/item/sign/flag/ravenheart/alt

/obj/item/sign/flag/ravenheart/alt
	name = "rolled banner of the Ravenheart"
	desc = "Свёрнутый баннер графства \"Воронье Сердце\"."
	icon_state = "mini_alt"
	sign_path = /obj/structure/sign/flag/ravenheart/alt

/obj/structure/sign/flag/saareflag
	name = "SAARE flag"
	desc = "The Hephaestus flag, designed for SAARE, hangs on walls without any physical effort and sits perfectly."
	icon_state = "flag_saare"
	item_flag = /obj/item/sign/flag/saaref

/obj/item/sign/flag/saaref
	name = "folded flag of the SAARE"
	desc = "The folded flag of the SAARE."
	icon_state = "folded_saare"
	sign_path = /obj/structure/sign/flag/saareflag
