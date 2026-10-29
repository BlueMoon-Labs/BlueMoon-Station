import { map } from 'common/collections';

import { useBackend } from '../backend';
import { Button, Section, Table } from '../components';
import { NtosWindow } from '../layouts';

export const NtosCrewManifest = (props) => {
  const { act, data } = useBackend();
  const {
    have_printer,
    manifest = {},
    department_names = {},
  } = data;
  return (
    <NtosWindow
      width={400}
      height={480}>
      <NtosWindow.Content overflow="auto">
        <Section
          title="Манифест экипажа"
          buttons={(
            <Button
              icon="print"
              content="Печать"
              disabled={!have_printer}
              onClick={() => act('PRG_print')} />
          )}>
          {map((entries, department) => (
            <Section
              key={department}
              level={2}
              title={department_names[department] || department}>
              <Table>
                {entries.map(entry => (
                  <Table.Row
                    key={entry.name}
                    className="candystripe"
                    bold={!!entry.head}>
                    <Table.Cell>
                      {entry.name}
                    </Table.Cell>
                    <Table.Cell>
                      ({!!entry.head && (
                        <span className="CrewManifest__HeadMark">{'★'}</span>
                      )}{entry.rank})
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          ))(manifest)}
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
