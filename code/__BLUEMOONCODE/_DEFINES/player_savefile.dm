// Журнал одиночных ключей старых сейвов (preferences.sav.journal). Новые сейвы журнала не пишут,
// но незалитый журнал доезжает в JSON при переносе старого сейва (player_save_json.dm).

/// Ключ блока журнала с отпечатком savefile на момент начала журнала: если файл с тех пор
/// менялся мимо журнала, блок устарел.
#define PREF_JOURNAL_BASE_KEY "__journal_base"
/// Строка, с которой начинается каждый блок журнала: обрывок до неё (недописанный блок) не читается.
#define PREF_JOURNAL_BLOCK_BEGIN "#single_prefs_block"
/// Строка, которой заканчивается каждый дописанный блок журнала: блок без неё оборван и не читается.
#define PREF_JOURNAL_BLOCK_END "#end_of_single_prefs_block"
/// Ключ поколения в блоках журнала прошлого формата: при чтении пропускается.
#define PREF_JOURNAL_EPOCH_KEY "__journal_epoch"
/// Ключ savefile с отпечатком файла до начатого слияния журнала, оборванного падением.
#define PREF_JOURNAL_MERGING_SAVE_KEY "journal_merging"
