import { Host, FlowRow, FilterChip } from "@expo/ui/jetpack-compose";
import { paddingAll } from "@expo/ui/jetpack-compose/modifiers";
import type { ChipFilterProps } from "./chip-filter.types";

function __COMPONENT_NAME__({ tags, selected, onToggle }: ChipFilterProps) {
  return (
    <Host matchContents>
      <FlowRow
        horizontalArrangement={{ spacedBy: 8 }}
        verticalArrangement={{ spacedBy: 8 }}
        modifiers={[paddingAll(16)]}
      >
        {tags.map((tag) => (
          <FilterChip
            key={tag}
            label={tag}
            selected={selected.includes(tag)}
            onPress={() => onToggle(tag)}
          />
        ))}
      </FlowRow>
    </Host>
  );
}

export { __COMPONENT_NAME__ };
