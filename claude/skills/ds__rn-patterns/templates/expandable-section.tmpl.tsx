import { useState } from "react";
import { View, Text, Pressable } from "react-native";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import { EaseView } from "react-native-ease/uniwind";
import type { ExpandableSectionProps } from "./expandable-section.types";

const Image = withUniwind(ExpoImage);

function __COMPONENT_NAME__({
  label,
  children,
  isExpanded,
  onToggle,
  defaultExpanded,
}: ExpandableSectionProps) {
  const [internalExpanded, setInternalExpanded] = useState(
    defaultExpanded ?? false
  );
  const expanded = isExpanded ?? internalExpanded;

  const handleToggle = (val: boolean) => {
    onToggle?.(val);
    if (isExpanded === undefined) setInternalExpanded(val);
  };

  return (
    <View className="overflow-hidden">
      <Pressable
        onPress={() => handleToggle(!expanded)}
        accessibilityRole="button"
        className="flex-row items-center justify-between px-component-md py-component-sm min-h-11 bg-surface-raised"
      >
        <Text className="text-content-primary text-base font-medium">
          {label}
        </Text>
        <EaseView
          animate={{ rotate: expanded ? 90 : 0 }}
          transition={{ type: "timing", duration: 200, easing: "easeOut" }}
        >
          <Image
            source="sf:chevron.right"
            className="w-4 h-4"
            tintColorClassName="accent-content-tertiary"
          />
        </EaseView>
      </Pressable>

      <EaseView
        animate={{ opacity: expanded ? 1 : 0 }}
        initialAnimate={{ opacity: 0 }}
        transition={{ type: "timing", duration: 200, easing: "easeOut" }}
      >
        {!!expanded && (
          <View className="px-component-md py-component-sm">{children}</View>
        )}
      </EaseView>
    </View>
  );
}

export { __COMPONENT_NAME__ };
