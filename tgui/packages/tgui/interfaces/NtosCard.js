import { Fragment } from 'inferno';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Input, NoticeBox, Section, Tabs } from '../components';
import { NtosWindow } from '../layouts';
import { AccessList } from './common/AccessList';

export const NtosCard = (props, context) => {
  return (
    <NtosWindow
      width={500}
      height={530}
      resizable>
      <NtosWindow.Content overflow="auto">
        <NtosCardContent />
      </NtosWindow.Content>
    </NtosWindow>
  );
};

export const NtosCardContent = (props, context) => {
  const { act, data } = useBackend(context);
  const [tab, setTab] = useLocalState(context, 'tab', 1);
  const {
    authenticated,
    regions = [],
    access_on_card = [],
    jobs = {},
    id_rank,
    id_custom_job,
    id_owner,
    has_main_id,
    has_id,
    have_printer,
    have_id_slot,
    id_name,
  } = data;
  const [
    selectedDepartment,
    setSelectedDepartment,
  ] = useLocalState(context, 'department', Object.keys(jobs)[0]);
  if (!have_id_slot) {
    return (
      <NoticeBox>
        This program requires an ID slot in order to function
      </NoticeBox>
    );
  }
  const departmentJobs = jobs[selectedDepartment] || [];

  // Для id_custom_job
  const serverCustom = id_custom_job || '';
  const [customDraft, setCustomDraft] = useLocalState(context, 'customDraft', serverCustom);
  const [isEditingCustom, setIsEditingCustom] = useLocalState(context, 'isEditingCustom', false);

  // что показываем в кнопке/инпуте
  const customValue = isEditingCustom ? customDraft : serverCustom;
  return (
    <Fragment>
      <Section
        title={has_id && authenticated
          ? (
            <Input
              value={id_owner}
              width="250px"
              onInput={(e, value) => act('PRG_edit', {
                name: value,
              })} />
          )
          : (id_owner || 'No Card Inserted')}
        buttons={(
          <Fragment>
            <Button
              icon="print"
              content="Print"
              disabled={!have_printer || !has_id}
              onClick={() => act('PRG_print')} />
            <Button
              icon={authenticated ? "sign-out-alt" : "sign-in-alt"}
              disabled={!has_main_id && !authenticated}
              content={authenticated ? "Log Out" : "Log In"}
              color={authenticated ? "bad" : "good"}
              onClick={() => {
                act(authenticated ? 'PRG_logout' : 'PRG_authenticate');
              }} />
            <Button
              icon="eject"
              tooltip={has_main_id ? "Eject ID" : "Insert ID"}
              color={has_main_id && "good"}
              tooltipPosition="bottom-start"
              onClick={() => act('PRG_eject', { name: "MainID" })} />
          </Fragment>
        )}>
        <Button
          fluid
          icon="eject"
          content={id_name}
          onClick={() => act('PRG_eject', { name: "SecondID" })} />
      </Section>
      {(!!has_id && !!authenticated) && (
        <Box>
          <Tabs>
            <Tabs.Tab
              selected={tab === 1}
              onClick={() => setTab(1)}>
              Access
            </Tabs.Tab>
            <Tabs.Tab
              selected={tab === 2}
              onClick={() => setTab(2)}>
              Jobs
            </Tabs.Tab>
          </Tabs>
          {tab === 1 && (
            <AccessList
              accesses={regions}
              selectedList={access_on_card}
              accessMod={ref => act('PRG_access', {
                access_target: ref,
              })}
              grantAll={() => act('PRG_grantall')}
              denyAll={() => act('PRG_denyall')}
              grantDep={dep => act('PRG_grantregion', {
                region: dep,
              })}
              denyDep={dep => act('PRG_denyregion', {
                region: dep,
              })} />
          )}
          {tab === 2 && (
            <Section
              title={id_rank}
              buttons={(
                <Button.Confirm
                  icon="exclamation-triangle"
                  content="Terminate"
                  color="bad"
                  onClick={() => act('PRG_terminate')} />
              )}>
              {/* <Button.Input
                fluid
                content="Custom..."
                placeholder={id_custom_job}
                onCommit={(e, value) => act('PRG_assign', {
                  assign_target: 'Custom',
                  custom_name: value,
                })} />*/}
              <Button.Input
                fluid
                content="Custom..."
                currentValue={customValue}
                onInput={(_e, value) => {
                  if (!isEditingCustom) {
                    // при старте редактирования подтянуть текущее серверное значение
                    setIsEditingCustom(true);
                    setCustomDraft(serverCustom);
                  }
                  setCustomDraft(value);
                }}
                onCommit={(_e, value) => {
                  setIsEditingCustom(false);
                  act('PRG_assign', {
                    assign_target: 'Custom',
                    custom_name: value,
                  });
                }}
              />

              <Flex md={2}>
                <Flex.Item mr={2}>
                  <Tabs vertical>
                    {Object.keys(jobs).map(department => (
                      <Tabs.Tab
                        key={department}
                        selected={department === selectedDepartment}
                        onClick={() => setSelectedDepartment(department)}>
                        {department}
                      </Tabs.Tab>
                    ))}
                  </Tabs>
                </Flex.Item>
                <Flex.Item grow={1} minWidth={0}>
                  {departmentJobs.map(job => (
                    <Button
                      fluid
                      key={job.job}
                      content={job.display_name}
                      onClick={() => act('PRG_assign', {
                        assign_target: job.job,
                      })} />
                  ))}
                </Flex.Item>
              </Flex>
            </Section>
          )}
        </Box>
      )}
    </Fragment>
  );
};
