import PropTypes from 'prop-types';
import { PureComponent } from 'react';

import { FormattedMessage } from 'react-intl';

import { withRouter } from 'react-router-dom';

import ImmutablePropTypes from 'react-immutable-proptypes';
import { connect } from 'react-redux';

// Local vs. Federated Trend Comparison: dedicated comparison-tile fetch alongside the list fetch
import { fetchTrendingHashtags, fetchTrendingHashtagsComparison } from 'mastodon/actions/trends';
import { DismissableBanner } from 'mastodon/components/dismissable_banner';
import { ImmutableHashtag as Hashtag } from 'mastodon/components/hashtag';
import { LoadingIndicator } from 'mastodon/components/loading_indicator';
import { WithRouterPropTypes } from 'mastodon/utils/react_router';

// Local vs. Federated Trend Comparison:
import { TrendComparisonTile } from './components/trend_comparison_tile';

const mapStateToProps = state => ({
  hashtags: state.getIn(['trends', 'tags', 'items']),
  isLoadingHashtags: state.getIn(['trends', 'tags', 'isLoading']),
  // Local vs. Federated Trend Comparison: the tile reads its OWN dedicated slice (scope-aware,
  // with history_local/history_remote), decoupled from the shared no-scope list slice above.
  comparisonHashtags: state.getIn(['trends', 'comparison', 'items']),
  isLoadingComparison: state.getIn(['trends', 'comparison', 'isLoading']),
});

class Tags extends PureComponent {

  static propTypes = {
    hashtags: ImmutablePropTypes.list,
    isLoading: PropTypes.bool,
    // Local vs. Federated Trend Comparison: props consumed by the comparison tile (its own slice)
    comparisonHashtags: ImmutablePropTypes.list,
    isLoadingComparison: PropTypes.bool,
    dispatch: PropTypes.func.isRequired,
    ...WithRouterPropTypes,
  };

  componentDidMount () {
    const { dispatch, history, hashtags, comparisonHashtags } = this.props;

    const isBackNavigation = history.action === 'POP';

    // If we're navigating back to the screen, do not trigger a reload of the (shared) hashtag list
    if (!(isBackNavigation && hashtags.size > 0)) {
      dispatch(fetchTrendingHashtags());
    }

    // Local vs. Federated Trend Comparison: fetch the tile's scope-aware data into its OWN slice,
    // guarded independently of the list. This slice is never populated by the no-scope navigation-panel
    // fetch, so a direct load / reload (history.action === 'POP') still fetches scope=all here — fixing
    // the empty-tile-on-load race — while genuine back-navigation to an already-populated tile is skipped.
    if (!(isBackNavigation && comparisonHashtags.size > 0)) {
      dispatch(fetchTrendingHashtagsComparison('all'));
    }
  }

  // Local vs. Federated Trend Comparison: re-fetch the tile's dedicated slice with the toggle-selected scope
  handleScopeChange = (scope) => {
    this.props.dispatch(fetchTrendingHashtagsComparison(scope));
  };

  render () {
    // Local vs. Federated Trend Comparison: the tile renders from its own comparison slice + loading flag
    const { isLoading, hashtags, comparisonHashtags, isLoadingComparison } = this.props;

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
        {/* Local vs. Federated Trend Comparison: comparison tile above the hashtag list, fed by its own slice */}
        <TrendComparisonTile tags={comparisonHashtags} isLoading={isLoadingComparison} onScopeChange={this.handleScopeChange} />
        {isLoading ? (<LoadingIndicator />) : hashtags.map(hashtag => (
          <Hashtag key={hashtag.get('name')} hashtag={hashtag} />
        ))}
      </div>
    );
  }

}

export default connect(mapStateToProps)(withRouter(Tags));
