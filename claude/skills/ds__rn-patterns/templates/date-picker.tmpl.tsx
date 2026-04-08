import { Text, Pressable } from "react-native";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import type { DatePickerProps } from "./date-picker.types";

const Image = withUniwind(ExpoImage);

// For full native date picker on all platforms, use @react-native-community/datetimepicker

function __COMPONENT_NAME__({
  value,
  onChange,
  mode,
}: DatePickerProps) {
  const formatted =
    mode === "time"
      ? value.toLocaleTimeString()
      : mode === "datetime"
        ? `${value.toLocaleDateString()} ${value.toLocaleTimeString()}`
        : value.toLocaleDateString();

  return (
    <Pressable
      accessibilityRole="button"
      className="bg-surface-raised border-default rounded-lg border-continuous px-component-md py-component-sm min-h-11 flex-row items-center justify-between"
    >
      <Text className="text-content-primary text-base">{formatted}</Text>
      <Image
        source="sf:calendar"
        className="w-5 h-5"
        tintColorClassName="accent-content-tertiary"
      />
    </Pressable>
  );
}

export { __COMPONENT_NAME__ };
