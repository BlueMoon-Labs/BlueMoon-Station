#define MC_TICK_CHECK ( ( TICK_USAGE > Master.current_ticklimit || src.state != SS_RUNNING ) ? pause() : 0 )

#define MC_SPLIT_TICK_INIT(phase_count) var/original_tick_limit = Master.current_ticklimit; var/split_tick_phases = ##phase_count
#define MC_SPLIT_TICK \
	if(split_tick_phases > 1){\
		Master.current_ticklimit = ((original_tick_limit - TICK_USAGE) / split_tick_phases) + TICK_USAGE;\
		--split_tick_phases;\
	} else {\
		Master.current_ticklimit = original_tick_limit;\
	}

// Used to smooth out costs to try and avoid oscillation.
#define MC_AVERAGE_FAST(average, current) (0.7 * (average) + 0.3 * (current))
#define MC_AVERAGE(average, current) (0.8 * (average) + 0.2 * (current))
#define MC_AVERAGE_SLOW(average, current) (0.9 * (average) + 0.1 * (current))

#define MC_AVG_FAST_UP_SLOW_DOWN(average, current) (average > current ? MC_AVERAGE_SLOW(average, current) : MC_AVERAGE_FAST(average, current))
#define MC_AVG_SLOW_UP_FAST_DOWN(average, current) (average < current ? MC_AVERAGE_SLOW(average, current) : MC_AVERAGE_FAST(average, current))

#define NEW_SS_GLOBAL(varname) if(varname != src){if(istype(varname)){Recover();qdel(varname);}varname = src;}

#define START_PROCESSING(Processor, Datum) if (!(Datum.datum_flags & DF_ISPROCESSING)) {Datum.datum_flags |= DF_ISPROCESSING;Processor.processing += Datum}
#define STOP_PROCESSING(Processor, Datum) Datum.datum_flags &= ~DF_ISPROCESSING;Processor.processing -= Datum;Processor.currentrun -= Datum

//! SubSystem flags (Please design any new flags so that the default is off, to make adding flags to subsystems easier)

/// Returns true if the MC is initialized and running.
/// Optional argument init_stage controls what stage the mc must have initializted to count as initialized. Defaults to INITSTAGE_MAX if not specified.
#define MC_RUNNING(INIT_STAGE...) (Master && Master.processing > 0 && Master.current_runlevel)

/// subsystem does not initialize.
#define SS_NO_INIT 1

/** subsystem does not fire. */
/// (like can_fire = 0, but keeps it from getting added to the processing subsystems list)
/// (Requires a MC restart to change)
#define SS_NO_FIRE 2

/** Subsystem only runs on spare cpu (after all non-background subsystems have ran that tick) */
/// SS_BACKGROUND has its own priority bracket, this overrides SS_TICKER's priority bump
#define SS_BACKGROUND 4

/// subsystem does not tick check, and should not run unless there is enough time (or its running behind (unless background))
#define SS_NO_TICK_CHECK 8

/** Treat wait as a tick count, not DS, run every wait ticks. */
/// (also forces it to run first in the tick (unless SS_BACKGROUND))
/// (implies all runlevels because of how it works)
/// This is designed for basically anything that works as a mini-mc (like SStimer)
#define SS_TICKER 16

/** keep the subsystem's timing on point by firing early if it fired late last fire because of lag */
/// ie: if a 20ds subsystem fires say 5 ds late due to lag or what not, its next fire would be in 15ds, not 20ds.
#define SS_KEEP_TIMING 32

/** Calculate its next fire after its fired. */
/// (IE: if a 5ds wait SS takes 2ds to run, its next fire should be 5ds away, not 3ds like it normally would be)
/// This flag overrides SS_KEEP_TIMING
#define SS_POST_FIRE_TIMING 64

//! SUBSYSTEM STATES
#define SS_IDLE 0		/// ain't doing shit.
#define SS_QUEUED 1		/// queued to run
#define SS_RUNNING 2	/// actively running
#define SS_PAUSED 3		/// paused by mc_tick_check
#define SS_SLEEPING 4	/// fire() slept.
#define SS_PAUSING 5 	/// in the middle of pausing

#define SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/controller/subsystem/##X);\
/datum/controller/subsystem/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
	PreInit();\
}\
/datum/controller/subsystem/##X

#define MOVEMENT_SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/controller/subsystem/movement/##X);\
/datum/controller/subsystem/movement/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
	PreInit();\
}\
/datum/controller/subsystem/movement/##X

#define PROCESSING_SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/controller/subsystem/processing/##X);\
/datum/controller/subsystem/processing/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
	PreInit();\
}\
/datum/controller/subsystem/processing/##X

#define VERB_MANAGER_SUBSYSTEM_DEF(X) GLOBAL_REAL(SS##X, /datum/controller/subsystem/verb_manager/##X);\
/datum/controller/subsystem/verb_manager/##X/New(){\
	NEW_SS_GLOBAL(SS##X);\
	PreInit();\
}\
/datum/controller/subsystem/verb_manager/##X/fire() {..() /*just so it shows up on the profiler*/} \
/datum/controller/subsystem/verb_manager/##X

//! ## Чёрный ящик мастер-контроллера
//! Живут здесь, а не рядом с кодом в code/controllers/mc_state.dm: master.dm подключается раньше и обязан их видеть.

/// Куда пишется сводка: data/ переживает раунд и перезапуск процесса, там же лежит GracefulEnding.json.
#define MC_STATE_SNAPSHOT_FILE "data/mc_state.txt"
/// С этой строки начинается сводка, затёртая штатным завершением.
#define MC_STATE_CLEAN_MARK "ШТАТНОЕ ЗАВЕРШЕНИЕ"
/// Какую долю тика (в процентах) чёрному ящику разрешено занимать в среднем.
///
/// Цена одной записи зависит от платформы на два порядка: rustg_file_write открывает,
/// пишет и закрывает файл на каждый вызов, и там, где Linux с page cache тратит десятки
/// микросекунд, Windows с антивирусом на пути тратит миллисекунды (замер юнит-теста
/// mc_state_snapshot_interval_adapts на рабочей машине: 8.2 мс, то есть 40% тика).
/// Поэтому в дефайне не частота, а бюджет: частоту подсистема подбирает сама под замер.
#define MC_STATE_TICK_BUDGET 1
/// Выше какой занятости тика (в процентах) запись сводки откладывается до следующего прохода.
///
/// Бюджет выше держит СРЕДНЮЮ цену, но выброс одной записи он не трогает: сколько стоит
/// вызов rustg_file_write, столько он и стоит. В проде 23.08 отдельные записи стоили 121%
/// тика (раунд 10087) и 80% (10091), и оба раза - в шторме логинов, то есть прибор добивал
/// тик ровно тогда, когда миру и без него было тяжело. Планка выбрана так, чтобы обычный
/// тик (единицы-десятки процентов) записи не терял вовсе, а тик на исходе бюджета - терял.
#define MC_STATE_TICK_SKIP_ABOVE 70
/// Чаще этого сводка не пишется никогда - один раз за проход петли МК.
#define MC_STATE_MIN_INTERVAL 1
/// Реже этого не пишется даже на самой медленной файловой системе: четыре секунды слепоты - предел.
#define MC_STATE_MAX_INTERVAL 200
/// Во сколько раз должен измениться интервал, чтобы об этом написали в лог. Без порога строка идёт на каждый шаг подстройки.
#define MC_STATE_INTERVAL_LOG_FACTOR 2
/// Сколько символов задачи подсистемы попадает в сводку.
#define MC_STATE_TASK_MAX_LEN 200
/// Сколько подсистем из очереди МК перечисляется в сводке.
#define MC_STATE_QUEUE_PREVIEW 8
/// После скольких неудачных записей подряд чёрный ящик выключается до конца раунда.
///
/// Запись идёт по нескольку раз в секунду, и падающая на каждой запись - это лог, забитый
/// одинаковой строкой, то есть худший из возможных исходов для диагностики краша.
#define MC_STATE_FAILURE_LIMIT 3
