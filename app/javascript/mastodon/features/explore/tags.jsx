import PropTypes from 'prop-types';
import { PureComponent } from 'react';

import { FormattedMessage } from 'react-intl';

import { withRouter } from 'react-router-dom';

import ImmutablePropTypes from 'react-immutable-proptypes';
import { connect } from 'react-redux';

import { fetchTrendingHashtags } from 'mastodon/actions/trends';
import { DismissableBanner } from 'mastodon/components/dismissable_banner';
import { ImmutableHashtag as Hashtag } from 'mastodon/components/hashtag';
import { LoadingIndicator } from 'mastodon/components/loading_indicator';
import { WithRouterPropTypes } from 'mastodon/utils/react_router';

// Local vs. Federated Trend Comparison:
import { TrendComparisonTile } from './components/trend_comparison_tile';

const mapStateToProps = state => ({
  hashtags: state.getIn(['trends', 'tags', 'items']),
  isLoadingHashtags: state.getIn(['trends', 'tags', 'isLoading']),
});

class Tags extends PureComponent {

  static propTypes = {
    hashtags: ImmutablePropTypes.list,
    isLoading: PropTypes.bool,
    // Local vs. Federated Trend Comparison:
    isLoadingHashtags: PropTypes.bool,
    dispatch: PropTypes.func.isRequired,
    ...WithRouterPropTypes,
  };

  componentDidMount () {
    const { dispatch, history, hashtags } = this.props;

    // If we're navigating back to the screen, do not trigger a reload
    if (history.action === 'POP' && hashtags.size > 0) {
      return;
    }

    // Local vs. Federated Trend Comparison: fetch combined (Compare) scope on mount
    dispatch(fetchTrendingHashtags('all'));
  }

  // Local vs. Federated Trend Comparison: re-fetch with the toggle-selected scope
  handleScopeChange = (scope) => {
    this.props.dispatch(fetchTrendingHashtags(scope));
  };

  render () {
    // Local vs. Federated Trend Comparison: also read the scoped loading flag for the tile
    const { isLoading, hashtags, isLoadingHashtags } = this.props;

    if (!isLoading && hashtags.isEmpty()) {
      return (
        <div className='explore__links scrollable scrollable--flex'>
          <div className='empty-column-indicator'>
            <FormattedMessage id='empty_column.explore_statuses' defaultMessage='Nothing is trending right now. Check back later!' tagName='span' />
          </div>
        </div>
      );
    }

    return (
      <div className='scrollable explore__links' data-nosnippet>
        {/* Local vs. Federated Trend Comparison: comparison tile above the hashtag list */}
        <TrendComparisonTile tags={hashtags} isLoading={isLoadingHashtags} onScopeChange={this.handleScopeChange} />
        {isLoading ? (<LoadingIndicator />) : hashtags.map(hashtag => (
          <Hashtag key={hashtag.get('name')} hashtag={hashtag} />
        ))}
      </div>
    );
  }

}

export default connect(mapStateToProps)(withRouter(Tags));
