/// Атом дополняет меню действий своими пунктами: (mob/user, list/entries)
#define COMSIG_ATOM_CONTEXT_MENU "atom_context_menu"

#define CONTEXT_ENTRY_NORMAL "normal"
/// Пункт текущего интента игрока
#define CONTEXT_ENTRY_CURRENT "current"
/// Агрессивное действие
#define CONTEXT_ENTRY_DANGER "danger"
/// Служебный пункт: назад, ещё
#define CONTEXT_ENTRY_SERVICE "service"

/// Строк пунктов на странице меню, без шапки
#define CONTEXT_MENU_MAX_ROWS 12
/// Ширина меню подгоняется под самый длинный пункт в этих пределах
#define CONTEXT_MENU_WIDTH 200
#define CONTEXT_MENU_MIN_WIDTH 90
#define CONTEXT_MENU_ROW_HEIGHT 16
/// Значок объекта в строке
#define CONTEXT_MENU_ICON_SIZE 16
/// Примерная ширина буквы Small Fonts 7px, с запасом
#define CONTEXT_MENU_CHAR_WIDTH 6
/// Столько одинаковых объектов на клетке сворачиваются в одну строку со счётом
#define CONTEXT_MENU_GROUP_MIN 3
/// Меню переживает ходьбу, пока его объект не дальше этого
#define CONTEXT_MENU_MAX_DISTANCE 7
