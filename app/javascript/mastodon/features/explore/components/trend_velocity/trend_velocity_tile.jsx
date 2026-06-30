import { defineMessages, useIntl } from 'react-intl';

import ImmutablePropTypes from 'react-immutable-proptypes';

import { Hashtag } from 'mastodon/components/hashtag';

import { TrendVelocitySparkline } from './trend_velocity_sparkline';

const messages = defineMessages({
  title: { id: 'trend_velocity.title', defaultMessage: 'Trend Velocity' },
});

export const TrendVelocityTile = ({ hashtags }) => {
  const intl = useIntl();

  if (!hashtags || hashtags.isEmpty()) {
    return null;
  }

  return (
    <div className='trends'>
      <h2 className='getting-started__trends-heading'>
        {intl.formatMessage(messages.title)}
      </h2>

      {hashtags.take(5).map((hashtag) => {
        const name = hashtag.get('name');
        const series = hashtag
          .get('history')
          .reverse()
          .map((entry) => Number(entry.get('uses')))
          .toArray();
        const people =
          Number(hashtag.getIn(['history', 0, 'accounts'])) +
          Number(hashtag.getIn(['history', 1, 'accounts']) ?? 0);

        return (
          <Hashtag
            key={name}
            name={name}
            to={`/tags/${name}`}
            people={people}
            uses={Number(hashtag.getIn(['history', 0, 'uses']))}
            withGraph={false}
          >
            <TrendVelocitySparkline history={series} />
          </Hashtag>
        );
      })}
    </div>
  );
};

TrendVelocityTile.propTypes = {
  hashtags: ImmutablePropTypes.list,
};
