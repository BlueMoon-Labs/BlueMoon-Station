import { useBackend } from "../backend";
import { Flex, Section, Table } from "../components";
import { Window } from "../layouts";

export const CrewManifest = (props) => {
  const { data: { manifest, positions, department_names = {} } } = useBackend();

  return (
    <Window title="Манифест экипажа" width={440} height={550}>
      <Window.Content overflow="auto">
        {Object.entries(manifest).map(([department, crew]) => (
          <Section
            className={"CrewManifest--" + department}
            key={department}
            title={
              <Flex style={{ width: '100%' }}>
                <Flex.Item>
                  {department_names[department] || department}
                </Flex.Item>
                <Flex.Item grow textAlign="right">
                  (Открытых позиций: {positions[department]})
                </Flex.Item>
              </Flex>
            }
          >
            <Table>
              {Object.entries(crew).map(([crewIndex, crewMember]) => (
                <Table.Row key={crewIndex} bold={!!crewMember.head}>
                  <Table.Cell className={"CrewManifest__Cell"}>
                    {crewMember.name}
                  </Table.Cell>
                  <Table.Cell
                    className={"CrewManifest__Cell"}
                    collapsing
                    color={crewMember.head ? undefined : "label"}
                  >
                    {!!crewMember.head && (
                      <span className="CrewManifest__HeadMark">{'★'}</span>
                    )}
                    {crewMember.rank}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        ))}
      </Window.Content>
    </Window>
  );
};
