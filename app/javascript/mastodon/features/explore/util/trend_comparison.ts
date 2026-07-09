// Local vs. Federated Trend Comparison: pure selectors/helpers for the comparison tile.
import type { List as ImmutableList, Map as ImmutableMap } from 'immutable';

export type TrendScope = 'all' | 'local' | 'remote';
export type DivergenceBadge = 'local-skewed' | 'network-wide' | null;

export const HISTORY_LENGTH = 7;
export const DIVERGENCE_THRESHOLD = 2; // fixed 2:1 ratio

type History = ImmutableList<ImmutableMap<string, string>> | undefined;

// Zero-fill for absent/partial scoped history (array of 0s, length 7 by default).
export const zeroFilledSeries = (length = HISTORY_LENGTH): number[] =>
  Array.from({ length }, () => 0);

// Numeric `uses` series for a sparkline, reversed to chronological order (oldest -> newest),
// zero-filled when history is absent/empty (mirrors hashtag.tsx behavior).
export const usesSeries = (history: History): number[] =>
  history && history.size > 0
    ? history
        .reverse()
        .map((day) => Number(day.get('uses')) || 0)
        .toArray()
    : zeroFilledSeries();

// Sum of `uses` over the most-recent N buckets (index 0 = today = "last 24h").
export const recentUses = (history: History, buckets = 1): number =>
  history
    ? history
        .slice(0, buckets)
        .reduce((sum, day) => sum + (Number(day.get('uses')) || 0), 0)
    : 0;

// Divide-by-zero-safe divergence ratio.
export const divergenceRatio = (local: number, remote: number): number =>
  Math.max(local, remote) / Math.max(Math.min(local, remote), 1);

// Badge classification with the fixed 2:1 threshold.
// Suppress (null) when either side is zero OR the ratio is below threshold.
export const classifyDivergence = (
  local: number,
  remote: number,
): DivergenceBadge => {
  if (local <= 0 || remote <= 0) return null;
  if (divergenceRatio(local, remote) < DIVERGENCE_THRESHOLD) return null;
  return local > remote ? 'local-skewed' : 'network-wide';
};
