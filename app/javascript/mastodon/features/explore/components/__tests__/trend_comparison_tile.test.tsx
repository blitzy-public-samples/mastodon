// Local vs. Federated Trend Comparison: component test for the comparison tile.
import { IntlProvider } from 'react-intl';

import type { List as ImmutableList, Map as ImmutableMap } from 'immutable';
import { fromJS } from 'immutable';

import { fireEvent, render, screen } from '@testing-library/react';
import { vi } from 'vitest';

import type { TrendScope } from '../../util/trend_comparison';
import { TrendComparisonTile } from '../trend_comparison_tile';

type TagList = ImmutableList<ImmutableMap<string, unknown>>;

const buildHistory = (values: number[]) =>
  values.map((value, index) => ({
    day: `${1700000000 - index * 86400}`,
    accounts: `${value}`,
    uses: `${value}`,
  }));

const buildTag = (name: string, localUses: number[], remoteUses: number[]) => ({
  name,
  history: buildHistory(localUses),
  history_local: buildHistory(localUses),
  history_remote: buildHistory(remoteUses),
});

const renderTile = (
  tags: TagList,
  onScopeChange: (scope: TrendScope) => void = vi.fn(),
  isLoading = false,
) =>
  render(
    <IntlProvider locale='en'>
      <TrendComparisonTile
        tags={tags}
        isLoading={isLoading}
        onScopeChange={onScopeChange}
      />
    </IntlProvider>,
  );

const sampleTags = fromJS([
  buildTag('localwins', [10, 8, 9, 7, 6, 5, 4], [1, 0, 1, 0, 1, 0, 1]),
  buildTag('networkwide', [1, 0, 1, 0, 1, 0, 1], [10, 8, 9, 7, 6, 5, 4]),
]) as unknown as TagList;

describe('<TrendComparisonTile />', () => {
  it('renders the heading and hashtag names with mock data', () => {
    renderTile(sampleTags);

    expect(screen.getByText('Local vs. Federated')).toBeDefined();
    expect(screen.getByText(/localwins/)).toBeDefined();
    expect(screen.getByText(/networkwide/)).toBeDefined();
  });

  it('calls onScopeChange with the selected scope when toggling', () => {
    const onScopeChange = vi.fn();
    renderTile(sampleTags, onScopeChange);

    fireEvent.click(screen.getByText('Local'));
    expect(onScopeChange).toHaveBeenCalledWith('local');

    fireEvent.click(screen.getByText('Federated'));
    expect(onScopeChange).toHaveBeenCalledWith('remote');

    fireEvent.click(screen.getByText('Compare'));
    expect(onScopeChange).toHaveBeenCalledWith('all');
  });

  it('shows the local-skewed badge only past the 2:1 threshold', () => {
    renderTile(
      fromJS([
        buildTag('hot', [10, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1]),
      ]) as unknown as TagList,
    );

    expect(screen.getByText('Hot here, quiet elsewhere')).toBeDefined();
    expect(screen.queryByText('Network-wide trend')).toBeNull();
  });

  it('shows the network-wide badge when remote dominates past the threshold', () => {
    renderTile(
      fromJS([
        buildTag('wide', [1, 1, 1, 1, 1, 1, 1], [10, 1, 1, 1, 1, 1, 1]),
      ]) as unknown as TagList,
    );

    expect(screen.getByText('Network-wide trend')).toBeDefined();
    expect(screen.queryByText('Hot here, quiet elsewhere')).toBeNull();
  });

  it('shows no badge for balanced usage', () => {
    renderTile(
      fromJS([
        buildTag('balanced', [3, 3, 3, 3, 3, 3, 3], [3, 3, 3, 3, 3, 3, 3]),
      ]) as unknown as TagList,
    );

    expect(screen.queryByText('Hot here, quiet elsewhere')).toBeNull();
    expect(screen.queryByText('Network-wide trend')).toBeNull();
  });

  it('renders the placeholder when the list is empty', () => {
    renderTile(fromJS([]) as unknown as TagList);

    expect(
      screen.getByText(
        'Not enough data yet to compare local and federated trends.',
      ),
    ).toBeDefined();
  });

  it('renders the placeholder when tags lack scoped history', () => {
    renderTile(
      fromJS([
        { name: 'bare', history: buildHistory([1, 2, 3, 4, 5, 6, 7]) },
      ]) as unknown as TagList,
    );

    expect(
      screen.getByText(
        'Not enough data yet to compare local and federated trends.',
      ),
    ).toBeDefined();
  });
});
