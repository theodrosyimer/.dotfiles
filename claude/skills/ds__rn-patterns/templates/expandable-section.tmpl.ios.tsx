import { useState } from "react";
import { Host, DisclosureGroup } from "@expo/ui/swift-ui";
import type { ExpandableSectionProps } from "./expandable-section.types";

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
    <Host matchContents>
      <DisclosureGroup
        label={label}
        isExpanded={expanded}
        onIsExpandedChange={handleToggle}
      >
        {children}
      </DisclosureGroup>
    </Host>
  );
}

export { __COMPONENT_NAME__ };
