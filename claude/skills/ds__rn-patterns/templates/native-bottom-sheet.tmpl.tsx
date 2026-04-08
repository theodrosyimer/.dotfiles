import { Modal, View, Pressable } from "react-native";
import { EaseView } from "react-native-ease/uniwind";
import type { NativeBottomSheetProps } from "./native-bottom-sheet.types";

function __COMPONENT_NAME__({
  isPresented,
  onDismiss,
  children,
  showDragHandle,
}: NativeBottomSheetProps) {
  return (
    <Modal
      visible={isPresented}
      transparent
      animationType="none"
      onRequestClose={onDismiss}
    >
      <Pressable
        onPress={onDismiss}
        style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.5)" }}
      >
        <View style={{ flex: 1 }} />
        <EaseView
          initialAnimate={{ translateY: 300 }}
          animate={{ translateY: 0 }}
          transition={{ type: "spring", damping: 25, stiffness: 300 }}
          className="bg-surface-raised rounded-t-2xl border-continuous pb-safe"
        >
          <Pressable>
            {showDragHandle !== false && (
              <View className="w-9 h-1 rounded-full bg-content-tertiary self-center mt-component-sm mb-component-xs" />
            )}
            <View className="p-component-md">{children}</View>
          </Pressable>
        </EaseView>
      </Pressable>
    </Modal>
  );
}

export { __COMPONENT_NAME__ };
