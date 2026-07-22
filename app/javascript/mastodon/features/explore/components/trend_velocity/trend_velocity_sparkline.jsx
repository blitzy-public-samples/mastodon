import PropTypes from 'prop-types';

import { defineMessages, useIntl } from 'react-intl';

import ArrowDownwardIcon from '@/material-icons/400-24px/arrow_downward.svg?react';
import ArrowRightAltIcon from '@/material-icons/400-24px/arrow_right_alt.svg?react';
import ArrowUpwardIcon from '@/material-icons/400-24px/arrow_upward.svg?react';
import { Icon } from 'mastodon/components/icon';

const messages = defineMessages({
  rising: { id: 'trend_velocity.rising', defaultMessage: 'Rising' },
  falling: { id: 'trend_velocity.falling', defaultMessage: 'Falling' },
  flat: { id: 'trend_velocity.flat', defaultMessage: 'Flat' },
});

const WIDTH = 50;
const HEIGHT = 28;

export const TrendVelocitySparkline = ({ history }) => {
  const intl = useIntl();

  // Guard against non-finite entries (for example a NaN produced by coercing
  // a malformed, non-numeric `uses` string). Only finite values can be
  // plotted or compared, so drop everything else first and fall back to the
  // degraded state when fewer than two finite points remain.
  const values = history.filter((value) => Number.isFinite(value));
  const length = values.length;

  if (length < 2) {
    return null;
  }

  const direction = Math.sign(values[length - 1] - values[length - 2]);

  const max = Math.max(...values);
  const min = Math.min(...values);

  const points = values
    .map((value, index) => {
      const x = (index / (length - 1)) * WIDTH;
      const y =
        HEIGHT -
        (max === min ? HEIGHT / 2 : ((value - min) / (max - min)) * HEIGHT);

      return `${x},${y}`;
    })
    .join(' ');

  let indicatorIcon;
  let indicatorColor;
  let indicatorLabel;

  if (direction > 0) {
    indicatorIcon = ArrowUpwardIcon;
    indicatorColor = 'var(--color-text-success)';
    indicatorLabel = intl.formatMessage(messages.rising);
  } else if (direction < 0) {
    indicatorIcon = ArrowDownwardIcon;
    indicatorColor = 'var(--color-text-error)';
    indicatorLabel = intl.formatMessage(messages.falling);
  } else {
    indicatorIcon = ArrowRightAltIcon;
    indicatorColor = 'var(--color-text-secondary)';
    indicatorLabel = intl.formatMessage(messages.flat);
  }

  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
      <svg
        width={WIDTH}
        height={HEIGHT}
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        aria-hidden='true'
      >
        <polyline
          points={points}
          fill='none'
          stroke='var(--color-graph-primary-stroke)'
          strokeWidth={1}
        />
      </svg>

      <Icon
        id='trend-velocity'
        icon={indicatorIcon}
        aria-label={indicatorLabel}
        style={{ color: indicatorColor }}
      />
    </div>
  );
};

TrendVelocitySparkline.propTypes = {
  history: PropTypes.arrayOf(PropTypes.number),
};
