import { View, Text as RNText, Pressable } from "react-native";
import {
  Host,
  Form,
  Section,
  Toggle,
  Picker,
  Slider,
  Text,
  RNHostView,
} from "@expo/ui/swift-ui";
import {
  scrollContentBackground,
  pickerStyle,
  tag,
} from "@expo/ui/swift-ui/modifiers";
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

function groupBySections(list: __SETTINGS_ITEM__[]) {
  const groups: Array<{ title: string; rows: Exclude<__SETTINGS_ITEM__, SectionHeader>[] }> = [];
  let current: (typeof groups)[number] | undefined;

  for (const item of list) {
    if (item._tag === "SectionHeader") {
      current = { title: item.title, rows: [] };
      groups.push(current);
    } else if (!!current) {
      current.rows.push(item);
    }
  }

  return groups;
}

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

  const groups = groupBySections(items);

  const renderRow = (item: Exclude<__SETTINGS_ITEM__, SectionHeader>) => {
    switch (item._tag) {
      case "ToggleRow":
        return (
          <Toggle
            key={item.key}
            isOn={!!toggles[item.key]}
            onIsOnChange={() => handleToggle(item.key)}
            label={item.label}
            {...(item.systemImage !== undefined && {
              systemImage: item.systemImage,
            })}
          />
        );

      case "PickerRow":
        return (
          <Picker
            key={item.key}
            selection={pickers[item.key] ?? item.options[0]?.value ?? ""}
            onSelectionChange={(value) =>
              handlePickerChange(item.key, value)
            }
            label={item.label}
            modifiers={[pickerStyle("menu")]}
          >
            {item.options.map((opt) => (
              <Text key={opt.value} modifiers={[tag(opt.value)]}>
                {opt.label}
              </Text>
            ))}
          </Picker>
        );

      case "SliderRow":
        return (
          <Slider
            key={item.key}
            value={sliders[item.key] ?? item.min}
            onValueChange={(value) =>
              handleSliderChange(item.key, value)
            }
            min={item.min}
            max={item.max}
            {...(item.step !== undefined && { step: item.step })}
            label={item.label}
          />
        );

      case "NavigationRow":
        return (
          <RNHostView key={item.href} matchContents>
            <Link href={item.href as never} asChild>
              <Pressable className="bg-surface-raised px-component-md py-component-sm min-h-11 flex-row items-center justify-between">
                <RNText className="text-content-primary text-base">
                  {item.label}
                </RNText>
                <RNText className="text-content-tertiary text-base">
                  {"\u203A"}
                </RNText>
              </Pressable>
            </Link>
          </RNHostView>
        );

      case "ActionRow":
        return (
          <RNHostView key={item.label} matchContents>
            <Pressable
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
          </RNHostView>
        );
    }
  };

  return (
    <>
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
      <Host style={{ flex: 1 }}>
        <Form modifiers={[scrollContentBackground("hidden")]}>
          {groups.map((group) => (
            <Section key={group.title} title={group.title}>
              {group.rows.map(renderRow)}
            </Section>
          ))}
        </Form>
      </Host>
    </>
  );
}
