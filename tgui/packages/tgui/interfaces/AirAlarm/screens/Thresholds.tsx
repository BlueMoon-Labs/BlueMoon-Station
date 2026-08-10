import { useBackend } from '../../../backend';
import { Button, NoticeBox, Table } from '../../../components';
import {
  formatThreshold,
  localizeEnvName,
  THRESHOLD_HINT,
  THRESHOLD_LABEL,
} from '../helpers';
import { AirAlarmData, ThresholdEdit, ThresholdVar } from '../types';

const COLUMNS: { val: ThresholdVar; color: string }[] = [
  { val: 'min2', color: 'bad' },
  { val: 'min1', color: 'average' },
  { val: 'max1', color: 'average' },
  { val: 'max2', color: 'bad' },
];

type Props = {
  readonly onEdit: (edit: ThresholdEdit) => void;
};

export const Thresholds = (props: Props) => {
  const { onEdit } = props;
  const { act, data } = useBackend<AirAlarmData>();
  const thresholds = data.thresholds || [];
  return (
    <>
      <NoticeBox info>
        Пороги газов задаются в парциальном давлении, а не в процентах. Прочерк
        означает, что порог не проверяется.
      </NoticeBox>
      <Table>
        <Table.Row header>
          <Table.Cell>Параметр</Table.Cell>
          {COLUMNS.map((column) => (
            <Table.Cell
              key={column.val}
              collapsing
              className={`color-${column.color}`}
              title={THRESHOLD_HINT[column.val]}>
              {THRESHOLD_LABEL[column.val]}
            </Table.Cell>
          ))}
          <Table.Cell collapsing />
        </Table.Row>
        {thresholds.map((threshold) => (
          <Table.Row key={threshold.env}>
            <Table.Cell className="LabeledList__label">
              {localizeEnvName(threshold.env, threshold.name)}
            </Table.Cell>
            {threshold.settings.map((setting) => (
              <Table.Cell key={setting.val} collapsing>
                <Button
                  content={formatThreshold(setting.selected, threshold.unit)}
                  tooltip={
                    setting.default === undefined || setting.default === null
                      ? undefined
                      : `Заводское: ${formatThreshold(
                          setting.default,
                          threshold.unit
                        )}`
                  }
                  onClick={() =>
                    onEdit({
                      env: threshold.env,
                      name: localizeEnvName(threshold.env, threshold.name),
                      unit: threshold.unit,
                      val: setting.val,
                      value: setting.selected,
                    })
                  }
                />
              </Table.Cell>
            ))}
            <Table.Cell collapsing>
              <Button
                icon="undo"
                disabled={threshold.is_default}
                tooltip="Вернуть заводские значения"
                onClick={() => act('reset_threshold', { env: threshold.env })}
              />
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </>
  );
};
