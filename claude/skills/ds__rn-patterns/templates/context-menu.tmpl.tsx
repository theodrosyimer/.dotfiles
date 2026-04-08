import { useState } from "react";
import { View, Text, Pressable, Modal } from "react-native";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import { EaseView } from "react-native-ease/uniwind";

import type { ContextMenuProps } from "./context-menu.types";

const Image = withUniwind(ExpoImage);

// For navigation elements, prefer Link.Menu from expo-router instead

function __COMPONENT_NAME__({
  actions,
  children,
}: ContextMenuProps) {
  const [menuVisible, setMenuVisible] = useState(false);

  return (
    <View>
      <Pressable onLongPress={() => setMenuVisible(true)}>
        {children}
      </Pressable>

      <Modal
        visible={menuVisible}
        transparent
        onRequestClose={() => setMenuVisible(false)}
      >
        <Pressable
          onPress={() => setMenuVisible(false)}
          style={{ flex: 1 }}
        >
          <EaseView
            initialAnimate={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ type: "timing", duration: 150, easing: "easeOut" }}
            className="bg-surface-raised rounded-xl border-continuous shadow-elevation-high py-component-xs"
            style={{ position: "absolute", top: "40%", left: "10%", right: "10%" }}
          >
            {actions.map((action) => (
              <Pressable
                key={action.label}
                onPress={() => {
                  action.onPress();
                  setMenuVisible(false);
                }}
                accessibilityRole="button"
                className="px-component-md py-component-sm min-h-11 flex-row items-center gap-inline-sm"
              >
                {!!action.systemImage && (
                  <Image
                    source={`sf:${action.systemImage}`}
                    className="w-5 h-5"
                    tintColorClassName={
                      action.role === "destructive"
                        ? "accent-status-error-icon"
                        : "accent-content-primary"
                    }
                  />
                )}
                <Text
                  className={
                    action.role === "destructive"
                      ? "text-status-error-text text-base"
                      : "text-content-primary text-base"
                  }
                >
                  {action.label}
                </Text>
              </Pressable>
            ))}
          </EaseView>
        </Pressable>
      </Modal>
    </View>
  );
}

export { __COMPONENT_NAME__ };
