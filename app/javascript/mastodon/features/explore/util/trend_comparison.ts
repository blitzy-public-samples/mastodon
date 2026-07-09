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

// Numeric `uses` series for a sparkline, reversed to chronological order (oldest -> newest).
// Always returns exactly HISTORY_LENGTH values: absent, empty, and partial (1-6 bucket)
// histories are zero-filled on the left so the most-recent bucket stays on the right
// (mirrors hashtag.tsx, which reverses most-recent-first history for the sparkline).
export const usesSeries = (history: History): number[] => {
  if (!history || history.size === 0) return zeroFilledSeries();

  // Reverse most-recent-first -> chronological (oldest -> newest), coercing string `uses`.
  const chronological = history
    .reverse()
    .map((day) => Number(day.get('uses')) || 0)
    .toArray();

  // Keep the most-recent HISTORY_LENGTH buckets and left-pad any missing older buckets
  // with zeroes, guaranteeing a length-7 series with the newest value on the right.
  const recent = chronological.slice(-HISTORY_LENGTH);

  return recent.length < HISTORY_LENGTH
    ? [...zeroFilledSeries(HISTORY_LENGTH - recent.length), ...recent]
    : recent;
};

// Sum of `uses` over the most-recent N buckets (index 0 = today = "last 24h").
export const recentUses = (history: History, buckets = 1): number =>
  history
    ? history
        .slice(0, buckets)
        .reduce((sum, day) => sum + (Number(day.get('uses')) || 0), 0)
    : 0;

// Sum of `uses` across the ENTIRE scoped history (all buckets). Used for
// empty-state detection: distinguishes a truly-empty scoped history from one
// that merely has a low most-recent bucket.
export const seriesTotal = (history: History): number =>
  history
    ? history.reduce((sum, day) => sum + (Number(day.get('uses')) || 0), 0)
    : 0;

// True when a tag has ANY recorded local OR remote usage. Absent keys and
// all-zero (freshly-deployed, present-but-zero) scoped histories both read as
// "no usage" so the tile can fall back to its empty-state placeholder instead
// of rendering flat-zero rows; a partial history (one side > 0) still counts as
// usage so that row keeps rendering.
export const hasScopedUsage = (local: History, remote: History): boolean =>
  seriesTotal(local) > 0 || seriesTotal(remote) > 0;

// Divide-by-zero-safe divergence ratio.
export const divergenceRatio = (local: number, remote: number): number =>
  Math.max(local, remote) / Math.max(Math.min(local, remote), 1);

// Badge classification with the fixed 2:1 threshold.
// Per the AAP the badge appears only when velocity diverges *beyond* the
// threshold (ratio strictly > 2:1); an exact 2:1 ratio must NOT badge. Suppress
// (null) when either side is zero OR the ratio does not exceed the threshold.
export const classifyDivergence = (
  local: number,
  remote: number,
): DivergenceBadge => {
  if (local <= 0 || remote <= 0) return null;
  if (divergenceRatio(local, remote) <= DIVERGENCE_THRESHOLD) return null;
  return local > remote ? 'local-skewed' : 'network-wide';
};
