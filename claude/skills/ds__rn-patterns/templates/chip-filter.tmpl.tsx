import { Text, ScrollView, Pressable } from "react-native";
import { cn } from "tailwind-variants";
import type { ChipFilterProps } from "./chip-filter.types";

function __COMPONENT_NAME__({ tags, selected, onToggle }: ChipFilterProps) {
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerClassName="gap-inline-sm px-component-md"
    >
      {tags.map((tag) => {
        const isSelected = selected.includes(tag);

        return (
          <Pressable
            key={tag}
            onPress={() => onToggle(tag)}
            accessibilityRole="button"
            className={cn(
              isSelected
                ? "bg-action-primary active:bg-action-primary-active rounded-full border-continuous px-component-md py-component-xs min-h-11 items-center justify-center"
                : "bg-surface-raised active:bg-action-ghost-active rounded-full border-continuous border-default px-component-md py-component-xs min-h-11 items-center justify-center",
            )}
          >
            <Text
              className={cn(
                isSelected
                  ? "text-content-on-action text-sm font-medium"
                  : "text-content-primary text-sm",
              )}
            >
              {tag}
            </Text>
          </Pressable>
        );
      })}
    </ScrollView>
  );
}

export { __COMPONENT_NAME__ };
