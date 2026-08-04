/datum/gas/oxygen
	id = GAS_O2
	specific_heat = 20
	name = "Oxygen"
	description = "Окислитель, без которого не горит ничего и не дышит никто. Берётся из воздухозаборника или разложением воды электролизёром. Сам по себе безвреден, но в смеси с плазмой или тритием даёт пожар, а при высоком парциальном давлении становится токсичен."
	tier = GAS_TIER_RAW
	price = 0
	oxidation_temperature = T0C - 100 // it checks max of this and fire temperature, so rarely will things spontaneously combust
	powermix = 1
	heat_penalty = 1
	transmit_modifier = 1.5

/datum/gas/oxygen/generate_TLV()
	return new/datum/tlv(16, 19, 40, 50)

/datum/gas/nitrogen
	id = GAS_N2
	specific_heat = 20
	name = "Nitrogen"
	description = "Балласт дыхательной смеси: сам не горит и горения не поддерживает, поэтому им разбавляют кислород до безопасной доли. Основа синтеза нитрила, нитрия и гипернобеля."
	tier = GAS_TIER_RAW
	price = 0
	powermix = -1
	heat_penalty = -1.5
	fire_burn_rate = 1
	fire_temperature = 2300
	fire_products = list(GAS_NITRIC = 2)
	breath_alert_info = list(
		not_enough_alert = list(
			alert_category = "not_enough_nitro",
			alert_type = /atom/movable/screen/alert/not_enough_nitro
		),
		too_much_alert = list(
			alert_category = "too_much_nitro",
			alert_type = /atom/movable/screen/alert/too_much_nitro
		)
	)

/datum/gas/carbon_dioxide //what the fuck is this?
	id = GAS_CO2
	specific_heat = 30
	name = "Carbon Dioxide"
	description = "Продукт дыхания и любого горения, поэтому на станции его всегда в избытке. Сырьё для алмаза в кристаллизаторе и для плуоксия. Не ядовит, но вытесняет кислород и в большой доле душит."
	tier = GAS_TIER_RAW
	price = 0
	powermix = 1
	heat_penalty = 0.1
	powerloss_inhibition = 1
	breath_results = GAS_O2
	breath_alert_info = list(
		not_enough_alert = list(
			alert_category = "not_enough_co2",
			alert_type = /atom/movable/screen/alert/not_enough_co2
		),
		too_much_alert = list(
			alert_category = "too_much_co2",
			alert_type = /atom/movable/screen/alert/too_much_co2
		)
	)
	fusion_power = 3
	enthalpy = -393500

/datum/gas/carbon_dioxide/generate_TLV()
	return new/datum/tlv(-1, -1, 5, 10)

/datum/gas/plasma
	id = GAS_PLASMA
	specific_heat = 200
	name = "Plasma"
	description = "Главное топливо станции и главная её опасность: горит с огромным выделением тепла и поджигает всё вокруг. Добывается из плазменных листов и с шахты. Токсична при вдыхании даже в малой доле."
	tier = GAS_TIER_RAW
	price = 0
	gas_overlay = "plasma"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS
	heat_penalty = 15
	transmit_modifier = 4
	powermix = 1
	fire_burn_rate = OXYGEN_BURN_RATE_BASE // named when plasma fires were the only fires, surely
	fire_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
	fire_products = list(GAS_CO2 = 1)
	enthalpy = FIRE_PLASMA_ENERGY_RELEASED // 3000000, 3 megajoules, 3000 kj

/datum/gas/nitrous_oxide
	id = GAS_NITROUS
	specific_heat = 40
	name = "Nitrous Oxide"
	description = "Веселящий газ: усыпляет и обезболивает, в больших дозах душит. Сырьё для BZ и для нитрила."
	tier = GAS_TIER_RAW
	price = 0
	gas_overlay = "nitrous_oxide"
	moles_visible = MOLES_GAS_VISIBLE * 2
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 10
	fire_products = list(GAS_N2 = 1)
	oxidation_rate = 0.5
	oxidation_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 100
	enthalpy = 81600
	heat_resistance = 6

/datum/gas/water_vapor
	id = GAS_H2O
	specific_heat = 40
	name = "Water Vapor"
	description = "Водяной пар. Тушит пожары и конденсируется в лёд при охлаждении. Электролизёр разлагает его на водород и кислород."
	tier = GAS_TIER_RAW
	price = 0
	gas_overlay = "water_vapor"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 8
	heat_penalty = 8
	enthalpy = -241800 // FIRE_HYDROGEN_ENERGY_RELEASED is actually what this was supposed to be
	powermix = 1
	breath_reagent = /datum/reagent/water


/datum/gas/pluoxium
	id = GAS_PLUOXIUM
	specific_heat = 80
	name = "Pluoxium"
	description = "Плотный носитель кислорода: даёт вчетверо больше кислорода на моль и не копится в крови как углекислота. Синтезируется из углекислоты, кислорода и трития. Вход в прото-нитрат."
	tier = GAS_TIER_BASIC
	price = 3.5
	gas_overlay = "pluoxium"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	fusion_power = 10
	oxidation_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 25 // it is VERY stable
	oxidation_rate = 8 // when it can oxidize, it can oxidize a LOT
	enthalpy = -2000000 // but it reduces the heat output a great deal (plasma fires add 3000000 per mole)
	powermix = -1
	heat_penalty = -1
	transmit_modifier = -5
	heat_resistance = 3

/datum/gas/pluoxium/generate_TLV()
	return new/datum/tlv(-1, -1, 5, 6)

/datum/gas/tritium
	id = GAS_TRITIUM
	specific_heat = 10
	name = "Tritium"
	description = "Радиоактивный изотоп водорода: горит жарче плазмы и облучает всё вокруг. Получается при горении плазмы в избытке кислорода. Ключевой компонент гипернобеля, нитрия и стимулума."
	tier = GAS_TIER_BASIC
	price = 3
	gas_overlay = "tritium"
	moles_visible = MOLES_GAS_VISIBLE
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 1
	powermix = 1
	heat_penalty = 10
	transmit_modifier = 30
	fire_products = list(GAS_H2O = 1)
	enthalpy = 300000
	fire_burn_rate = 2
	fire_radiation_released = 50 // arbitrary number, basically 60 moles of trit burning will just barely start to harm you
	fire_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST - 50

/datum/gas/nitric_oxide
	id = GAS_NITRIC
	specific_heat = 20
	name = "Nitric oxide"
	description = "Промежуточный продукт азотной химии, распадается сам. Практической ценности мало, но его появление означает, что в контуре идут азотные реакции."
	tier = GAS_TIER_RAW
	price = 0
	odor = "sharp sweetness"
	odor_strength = 1
	fusion_power = 15
	enthalpy = 91290
	heat_resistance = 2
	powermix = -1
	heat_penalty = -1

/datum/gas/nitryl
	id = GAS_NITRYL
	specific_heat = 20
	name = "Nitrogen dioxide"
	description = "Едкий продукт азота, закиси и кислорода при высокой температуре. Разъедает лёгкие при вдыхании. Нужен для синтеза стимулума."
	tier = GAS_TIER_BASIC
	price = 2.5
	gas_overlay = "nitryl"
	color = "#963"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 15
	fire_products = list(GAS_N2 = 0.5)
	enthalpy = 33200
	oxidation_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST - 50

/datum/gas/hypernoblium
	id = GAS_HYPERNOB
	specific_heat = 2000
	name = "Hyper-noblium"
	description = "Благородный газ, который глушит вообще все реакции в смеси - в том числе пожар и распад супермтерии. Варится из азота и трития при криогенных температурах. Лучшее аварийное средство в игре и вход в осколок супермтерии."
	// Верх полосы: своя крио-петля ниже 15 К плюс тритий из камеры сгорания -
	// два узла с противоположными режимами.
	tier = GAS_TIER_ADVANCED
	price = GAS_PRICE_MAX_TIER_ADVANCED
	gas_overlay = "freon"
	color = "#4488ff"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	fusion_power = 10

/datum/gas/hydrogen
	id = GAS_HYDROGEN
	specific_heat = 10
	name = "Hydrogen"
	description = "Лёгкий и крайне горючий газ, продукт электролиза воды. Сырьё для металлического водорода, аммиака и прото-нитрата."
	tier = GAS_TIER_BASIC
	price = 2
	flags = GAS_FLAG_DANGEROUS
	moles_visible = MOLES_GAS_VISIBLE
	color = "#ffe"
	fusion_power = 0
	powermix = 1
	heat_penalty = 3
	transmit_modifier = 10
	fire_products = list(GAS_H2O = 1)
	fire_burn_rate = 2
	fire_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST - 50

/datum/gas/bz
	id = GAS_BZ
	specific_heat = 20
	name = "BZ"
	description = "Катализатор половины верхней химии и сильный психотроп: вызывает галлюцинации и повреждает мозг. Варится из закиси азота и плазмы. Нужен для фреона, нитрия, стимулума и почти всех верхних рецептов кристаллизатора."
	tier = GAS_TIER_BASIC
	price = 3
	flags = GAS_FLAG_DANGEROUS
	fusion_power = 8
	powermix = 1
	heat_penalty = 5
	enthalpy = FIRE_CARBON_ENERGY_RELEASED // it is a mystery
	transmit_modifier = -2
	radioactivity_modifier = 5

/datum/gas/stimulum
	id = GAS_STIMULUM
	specific_heat = 5
	odor = "the color blue" // fast
	odor_strength = 10
	name = "Stimulum"
	description = "Боевой стимулятор в газовой форме: снимает усталость и держит на ногах. Самая дорогая цепочка в игре - требует трития, плазмы, нитрила и BZ-катализатора одновременно."
	// Вершина не по глубине, а по ширине: четыре газа в одной камере плюс
	// температура, которую обычная разводка не держит.
	tier = GAS_TIER_EXOTIC
	price = 18
	fusion_power = 7

/datum/gas/miasma
	id = GAS_MIASMA
	specific_heat = 20
	fusion_power = 50
	flags = GAS_FLAG_DANGEROUS
	// snowflaked odor
	name = "Miasma"
	description = "Трупный газ. Скапливается там, где давно лежат тела, вызывает болезни и отвратительно пахнет. Выжигается огнём и разлагается сам в жаре."
	tier = GAS_TIER_RAW
	price = 1
	gas_overlay = "miasma"
	color = "#963"
	moles_visible = MOLES_GAS_VISIBLE * 60

/datum/gas/methane
	id = GAS_METHANE
	specific_heat = 30
	name = "Methane"
	description = "Горючий газ биологического происхождения. Дешёвое топливо, но при утечке в атмосферу станции даёт объёмный взрыв."
	tier = GAS_TIER_RAW
	price = 1
	odor = "natural gas"
	odor_strength = 2
	flags = GAS_FLAG_DANGEROUS
	powerloss_inhibition = 1
	heat_resistance = 3
	breath_results = GAS_METHYL_BROMIDE
	fire_products = list(GAS_CO2 = 1, GAS_H2O = 2)
	fire_burn_rate = 0.5
	breath_alert_info = list(
		not_enough_alert = list(
			alert_category = "not_enough_ch4",
			alert_type = /atom/movable/screen/alert/not_enough_ch4
		),
		too_much_alert = list(
			alert_category = "too_much_ch4",
			alert_type = /atom/movable/screen/alert/too_much_ch4
		)
	)
	enthalpy = -74600
	fire_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST

/datum/gas/methyl_bromide
	id = GAS_METHYL_BROMIDE
	specific_heat = 42
	name = "Methyl Bromide"
	description = "Пестицид в газовой форме: убивает всё живое в гидропонике, включая сорняки и вредителей. Для людей ядовит."
	tier = GAS_TIER_RAW
	price = 1
	powermix = 1
	heat_penalty = -1
	flags = GAS_FLAG_DANGEROUS
	breath_alert_info = list(
		not_enough_alert = list(
			alert_category = "not_enough_ch3br",
			alert_type = /atom/movable/screen/alert/not_enough_ch3br
		),
		too_much_alert = list(
			alert_category = "too_much_ch3br",
			alert_type = /atom/movable/screen/alert/too_much_ch3br
		)
	)
	fire_products = list(GAS_CO2 = 1, GAS_H2O = 1.5, GAS_BROMINE = 0.5)
	enthalpy = -35400
	fire_burn_rate = 4 / 7 // oh no
	fire_temperature = 808 // its autoignition; it apparently doesn't spark readily, so i don't put it lower

/datum/gas/bromine
	id = GAS_BROMINE
	specific_heat = 76
	name = "Bromine"
	description = "Едкий галоген, продукт распада метилбромида. Разъедает дыхательные пути."
	tier = GAS_TIER_RAW
	price = 0.5
	flags = GAS_FLAG_DANGEROUS | GAS_FLAG_CHEMICAL
	group = GAS_GROUP_CHEMICALS
	color = "#6e1f00"
	moles_visible = MOLES_GAS_VISIBLE
	odor = "bromine" // it's a very recognizable smell
	odor_strength = 0.1
	enthalpy = 193 // yeah it's small but it's good to include it
	breath_reagent = /datum/reagent/bromine

/datum/gas/ammonia
	id = GAS_AMMONIA
	specific_heat = 35
	name = "Ammonia"
	description = "Удобрение в газовой форме: ускоряет рост растений в гидропонике. Синтезируется из водорода и азота. Раздражает лёгкие."
	tier = GAS_TIER_RAW
	price = 0.5
	odor = "ammonia"
	odor_strength = 0.01
	flags = GAS_FLAG_DANGEROUS | GAS_FLAG_CHEMICAL
	group = GAS_GROUP_CHEMICALS
	enthalpy = -45900
	breath_reagent = /datum/reagent/ammonia
	fire_products = list(GAS_H2O = 1.5, GAS_N2 = 0.5)
	fire_burn_rate = 4/3
	fire_temperature = 924

/datum/gas/quark_matter
	id = GAS_QCD
	specific_heat = 10
	name = "Quark Matter"
	description = "Экзотическая материя, существующая только при чудовищных энергиях. Продукт распада адронов в HFR."
	tier = GAS_TIER_EXOTIC
	// Нижняя граница полосы: температура нужна запредельная, но выходит материи
	// сразу тысячами молей, и ниже 1.99e12 К она конденсируется обратно.
	price = GAS_PRICE_MIN_TIER_EXOTIC
	flags = GAS_FLAG_DANGEROUS
	powermix = -1
	transmit_modifier = -10
	heat_penalty = -10

/datum/gas/helium
	id = GAS_HELIUM
	specific_heat = 15
	name = "Helium"
	description = "Инертный газ, ни с чем не реагирует. Нужен кристаллизатору для ультра-ячейки."
	// Своего окна у хилия нет: он выпадает побочным продуктом реакции
	// прото-нитрата с BZ. Отсюда уровень прото-нитрата и низ его полосы.
	tier = GAS_TIER_ADVANCED
	price = GAS_PRICE_MIN_TIER_ADVANCED
	fusion_power = 7

/datum/gas/freon
	id = GAS_FREON
	specific_heat = 600
	name = "Freon"
	description = "Хладагент, поглощающий тепло при горении вместо того чтобы его выделять - единственный газ, которым можно тушить пожар охлаждением. Варится из BZ, углекислоты и плазмы. Вход в горячий лёд и в хилий."
	tier = GAS_TIER_BASIC
	price = 4
	gas_overlay = "freon"
	color = "#66ccff"
	moles_visible = MOLES_GAS_VISIBLE * 15
	fusion_power = -5
	flags = GAS_FLAG_DANGEROUS
	breath_reagent = /datum/reagent/freon

/datum/gas/halon
	id = GAS_HALON
	specific_heat = 175
	name = "Halon"
	description = "Пожарный газ: связывает кислород и гасит пламя, попутно охлаждая помещение. Опасен тем же, чем полезен - в загазованной комнате нечем дышать."
	tier = GAS_TIER_BASIC
	price = 3.5
	gas_overlay = "halon"
	color = "#44cc44"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	flags = GAS_FLAG_DANGEROUS
	breath_reagent = /datum/reagent/halon

/datum/gas/antinoblium
	id = GAS_ANTINOBLIUM
	specific_heat = 1
	name = "Antinoblium"
	description = "Аномальный газ, который размножается сам и разгоняет реакции вместо того чтобы их глушить. Не синтезируется штатно. Нужен для заукерита и осколка супермтерии."
	// Верх всей лестницы: гипернобель под разрядом супермтерии либо HFR на
	// предпоследнем уровне мощности.
	tier = GAS_TIER_EXOTIC
	price = GAS_PRICE_MAX_TIER_EXOTIC
	gas_overlay = "antinoblium"
	color = "#9966ff"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	fusion_power = 20
	flags = GAS_FLAG_DANGEROUS

/datum/gas/proto_nitrate
	id = GAS_PROTO_NITRATE
	specific_heat = 30
	name = "Proto Nitrate"
	description = "Реактивный газ, по-разному отвечающий на водород, тритий и BZ - на этом строят каскадные схемы. Варится из водорода и плуоксия."
	tier = GAS_TIER_ADVANCED
	price = 7
	gas_overlay = "proto_nitrate"
	color = "#44dd66"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	flags = GAS_FLAG_DANGEROUS

/datum/gas/zauker
	id = GAS_ZAUKER
	specific_heat = 350
	name = "Zauker"
	description = "Боевой отравляющий газ: убивает быстро и без шансов. Самая глубокая цепочка в игре - гипернобель плюс нитрий, каждый со своим синтезом. Распадается в присутствии азота."
	// Криогенный гипернобель и горячий нитрий в одной камере - две несовместимые
	// ветки сразу. До калибровки заукер стоил 7 против 6 у вдвое более простого
	// нитрия; ровно здесь лестница и разъехалась.
	tier = GAS_TIER_EXOTIC
	price = 20
	gas_overlay = "zauker"
	color = "#6644aa"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	flags = GAS_FLAG_DANGEROUS

/datum/gas/healium
	id = GAS_HEALIUM
	specific_heat = 10
	name = "Healium"
	description = "Лечебный газ: восстанавливает раны и вводит в целебный сон. Варится из BZ и фреона. Основа медицинской атмосферики."
	tier = GAS_TIER_ADVANCED
	price = 8
	gas_overlay = "generic"
	color = "#ff4444"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	flags = GAS_FLAG_DANGEROUS

/datum/gas/nitrium
	id = GAS_NITRIUM
	specific_heat = 10
	name = "Nitrium"
	description = "Стимулятор, ускоряющий движение и реакции, но накапливающийся в организме как токсин. Варится из BZ, азота и трития. Распадается в присутствии кислорода."
	tier = GAS_TIER_ADVANCED
	price = 7
	gas_overlay = "nitrium"
	color = "#8b7355"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	fusion_power = 7
	flags = GAS_FLAG_DANGEROUS

// Оба газа ниже требуют давления, до которого не достаёт газовый насос.
// Облако обоим даёт готовое состояние "generic" - новых спрайтов не рисуется,
// различает их цвет.
/datum/gas/pyronite
	id = GAS_PYRONITE
	specific_heat = 25
	name = "Pyronite"
	description = "Топливо высокого давления: горит вдвое жарче плазмы и питает верхние рецепты кристаллизатора. Варится из трития и плазмы на прото-нитрате при 1500-6000 K и давлении не ниже 15000 кПа - его дают объёмный насос или нагрев контура. Смертельно опасен тем же, чем полезен: попав в помещение вместе с кислородом, выжигает его целиком."
	gas_overlay = "generic"
	color = "#ff7722"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	flags = GAS_FLAG_DANGEROUS
	// Свойств супермтерии у обоих газов намеренно нет: связка "новое топливо -
	// новый режим кристалла" это отдельная балансная работа, а не побочный
	// эффект добавления газа.
	fire_products = list(GAS_CO2 = 1, GAS_H2O = 1)
	fire_burn_rate = 1
	fire_temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
	enthalpy = PYRONITE_COMBUSTION_ENERGY
	// Вершина цепочки: реакция требует давления, которое надо собирать
	// осознанно. Отсюда и цена выше заукера - тот при всей своей глубине
	// варится на обычном насосе.
	tier = GAS_TIER_EXOTIC
	price = 22

/datum/gas/fluxin
	id = GAS_FLUXIN
	specific_heat = 45
	name = "Fluxin"
	description = "Катализатор: раздвигает верхнюю границу температурного окна плуоксия, прото-нитрата, хилия и заукера и снижает расход сырья в них - то есть делает дешевле саму глубину. Варится из гелия, BZ и плазмы при 300-600 K и давлении не ниже 15000 кПа. Медленно тратится в тех реакциях, которым помогает, и не ядовит сам по себе - опасен тем, что уводит чужие реакции туда, где контур к ним не готов."
	gas_overlay = "generic"
	color = "#33ddcc"
	moles_visible = MOLES_GAS_VISIBLE * 0.5
	// Как и пиронит: за порогом высокого давления, значит вершина цепочки.
	// Дороже пиронита, потому что удешевляет саму глубину - работает на всю
	// цепочку, а не на один рецепт.
	tier = GAS_TIER_EXOTIC
	price = 24
