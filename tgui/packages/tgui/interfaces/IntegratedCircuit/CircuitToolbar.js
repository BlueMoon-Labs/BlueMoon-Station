import { Box, Button, Icon, Stack } from '../../components';

/**
 * Верхняя панель: состояние платы, счётчики, масштаб, краткая легенда управления.
 */
export const CircuitToolbar = (props) => {
  const {
    circuitOn,
    componentCount,
    variableCount,
    zoomPercent,
    showVariableChip = true,
    lgbtqRainbowMode = false,
    onLgbtqRainbowToggle,
    onPanToOrigin,
    onEjectPowerCell,
    /** Wiremod: null = нет ячейки, число = % (поле есть в ui_data). */
    circuitCellPercent,
    /** IE assembly only: null = no cell, number = charge % */
    ieBatteryPercent,
    /** IE: "assembly" | "chip" — показать кнопку копирования JSON для принтера / одного чипа */
    ieCloneCopyMode,
    onIeCloneCopy,
    /** IE: переключиться на классический браузерный UI */
    onIeClassicUi,
    /** IE: вставить чип из руки в центр текущего вида поля */
    onIePlaceChipCenter,
    /** IE: размер (сумма size) и лимит корпуса; max null = одиночный чип без корпуса */
    ieUsedSize,
    ieMaxSize,
    ieUsedComplexity,
    ieMaxComplexity,
  } = props;

  const powered = circuitOn !== false && circuitOn !== 0;

  const showIeLimits = ieUsedSize !== null && ieUsedSize !== undefined
    && ieUsedComplexity !== null && ieUsedComplexity !== undefined;
  const sizeFull = ieMaxSize !== null && ieMaxSize !== undefined
    && ieUsedSize >= ieMaxSize;
  const complexityFull = ieMaxComplexity !== null && ieMaxComplexity !== undefined
    && ieUsedComplexity >= ieMaxComplexity;

  return (
    <Box className="IntegratedCircuit__toolbar">
      <Stack align="center" wrap="wrap">
        <Stack.Item>
          <Box
            className={powered
              ? 'IntegratedCircuit__chip IntegratedCircuit__chip--on'
              : 'IntegratedCircuit__chip IntegratedCircuit__chip--off'}>
            <Icon name="power-off" style={{ 'margin-right': '0.35em' }} />
            {powered ? 'Плата вкл.' : 'Плата выкл.'}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box
            className="IntegratedCircuit__chip IntegratedCircuit__chip--muted"
            title={ieBatteryPercent !== undefined
              ? 'Считаются только микросхемы (чипы с интегрального принтера). Батарея — отдельно.'
              : undefined}>
            <Icon name="microchip" style={{ 'margin-right': '0.35em' }} />
            {ieBatteryPercent !== undefined ? (
              <Box as="span" color="#ff79c6">
                Чипов (принтер)
              </Box>
            ) : (
              'Компонентов'
            )}
            : <b>{componentCount}</b>
          </Box>
        </Stack.Item>
        {!!showIeLimits && (
          <Stack.Item>
            <Box
              className="IntegratedCircuit__chip IntegratedCircuit__chip--muted"
              title="Занято места: сумма размеров (size) всех чипов. Максимум — запас корпуса; при переполнении нельзя вставить деталь.">
              <Icon name="expand-arrows-alt" style={{ 'margin-right': '0.35em' }} />
              Размер:{' '}
              <Box as="span" color={sizeFull ? '#ff5555' : undefined}>
                <b>
                  {ieUsedSize}
                  {ieMaxSize !== null && ieMaxSize !== undefined ? ` / ${ieMaxSize}` : ''}
                </b>
              </Box>
            </Box>
          </Stack.Item>
        )}
        {!!showIeLimits && (
          <Stack.Item>
            <Box
              className="IntegratedCircuit__chip IntegratedCircuit__chip--muted"
              title="Сумма сложностей всех чипов. Максимум задаёт корпус; при переполнении схема слишком сложная для этого кейса.">
              <Icon name="project-diagram" style={{ 'margin-right': '0.35em' }} />
              Сложность:{' '}
              <Box as="span" color={complexityFull ? '#ff5555' : undefined}>
                <b>
                  {ieUsedComplexity}
                  {ieMaxComplexity !== null && ieMaxComplexity !== undefined ? ` / ${ieMaxComplexity}` : ''}
                </b>
              </Box>
            </Box>
          </Stack.Item>
        )}
        {ieBatteryPercent !== undefined && (
          <Stack.Item>
            <Stack align="center">
              <Box
                className="IntegratedCircuit__chip IntegratedCircuit__chip--muted"
                title="Элемент питания в отсеке батареи, не логический чип.">
                <Icon name="battery-half" style={{ 'margin-right': '0.35em' }} />
                Батарея:{' '}
                <b>{ieBatteryPercent === null ? 'нет' : `${ieBatteryPercent}%`}</b>
              </Box>
              {ieBatteryPercent !== null && typeof onEjectPowerCell === 'function' && (
                <Button
                  color="transparent"
                  icon="eject"
                  compact
                  tooltip="Достать батарею (в руки или на пол под сборкой)"
                  onClick={onEjectPowerCell}
                />
              )}
            </Stack>
          </Stack.Item>
        )}
        {circuitCellPercent !== undefined && (
          <Stack.Item>
            <Stack align="center">
              <Box
                className="IntegratedCircuit__chip IntegratedCircuit__chip--muted"
                title="Элемент питания платы (wiremod).">
                <Icon name="battery-half" style={{ 'margin-right': '0.35em' }} />
                Ячейка:{' '}
                <b>{circuitCellPercent === null ? 'нет' : `${circuitCellPercent}%`}</b>
              </Box>
              {circuitCellPercent !== null && typeof onEjectPowerCell === 'function' && (
                <Button
                  color="transparent"
                  icon="eject"
                  compact
                  tooltip="Извлечь ячейку (как отвёрткой по плате)"
                  onClick={onEjectPowerCell}
                />
              )}
            </Stack>
          </Stack.Item>
        )}
        {!!showVariableChip && (
          <Stack.Item>
            <Box className="IntegratedCircuit__chip IntegratedCircuit__chip--muted">
              <Icon name="database" style={{ 'margin-right': '0.35em' }} />
              Переменных: <b>{variableCount}</b>
            </Box>
          </Stack.Item>
        )}
        {(ieCloneCopyMode === 'assembly' || ieCloneCopyMode === 'chip') && !!onIeCloneCopy && (
          <Stack.Item>
            <Button
              color="transparent"
              icon="copy"
              compact
              tooltip={ieCloneCopyMode === 'assembly'
                ? 'Код сборки (JSON) для принтера — как ghost scan / анализатор'
                : 'JSON одного чипа (имя, входы) — открыть и скопировать из окна'}
              onClick={onIeCloneCopy}>
              {ieCloneCopyMode === 'assembly' ? 'Код сборки' : 'Код чипа'}
            </Button>
          </Stack.Item>
        )}
        {typeof onIeClassicUi === 'function' && (
          <Stack.Item>
            <Button
              color="transparent"
              icon="window-restore"
              compact
              tooltip="Классический интерфейс (окно браузера Byond). Настройка сохраняется в префах."
              onClick={onIeClassicUi}>
              Классика
            </Button>
          </Stack.Item>
        )}
        {typeof onIePlaceChipCenter === 'function' && (
          <Stack.Item>
            <Button
              color="transparent"
              icon="crosshairs"
              compact
              tooltip="Вставить чип из руки в центр текущего вида (корпус открыт). Shift+ЛКМ по полю — в точку клика."
              onClick={onIePlaceChipCenter}>
              Чип сюда
            </Button>
          </Stack.Item>
        )}
        <Stack.Item>
          <Box className="IntegratedCircuit__chip IntegratedCircuit__chip--muted">
            <Icon name="search-plus" style={{ 'margin-right': '0.35em' }} />
            Масштаб: <b>{zoomPercent}</b>%
          </Box>
        </Stack.Item>
        {typeof onPanToOrigin === 'function' && (
          <Stack.Item>
            <Button
              color="transparent"
              icon="home"
              compact
              tooltip="Сдвинуть поле к координатам (0, 0)"
              onClick={onPanToOrigin}>
              0,0
            </Button>
          </Stack.Item>
        )}
        {typeof onLgbtqRainbowToggle === 'function' && (
          <Stack.Item>
            <Button
              color="transparent"
              icon="palette"
              compact
              selected={lgbtqRainbowMode}
              tooltip={
                lgbtqRainbowMode
                  ? 'Выключить ЛГБТК+ режим'
                  : 'ЛГБТК+ режим: всё окно переливается радужными цветами'
              }
              onClick={onLgbtqRainbowToggle}>
              ЛГБТК+
            </Button>
          </Stack.Item>
        )}
        <Stack.Item grow className="IntegratedCircuit__legendWrap">
          <Box
            className="IntegratedCircuit__legend"
            title={
              'Поле: перетаскивание ЛКМ. '
              + 'Нода: перетаскивание за заголовок. '
              + 'Связь: ЛКМ от выхода (справа) ко входу (слева). '
              + 'Снять связь: ПКМ по порту. '
              + 'Несколько проводов на вход: кнопки ⇄ меняют порядок. '
              + 'Масштаб: кнопки +/− у полосы внизу. '
              + 'IE: «Чип сюда» / Shift+ЛКМ по полю — вставить чип из руки в видимую область.'
            }>
            <Icon
              name="mouse-pointer"
              style={{ 'margin-right': '0.35em', opacity: 0.75 }}
            />
            Поле · ЛКМ — сдвиг · +/− — зум · связь выход→вход · ПКМ — снять
          </Box>
        </Stack.Item>
      </Stack>
    </Box>
  );
};
