type ContextMenuAction = {
  label: string;
  systemImage?: string;
  role?: "destructive" | "cancel";
  onPress: () => void;
};

type ContextMenuProps = {
  actions: ContextMenuAction[];
  children: React.ReactNode;
  preview?: React.ReactNode;
};

export type { ContextMenuAction, ContextMenuProps };
