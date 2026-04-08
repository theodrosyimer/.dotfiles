import { Host, BottomSheet, Group, RNHostView } from "@expo/ui/swift-ui";
import {
  presentationDetents,
  presentationDragIndicator,
} from "@expo/ui/swift-ui/modifiers";
import type { NativeBottomSheetProps } from "./native-bottom-sheet.types";

function __COMPONENT_NAME__({
  isPresented,
  onDismiss,
  children,
  detents,
  showDragHandle,
}: NativeBottomSheetProps) {
  return (
    <Host matchContents>
      <BottomSheet
        isPresented={isPresented}
        onIsPresentedChange={(v) => {
          if (!v) onDismiss();
        }}
      >
        <Group
          modifiers={[
            presentationDetents(detents ?? ["medium", "large"]),
            presentationDragIndicator(
              showDragHandle !== false ? "visible" : "hidden"
            ),
          ]}
        >
          <RNHostView matchContents>{children}</RNHostView>
        </Group>
      </BottomSheet>
    </Host>
  );
}

export { __COMPONENT_NAME__ };
