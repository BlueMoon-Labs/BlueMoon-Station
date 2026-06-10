
import { Fragment, useState } from 'react';

import { useBackend, useLocalState } from '../backend';
import { Button, Flex, Icon, Input, LabeledList, Section, Table } from '../components';
import { Window } from '../layouts';
import { LoginInfo } from './common/LoginInfo';
import { LoginScreen } from './common/LoginScreen';

const safe = (v, d = '') => (v === null || v === undefined ? d : v);

export const AccountsUplinkTerminal = (_props) => {
  try {
    const { data } = useBackend();
    const loginState = safe(data?.loginState, { logged_in: 0 });
    const currentPage = safe(data?.currentPage, 1);

    // Не залогинен → показываем стандартный логин
    if (!loginState.logged_in) {
      return (
        <Window resizable>
          <Window.Content>
            <LoginScreen />
          </Window.Content>
        </Window>
      );
    }

    let body = null;
    if (currentPage === 1) body = <AccountsRecordList />;
    else if (currentPage === 2) body = <DetailedAccountInfo />;
    else if (currentPage === 3) body = <CreateAccount />;

    return (
      <Window resizable>
        <Window.Content scrollable>
          <LoginInfo />
          {body}
        </Window.Content>
      </Window>
    );
  } catch (err) {
    // Если что-то пошло не так — выводим это прямо в окне
    return (
      <Window title="Accounts Uplink Terminal (render error)">
        <Window.Content scrollable>
          <Section title="Render error" level={2}>
            <div style={{ color: 'red', marginBottom: '8px' }}>
              {String(err?.message || err)}
            </div>
            <pre style={{ whiteSpace: 'pre-wrap' }}>{err?.stack}</pre>
          </Section>
        </Window.Content>
      </Window>
    );
  }
};

// ─────────────────────────────────────────────────────────────
// LIST
// ─────────────────────────────────────────────────────────────

const AccountsRecordList = (_props) => {
  const { act, data } = useBackend();
  const accounts = Array.isArray(data?.accounts) ? data.accounts : [];

  const [searchText, setSearchText] = useLocalState('searchText', '');
  const [sortId, setSortId] = useState('owner_name');
  const [sortOrder, setSortOrder] = useState(true);

  const passSort = { sortId, setSortId, sortOrder, setSortOrder };

  const match = (acc) => {
    const hay =
      safe(acc.owner_name, '') +
      '|' +
      safe(acc.account_number, '') +
      '|' +
      safe(acc.suspended, '');
    return hay.toLowerCase().includes(searchText.toLowerCase());
  };

  const sorted = [...accounts]
    .filter(match)
    .sort((a, b) => {
      const ai = safe(a[sortId], '').toString();
      const bi = safe(b[sortId], '').toString();
      const dir = sortOrder ? 1 : -1;
      return ai.localeCompare(bi) * dir;
    });

  return (
    <Flex direction="column" height="100%">
      <AccountsActions />
      <Flex.Item flexGrow="1" mt="0.5rem">
        <Section height="100%">
          <Table className="AccountsUplinkTerminal__list">
            <Table.Row bold>
              <SortButton id="owner_name" {...passSort}>
                Account Holder
              </SortButton>
              <SortButton id="account_number" {...passSort}>
                Account Number
              </SortButton>
              <SortButton id="suspended" {...passSort}>
                Account Status
              </SortButton>
            </Table.Row>

            {sorted.map((account, idx) => (
              <Table.Row
                key={account.id ?? idx}
                onClick={() => {
                  if (account.account_index === -1) {
                    act('view_account_detail', {
                      index: -1,
                      dep_index: account.dep_index, // ✅ добавили
                      dep_id: account.dep_id, // ✅ добавили
                      // target_name: account.target_name, // можно, но уже не обязательно
                    });
                  } else {
                    act('view_account_detail', {
                      index: account.account_index,
                    });
                  }
                }}
              >
                <Table.Cell>
                  <Icon name="user" /> {safe(account.owner_name, 'Unknown')}
                </Table.Cell>
                <Table.Cell>#{safe(account.account_number, 'N/A')}</Table.Cell>
                <Table.Cell>{safe(account.suspended, 'Unknown')}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Flex.Item>
    </Flex>
  );
};

const SortButton = (props, _context) => {
  const { id, children, sortId, setSortId, sortOrder, setSortOrder } = props;
  const active = sortId === id;
  return (
    <Table.Cell>
      <Button
        color={!active && 'transparent'}
        width="100%"
        onClick={() => {
          if (active) setSortOrder(!sortOrder);
          else {
            setSortId(id);
            setSortOrder(true);
          }
        }}
      >
        {children}
        {active && <Icon name={sortOrder ? 'sort-up' : 'sort-down'} ml="0.25rem" />}
      </Button>
    </Table.Cell>
  );
};

const AccountsActions = (_props) => {
  const { act, data } = useBackend();
  const is_printing = !!data?.is_printing;

  const [, setSearchText] = useLocalState('searchText', '');

  return (
    <Flex>
      <Flex.Item>
        <Button content="New Account" icon="plus" onClick={() => act('create_new_account')} />
        <Button
          icon="print"
          content="Print Account List"
          disabled={is_printing}
          ml="0.25rem"
          onClick={() => act('print_records')}
        />
      </Flex.Item>
      <Flex.Item grow="1" ml="0.5rem">
        <Input
          placeholder="Search by account holder, number, status"
          width="100%"
          onInput={(e, value) => setSearchText(value)}
        />
      </Flex.Item>
    </Flex>
  );
};

// ─────────────────────────────────────────────────────────────
// DETAILS
// ─────────────────────────────────────────────────────────────

const DetailedAccountInfo = (_props) => {
  const { act, data } = useBackend();
  const {
    is_printing = false,
    account_number = '',
    owner_name = '',
    money = '0',
    suspended = false,
  } = data;

  const transactions = Array.isArray(data.transactions) ? data.transactions : [];
  const isDepartment = !!data.is_department;
  return (
    <>
      <Section
        title={`#${account_number} / ${owner_name}`}
        mt={1}
        buttons={
          <>
            <Button
              icon="print"
              content="Print Account Details"
              disabled={is_printing}
              onClick={() => act('print_account_details')}
            />
            <Button
              icon="arrow-left"
              content="Back"
              onClick={() => act('back')}
            />
          </>
        }>
        <LabeledList>
          <LabeledList.Item label="Account Number">
            #{account_number}
          </LabeledList.Item>
          <LabeledList.Item label="Account Holder">
            {owner_name}
          </LabeledList.Item>
          <LabeledList.Item label="Account Balance">
            {money}
            {!isDepartment && (
            <Button
              ml={1}
              icon="dollar-sign"
              content="Change Pay Level"
              onClick={() => act('change_pay_level')}
            />
          )}
          </LabeledList.Item>
          <LabeledList.Item label="Account Status" color={suspended ? 'red' : 'green'}>
            {suspended ? 'Suspended' : 'Active'}
            {!isDepartment && (
            <Button
              ml={1}
              content={suspended ? 'Unsuspend' : 'Suspend'}
              icon={suspended ? 'unlock' : 'lock'}
              onClick={() => act('toggle_suspension')}
            />
            )}
          </LabeledList.Item>
        </LabeledList>

    {/* 🔻 Добавляем предупреждение */}
    {data.suspicious && (
      <Section
        title="⚠ Suspicious Activity Detected"
        color="bad"
        mt={1}
      >
        <div style={{ color: 'red', fontWeight: 'bold' }}>
          {data.suspicious_reason || 'Unusual account behavior detected.'}
        </div>
      </Section>
    )}
      </Section>

      <Section title="Transactions">
        <Table>
          <Table.Row header>
            <Table.Cell>Timestamp</Table.Cell>
            <Table.Cell>Target</Table.Cell>
            <Table.Cell>Reason</Table.Cell>
            <Table.Cell>Value</Table.Cell>
            <Table.Cell>Terminal</Table.Cell>
          </Table.Row>
          {transactions.map((t, i) => (
            <Table.Row key={`${t.date}-${t.time}-${i}`}>
              <Table.Cell>
                {t.date || '??'} {t.time || ''}
              </Table.Cell>
              <Table.Cell>{t.target_name || '-'}</Table.Cell>
              <Table.Cell>{t.purpose || '-'}</Table.Cell>
              <Table.Cell>${t.amount || '0'}</Table.Cell>
              <Table.Cell>{t.source_terminal || '-'}</Table.Cell>
            </Table.Row>
          ))}
          {transactions.length === 0 && (
            <Table.Row>
              <Table.Cell colSpan={5} textAlign="center" color="label">
                No transactions found.
              </Table.Cell>
            </Table.Row>
          )}
        </Table>
      </Section>
    </>
  );
};


// ─────────────────────────────────────────────────────────────
// CREATE
// ─────────────────────────────────────────────────────────────

const CreateAccount = (_props) => {
  const { act } = useBackend();
  const [accName, setAccName] = useState('');
  const [accDeposit, setAccDeposit] = useState('');

  return (
    <Section
      title="Create Account"
      buttons={<Button icon="arrow-left" content="Back" onClick={() => act('back')} />}
    >
      <LabeledList>
        <LabeledList.Item label="Account Holder">
          <Input placeholder="Name Here" onChange={(e, v) => setAccName(v)} />
        </LabeledList.Item>
        <LabeledList.Item label="Initial Deposit">
          <Input placeholder="0" onChange={(e, v) => setAccDeposit(v)} />
        </LabeledList.Item>
      </LabeledList>
      <Button
        mt={1}
        fluid
        content="Create Account"
        onClick={() => act('finalise_create_account', { holder_name: accName, starting_funds: accDeposit })}
      />
    </Section>
  );
};
