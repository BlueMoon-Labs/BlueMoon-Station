import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Table } from '../components';
import { Window } from '../layouts';

export const AdminTicketStats = (props, context) => {
  return (
    <Window
      title="Admin Ticket Statistics"
      width={900}
      height={600}
      theme="admin"
      resizable
    >
      <Window.Content scrollable>
        <TicketStatsPanel />
      </Window.Content>
    </Window>
  );
};

export const TicketStatsPanel = (props, context) => {
  const { act, data } = useBackend(context);

  const {
    loading,
    stats_data,
    error_message,
    default_start_date,
    default_end_date,
    available_columns,
    grouping_options,
    admin_list,
  } = data;

  return (
    <Section title="Admin Ticket Statistics">
      {/* Filters Section */}
      <FilterControls
        act={act}
        default_start_date={default_start_date}
        default_end_date={default_end_date}
        grouping_options={grouping_options}
        admin_list={admin_list}
        available_columns={available_columns}
        loading={loading}
      />

      {/* Loading State */}
      {loading && (
        <NoticeBox info>
          <Flex align="center">
            <ProgressBar value={1} ranges={{ good: [0, 1] }} />
            <Box ml={2}>Loading data...</Box>
          </Flex>
        </NoticeBox>
      )}

      {/* Error Display */}
      {error_message && (
        <NoticeBox danger>
          Error: {error_message}
        </NoticeBox>
      )}

      {/* Results Display */}
      {!loading && stats_data && stats_data.length > 0 && (
        <StatsResults
          stats_data={stats_data}
          available_columns={available_columns}
        />
      )}

      {!loading && stats_data && stats_data.length === 0 && (
        <NoticeBox info>
          No data found for the selected criteria.
        </NoticeBox>
      )}
    </Section>
  );
};

export const FilterControls = (props, context) => {
  const {
    act,
    default_start_date,
    default_end_date,
    grouping_options,
    admin_list,
    available_columns,
    loading,
  } = props;

  const [startDate, setStartDate] = useLocalState(context, 'startDate', default_start_date);
  const [endDate, setEndDate] = useLocalState(context, 'endDate', default_end_date);
  const [adminFilter, setAdminFilter] = useLocalState(context, 'adminFilter', '');
  const [grouping, setGrouping] = useLocalState(context, 'grouping', 'none');
  const [selectedColumns, setSelectedColumns] = useLocalState(context, 'selectedColumns',
    available_columns.map(col => col.key)
  );
  const [sortColumn, setSortColumn] = useLocalState(context, 'sortColumn', 'admin_name');
  const [sortOrder, setSortOrder] = useLocalState(context, 'sortOrder', 'ASC');

  const handleFetchStats = () => {
    act('fetch_stats', {
      start_date: startDate,
      end_date: endDate,
      admin_filter: adminFilter,
      grouping: grouping,
      selected_columns: selectedColumns,
      sort_column: sortColumn,
      sort_order: sortOrder,
    });
  };

  const toggleColumn = (columnKey) => {
    setSelectedColumns(prev =>
      prev.includes(columnKey)
        ? prev.filter(col => col !== columnKey)
        : [...prev, columnKey]
    );
  };

  const handleSortChange = (column) => {
    if (sortColumn === column) {
      setSortOrder(sortOrder === 'ASC' ? 'DESC' : 'ASC');
    } else {
      setSortColumn(column);
      setSortOrder('ASC');
    }
  };

  const clearAdminFilter = () => {
    setAdminFilter('');
  };

  // Get display name for sort column
  const getSortColumnName = () => {
    if (sortColumn === 'admin_name') return 'Admin Name';
    const column = available_columns.find(col => col.key === sortColumn);
    return column ? column.name : sortColumn;
  };

  return (
    <Box>
      {/* Date Range */}
      <LabeledList>
        <LabeledList.Item label="Start Date">
          <Input
            type="date"
            value={startDate}
            onChange={(e, value) => setStartDate(value)}
            style={{ width: '200px' }}
            disabled={loading}
          />
        </LabeledList.Item>
        <LabeledList.Item label="End Date">
          <Input
            type="date"
            value={endDate}
            onChange={(e, value) => setEndDate(value)}
            style={{ width: '200px' }}
            disabled={loading}
          />
        </LabeledList.Item>
      </LabeledList>

      {/* Admin Filter */}
      <LabeledList>
        <LabeledList.Item label="Filter by Admin">
          <Flex>
            <Dropdown
              width="180px"
              selected={adminFilter || "All Admins"}
              options={['', ...admin_list]}
              onSelected={(value) => setAdminFilter(value)}
              disabled={loading}
            />
            {adminFilter && (
              <Button
                icon="times"
                color="bad"
                onClick={clearAdminFilter}
                tooltip="Clear filter"
                ml={1}
                disabled={loading}
              />
            )}
          </Flex>
        </LabeledList.Item>
      </LabeledList>

      {/* Grouping Options */}
      <LabeledList>
        <LabeledList.Item label="Group By">
          <Dropdown
            width="200px"
            selected={grouping}
            options={grouping_options.map(opt => opt.key)}
            displayText={grouping_options.find(opt => opt.key === grouping)?.name}
            onSelected={(value) => setGrouping(value)}
            disabled={loading}
          />
        </LabeledList.Item>
      </LabeledList>

      {/* Sort Options */}
      <LabeledList>
        <LabeledList.Item label="Sort By">
          <Dropdown
            width="200px"
            selected={sortColumn}
            options={['admin_name', ...available_columns.map(col => col.key)]}
            displayText={getSortColumnName()}
            onSelected={(value) => handleSortChange(value)}
            disabled={loading}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Sort Order">
          <Button
            icon={sortOrder === 'ASC' ? 'sort-amount-up' : 'sort-amount-down'}
            selected
            onClick={() => setSortOrder(sortOrder === 'ASC' ? 'DESC' : 'ASC')}
            tooltip={sortOrder === 'ASC' ? 'Ascending' : 'Descending'}
            disabled={loading}
          >
            {sortOrder === 'ASC' ? 'ASC ↑' : 'DESC ↓'}
          </Button>
        </LabeledList.Item>
      </LabeledList>

      {/* Column Selection */}
      <Section title="Select Columns">
        <Flex wrap="wrap">
          {available_columns.map(column => (
            <Button
              key={column.key}
              selected={selectedColumns.includes(column.key)}
              onClick={() => toggleColumn(column.key)}
              m={0.5}
              disabled={loading}
            >
              {column.name}
            </Button>
          ))}
        </Flex>
      </Section>

      {/* Fetch Button */}
      <Button
        icon="search"
        color="good"
        onClick={handleFetchStats}
        disabled={selectedColumns.length === 0 || loading}
        tooltip={selectedColumns.length === 0 ? "Select at least one column" : ""}
      >
        {loading ? "Loading..." : "Fetch Statistics"}
      </Button>
    </Box>
  );
};

export const StatsResults = (props, context) => {
  const { stats_data, available_columns } = props;

  // Get all possible column keys from the first row
  const allColumns = Object.keys(stats_data[0] || {});
  const visibleColumns = allColumns.filter(col =>
    col !== 'admin_name' && col !== 'admin_rank' && col !== 'period_group'
  );

  return (
    <Section title="Results" mt={2}>
      <Table>
        <Table.Row header>
          {stats_data[0].period_group && <Table.Cell>Period</Table.Cell>}
          <Table.Cell>Admin</Table.Cell>
          <Table.Cell>Rank</Table.Cell>
          {visibleColumns.map(column => {
            const columnInfo = available_columns.find(col => col.key === column);
            return (
              <Table.Cell key={column}>
                {columnInfo ? columnInfo.name : column}
              </Table.Cell>
            );
          })}
        </Table.Row>
        {stats_data.map((row, index) => (
          <Table.Row key={index}>
            {row.period_group && <Table.Cell>{row.period_group}</Table.Cell>}
            <Table.Cell>{row.admin_name}</Table.Cell>
            <Table.Cell>{row.admin_rank}</Table.Cell>
            {visibleColumns.map(column => (
              <Table.Cell key={column}>
                {row[column] || 0}
              </Table.Cell>
            ))}
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};
