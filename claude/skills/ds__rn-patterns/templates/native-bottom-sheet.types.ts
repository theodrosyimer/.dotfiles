type NativeBottomSheetProps = {
  isPresented: boolean;
  onDismiss: () => void;
  children: React.ReactNode;
  /** iOS detents: "medium" | "large" or fraction/fixed values */
  detents?: Array<"medium" | "large">;
  showDragHandle?: boolean;
};

export type { NativeBottomSheetProps };
