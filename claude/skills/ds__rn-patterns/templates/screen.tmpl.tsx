import { ScrollView, View, Text } from "react-native";
import { Stack } from "expo-router/stack";

export default function __SCREEN_NAME__() {
  return (
    <>
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        contentContainerClassName="px-component-md py-component-md gap-layout-md"
      >
        <View className="gap-layout-sm">
          <Text className="text-content-primary text-2xl font-bold">
            __SCREEN_TITLE__
          </Text>
          <Text className="text-content-secondary text-base">
            {/* Body text */}
          </Text>
        </View>

        <View className="bg-surface-raised rounded-xl border-continuous p-component-md gap-layout-sm">
          <Text className="text-content-primary text-lg font-semibold">
            {/* Section heading */}
          </Text>
          <Text className="text-content-secondary text-base">
            {/* Section body */}
          </Text>
        </View>
      </ScrollView>
    </>
  );
}
