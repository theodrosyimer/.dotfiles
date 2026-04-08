import {
  Host,
  ContentUnavailableView,
  VStack,
  Button,
  Text,
} from "@expo/ui/swift-ui";
import type { NativeEmptyStateProps } from "./native-empty-state.types";

// NOTE: ContentUnavailableView API is unverified — adjust props if needed

// --- Primary: ContentUnavailableView (if available) ---
function __COMPONENT_NAME__({
  icon,
  title,
  subtitle,
  actionLabel,
  onAction,
}: NativeEmptyStateProps) {
  return (
    <Host style={{ flex: 1 }}>
      {/* Prop-based API (most likely): */}
      <ContentUnavailableView
        title={title}
        description={subtitle}
        systemImage={icon}
      >
        {/* If it accepts children instead, move title/description/systemImage as child elements */}
        {!!actionLabel && !!onAction && (
          <Button label={actionLabel} onPress={onAction} />
        )}
      </ContentUnavailableView>
    </Host>
  );
}

// --- Fallback: Custom SwiftUI composition (if ContentUnavailableView is unavailable) ---
// import { Host, VStack, Button, Text, Image } from "@expo/ui/swift-ui";
//
// function __COMPONENT_NAME__({
//   icon,
//   title,
//   subtitle,
//   actionLabel,
//   onAction,
// }: NativeEmptyStateProps) {
//   return (
//     <Host style={{ flex: 1 }}>
//       <VStack>
//         <Image systemName={icon} />
//         <Text>{title}</Text>
//         <Text>{subtitle}</Text>
//         {!!actionLabel && !!onAction && (
//           <Button label={actionLabel} onPress={onAction} />
//         )}
//       </VStack>
//     </Host>
//   );
// }

export { __COMPONENT_NAME__ };
