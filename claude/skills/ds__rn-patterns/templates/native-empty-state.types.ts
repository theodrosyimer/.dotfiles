type NativeEmptyStateProps = {
  /** SF Symbol name (e.g. "tray", "magnifyingglass") */
  icon: string;
  title: string;
  subtitle: string;
  actionLabel?: string;
  onAction?: () => void;
};

export type { NativeEmptyStateProps };
