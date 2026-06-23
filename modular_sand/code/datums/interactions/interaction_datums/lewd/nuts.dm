/datum/interaction/lewd/nuts
	description = "Яйца. Потереться о лицо."
	interaction_sound = null
	required_from_user_exposed = INTERACTION_REQUIRE_BALLS
	required_from_target = INTERACTION_REQUIRE_MOUTH
	write_log_user = "make-them-suck-their-nuts"
	write_log_target = "was made to suck nuts by"
	p13user_emote = PLUG13_EMOTE_GROIN
	p13user_strength = PLUG13_STRENGTH_NORMAL
	p13target_emote = PLUG13_EMOTE_FACE
	p13target_strength = PLUG13_STRENGTH_LOW

/datum/interaction/lewd/nuts/display_interaction(mob/living/user, mob/living/partner, is_hidden)
	var/message

	//var/lust_increase = 1 // BLUEMOON EDIT commented
	var/distance = 7
	var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
	var/const/volume = 70
	if(is_hidden)
		distance = 1
	var/picked_hidden = pick(hidden_additional)
	if(user.is_fucking(partner, NUTS_TO_FACE))
		message = pick(list(
			"хватается за затылок <b>[partner]</b> и с силой тянет к своей промежности.",
			"суёт свои яйца прямо в лицо <b>[partner]</b> и широко ухмыляется.",
			"грубо суёт свои семенники прямо в рот <b>[partner]</b> с самодовольным настроем.",
			"вытаскивает покрытые слюнкой семенники из осквернённого рта <b>[partner]</b>, а затем вытирает влагу об лицо <b>[partner]</b>."))
	else
		message = pick(list(
			"втискивает свой палец сбоку в челюсти <b>[partner]</b> и с лёгкостью её разжимает, после чего использует вторую свою руку, чтобы засунуть свои семенники внутрь!",
			"встает так, чтобы пах находился в нескольких сантиметрах от лица <b>[partner]</b>, затем толкает свои бедра вперед и начинает тереться своими яйцами об лицо <b>[partner]</b>."))
		user.set_is_fucking(partner, NUTS_TO_FACE, user.getorganslot(ORGAN_SLOT_PENIS))

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/foot_dry1.ogg',
						'modular_sand/sound/interactions/oral1.ogg',
						'modular_sand/sound/interactions/oral2.ogg',), volume, 1, extrarange) //These files don't even exist but nobody noticed because double-quotes were used instead of single.
	user.visible_message(span_lewd("[is_hidden ? (picked_hidden) : null]<b>\The [user]</b> [message]"), ignored_mobs = user.get_unconsenting(), vision_distance = distance)
	// BLUEMOON EDIT START
	user.handle_post_sex(HAS_TRAIT(user, TRAIT_NYMPHO) ? NORMAL_LUST : LOW_LUST, NUTS_TO_FACE, partner, ORGAN_SLOT_PENIS)
	if(HAS_TRAIT(partner, TRAIT_NYMPHO))
		partner.handle_post_sex(LOW_LUST, partner = user)
	// BLUEMOON EDIT END

/datum/interaction/lewd/nut_smack
	description = "Яйца. Шлёпнуть по яйцам."
	interaction_sound = 'modular_sand/sound/interactions/slap.ogg'
	simple_message = "USER шлёпает семенники TARGET!"
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target_exposed = INTERACTION_REQUIRE_BALLS
	write_log_user = "slapped-nuts"
	write_log_target = "had their nuts slapped by"
	p13target_emote = "front"
	p13user_emote = PLUG13_EMOTE_GROIN
	p13user_strength = PLUG13_STRENGTH_NORMAL
