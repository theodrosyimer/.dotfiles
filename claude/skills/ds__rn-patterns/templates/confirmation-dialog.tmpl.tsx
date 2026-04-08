import { Modal, View, Text, Pressable } from "react-native";
import { EaseView } from "react-native-ease/uniwind";
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
    <Modal
      visible={isPresented}
      transparent
      animationType="none"
      onRequestClose={onDismiss}
    >
      <Pressable
        onPress={onDismiss}
        className="flex-1 items-center justify-center"
        style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
      >
        <EaseView
          initialAnimate={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ type: "timing", duration: 200, easing: "easeOut" }}
          className="bg-surface-raised rounded-xl border-continuous mx-component-lg p-component-lg shadow-elevation-high"
          style={{ maxWidth: 320 }}
        >
          <Pressable>
            <Text className="text-content-primary text-lg font-semibold mb-inline-xs">
              {title}
            </Text>

            {!!message && (
              <Text className="text-content-secondary text-base mb-component-md">
                {message}
              </Text>
            )}

            <View className="flex-row justify-end gap-inline-sm">
              <Pressable
                onPress={onDismiss}
                accessibilityRole="button"
                className="px-component-md py-component-sm min-h-11 items-center justify-center rounded-lg border-continuous"
              >
                <Text className="text-content-primary text-base font-medium">
                  {cancelLabel}
                </Text>
              </Pressable>

              <Pressable
                onPress={onConfirm}
                accessibilityRole="button"
                className={
                  !!destructive
                    ? "bg-status-error-bg active:bg-status-error-bg-hover px-component-md py-component-sm min-h-11 items-center justify-center rounded-lg border-continuous"
                    : "bg-action-primary active:bg-action-primary-active px-component-md py-component-sm min-h-11 items-center justify-center rounded-lg border-continuous"
                }
              >
                <Text
                  className={
                    !!destructive
                      ? "text-content-on-action text-base font-medium"
                      : "text-content-on-action text-base font-medium"
                  }
                >
                  {confirmLabel}
                </Text>
              </Pressable>
            </View>
          </Pressable>
        </EaseView>
      </Pressable>
    </Modal>
  );
}

export { __COMPONENT_NAME__ };
