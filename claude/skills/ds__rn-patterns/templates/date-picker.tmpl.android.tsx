import { Host, DateTimePicker } from "@expo/ui/jetpack-compose";
import type { DatePickerProps } from "./date-picker.types";

function __COMPONENT_NAME__({
  value,
  onChange,
  mode,
  min,
  max,
}: DatePickerProps) {
  return (
    <Host matchContents>
      <DateTimePicker
        onDateSelected={onChange}
        initialDate={value.toISOString()}
        displayedComponents={
          mode === "time"
            ? "hourAndMinute"
            : mode === "datetime"
              ? "dateAndTime"
              : "date"
        }
        variant="picker"
        {...(!!min || !!max
          ? {
              selectableDates: {
                start: min ?? new Date(0),
                end: max ?? new Date(2099, 11, 31),
              },
            }
          : {})}
      />
    </Host>
  );
}

export { __COMPONENT_NAME__ };
