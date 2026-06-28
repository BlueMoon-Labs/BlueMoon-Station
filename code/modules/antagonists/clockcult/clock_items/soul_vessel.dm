//Soul vessel: An ancient positronic brain that serves only Ratvar.
/obj/item/mmi/posibrain/soul_vessel
	name = "soul vessel"
	desc = "Тяжелый латунный куб со стороной три дюйма, с одним выступающим зубчатым колесом."
	var/clockwork_desc = "Сосуд для душ - древняя реликвия, способная притягивать души проклятых или просто вырывать разум из тела без сознания или мертвого человека.\n\
	<span class='brass'>В случае активации может служить в качестве позитронного мозга, который можно разместить в корпусах киборгов или часовых конструкций.</span>"
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "soul_vessel"
	req_access = list()
	braintype = "Слуга"
	begin_activation_message = "<span class='brass'>Вы включаете шестеренку. Она с трудом запускается и на мгновение замирает, когда начинает вращаться.</span>"
	success_message = "<span class='brass'>Вращение шестерни становится более плавным по мере активации сосуда души.</span>"
	fail_message = "<span class='warning'>Зубчатое колесо скрипнуло и с трудом остановилось. Может, попробуете ещё раз?</span>"
	new_role = "Soul Vessel"
	welcome_message = "<span class='warning'>ВСЕ ПРОШЛЫЕ ЖИЗНИ ЗАБЫТЫ.</span>\n\
	<b>Ты сосуд для души - механический разум, созданный Ратваром, Часовым Юстициаром.\n\
	Вы подчиняетесь Ратвару и его слугам. Решать, подчиняться ли кому-либо еще, остается на ваше усмотрение.\n\
	Смысл твоего существования заключается в том, чтобы способствовать достижению целей слуг и самого Ратвара. Прежде всего, служи Ратвару.</b>"
	new_mob_message = "<span class='brass'>Сосуд души выпускает струю пара, прежде чем его шестерня приходит в равновесие.</span>"
	dead_message = "<span class='deadsay'>Его шестерня, поцарапанная и помятая, лежит неподвижно.</span>"
	recharge_message = "<span class='warning'>Внутренний конденсатор Гейс сосуда души все еще заряжается!</span>"
	possible_names = list("Судья", "Страж", "Служитель", "Кузнец", "Спираль")
	autoping = FALSE
	resistance_flags = FIRE_PROOF | ACID_PROOF
	force_replace_ai_name = TRUE
	overrides_aicore_laws = TRUE

/obj/item/mmi/posibrain/soul_vessel/Initialize(mapload)
	. = ..()
	radio.on = FALSE
	laws = new /datum/ai_laws/ratvar()
	braintype = picked_name
	GLOB.all_clockwork_objects += src
	brainmob.grant_language(/datum/language/ratvar, TRUE, TRUE, LANGUAGE_CLOCKIE)

/obj/item/mmi/posibrain/soul_vessel/Destroy()
	GLOB.all_clockwork_objects -= src
	return ..()

/obj/item/mmi/posibrain/soul_vessel/examine(mob/user)
	if((is_servant_of_ratvar(user) || isobserver(user)) && clockwork_desc)
		desc = clockwork_desc
	. = ..()
	desc = initial(desc)

/obj/item/mmi/posibrain/soul_vessel/transfer_personality(mob/candidate)
	. = ..()
	if(.)
		add_servant_of_ratvar(brainmob, TRUE)

/obj/item/mmi/posibrain/soul_vessel/attack_self(mob/living/user)
	if(!is_servant_of_ratvar(user))
		to_chat(user, "<span class='warning'>Вы возитесь с [src], но это не приносит результата.</span>")
		return FALSE
	..()

/obj/item/mmi/posibrain/soul_vessel/attack(mob/living/target, mob/living/carbon/human/user)
	if(!is_servant_of_ratvar(user) || !ishuman(target))
		..()
		return
	if(QDELETED(brainmob))
		return
	if(brainmob.key)
		to_chat(user, "<span class='nezbere'>\"Этот сосуд наполнен, друг мой. Дай ему тело.\"</span>")
		return
	if(is_servant_of_ratvar(target))
		to_chat(user, "<span class='nezbere'>\"Было бы разумнее воскресить своих союзников, друг мой.\"</span>")
		return
	var/mob/living/carbon/human/H = target
	if(H.stat == CONSCIOUS)
		to_chat(user, "<span class='warning'>[H] должен быть мёртвым или без сознания, чтобы захватить [H.ru_ego()] разум!</span>")
		return
	if(H.head)
		var/obj/item/I = H.head
		if(I.flags_inv & HIDEHAIR) //they're wearing a hat that covers their skull
			to_chat(user, "<span class='warning'>Голова [H] покрыта, сначала уберите [H.ru_ego()] [H.head]!</span>")
			return
	if(H.wear_mask)
		var/obj/item/I = H.wear_mask
		if(I.flags_inv & HIDEHAIR) //they're wearing a mask that covers their skull
			to_chat(user, "<span class='warning'>Голова [H] покрыта, сначала уберите [H.ru_ego()] [H.wear_mask]!</span>")
			return
	var/obj/item/bodypart/head/HE = H.get_bodypart(BODY_ZONE_HEAD)
	if(!HE) //literally headless
		to_chat(user, "<span class='warning'>[H] не имеет головы, а значит, и разума, который можно было бы забрать!</span>")
		return
	var/obj/item/organ/brain/B = H.getorgan(/obj/item/organ/brain)
	if(!B) //either somebody already got to them or robotics did
		to_chat(user, "<span class='warning'>[H] не имеет мозга, а значит, и разума, который можно было бы забрать!</span>")
		return
	if(!H.key) //nobody's home
		to_chat(user, "<span class='warning'>[H] не имеет разума, который можно было бы забрать!</span>")
		return
	playsound(H, 'sound/misc/splort.ogg', 60, 1, -1)
	playsound(H, 'sound/magic/clockwork/anima_fragment_attack.ogg', 40, 1, -1)
	H.fakedeath("soul_vessel") //we want to make sure they don't deathgasp and maybe possibly explode
	H.death()
	H.cure_fakedeath("soul_vessel")
	H.apply_status_effect(STATUS_EFFECT_SIGILMARK) //let them be affected by vitality matrices
	picked_name = "Раб"
	braintype = picked_name
	brainmob.timeofhostdeath = H.timeofdeath
	user.visible_message("<span class='warning'>[user] прижимает [src] к голове [H], прорывая череп и аккуратно извлекая мозг!</span>", \
	"<span class='brass'>Вы извлекаете сознание [H] из [H.ru_ego()] тела и заключаете [H.ru_ego()] в сосуд души.</span>")
	transfer_personality(H)
	brainmob.fully_replace_character_name(null, "[braintype] [H.real_name]")
	name = "[initial(name)] ([brainmob.name])"
	B.Remove()
	qdel(B)
	H.update_hair()
