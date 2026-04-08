import { useState, useCallback, useEffect, useMemo } from "react";
import {
  View,
  Text,
  ScrollView,
  Pressable,
  ActivityIndicator,
  RefreshControl,
} from "react-native";
import { FlashList } from "@shopify/flash-list";
import { Stack } from "expo-router/stack";
import { useNavigation } from "expo-router";
import { cn } from "tailwind-variants";
import type { __SEARCH_RESULT__ } from "./native-search.types";

function useSearch(options: { placeholder?: string } = {}) {
  const [search, setSearch] = useState("");
  const navigation = useNavigation();

  useEffect(() => {
    navigation.setOptions({
      headerShown: true,
      headerSearchBarOptions: {
        placeholder: options.placeholder ?? "Search...",
        hideWhenScrolling: true,
        onChangeText: (e: { nativeEvent: { text: string } }) => {
          setSearch(e.nativeEvent.text);
        },
        onCancelButtonPress: () => {
          setSearch("");
        },
      },
    });
  }, [navigation, options.placeholder]);

  return search;
}

export default function __SCREEN_NAME__() {
  const search = useSearch({ placeholder: "__SEARCH_PLACEHOLDER__" });
  const [selectedFilters, setSelectedFilters] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // TODO: replace with real data source
  const filters: string[] = ["__FILTER_1__", "__FILTER_2__", "__FILTER_3__"];
  const allResults: __SEARCH_RESULT__[] = [];

  const filtered = useMemo(
    () =>
      allResults.filter((item) => {
        const q = search.toLowerCase();
        const matchesQuery =
          item.title.toLowerCase().includes(q) ||
          (!!item.subtitle && item.subtitle.toLowerCase().includes(q));
        const matchesFilters =
          selectedFilters.length === 0 || selectedFilters.length > 0;
        return matchesQuery && matchesFilters;
      }),
    [search, allResults, selectedFilters],
  );

  const onToggleFilter = useCallback((filter: string) => {
    setSelectedFilters((prev) =>
      prev.includes(filter)
        ? prev.filter((f) => f !== filter)
        : [...prev, filter],
    );
  }, []);

  const onSelectResult = useCallback((item: __SEARCH_RESULT__) => {
    // TODO: handle selection
  }, []);

  const onRefresh = useCallback(() => {
    setIsRefreshing(true);
    // TODO: fetch data then setIsRefreshing(false)
  }, []);

  const renderItem = useCallback(
    ({ item }: { item: __SEARCH_RESULT__ }) => (
      <Pressable
        onPress={() => onSelectResult(item)}
        accessibilityRole="button"
        className="bg-surface-raised px-component-md py-component-sm min-h-11"
      >
        <Text className="text-content-primary text-base">{item.title}</Text>
        {!!item.subtitle && (
          <Text className="text-content-secondary text-sm">
            {item.subtitle}
          </Text>
        )}
      </Pressable>
    ),
    [onSelectResult],
  );

  // --- Idle: no query ---
  if (!search) {
    return (
      <View className="flex-1 bg-surface-default items-center justify-center">
        <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
        <Text className="text-content-tertiary text-base">
          Search for __SEARCH_SUBJECT__
        </Text>
      </View>
    );
  }

  // --- Loading ---
  if (isLoading) {
    return (
      <View className="flex-1 bg-surface-default items-center justify-center">
        <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
        <ActivityIndicator colorClassName="accent-content-secondary" />
      </View>
    );
  }

  // --- Results ---
  return (
    <View className="flex-1 bg-surface-default">
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerClassName="gap-inline-sm px-component-md py-component-sm"
      >
        {filters.map((filter) => {
          const isSelected = selectedFilters.includes(filter);

          return (
            <Pressable
              key={filter}
              onPress={() => onToggleFilter(filter)}
              accessibilityRole="button"
              className={cn(
                isSelected
                  ? "bg-action-primary active:bg-action-primary-active rounded-full border-continuous px-component-md py-component-xs min-h-11 items-center justify-center"
                  : "bg-surface-raised active:bg-action-ghost-active rounded-full border-continuous border-default px-component-md py-component-xs min-h-11 items-center justify-center",
              )}
            >
              <Text
                className={cn(
                  isSelected
                    ? "text-content-on-action text-sm font-medium"
                    : "text-content-primary text-sm",
                )}
              >
                {filter}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>

      {search && filtered.length === 0 ? (
        <View className="flex-1 items-center justify-center px-component-lg">
          <Text className="text-content-secondary text-base">
            No results for "{search}"
          </Text>
        </View>
      ) : (
        <FlashList
          data={filtered}
          renderItem={renderItem}
          keyExtractor={(item) => item.id}
          contentInsetAdjustmentBehavior="automatic"
          contentContainerClassName="py-component-sm"
          refreshControl={
            <RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />
          }
        />
      )}
    </View>
  );
}
