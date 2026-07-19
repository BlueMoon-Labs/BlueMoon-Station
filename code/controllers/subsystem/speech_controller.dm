///verb manager subsystem just for speech verbs (say/whisper/me): they run
///before SSverb_manager in the tick so speech comes out earliest (tg port).
VERB_MANAGER_SUBSYSTEM_DEF(speech_controller)
	name = "Speech Controller"
	wait = 1
	flags = SS_TICKER | SS_NO_INIT
	priority = FIRE_PRIORITY_SPEECH_CONTROLLER
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

///базовый Recover у verb_manager восстанавливает очередь из SSverb_manager -
///у сабтипа свой глобал, иначе очередь речи потерялась бы при рекавере МК
/datum/controller/subsystem/verb_manager/speech_controller/Recover()
	verb_queue = SSspeech_controller.verb_queue
