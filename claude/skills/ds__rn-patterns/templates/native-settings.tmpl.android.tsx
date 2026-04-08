import { ScrollView, View, Text as RNText, Pressable } from "react-native";
import { Host, Switch, Slider } from "@expo/ui/jetpack-compose";
import { fillMaxWidth } from "@expo/ui/jetpack-compose/modifiers";
import { Link, Stack } from "expo-router";
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

  const renderItem = (item: __SETTINGS_ITEM__, index: number) => {
    switch (item._tag) {
      case "SectionHeader":
        return (
          <View
            key={`section-${item.title}`}
            className="px-component-md pt-component-lg pb-component-xs"
          >
            <RNText className="text-content-secondary text-sm font-bold uppercase tracking-wide">
              {item.title}
            </RNText>
          </View>
        );

      case "ToggleRow":
        return (
          <View
            key={`toggle-${item.key}`}
            className="bg-surface-raised px-component-md py-component-sm min-h-11 flex-row items-center justify-between"
          >
            <RNText className="text-content-primary text-base flex-1">
              {item.label}
            </RNText>
            <Host matchContents>
              <Switch
                value={!!toggles[item.key]}
                onCheckedChange={() => handleToggle(item.key)}
              />
            </Host>
          </View>
        );

      case "PickerRow":
        return (
          <Link
            key={`picker-${item.key}`}
            href={`/__PICKER_SCREEN_HREF__?key=${item.key}` as never}
            asChild
          >
            <Pressable className="bg-surface-raised px-component-md py-component-sm min-h-11 flex-row items-center justify-between">
              <RNText className="text-content-primary text-base">
                {item.label}
              </RNText>
              <RNText className="text-content-tertiary text-base">
                {item.options.find(
                  (opt) =>
                    opt.value ===
                    (pickers[item.key] ?? item.options[0]?.value),
                )?.label ?? ""}
              </RNText>
            </Pressable>
          </Link>
        );

      case "SliderRow":
        return (
          <View
            key={`slider-${item.key}`}
            className="bg-surface-raised px-component-md py-component-sm min-h-11 gap-inline-xs"
          >
            <View className="flex-row items-center justify-between">
              <RNText className="text-content-primary text-base">
                {item.label}
              </RNText>
              <RNText className="text-content-secondary text-sm">
                {Math.round(sliders[item.key] ?? item.min)}
              </RNText>
            </View>
            <Host matchContents>
              <Slider
                value={sliders[item.key] ?? item.min}
                onValueChange={(value) =>
                  handleSliderChange(item.key, value)
                }
                min={item.min}
                max={item.max}
                {...(item.step !== undefined && {
                  steps: Math.round((item.max - item.min) / item.step) - 1,
                })}
                modifiers={[fillMaxWidth()]}
              />
            </Host>
          </View>
        );

      case "NavigationRow":
        return (
          <Link key={`nav-${item.href}`} href={item.href as never} asChild>
            <Pressable className="bg-surface-raised px-component-md py-component-sm min-h-11 flex-row items-center justify-between">
              <RNText className="text-content-primary text-base">
                {item.label}
              </RNText>
              <RNText className="text-content-tertiary text-base">
                {"\u203A"}
              </RNText>
            </Pressable>
          </Link>
        );

      case "ActionRow":
        return (
          <Pressable
            key={`action-${item.label}`}
            onPress={() => handleAction(item.label)}
            accessibilityRole="button"
            className="bg-surface-raised active:bg-action-ghost-active px-component-md py-component-sm min-h-11 flex-row items-center"
          >
            <RNText
              className={
                !!item.destructive
                  ? "text-status-error-text text-base font-medium"
                  : "text-content-primary text-base"
              }
            >
              {item.label}
            </RNText>
          </Pressable>
        );
    }
  };

  return (
    <>
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
      <ScrollView
        className="flex-1 bg-surface-default"
        contentContainerClassName="py-component-sm"
      >
        {items.map((item, index) => renderItem(item, index))}
      </ScrollView>
    </>
  );
}
