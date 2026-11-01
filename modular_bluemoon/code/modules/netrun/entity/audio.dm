/// Physical speech is an explicit machine capability, never inferred from the
/// existence of a network address. Other microphones may opt in with a component.
/datum/component/netrun_audio_transceiver
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/netrun_audio_transceiver/Initialize()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/netrun_audio_transceiver/proc/transmit(mob/camera/netrun_entity/entity, message, list/spans)
	return FALSE

/datum/component/netrun_audio_transceiver/intercom/transmit(mob/camera/netrun_entity/entity, message, list/spans)
	var/obj/item/radio/intercom/intercom = parent
	if(!istype(intercom) || !intercom.on || intercom.emped || !intercom.listening)
		return FALSE
	entity.log_talk(message, LOG_SAY, tag = "netrun via [intercom]")
	if(intercom.broadcasting)
		intercom.talk_into(entity, message, null, spans)
	intercom.audible_message(span_name("[intercom]") + span_radio(" передаёт, \"[message]\""), null, intercom.canhear_range)
	return TRUE

/datum/netrun_entity_module/audio
	id = "audio"
	priority = 55
	requires = list("console")

/datum/netrun_entity_module/audio/on_install()
	return listen(owner, COMSIG_NETRUN_ENTITY_SPEAK, PROC_REF(on_speak))

/datum/netrun_entity_module/audio/proc/on_speak(datum/source, message, list/spans)
	SIGNAL_HANDLER
	if(!installed || !enabled || !owner.host_node?.is_online())
		return FALSE
	var/atom/host = owner.host_node.parent
	var/datum/component/netrun_audio_transceiver/output = host.GetComponent(/datum/component/netrun_audio_transceiver)
	return output?.transmit(owner, message, spans) || FALSE
