import { useState } from "react";
import { View, Text } from "react-native";
import { Host, ColorPicker } from "@expo/ui/swift-ui";
import { Stack } from "expo-router/stack";

export default function __SCREEN_NAME__() {
  const [color, setColor] = useState<string | null>("#__DEFAULT_COLOR__");

  return (
    <View className="flex-1 bg-surface-default">
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />

      <View className="p-component-md">
        <Host matchContents>
          <ColorPicker
            label="__PICKER_LABEL__"
            selection={color}
            onSelectionChange={setColor}
            supportsOpacity={__SUPPORTS_OPACITY__}
          />
        </Host>

        <View className="flex-row items-center gap-inline-md mt-component-md">
          <View
            className="w-16 h-16 rounded-lg border-continuous border-default"
            style={{ backgroundColor: color ?? "#000000" }}
          />
          <Text className="text-content-secondary text-sm font-mono mt-inline-xs">
            {color ?? "#000000"}
          </Text>
        </View>
      </View>
    </View>
  );
}
