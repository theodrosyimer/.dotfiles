type __SEARCH_RESULT__ = {
  id: string;
  title: string;
  subtitle?: string;
};

type NativeSearchProps = {
  query: string;
  onQueryChange: (query: string) => void;
  filters: string[];
  selectedFilters: string[];
  onToggleFilter: (filter: string) => void;
  results: __SEARCH_RESULT__[];
  onSelectResult: (result: __SEARCH_RESULT__) => void;
  isRefreshing?: boolean;
  onRefresh?: () => void;
};

export type { __SEARCH_RESULT__, NativeSearchProps };
