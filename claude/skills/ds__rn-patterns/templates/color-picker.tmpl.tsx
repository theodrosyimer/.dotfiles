import { View, Text, ScrollView, Pressable, TextInput } from "react-native";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";

const Image = withUniwind(ExpoImage);

const __PALETTE__ = [
  "#FF6347",
  "#4169E1",
  "#32CD32",
  "#FFD700",
  "#8A2BE2",
  "#FF69B4",
  "#00CED1",
  "#FF8C00",
  "#2E8B57",
  "#DC143C",
  "#4682B4",
  "#9ACD32",
];

type ColorPickerProps = {
  value: string | null;
  onChange: (color: string) => void;
};

function __COMPONENT_NAME__({ value, onChange }: ColorPickerProps) {
  return (
    <ScrollView contentInsetAdjustmentBehavior="automatic">
      <View className="p-component-md">
        <View className="flex-row flex-wrap gap-inline-sm p-component-md">
          {__PALETTE__.map((hex) => (
            <Pressable
              key={hex}
              onPress={() => onChange(hex)}
              accessibilityRole="button"
              className="w-12 h-12 rounded-lg border-continuous border-default items-center justify-center"
              style={{ backgroundColor: hex }}
            >
              {!!value && value === hex && (
                <Image
                  source="sf:checkmark"
                  className="w-5 h-5"
                  tintColorClassName="accent-content-on-action"
                />
              )}
            </Pressable>
          ))}
        </View>

        <View className="flex-row items-center gap-inline-md mt-component-md px-component-md">
          <View
            className="w-16 h-16 rounded-lg border-continuous border-default"
            style={{ backgroundColor: value ?? "#000000" }}
          />
          <TextInput
            value={value ?? ""}
            onChangeText={onChange}
            placeholder="#000000"
            className="flex-1 bg-surface-raised rounded-lg border-continuous border-default px-component-md py-component-sm min-h-11 text-content-primary text-sm font-mono"
            autoCapitalize="none"
            autoCorrect={false}
          />
        </View>
      </View>
    </ScrollView>
  );
}

export { __COMPONENT_NAME__ };
