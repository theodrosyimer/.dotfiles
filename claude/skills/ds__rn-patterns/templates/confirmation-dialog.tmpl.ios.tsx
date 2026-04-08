import { useState } from "react";
import { Host, ConfirmationDialog, Button, Text } from "@expo/ui/swift-ui";
import type { ConfirmationDialogProps } from "./confirmation-dialog.types";

function __COMPONENT_NAME__({
  title,
  message,
  isPresented,
  onDismiss,
  onConfirm,
  destructive,
  confirmLabel = "Confirm",
  cancelLabel = "Cancel",
}: ConfirmationDialogProps) {
  return (
    <Host matchContents>
      <ConfirmationDialog
        title={title}
        isPresented={isPresented}
        onIsPresentedChange={(presented) => {
          if (!presented) {
            onDismiss();
          }
        }}
        titleVisibility="visible"
      >
        <ConfirmationDialog.Trigger>
          <Button
            label="__TRIGGER_LABEL__"
            onPress={() => {
              // Trigger presentation — parent controls isPresented
            }}
          />
        </ConfirmationDialog.Trigger>

        <ConfirmationDialog.Actions>
          {!!destructive ? (
            <Button
              label={confirmLabel}
              role="destructive"
              onPress={onConfirm}
            />
          ) : (
            <Button label={confirmLabel} onPress={onConfirm} />
          )}
          <Button label={cancelLabel} role="cancel" />
        </ConfirmationDialog.Actions>

        {!!message && (
          <ConfirmationDialog.Message>
            <Text>{message}</Text>
          </ConfirmationDialog.Message>
        )}
      </ConfirmationDialog>
    </Host>
  );
}

export { __COMPONENT_NAME__ };
