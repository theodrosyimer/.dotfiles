type ConfirmationDialogProps = {
  title: string;
  message?: string;
  isPresented: boolean;
  onDismiss: () => void;
  onConfirm: () => void;
  destructive?: boolean;
  confirmLabel?: string;
  cancelLabel?: string;
};

export type { ConfirmationDialogProps };
