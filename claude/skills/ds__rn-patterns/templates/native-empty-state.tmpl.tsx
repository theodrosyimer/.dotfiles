import { Text, Pressable } from "react-native";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import { EaseView } from "react-native-ease/uniwind";

import type { NativeEmptyStateProps } from "./native-empty-state.types";

const Image = withUniwind(ExpoImage);

function __COMPONENT_NAME__({
  icon,
  title,
  subtitle,
  actionLabel,
  onAction,
}: NativeEmptyStateProps) {
  return (
    <EaseView
      initialAnimate={{ opacity: 0, translateY: 20 }}
      animate={{ opacity: 1, translateY: 0 }}
      transition={{ type: "timing", duration: 300, easing: "easeOut" }}
      className="flex-1 items-center justify-center px-component-lg"
    >
      <Image
        source={`sf:${icon}`}
        className="w-16 h-16 mb-layout-sm"
        tintColorClassName="accent-content-tertiary"
      />
      <Text className="text-content-primary text-lg font-semibold mb-inline-xs text-center">
        {title}
      </Text>
      <Text className="text-content-secondary text-base text-center mb-layout-md">
        {subtitle}
      </Text>
      {!!actionLabel && !!onAction && (
        <Pressable
          onPress={onAction}
          accessibilityRole="button"
          className="bg-action-primary active:bg-action-primary-active active:opacity-90 rounded-lg border-continuous px-component-lg py-component-sm min-h-11 items-center justify-center"
        >
          <Text className="text-content-on-action text-base font-semibold">
            {actionLabel}
          </Text>
        </Pressable>
      )}
    </EaseView>
  );
}

export { __COMPONENT_NAME__ };
