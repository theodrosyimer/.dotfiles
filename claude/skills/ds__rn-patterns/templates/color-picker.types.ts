type ColorPickerProps = {
  label?: string;
  /** Hex color string: #RRGGBB or #RRGGBBAA */
  value: string | null;
  onChange: (color: string) => void;
  supportsOpacity?: boolean;
};

export type { ColorPickerProps };
