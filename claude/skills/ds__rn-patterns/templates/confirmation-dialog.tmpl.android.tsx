import { Host, AlertDialog, Button, Text } from "@expo/ui/jetpack-compose";
import type { ConfirmationDialogProps } from "./confirmation-dialog.types";

function __COMPONENT_NAME__({
  title,
  message,
  isPresented,
  onDismiss,
  onConfirm,
  confirmLabel = "Confirm",
  cancelLabel = "Cancel",
}: ConfirmationDialogProps) {
  return (
    <>
      {!!isPresented && (
        <Host matchContents>
          <AlertDialog onDismissRequest={onDismiss}>
            <AlertDialog.Title>
              <Text>{title}</Text>
            </AlertDialog.Title>

            {!!message && (
              <AlertDialog.Text>
                <Text>{message}</Text>
              </AlertDialog.Text>
            )}

            <AlertDialog.ConfirmButton>
              <Button onClick={onConfirm}>
                <Text>{confirmLabel}</Text>
              </Button>
            </AlertDialog.ConfirmButton>

            <AlertDialog.DismissButton>
              <Button onClick={onDismiss}>
                <Text>{cancelLabel}</Text>
              </Button>
            </AlertDialog.DismissButton>
          </AlertDialog>
        </Host>
      )}
    </>
  );
}

export { __COMPONENT_NAME__ };
