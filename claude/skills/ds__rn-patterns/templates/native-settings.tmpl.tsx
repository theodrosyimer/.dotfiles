import { View, Text, Pressable, Switch } from "react-native";
import RNSlider from "@react-native-community/slider";
import { Link } from "expo-router";
import { FlashList } from "@shopify/flash-list";
import { Stack } from "expo-router/stack";
import { useState, useCallback } from "react";

import type {
  __SETTINGS_ITEM__,
  SectionHeader,
  ToggleRow,
  PickerRow,
  SliderRow,
  NavigationRow,
  ActionRow,
} from "./native-settings.types";

const items: __SETTINGS_ITEM__[] = [
  { _tag: "SectionHeader", title: "__SECTION_1__" },
  { _tag: "ToggleRow", label: "__TOGGLE_1__", key: "toggle1" },
  {
    _tag: "PickerRow",
    label: "__PICKER_1__",
    key: "picker1",
    options: [
      { label: "Option A", value: "a" },
      { label: "Option B", value: "b" },
      { label: "Option C", value: "c" },
    ],
  },
  { _tag: "SectionHeader", title: "__SECTION_2__" },
  {
    _tag: "SliderRow",
    label: "__SLIDER_1__",
    key: "slider1",
    min: 0,
    max: 100,
    step: 1,
  },
  {
    _tag: "NavigationRow",
    label: "__NAV_1__",
    href: "/__NAV_1_HREF__",
  },
  { _tag: "SectionHeader", title: "__SECTION_3__" },
  { _tag: "ActionRow", label: "Sign Out", destructive: true },
];

export default function __SCREEN_NAME__() {
  const [toggles, setToggles] = useState<Record<string, boolean>>({});
  const [pickers, setPickers] = useState<Record<string, string>>({});
  const [sliders, setSliders] = useState<Record<string, number>>({});

  const handleToggle = useCallback((key: string) => {
    setToggles((prev) => ({ ...prev, [key]: !prev[key] }));
  }, []);

  const handlePickerChange = useCallback((key: string, value: string) => {
    setPickers((prev) => ({ ...prev, [key]: value }));
  }, []);

  const handleSliderChange = useCallback((key: string, value: number) => {
    setSliders((prev) => ({ ...prev, [key]: value }));
  }, []);

  const handleAction = useCallback((label: string) => {
    // TODO: handle action
  }, []);

  const renderItem = useCallback(
    ({ item }: { item: __SETTINGS_ITEM__ }) => {
      switch (item._tag) {
        case "SectionHeader":
          return (
            <View className="px-component-md pt-component-lg pb-component-xs">
              <Text className="text-content-secondary text-sm font-bold uppercase tracking-wide">
                {item.title}
              </Text>
            </View>
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

        case "PickerRow":
          return (
            <Link
              href={`/__PICKER_SCREEN_HREF__?key=${item.key}` as never}
              asChild
            >
              <Pressable className="bg-surface-raised px-component-md py-component-sm min-h-11 flex-row items-center justify-between">
                <Text className="text-content-primary text-base">
                  {item.label}
                </Text>
                <View className="flex-row items-center gap-inline-xs">
                  <Text className="text-content-tertiary text-base">
                    {item.options.find(
                      (opt) =>
                        opt.value ===
                        (pickers[item.key] ?? item.options[0]?.value),
                    )?.label ?? ""}
                  </Text>
                  <Text className="text-content-tertiary text-base">
                    {"\u203A"}
                  </Text>
                </View>
              </Pressable>
            </Link>
          );

        case "SliderRow":
          return (
            <View className="bg-surface-raised px-component-md py-component-sm min-h-11 gap-inline-xs">
              <View className="flex-row items-center justify-between">
                <Text className="text-content-primary text-base">
                  {item.label}
                </Text>
                <Text className="text-content-secondary text-sm">
                  {Math.round(sliders[item.key] ?? item.min)}
                </Text>
              </View>
              <RNSlider
                value={sliders[item.key] ?? item.min}
                minimumValue={item.min}
                maximumValue={item.max}
                {...(item.step !== undefined && { step: item.step })}
                onValueChange={(value) =>
                  handleSliderChange(item.key, value)
                }
                minimumTrackTintColorClassName="accent-action-primary"
                maximumTrackTintColorClassName="accent-surface-sunken"
                thumbTintColorClassName="accent-white"
              />
            </View>
          );

        case "NavigationRow":
          return (
            <Link href={item.href as never} asChild>
              <Pressable className="bg-surface-raised px-component-md py-component-sm min-h-11 flex-row items-center justify-between">
                <Text className="text-content-primary text-base">
                  {item.label}
                </Text>
                <Text className="text-content-tertiary text-base">
                  {"\u203A"}
                </Text>
              </Pressable>
            </Link>
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
    [toggles, pickers, sliders, handleToggle, handlePickerChange, handleSliderChange, handleAction],
  );

  const getItemType = useCallback(
    (item: __SETTINGS_ITEM__) => item._tag,
    [],
  );

  return (
    <>
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
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