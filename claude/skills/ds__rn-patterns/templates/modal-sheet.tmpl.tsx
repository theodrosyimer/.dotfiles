import { View, Text, Pressable } from "react-native";
import { Stack } from "expo-router/stack";

export default function __SCREEN_NAME__() {
  const handleCancel = () => {
    // TODO: dismiss modal
  };

  const handleConfirm = () => {
    // TODO: confirm action
  };

  return (
    <>
      <Stack.Screen
        options={{
          presentation: "formSheet",
          sheetGrabberVisible: true,
          sheetAllowedDetents: [0.5, 1.0],
          contentStyle: { backgroundColor: "transparent" },
        }}
      />
      <View className="flex-1 bg-surface-default pb-safe px-component-md justify-between">
        <View className="gap-layout-sm pt-component-md">
          <Text className="text-content-primary text-2xl font-bold">
            __MODAL_TITLE__
          </Text>
          <Text className="text-content-secondary text-base leading-relaxed">
            __MODAL_DESCRIPTION__
          </Text>
        </View>

        <View className="gap-inline-sm">
          <Pressable
            onPress={handleConfirm}
            accessibilityRole="button"
            className="bg-action-primary active:bg-action-primary-active border-continuous rounded-xl min-h-11 items-center justify-center py-component-sm"
          >
            <Text className="text-content-on-action text-base font-semibold">
              Confirm
            </Text>
          </Pressable>

          <Pressable
            onPress={handleCancel}
            accessibilityRole="button"
            className="bg-action-secondary active:bg-action-secondary-active border-continuous rounded-xl min-h-11 items-center justify-center py-component-sm"
          >
            <Text className="text-content-primary text-base font-semibold">
              Cancel
            </Text>
          </Pressable>
        </View>
      </View>
    </>
  );
}
