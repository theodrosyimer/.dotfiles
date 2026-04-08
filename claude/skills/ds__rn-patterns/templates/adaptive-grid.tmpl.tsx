import { View, Text, Pressable, useWindowDimensions } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import { Link } from "expo-router";
import { Stack } from "expo-router/stack";
import { memo, useState } from "react";

const Image = withUniwind(ExpoImage);

type __GRID_ITEM_TYPE__ = {
  id: string;
  title: string;
  imageUrl: string;
};

const GridCard = memo(function GridCard({
  id,
  title,
  imageUrl,
}: {
  id: string;
  title: string;
  imageUrl: string;
}) {
  return (
    <Link href={`/__SCREEN_NAME__/${id}`} asChild>
      <Pressable className="flex-1 bg-surface-raised rounded-xl border-continuous border border-default shadow-elevation-low">
        <Image
          source={{ uri: imageUrl }}
          recyclingKey={id}
          contentFit="cover"
          className="w-full aspect-square rounded-t-xl"
        />
        <View className="p-component-sm">
          <Text
            className="text-content-primary text-sm font-medium"
            numberOfLines={2}
          >
            {title}
          </Text>
        </View>
      </Pressable>
    </Link>
  );
});

export default function __SCREEN_NAME__() {
  const { width } = useWindowDimensions();
  const [items] = useState<__GRID_ITEM_TYPE__[]>([]);

  // Dynamic columns based on screen width
  const cols = width > 1024 ? 4 : width > 768 ? 3 : 2;

  return (
    <>
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
      <FlashList
        data={items}
        numColumns={cols}
        renderItem={({ item }) => (
          <GridCard id={item.id} title={item.title} imageUrl={item.imageUrl} />
        )}
        keyExtractor={(item) => item.id}
        contentInsetAdjustmentBehavior="automatic"
        contentContainerClassName="px-component-sm sm:px-component-md py-component-md"
        ItemSeparatorComponent={() => <View className="h-2" />}
        ListEmptyComponent={
          <View className="items-center justify-center py-component-md">
            <Text className="text-content-tertiary text-base">
              No items yet
            </Text>
          </View>
        }
      />
    </>
  );
}

// Alternative: Uniwind breakpoints (no useWindowDimensions needed)
// <ScrollView
//   contentInsetAdjustmentBehavior="automatic"
//   contentContainerClassName="px-component-sm sm:px-component-md py-component-md"
// >
//   <View className="flex-row flex-wrap">
//     <View className="w-full sm:w-1/2 lg:w-1/3 xl:w-1/4 p-component-sm">
//       <GridCard ... />
//     </View>
//   </View>
// </ScrollView>
