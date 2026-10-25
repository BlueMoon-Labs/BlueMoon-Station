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
#define CONTEXT_MENU_MAX_ROWS 10
/// Строк на странице списка объектов клетки: его листают, чтобы найти вещь, страницы длиннее
#define CONTEXT_MENU_MAX_LIST_ROWS 16
/// С этого числа объектов на клетке ПКМ по предмету в куче открывает сразу список клетки
#define CONTEXT_MENU_PILE_MIN 6
/// Ширина меню подгоняется под самый длинный пункт в этих пределах
#define CONTEXT_MENU_WIDTH 200
#define CONTEXT_MENU_MIN_WIDTH 60
#define CONTEXT_MENU_ROW_HEIGHT 11
/// Строка со значком объекта
#define CONTEXT_MENU_ICON_ROW_HEIGHT 16
/// Место под значок объекта в строке: видимая часть спрайта как есть или уменьшенная вдвое
#define CONTEXT_MENU_ICON_SIZE 16
/// Столько одинаковых объектов на клетке сворачиваются в одну строку со счётом
#define CONTEXT_MENU_GROUP_MIN 3
/// Меню переживает ходьбу, пока его объект не дальше этого
#define CONTEXT_MENU_MAX_DISTANCE 7

/// Режимы ПКМ (преф right_click_choice): ПКМ сразу действует, меню на Shift+ПКМ
#define RIGHT_CLICK_MODE_ACTION 0
/// ПКМ - меню действий, Shift+ПКМ - второе действие
#define RIGHT_CLICK_MODE_MENU 1
/// Как раньше: вне боя ПКМ - меню BYOND, в комбат-режиме и в мехе - действие, Shift+ПКМ - осмотр
#define RIGHT_CLICK_MODE_NATIVE 2
