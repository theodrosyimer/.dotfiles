import { View, Text, Pressable, Switch } from "react-native";
import { Link } from "expo-router";
import { FlashList } from "@shopify/flash-list";
import { Stack } from "expo-router/stack";
import { useState, useCallback } from "react";

type SectionHeader = { _tag: "SectionHeader"; title: string };
type NavigationRow = { _tag: "NavigationRow"; label: string; href: string };
type ToggleRow = { _tag: "ToggleRow"; label: string; key: string };
type ActionRow = { _tag: "ActionRow"; label: string; destructive?: boolean };

type SettingsItem = SectionHeader | NavigationRow | ToggleRow | ActionRow;

const items: SettingsItem[] = [
  { _tag: "SectionHeader", title: "Account" },
  { _tag: "NavigationRow", label: "Profile", href: "/settings/profile" },
  {
    _tag: "NavigationRow",
    label: "Notifications",
    href: "/settings/notifications",
  },
  { _tag: "SectionHeader", title: "Preferences" },
  { _tag: "ToggleRow", label: "Dark Mode", key: "darkMode" },
  { _tag: "ToggleRow", label: "Push Notifications", key: "pushNotifications" },
  { _tag: "SectionHeader", title: "Support" },
  { _tag: "NavigationRow", label: "Help Center", href: "/settings/help" },
  { _tag: "NavigationRow", label: "Privacy Policy", href: "/settings/privacy" },
  { _tag: "SectionHeader", title: "Danger Zone" },
  { _tag: "ActionRow", label: "Sign Out", destructive: true },
];

export default function __SCREEN_NAME__() {
  const [toggles, setToggles] = useState<Record<string, boolean>>({});

  const handleToggle = useCallback((key: string) => {
    setToggles((prev) => ({ ...prev, [key]: !prev[key] }));
  }, []);

  const handleAction = useCallback((label: string) => {
    // TODO: handle action
  }, []);

  const renderItem = useCallback(
    ({ item }: { item: SettingsItem }) => {
      switch (item._tag) {
        case "SectionHeader":
          return (
            <View className="px-component-md pt-component-lg pb-component-xs">
              <Text className="text-content-secondary text-sm font-bold uppercase tracking-wide">
                {item.title}
              </Text>
            </View>
          );

        case "NavigationRow":
          return (
            <Link href={item.href as never} asChild>
              <Pressable className="bg-surface-raised px-component-md py-component-sm min-h-11 flex-row items-center justify-between">
                <Text className="text-content-primary text-base">
                  {item.label}
                </Text>
                <Text className="text-content-tertiary text-base">{">"}</Text>
              </Pressable>
            </Link>
          );

        case "ToggleRow":
          return (
            <View className="bg-surface-raised px-component-md py-component-sm min-h-11 flex-row items-center justify-between">
              <Text className="text-content-primary text-base">
                {item.label}
              </Text>
              <Switch
                value={!!toggles[item.key]}
                onValueChange={() => handleToggle(item.key)}
                thumbColorClassName="accent-white"
                trackColorOnClassName="accent-action-primary"
                trackColorOffClassName="accent-surface-sunken"
              />
            </View>
          );

        case "ActionRow":
          return (
            <Pressable
              onPress={() => handleAction(item.label)}
              accessibilityRole="button"
              className="bg-surface-raised active:bg-action-ghost-active px-component-md py-component-sm min-h-11 flex-row items-center"
            >
              <Text
                className={
                  !!item.destructive
                    ? "text-status-error-text text-base font-medium"
                    : "text-content-primary text-base"
                }
              >
                {item.label}
              </Text>
            </Pressable>
          );
      }
    },
    [toggles, handleToggle, handleAction],
  );

  const getItemType = useCallback((item: SettingsItem) => item._tag, []);

  return (
    <>
      <Stack.Screen options={{ title: "Settings" }} />
      <FlashList
        data={items}
        renderItem={renderItem}
        getItemType={getItemType}
        keyExtractor={(item, index) =>
          item._tag === "SectionHeader"
            ? `section-${item.title}`
            : `row-${index}`
        }
        contentInsetAdjustmentBehavior="automatic"
        contentContainerClassName="py-component-sm"
      />
    </>
  );
}
