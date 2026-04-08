import { useRef } from "react";
import { Host, ModalBottomSheet } from "@expo/ui/jetpack-compose";
import type { ModalBottomSheetRef } from "@expo/ui/jetpack-compose";
import type { NativeBottomSheetProps } from "./native-bottom-sheet.types";

function __COMPONENT_NAME__({
  isPresented,
  onDismiss,
  children,
  showDragHandle,
}: NativeBottomSheetProps) {
  const sheetRef = useRef<ModalBottomSheetRef>(null);

  return (
    <>
      {!!isPresented && (
        <Host matchContents>
          <ModalBottomSheet
            ref={sheetRef}
            onDismissRequest={onDismiss}
            showDragHandle={showDragHandle !== false}
          >
            {children}
          </ModalBottomSheet>
        </Host>
      )}
    </>
  );
}

export { __COMPONENT_NAME__ };
