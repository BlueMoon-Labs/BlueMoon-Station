/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { classes } from 'common/react';
import { Component } from 'react';

import { Box } from './Box';
import { Icon } from './Icon';

// Вариант списка — либо примитив (значение и подпись совпадают), либо пара
// { value, displayText }: она позволяет вызывающему держать выбор на
// устойчивом идентификаторе, а показывать переведённую или отформатированную
// подпись. Пара распознаётся по наличию самих ключей, а не по
// typeof === 'object': в options уже кладут готовые React-элементы, и они
// обязаны и дальше рендериться как есть.
const isOptionPair = option => (
  option !== null
  && typeof option === 'object'
  && (option.value !== undefined || option.displayText !== undefined)
);

// Полупара разбирается симметрично: без displayText подписью служит значение,
// без value значением служит подпись. Иначе вариант { displayText } молча
// уводил бы в onSelected сам объект (и вырождал key в [object Object]), а
// вариант { value } падал бы на «Objects are not valid as a React child».
const optionValue = option => (isOptionPair(option)
  ? (option.value !== undefined ? option.value : option.displayText)
  : option);

const optionLabel = option => (isOptionPair(option)
  ? (option.displayText !== undefined ? option.displayText : option.value)
  : option);

export class Dropdown extends Component {
  constructor(props) {
    super(props);
    this.state = {
      selected: props.selected,
      open: false,
    };
    this.handleClick = () => {
      if (this.state.open) {
        this.setOpen(false);
      }
    };
  }

  componentWillUnmount() {
    window.removeEventListener('click', this.handleClick);
  }

  setOpen(open) {
    // The menu node exists only after the re-render, so focus it
    // in the setState callback (setState is asynchronous in React).
    this.setState({ open: open }, () => {
      if (open) {
        this.menuRef?.focus();
      }
    });
    if (open) {
      setTimeout(() => window.addEventListener('click', this.handleClick));
    }
    else {
      window.removeEventListener('click', this.handleClick);
    }
  }

  // state.selected — выбор для неуправляемого случая: там меню закрывается по
  // клику, а другого источника подписи у контрола нет. Управляемому окну этот
  // state в подпись не идёт (см. render), но пишется он всегда: так контрол
  // переживает окно, которое перестало присылать selected.
  setSelected(selected) {
    this.setState({
      selected: selected,
    });
    this.setOpen(false);
    this.props.onSelected(selected);
  }

  buildMenu(optionList) {
    const ops = optionList.map(option => {
      const value = optionValue(option);
      return (
        <Box
          key={value}
          className="Dropdown__menuentry"
          onClick={() => {
            this.setSelected(value);
          }}>
          {optionLabel(option)}
        </Box>
      );
    });
    return ops.length ? ops : 'No Options Found';
  }

  render() {
    const { props } = this;
    const {
      icon,
      iconRotation,
      iconSpin,
      color = 'default',
      over,
      noscroll,
      nochevron,
      width,
      onClick,
      onSelected,
      options,
      selected,
      disabled,
      displayText,
      ...boxProps
    } = props;
    const {
      className,
      ...rest
    } = boxProps;

    const adjustedOpen = over ? !this.state.open : this.state.open;

    // options приходит из окон и не обязан быть массивом: часть вызывающих
    // кладёт туда объект или строку (ComplexModal.js, IPCConstructor.js,
    // MailAdminPanel.js). Раньше не-массив ронял только клик по контролу,
    // теперь поиск подписи идёт в render() — и без приведения окно уходило
    // бы в белый экран на первом же рендере.
    const optionList = Array.isArray(options) ? options : [];

    // Контрол условно управляемый. Если проп selected передан, подпись всегда
    // считается из него: машина имеет право молча отвергнуть act
    // (omni_devices.dm: смена газа применяется только на порту с ролью
    // filter), и тогда бэкенд продолжает слать прежнее значение — подпись
    // обязана откатиться на него, а не остаться на выборе игрока.
    // Дюжина окон (BrigTimer, Filteriffic, VariableMenu, MODsuit,
    // PlayerPanel2, Techweb, SDQLSpellMenu, CircuitModule, FundamentalTypes,
    // ShuttleManipulator, CommandReport, AdminLogViewer — 18 вызовов на всех)
    // проп не передаёт вовсе: для них выбор живёт только здесь, в state, и
    // читать оттуда обязательно, иначе после клика контрол оставался бы пуст.
    // Наличие пропа проверяется через !== undefined, а не на истинность:
    // 0 и пустая строка — валидный выбор.
    const shownSelected = selected !== undefined
      ? selected
      : this.state.selected;

    // Подпись выбранного варианта лежит в самих options: без этого при
    // объектных вариантах в контроле светился бы сырой идентификатор, и
    // каждому окну пришлось бы дублировать поиск своим displayText.
    const currentOption = optionList.find(
      option => optionValue(option) === shownSelected);
    const selectedLabel = currentOption !== undefined
      ? optionLabel(currentOption)
      : shownSelected;

    const menu = this.state.open ? (
      <div
        ref={menu => { this.menuRef = menu; }}
        tabIndex="-1"
        style={{
          'width': width,
        }}
        className={classes([
          noscroll && 'Dropdown__menu-noscroll' || 'Dropdown__menu',
          over && 'Dropdown__over',
        ])}>
        {this.buildMenu(optionList)}
      </div>
    ) : null;

    return (
      <div className="Dropdown">
        <Box
          width={width}
          className={classes([
            'Dropdown__control',
            'Button',
            'Button--color--' + color,
            disabled && 'Button--disabled',
            className,
          ])}
          {...rest}
          onClick={() => {
            if (disabled && !this.state.open) {
              return;
            }
            this.setOpen(!this.state.open);
          }}>
          {icon && (
            <Icon
              name={icon}
              rotation={iconRotation}
              spin={iconSpin}
              mr={1} />
          )}
          <span className="Dropdown__selected-text">
            {displayText ? displayText : selectedLabel}
          </span>
          {!!nochevron || (
            <span className="Dropdown__arrow-button">
              <Icon name={adjustedOpen ? 'chevron-up' : 'chevron-down'} />
            </span>
          )}
        </Box>
        {menu}
      </div>
    );
  }
}
