import { View, Text, ActivityIndicator } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import { Link } from "expo-router";
import { Stack } from "expo-router/stack";
import { memo, useState, useCallback, useEffect, useMemo } from "react";
import { useNavigation } from "expo-router";

const Image = withUniwind(ExpoImage);

type __ITEM_TYPE__ = {
  id: string;
  title: string;
  subtitle: string;
  imageUrl: string;
};

// --- useSearch hook (from building-native-ui search.md) ---
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

// --- Memoized item — primitive props only ---
const SearchResultItem = memo(function SearchResultItem({
  id,
  title,
  subtitle,
  imageUrl,
}: {
  id: string;
  title: string;
  subtitle: string;
  imageUrl: string;
}) {
  return (
    <Link href={`/__ROUTE_PREFIX__/${id}`} asChild>
      <Link.Trigger>
        <View className="flex-row gap-inline-sm px-component-md py-component-sm items-center min-h-11">
          <Image
            source={{ uri: imageUrl }}
            className="w-10 h-10 rounded-lg border-continuous"
            contentFit="cover"
            recyclingKey={imageUrl}
            transition={100}
          />
          <View className="flex-1">
            <Text className="text-content-primary text-base">{title}</Text>
            <Text className="text-content-secondary text-sm">{subtitle}</Text>
          </View>
        </View>
      </Link.Trigger>
      <Link.Preview />
    </Link>
  );
});

export default function __SCREEN_NAME__() {
  const search = useSearch({ placeholder: "__SEARCH_PLACEHOLDER__" });
  const [isLoading, setIsLoading] = useState(false);
  // Replace with real data source
  const allItems: __ITEM_TYPE__[] = [];

  const filtered = useMemo(
    () =>
      allItems.filter((item) => {
        const q = search.toLowerCase();
        return (
          item.title.toLowerCase().includes(q) ||
          item.subtitle.toLowerCase().includes(q)
        );
      }),
    [search, allItems],
  );

  const renderItem = useCallback(
    ({ item }: { item: __ITEM_TYPE__ }) => (
      <SearchResultItem
        id={item.id}
        title={item.title}
        subtitle={item.subtitle}
        imageUrl={item.imageUrl}
      />
    ),
    [],
  );

  // --- Render states ---
  // No query yet
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

  // Loading
  if (isLoading) {
    return (
      <View className="flex-1 bg-surface-default items-center justify-center">
        <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
        <ActivityIndicator colorClassName="accent-content-secondary" />
      </View>
    );
  }

  // Empty results
  if (search && filtered.length === 0) {
    return (
      <View className="flex-1 bg-surface-default items-center justify-center px-component-lg">
        <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
        <Text className="text-content-secondary text-base">
          No results for "{search}"
        </Text>
      </View>
    );
  }

  // Results
  return (
    <View className="flex-1 bg-surface-default">
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
      <FlashList
        data={filtered}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        contentInsetAdjustmentBehavior="automatic"
        contentContainerClassName="py-component-sm"
      />
    </View>
  );
}
