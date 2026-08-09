import { useBackend } from '../../backend';
import { Box, Icon, NoticeBox } from '../../components';
import { collectAlerts } from './helpers';
import { HypertorusData } from './types';

const ALERT_ICON = {
  danger: 'exclamation-triangle',
  warning: 'exclamation-circle',
  info: 'info-circle',
};

/**
 * Претензии реактора списком. Раньше эти же состояния можно было прочитать
 * только по цифрам в семи разных секциях - или по крику в рацию, когда уже
 * поздно.
 */
export const Alerts = () => {
  const { data } = useBackend<HypertorusData>();
  const alerts = collectAlerts(data);

  if (!alerts.length) {
    return (
      <NoticeBox success className="Hypertorus__alert">
        <Icon name="check-circle" mr={1} />
        Реактор в штатном режиме.
      </NoticeBox>
    );
  }

  return (
    <Box>
      {alerts.map((alert) => (
        // NoticeBox без модификатора и есть предупреждение: жёлтый - его тема
        // по умолчанию, а проп warning в этой версии компонента ничего не даёт.
        <NoticeBox
          key={alert.id}
          danger={alert.level === 'danger'}
          info={alert.level === 'info'}
          className="Hypertorus__alert"
        >
          <Icon name={ALERT_ICON[alert.level]} mr={1} />
          {alert.text}
        </NoticeBox>
      ))}
    </Box>
  );
};
