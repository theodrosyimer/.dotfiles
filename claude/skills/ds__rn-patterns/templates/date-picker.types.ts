type DatePickerMode = "date" | "time" | "datetime";

type DatePickerProps = {
  value: Date;
  onChange: (date: Date) => void;
  mode?: DatePickerMode;
  min?: Date;
  max?: Date;
  label?: string;
};

export type { DatePickerMode, DatePickerProps };
