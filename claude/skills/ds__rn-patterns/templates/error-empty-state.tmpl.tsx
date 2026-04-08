import { Text, Pressable } from "react-native";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import { SymbolView } from "expo-symbols";
import { PlatformColor } from "react-native";
import { EaseView } from "react-native-ease/uniwind";

const Image = withUniwind(ExpoImage);

// --- Empty State ---
function EmptyState({
  icon,
  title,
  subtitle,
  actionLabel,
  onAction,
}: {
  icon: string;
  title: string;
  subtitle: string;
  actionLabel?: string;
  onAction?: () => void;
}) {
  return (
    <EaseView
      initialAnimate={{ opacity: 0, translateY: 20 }}
      animate={{ opacity: 1, translateY: 0 }}
      transition={{ type: "timing", duration: 300, easing: "easeOut" }}
      className="flex-1 items-center justify-center px-component-lg"
    >
      <Image
        source={`sf:${icon}`}
        className="w-16 h-16 mb-layout-sm"
        tintColorClassName="accent-content-tertiary"
      />
      <Text className="text-content-primary text-lg font-semibold mb-inline-xs text-center">
        {title}
      </Text>
      <Text className="text-content-secondary text-base text-center mb-layout-md">
        {subtitle}
      </Text>
      {!!actionLabel && !!onAction && (
        <Pressable
          onPress={onAction}
          accessibilityRole="button"
          className="bg-action-primary active:bg-action-primary-active active:opacity-90 rounded-lg border-continuous px-component-lg py-component-sm min-h-11 items-center justify-center"
        >
          <Text className="text-content-on-action text-base font-semibold">
            {actionLabel}
          </Text>
        </Pressable>
      )}
    </EaseView>
  );
}

// --- Error State ---
function ErrorState({
  message,
  onRetry,
}: {
  message: string;
  onRetry: () => void;
}) {
  return (
    <EaseView
      initialAnimate={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ type: "timing", duration: 200, easing: "easeOut" }}
      className="flex-1 items-center justify-center px-component-lg bg-surface-default"
    >
      {process.env.EXPO_OS === "ios" ? (
        <SymbolView
          name="exclamationmark.triangle"
          tintColor={PlatformColor("systemRed")}
          size={48}
          weight="medium"
          animationSpec={{ effect: { type: "bounce", direction: "up" } }}
          style={{ marginBottom: 16 }}
        />
      ) : (
        <Image
          source="sf:exclamationmark.triangle"
          className="w-12 h-12 mb-layout-sm"
          tintColorClassName="accent-status-error-icon"
        />
      )}
      <Text className="text-content-primary text-lg font-semibold mb-inline-xs text-center">
        Something went wrong
      </Text>
      <Text className="text-content-secondary text-base text-center mb-layout-md">
        {message}
      </Text>
      <Pressable
        onPress={onRetry}
        accessibilityRole="button"
        className="bg-action-primary active:bg-action-primary-active active:opacity-90 rounded-lg border-continuous px-component-lg py-component-sm min-h-11 items-center justify-center"
      >
        <Text className="text-content-on-action text-base font-semibold">
          Try Again
        </Text>
      </Pressable>
    </EaseView>
  );
}

// --- Usage Examples ---

// Empty state — first-use
// <EmptyState
//   icon="__EMPTY_ICON__"
//   title="__EMPTY_TITLE__"
//   subtitle="__EMPTY_SUBTITLE__"
//   actionLabel="__EMPTY_ACTION__"
//   onAction={__ON_EMPTY_ACTION__}
// />

// Error state — network failure
// <ErrorState
//   message="__ERROR_MESSAGE__"
//   onRetry={__ON_RETRY__}
// />

export { EmptyState, ErrorState };
