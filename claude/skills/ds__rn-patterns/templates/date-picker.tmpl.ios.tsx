import { Host, DatePicker } from "@expo/ui/swift-ui";
import { datePickerStyle } from "@expo/ui/swift-ui/modifiers";
import type { DatePickerProps } from "./date-picker.types";

function __COMPONENT_NAME__({
  value,
  onChange,
  mode,
  min,
  max,
  label,
}: DatePickerProps) {
  return (
    <Host matchContents>
      <DatePicker
        selection={value}
        onDateChange={onChange}
        displayedComponents={
          mode === "time"
            ? ["hourAndMinute"]
            : mode === "datetime"
              ? ["date", "hourAndMinute"]
              : ["date"]
        }
        {...(!!min || !!max
          ? { range: { start: min, end: max } }
          : {})}
        {...(label !== undefined && { title: label })}
        modifiers={[datePickerStyle("compact")]}
      />
    </Host>
  );
}

export { __COMPONENT_NAME__ };
