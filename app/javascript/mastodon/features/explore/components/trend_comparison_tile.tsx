// Local vs. Federated Trend Comparison: comparison tile for Explore → Hashtags (paired sparklines + scope toggle + divergence badge).
import { Component, useCallback, useState } from 'react';

import { FormattedMessage } from 'react-intl';

import classNames from 'classnames';

import type { List as ImmutableList, Map as ImmutableMap } from 'immutable';

import { Sparklines, SparklinesCurve } from 'react-sparklines';

import { LoadingIndicator } from 'mastodon/components/loading_indicator';

import type { TrendScope } from '../util/trend_comparison';
import {
  classifyDivergence,
  hasScopedUsage,
  recentUses,
  usesSeries,
} from '../util/trend_comparison';

// Local, private copy of hashtag.tsx's SilentErrorBoundary (kept local so the tile is self-contained; NOT imported from hashtag.tsx).
interface SilentErrorBoundaryProps {
  children: React.ReactNode;
}

class SilentErrorBoundary extends Component<SilentErrorBoundaryProps> {
  state = {
    error: false,
  };

  componentDidCatch() {
    this.setState({ error: true });
  }

  render() {
    if (this.state.error) {
      return null;
    }

    return this.props.children;
  }
}

type TagMap = ImmutableMap<string, unknown>;
type ScopedHistory = ImmutableList<ImmutableMap<string, string>> | undefined;

interface ScopeButtonProps {
  scope: TrendScope;
  active: boolean;
  onSelect: (scope: TrendScope) => void;
  children: React.ReactNode;
}

const ScopeButton: React.FC<ScopeButtonProps> = ({
  scope,
  active,
  onSelect,
  children,
}) => {
  const handleClick = useCallback(() => {
    onSelect(scope);
  }, [scope, onSelect]);

  return (
    <button
      type='button'
      aria-pressed={active}
      onClick={handleClick}
      className={classNames('trend-comparison__toggle-button', {
        'trend-comparison__toggle-button--active': active,
      })}
    >
      {children}
    </button>
  );
};

interface TrendComparisonTileProps {
  tags: ImmutableList<TagMap>;
  isLoading: boolean;
  onScopeChange: (scope: TrendScope) => void;
}

export const TrendComparisonTile: React.FC<TrendComparisonTileProps> = ({
  tags,
  isLoading,
  onScopeChange,
}) => {
  const [scope, setScope] = useState<TrendScope>('all');

  const handleScopeSelect = useCallback(
    (next: TrendScope) => {
      setScope(next);
      onScopeChange(next);
    },
    [onScopeChange],
  );

  // Local vs. Federated Trend Comparison: treat absent AND present-but-all-zero
  // scoped histories as empty (a freshly-deployed instance has zero-filled keys),
  // so the tile shows its placeholder rather than flat-zero rows. A tag with any
  // local OR remote usage (including partial, one-sided data) keeps the tile live.
  const isEmpty =
    tags.isEmpty() ||
    tags.every(
      (tag) =>
        !hasScopedUsage(
          tag.get('history_local') as ScopedHistory,
          tag.get('history_remote') as ScopedHistory,
        ),
    );

  let body: React.ReactNode;

  if (isLoading) {
    body = <LoadingIndicator />;
  } else if (isEmpty) {
    body = (
      <div className='trend-comparison__empty'>
        <FormattedMessage
          id='trend_comparison.empty'
          defaultMessage='Not enough data yet to compare local and federated trends.'
        />
      </div>
    );
  } else {
    body = tags
      .map((tag) => {
        const name = tag.get('name') as string;
        const localHistory = tag.get('history_local') as ScopedHistory;
        const remoteHistory = tag.get('history_remote') as ScopedHistory;
        const badge = classifyDivergence(
          recentUses(localHistory),
          recentUses(remoteHistory),
        );

        return (
          <div className='trend-comparison__row' key={name}>
            <span className='trend-comparison__name'>#{name}</span>

            <div
              className={classNames('trend-comparison__sparkline', {
                'trend-comparison__sparkline--dimmed': scope === 'remote',
              })}
            >
              <SilentErrorBoundary>
                <Sparklines
                  width={50}
                  height={28}
                  data={usesSeries(localHistory)}
                >
                  <SparklinesCurve style={{ fill: 'none' }} />
                </Sparklines>
              </SilentErrorBoundary>
            </div>

            <div
              className={classNames('trend-comparison__sparkline', {
                'trend-comparison__sparkline--dimmed': scope === 'local',
              })}
            >
              <SilentErrorBoundary>
                <Sparklines
                  width={50}
                  height={28}
                  data={usesSeries(remoteHistory)}
                >
                  <SparklinesCurve style={{ fill: 'none' }} />
                </Sparklines>
              </SilentErrorBoundary>
            </div>

            {badge === 'local-skewed' && (
              <span className='trend-comparison__badge'>
                <FormattedMessage
                  id='trend_comparison.badge.local_skewed'
                  defaultMessage='Hot here, quiet elsewhere'
                />
              </span>
            )}
            {badge === 'network-wide' && (
              <span className='trend-comparison__badge'>
                <FormattedMessage
                  id='trend_comparison.badge.network_wide'
                  defaultMessage='Network-wide trend'
                />
              </span>
            )}
          </div>
        );
      })
      .toArray();
  }

  return (
    <div className='trend-comparison'>
      <div className='trend-comparison__header'>
        <h3 className='trend-comparison__title'>
          <FormattedMessage
            id='trend_comparison.title'
            defaultMessage='Local vs. Federated'
          />
        </h3>

        <div className='trend-comparison__toggle'>
          <ScopeButton
            scope='all'
            active={scope === 'all'}
            onSelect={handleScopeSelect}
          >
            <FormattedMessage
              id='trend_comparison.compare'
              defaultMessage='Compare'
            />
          </ScopeButton>
          <ScopeButton
            scope='local'
            active={scope === 'local'}
            onSelect={handleScopeSelect}
          >
            <FormattedMessage
              id='trend_comparison.local'
              defaultMessage='Local'
            />
          </ScopeButton>
          <ScopeButton
            scope='remote'
            active={scope === 'remote'}
            onSelect={handleScopeSelect}
          >
            <FormattedMessage
              id='trend_comparison.federated'
              defaultMessage='Federated'
            />
          </ScopeButton>
        </div>
      </div>

      {body}
    </div>
  );
};
