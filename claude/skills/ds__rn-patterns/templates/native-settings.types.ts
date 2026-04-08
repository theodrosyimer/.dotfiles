type SectionHeader = { _tag: "SectionHeader"; title: string };
type ToggleRow = {
  _tag: "ToggleRow";
  label: string;
  key: string;
  systemImage?: string;
};
type PickerRow = {
  _tag: "PickerRow";
  label: string;
  key: string;
  options: Array<{ label: string; value: string }>;
};
type SliderRow = {
  _tag: "SliderRow";
  label: string;
  key: string;
  min: number;
  max: number;
  step?: number;
};
type NavigationRow = { _tag: "NavigationRow"; label: string; href: string };
type ActionRow = { _tag: "ActionRow"; label: string; destructive?: boolean };

type __SETTINGS_ITEM__ =
  | SectionHeader
  | ToggleRow
  | PickerRow
  | SliderRow
  | NavigationRow
  | ActionRow;

type NativeSettingsProps = {
  items: __SETTINGS_ITEM__[];
  toggles: Record<string, boolean>;
  onToggle: (key: string) => void;
  pickers: Record<string, string>;
  onPickerChange: (key: string, value: string) => void;
  sliders: Record<string, number>;
  onSliderChange: (key: string, value: number) => void;
  onAction: (label: string) => void;
};

export type {
  SectionHeader,
  ToggleRow,
  PickerRow,
  SliderRow,
  NavigationRow,
  ActionRow,
  __SETTINGS_ITEM__,
  NativeSettingsProps,
};
