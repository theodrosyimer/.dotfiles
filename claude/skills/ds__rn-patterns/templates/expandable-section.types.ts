type ExpandableSectionProps = {
  label: string;
  children: React.ReactNode;
  isExpanded?: boolean;
  onToggle?: (expanded: boolean) => void;
  defaultExpanded?: boolean;
};

export type { ExpandableSectionProps };
