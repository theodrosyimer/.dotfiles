import { View, Text, RefreshControl } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { GestureDetector, Gesture } from "react-native-gesture-handler";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  interpolate,
  runOnJS,
} from "react-native-reanimated";
import { EaseView } from "react-native-ease/uniwind";
import * as Haptics from "expo-haptics";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import { Stack } from "expo-router/stack";
import { memo, useState, useCallback } from "react";

const Image = withUniwind(ExpoImage);

type __ITEM_TYPE__ = {
  id: string;
  title: string;
  subtitle: string;
  imageUrl: string;
};

const DELETE_THRESHOLD = -100;
const OFFSCREEN_X = -300;

function SwipeableRow({
  onDelete,
  children,
}: {
  onDelete: () => void;
  children: React.ReactNode;
}) {
  const translateX = useSharedValue(0);

  const pan = Gesture.Pan()
    .activeOffsetX([-10, 10])
    .onUpdate((e) => {
      translateX.set(Math.min(0, e.translationX));
    })
    .onEnd((e) => {
      if (e.translationX < DELETE_THRESHOLD) {
        translateX.set(withTiming(OFFSCREEN_X));
        runOnJS(onDelete)();
      } else {
        translateX.set(withTiming(0));
      }
    });

  const rowStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.get() }],
  }));

  const deleteStyle = useAnimatedStyle(() => ({
    opacity: interpolate(
      translateX.get(),
      [0, DELETE_THRESHOLD],
      [0, 1],
      "clamp",
    ),
  }));

  return (
    <View className="overflow-hidden">
      <Animated.View
        style={deleteStyle}
        className="absolute inset-y-0 right-0 w-24 bg-status-error-bg items-center justify-center rounded-xl border-continuous"
      >
        <Text className="text-status-error-text text-sm font-semibold">
          Delete
        </Text>
      </Animated.View>
      <GestureDetector gesture={pan}>
        <Animated.View style={rowStyle}>{children}</Animated.View>
      </GestureDetector>
    </View>
  );
}

const AnimatedItem = memo(function AnimatedItem({
  id,
  title,
  subtitle,
  imageUrl,
  index,
  onDelete,
}: {
  id: string;
  title: string;
  subtitle: string;
  imageUrl: string;
  index: number;
  onDelete: (id: string) => void;
}) {
  const handleDelete = useCallback(() => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    onDelete(id);
  }, [id, onDelete]);

  return (
    <EaseView
      animate={{ opacity: 1, translateY: 0 }}
      initial={{ opacity: 0, translateY: 20 }}
      transition={{
        type: "spring",
        damping: 15,
        stiffness: 120,
        delay: index * 50,
      }}
    >
      <SwipeableRow onDelete={handleDelete}>
        <View className="bg-surface-raised rounded-xl border-continuous p-component-md flex-row gap-inline-md items-center min-h-11">
          <Image
            source={{ uri: imageUrl }}
            recyclingKey={id}
            contentFit="cover"
            className="w-12 h-12 rounded-lg border-continuous"
          />
          <View className="flex-1 gap-inline-xs">
            <Text className="text-content-primary text-base font-medium">
              {title}
            </Text>
            <Text className="text-content-secondary text-sm">{subtitle}</Text>
          </View>
        </View>
      </SwipeableRow>
    </EaseView>
  );
});

export default function __SCREEN_NAME__() {
  const [items, setItems] = useState<__ITEM_TYPE__[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  const onRefresh = useCallback(() => {
    setRefreshing(true);
    // TODO: fetch data
    setRefreshing(false);
  }, []);

  const handleDelete = useCallback((id: string) => {
    setItems((prev) => prev.filter((item) => item.id !== id));
  }, []);

  const renderItem = useCallback(
    ({ item, index }: { item: __ITEM_TYPE__; index: number }) => {
      return (
        <AnimatedItem
          id={item.id}
          title={item.title}
          subtitle={item.subtitle}
          imageUrl={item.imageUrl}
          index={index}
          onDelete={handleDelete}
        />
      );
    },
    [handleDelete],
  );

  return (
    <>
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
      <FlashList
        data={items}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        contentInsetAdjustmentBehavior="automatic"
        contentContainerClassName="px-component-md py-component-md"
        ItemSeparatorComponent={() => <View className="h-2" />}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
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
