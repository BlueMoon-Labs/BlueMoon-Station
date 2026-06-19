// Латексный замок.
// Даёт латексной кинк-одежде возможность запираться латексным ключом
// (/obj/item/key/latex, "Latex Adjustment Override").
//
// Заперто -> на предмет вешается TRAIT_NODROP: его нельзя снять ни самому,
// ни стрипом другим игроком (force-снятие админом/раздеванием обходит, как и
// любой NODROP). Открывает только тот же ключ.
//
// Запереть предмет, надетый на ДРУГОМ игроке, можно только если у него включён
// VERB_CONSENT. Отпереть (разблокировать) - всегда.

/// Источник трейта NODROP от латексного замка. Отдельный, чтобы не конфликтовать
/// с другими источниками NODROP на том же предмете.
#define LATEX_LOCK_TRAIT "latex_lock"

/// Дефолтный флейвор при безуспешной попытке стянуть запертый предмет с себя.
GLOBAL_LIST_INIT(latex_lock_default_messages, list(
	"Вы безуспешно шарите руками по латексу в поисках застёжки.",
	"Вы не можете подцепить край - материал словно прилип к коже.",
	"Чем сильнее вы тянете, тем плотнее оно облегает.",
))

/datum/component/latex_lockable
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Заперт ли замок.
	var/locked = FALSE
	/// Пул сообщений при попытке самоснятия запертого предмета.
	var/list/lock_messages

/datum/component/latex_lockable/Initialize(locked = FALSE, list/lock_messages)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	src.locked = locked
	src.lock_messages = lock_messages || GLOB.latex_lock_default_messages

/datum/component/latex_lockable/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equipped))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_dropped))
	RegisterSignal(parent, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_ATTACK_PAW), PROC_REF(on_attack_hand))
	// Чтобы латексным ключом можно было щёлкнуть по предмету, пока он надет на
	// ДРУГОМ игроке - через меню стрипа (use_item_on_strippable -> attackby). Без
	// этого надетый запертый предмет нечем разблокировать. Заодно даёт зелёную
	// подсветку слота в меню стрипа.
	var/obj/item/item = parent
	item.interactable_in_strip_menu = TRUE
	// На случай, если предмет создан уже надетым и запертым.
	refresh_nodrop()

/datum/component/latex_lockable/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_PARENT_ATTACKBY,
		COMSIG_ITEM_EQUIPPED,
		COMSIG_ITEM_DROPPED,
		COMSIG_ATOM_ATTACK_HAND,
		COMSIG_ATOM_ATTACK_PAW,
	))
	REMOVE_TRAIT(parent, TRAIT_NODROP, LATEX_LOCK_TRAIT)
	var/obj/item/item = parent
	item.interactable_in_strip_menu = initial(item.interactable_in_strip_menu)

/// Человек, на ком предмет НАДЕТ в слоте (не в руках), иначе null.
/datum/component/latex_lockable/proc/get_wearer()
	var/obj/item/item = parent
	if(!ishuman(item.loc))
		return null
	var/mob/living/carbon/human/wearer = item.loc
	if(wearer.is_holding(item))
		return null
	return wearer

/// Выдать/снять NODROP по текущему состоянию замка и того, надет ли предмет.
/datum/component/latex_lockable/proc/refresh_nodrop()
	if(locked && get_wearer())
		ADD_TRAIT(parent, TRAIT_NODROP, LATEX_LOCK_TRAIT)
	else
		REMOVE_TRAIT(parent, TRAIT_NODROP, LATEX_LOCK_TRAIT)

/datum/component/latex_lockable/proc/on_attackby(datum/source, obj/item/weapon, mob/user, params)
	SIGNAL_HANDLER
	if(!istype(weapon, /obj/item/key/latex))
		return
	var/obj/item/item = parent
	var/mob/living/carbon/human/wearer = get_wearer()
	// Согласие нужно только при ЗАПИРАНИИ чужого надетого предмета.
	if(!locked && wearer && wearer != user)
		if(!(wearer.client?.prefs?.toggles & VERB_CONSENT))
			to_chat(user, span_warning("Они не хотят, чтобы вы это делали!"))
			return COMPONENT_NO_AFTERATTACK
	locked = !locked
	refresh_nodrop()
	to_chat(user, span_warning("[item] внезапно [locked ? "затягивается" : "ослабляется"]!"))
	return COMPONENT_NO_AFTERATTACK

/datum/component/latex_lockable/proc/on_equipped(datum/source, mob/equipper, slot)
	SIGNAL_HANDLER
	var/obj/item/item = parent
	// NODROP вешаем только когда предмет надет в свой штатный слот. Иначе запертый
	// предмет, убранный в карман/рюкзак/подсумок, оказался бы заперт там навсегда.
	if(locked && (slot & item.slot_flags))
		ADD_TRAIT(parent, TRAIT_NODROP, LATEX_LOCK_TRAIT)
	else
		REMOVE_TRAIT(parent, TRAIT_NODROP, LATEX_LOCK_TRAIT)

/datum/component/latex_lockable/proc/on_dropped(datum/source, mob/user)
	SIGNAL_HANDLER
	REMOVE_TRAIT(parent, TRAIT_NODROP, LATEX_LOCK_TRAIT)

/datum/component/latex_lockable/proc/on_attack_hand(datum/source, mob/user)
	SIGNAL_HANDLER
	if(!locked)
		return
	if(get_wearer() != user)
		return
	to_chat(user, span_purple(pick(lock_messages)))
	return COMPONENT_NO_ATTACK_HAND

#undef LATEX_LOCK_TRAIT
