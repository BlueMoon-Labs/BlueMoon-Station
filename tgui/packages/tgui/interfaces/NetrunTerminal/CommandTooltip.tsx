import { Icon } from '../../components';
import { themeStyle } from './themes';
import { ACCESS_NAMES, NetCommand } from './types';
import { useNetrunSelector } from './useNetrunBackend';

type Fact = { label: string; value: string; warning?: boolean };
type Notice = { text: string; danger?: boolean };

/** The shared tooltip portal is outside the workspace, so the card owns its palette. */
export const ActionTooltip = (props: { name: string; id: string; icon?: string; description?: string;
  details?: string; facts: Fact[]; notices?: Notice[] }) => {
  const theme = useNetrunSelector((data) => data.ui_theme);
  return (<div role="tooltip" className="netrun-command-tooltip" style={themeStyle(theme)}>
    <div className="netrun-command-tooltip__heading">
      <span className="netrun-command-tooltip__icon"><Icon name={props.icon || 'terminal'} /></span>
      <div><strong>{props.name}</strong><code>{props.id}</code></div>
    </div>
    {!!props.description && <p>{props.description}</p>}
    {!!props.details && <div className="netrun-command-tooltip__details">
      {props.details.split('\n').filter(Boolean).map((line, index) => <p key={index}>{line}</p>)}
                        </div>}
    <dl>{props.facts.map((fact) => <div key={fact.label}><dt>{fact.label}</dt><dd className={fact.warning ? 'is-warning' : ''}>{fact.value}</dd></div>)}</dl>
    {props.notices?.map((notice, index) => (<div key={index} className={`netrun-command-tooltip__notice ${notice.danger ? 'is-danger' : 'is-warning'}`}>
      <Icon name={notice.danger ? 'triangle-exclamation' : 'circle-info'} /> {notice.text}
                                            </div>))}
          </div>);
};

export const CommandTooltip = ({ command }: { command: NetCommand }) => {
  const facts: Fact[] = [
    { label: 'Доступ', value: ACCESS_NAMES[command.access] || '—' },
    { label: 'Трассировка', value: command.illegal && command.trace ? `+${command.trace}%` : '+0%', warning: !!command.illegal && !!command.trace },
  ];
  if (command.latency_ms !== undefined) {
    facts.push({ label: 'Доставка', value: Number.isFinite(command.latency_ms)
      ? command.latency_ms > 0 ? `~${Math.round(command.latency_ms)} мс` : 'Мгновенно' : 'Нет маршрута' });
  }
  facts.push({ label: 'Связь', value: command.works_offline ? 'Работает офлайн' : 'Требуется онлайн' });
  const notices: Notice[] = [];
  if (command.danger) { notices.push({ text: 'Вмешательство в работу устройства', danger: true }); }
  if (!command.allowed) { notices.push({ text: command.unavailable_reason || 'Сейчас действие недоступно.' }); }
  else if (command.illegal) { notices.push({ text: 'Используется полученный доступ. Защита может отреагировать.' }); }
  return (<ActionTooltip name={command.name} id={command.id} icon={command.icon}
    description={command.desc || command.help} details={command.details} facts={facts} notices={notices} />);
};
