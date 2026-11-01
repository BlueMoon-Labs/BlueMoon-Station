/// Атом дополняет меню действий своими пунктами: (mob/user, list/entries)
#define COMSIG_ATOM_CONTEXT_MENU "atom_context_menu"

#define CONTEXT_ENTRY_NORMAL "normal"
/// Пункт текущего интента игрока
#define CONTEXT_ENTRY_CURRENT "current"
/// Агрессивное действие
#define CONTEXT_ENTRY_DANGER "danger"
/// Служебный пункт: назад, ещё
#define CONTEXT_ENTRY_SERVICE "service"
/// Админ-вербы: на каждой странице, своим цветом
#define CONTEXT_ENTRY_ADMIN "admin"

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

/// Что делает ПКМ или Shift+ПКМ (префы right_click_choice и shift_right_click_choice): второе действие сразу
#define RIGHT_CLICK_MODE_ACTION 0
/// Меню действий у курсора
#define RIGHT_CLICK_MODE_MENU 1
/// Меню BYOND, как раньше; в комбат-режиме и в мехе ПКМ - действие, Shift+ПКМ - осмотр
#define RIGHT_CLICK_MODE_NATIVE 2

/// Пункт выбора режима ПКМ, который открывает настройки игры
#define CONTEXT_MENU_SETTINGS_CHOICE "Настроить вид меню и любую раскладку…"

/// Непрозрачность фона меню в процентах
#define CONTEXT_MENU_OPACITY_MIN 40
#define CONTEXT_MENU_OPACITY_DEFAULT 92
/// Настройки вида со свободным значением, которых нет в GLOB.context_menu_style_choices
#define CONTEXT_MENU_FREE_OPTIONS list("opacity", "accent")
/// Кегль текста меню при 100%: и Small Fonts 7px, и Tahoma 7px - около 11 пикселей строки
#define CONTEXT_MENU_FONT_PX 7
/// Зум карты, пока клиент не ответил: окно на полэкрана и больше
#define CONTEXT_MENU_DEFAULT_ZOOM 2

/// Статистика меню в context_menu.json: выгрузка не чаще, пунктов и смен настроек не больше
#define CONTEXT_MENU_STATS_EXPORT_DELAY (1 MINUTES)
#define CONTEXT_MENU_STATS_MAX_ENTRIES 300
#define CONTEXT_MENU_STATS_MAX_CHANGES 2000

/// Элемент скина браузерного меню действий и сколько ждать загрузки его страницы перед первым показом
#define CONTEXT_MENU_HTML_CONTROL "mainwindow.context_menu"
#define CONTEXT_MENU_HTML_PAGE_GRACE (1 SECONDS)
/// Сколько разных стейтов держит кэш значков браузерного меню
#define CONTEXT_MENU_HTML_ICON_CACHE 2000
/// Сколько процентов тика одна отрисовка тратит на новые значки; остальные дорисовываются следующим тиком
#define CONTEXT_MENU_HTML_ICON_BUDGET 10
