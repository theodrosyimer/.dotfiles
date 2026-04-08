import { useState, useCallback } from "react";
import {
  Host,
  DockedSearchBar,
  FlowRow,
  FilterChip,
  LazyColumn,
  ListItem,
  PullToRefreshBox,
  Text,
} from "@expo/ui/jetpack-compose";
import { paddingAll, fillMaxWidth } from "@expo/ui/jetpack-compose/modifiers";
import { Stack } from "expo-router/stack";
import type { __SEARCH_RESULT__, NativeSearchProps } from "./native-search.types";

export default function __SCREEN_NAME__() {
  const [query, setQuery] = useState("");
  const [selectedFilters, setSelectedFilters] = useState<string[]>([]);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // TODO: replace with real data source
  const filters: string[] = ["__FILTER_1__", "__FILTER_2__", "__FILTER_3__"];
  const results: __SEARCH_RESULT__[] = [];

  const onQueryChange = useCallback((text: string) => {
    setQuery(text);
  }, []);

  const onToggleFilter = useCallback((filter: string) => {
    setSelectedFilters((prev) =>
      prev.includes(filter)
        ? prev.filter((f) => f !== filter)
        : [...prev, filter],
    );
  }, []);

  const onRefresh = useCallback(() => {
    setIsRefreshing(true);
    // TODO: fetch data then setIsRefreshing(false)
  }, []);

  const onSelectResult = useCallback((result: __SEARCH_RESULT__) => {
    // TODO: handle selection
  }, []);

  return (
    <>
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
      <Host style={{ flex: 1 }}>
        <DockedSearchBar onQueryChange={onQueryChange}>
          <DockedSearchBar.Placeholder>
            <Text>__SEARCH_PLACEHOLDER__</Text>
          </DockedSearchBar.Placeholder>
        </DockedSearchBar>

        <FlowRow
          horizontalArrangement={{ spacedBy: 8 }}
          modifiers={[paddingAll(8)]}
        >
          {filters.map((filter) => (
            <FilterChip
              key={filter}
              label={filter}
              selected={selectedFilters.includes(filter)}
              onPress={() => onToggleFilter(filter)}
            />
          ))}
        </FlowRow>

        <PullToRefreshBox isRefreshing={isRefreshing} onRefresh={onRefresh}>
          <LazyColumn contentPadding={{ top: 8, bottom: 8 }}>
            {results.map((result) => (
              <ListItem
                key={result.id}
                headline={result.title}
                {...(result.subtitle !== undefined && {
                  supportingText: result.subtitle,
                })}
              />
            ))}
          </LazyColumn>
        </PullToRefreshBox>
      </Host>
    </>
  );
}
