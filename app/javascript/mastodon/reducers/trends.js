import { Map as ImmutableMap, List as ImmutableList, fromJS } from 'immutable';

import {
  TRENDS_TAGS_FETCH_REQUEST,
  TRENDS_TAGS_FETCH_SUCCESS,
  TRENDS_TAGS_FETCH_FAIL,
  // Local vs. Federated Trend Comparison: dedicated comparison-tile action types
  TRENDS_TAGS_COMPARISON_FETCH_REQUEST,
  TRENDS_TAGS_COMPARISON_FETCH_SUCCESS,
  TRENDS_TAGS_COMPARISON_FETCH_FAIL,
  TRENDS_LINKS_FETCH_REQUEST,
  TRENDS_LINKS_FETCH_SUCCESS,
  TRENDS_LINKS_FETCH_FAIL,
} from 'mastodon/actions/trends';

const initialState = ImmutableMap({
  tags: ImmutableMap({
    items: ImmutableList(),
    isLoading: false,
  }),

  // Local vs. Federated Trend Comparison: dedicated slice holding the scope-aware trending tags
  // (with history_local/history_remote) rendered by the comparison tile. Isolated from `tags` so the
  // no-scope list fetch (and the nav-panel's periodic refresh) can never overwrite the tile's data.
  comparison: ImmutableMap({
    items: ImmutableList(),
    isLoading: false,
  }),

  links: ImmutableMap({
    items: ImmutableList(),
    isLoading: false,
  }),
});

export default function trendsReducer(state = initialState, action) {
  switch(action.type) {
  case TRENDS_TAGS_FETCH_REQUEST:
    return state.setIn(['tags', 'isLoading'], true);
  case TRENDS_TAGS_FETCH_SUCCESS:
    return state.withMutations(map => {
      map.setIn(['tags', 'items'], fromJS(action.trends));
      map.setIn(['tags', 'isLoading'], false);
    });
  case TRENDS_TAGS_FETCH_FAIL:
    return state.setIn(['tags', 'isLoading'], false);
  // Local vs. Federated Trend Comparison: maintain the tile's dedicated comparison slice
  case TRENDS_TAGS_COMPARISON_FETCH_REQUEST:
    return state.setIn(['comparison', 'isLoading'], true);
  case TRENDS_TAGS_COMPARISON_FETCH_SUCCESS:
    return state.withMutations(map => {
      map.setIn(['comparison', 'items'], fromJS(action.trends));
      map.setIn(['comparison', 'isLoading'], false);
    });
  case TRENDS_TAGS_COMPARISON_FETCH_FAIL:
    return state.setIn(['comparison', 'isLoading'], false);
  case TRENDS_LINKS_FETCH_REQUEST:
    return state.setIn(['links', 'isLoading'], true);
  case TRENDS_LINKS_FETCH_SUCCESS:
    return state.withMutations(map => {
      map.setIn(['links', 'items'], fromJS(action.trends));
      map.setIn(['links', 'isLoading'], false);
    });
  case TRENDS_LINKS_FETCH_FAIL:
    return state.setIn(['links', 'isLoading'], false);
  default:
    return state;
  }
}
