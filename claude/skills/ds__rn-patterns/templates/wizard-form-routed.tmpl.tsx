// --- store/__STORE_NAME__.ts ---

import { create } from "zustand";

type __FORM_DATA__ = {
  name?: string;
  email?: string;
  bio?: string;
};

type __STORE_TYPE__ = {
  data: __FORM_DATA__;
  update: (field: keyof __FORM_DATA__, value: string) => void;
  reset: () => void;
};

const initialData: __FORM_DATA__ = {};

export const __USE_STORE__ = create<__STORE_TYPE__>((set) => ({
  data: initialData,
  update: (field, value) =>
    set((s) => ({ data: { ...s.data, [field]: value } })),
  reset: () => set({ data: initialData }),
}));

// --- app/__WIZARD_ROUTE__/_layout.tsx ---

import { Stack } from "expo-router/stack";

export default function __WIZARD_LAYOUT__() {
  return (
    <Stack>
      <Stack.Screen name="step-1" options={{ title: "__STEP_1_TITLE__" }} />
      <Stack.Screen name="step-2" options={{ title: "__STEP_2_TITLE__" }} />
      <Stack.Screen name="confirm" options={{ title: "__CONFIRM_TITLE__" }} />
    </Stack>
  );
}

// --- app/__WIZARD_ROUTE__/step-1.tsx ---

import { View, Text, TextInput, Pressable } from "react-native";
import { KeyboardAwareScrollView } from "react-native-keyboard-controller";
import { useRouter } from "expo-router";
import { __USE_STORE__ } from "@/store/__STORE_NAME__";

export default function Step1() {
  const router = useRouter();
  const { data, update } = __USE_STORE__();

  return (
    <KeyboardAwareScrollView
      bottomOffset={20}
      keyboardShouldPersistTaps="handled"
      contentContainerClassName="px-component-md py-component-md gap-layout-md"
    >
      <View className="gap-inline-xs">
        <Text className="text-content-primary text-sm font-medium">Name</Text>
        <TextInput
          value={data.name ?? ""}
          onChangeText={(v) => update("name", v)}
          placeholder="Your name"
          placeholderTextColorClassName="accent-content-tertiary"
          cursorColorClassName="accent-action-primary"
          selectionColorClassName="accent-action-primary"
          autoComplete="name"
          className="bg-surface-raised border border-default focus:border-focus rounded-xl border-continuous px-component-md py-component-sm text-content-primary text-base"
        />
      </View>

      <View className="gap-inline-xs">
        <Text className="text-content-primary text-sm font-medium">Email</Text>
        <TextInput
          value={data.email ?? ""}
          onChangeText={(v) => update("email", v)}
          placeholder="you@example.com"
          placeholderTextColorClassName="accent-content-tertiary"
          cursorColorClassName="accent-action-primary"
          selectionColorClassName="accent-action-primary"
          keyboardType="email-address"
          autoCapitalize="none"
          autoComplete="email"
          className="bg-surface-raised border border-default focus:border-focus rounded-xl border-continuous px-component-md py-component-sm text-content-primary text-base"
        />
      </View>

      <View className="pb-safe-or-4">
        <Pressable
          onPress={() => router.push("/__WIZARD_ROUTE__/step-2")}
          accessibilityRole="button"
          className="bg-action-primary active:bg-action-primary-active border-continuous rounded-xl min-h-11 items-center justify-center py-component-sm"
        >
          <Text className="text-content-on-action text-base font-semibold">
            Next
          </Text>
        </Pressable>
      </View>
    </KeyboardAwareScrollView>
  );
}

// --- app/__WIZARD_ROUTE__/step-2.tsx ---

import { View, Text, TextInput, Pressable } from "react-native";
import { KeyboardAwareScrollView } from "react-native-keyboard-controller";
import { useRouter } from "expo-router";
import { __USE_STORE__ } from "@/store/__STORE_NAME__";

export default function Step2() {
  const router = useRouter();
  const { data, update } = __USE_STORE__();

  return (
    <KeyboardAwareScrollView
      bottomOffset={20}
      keyboardShouldPersistTaps="handled"
      contentContainerClassName="px-component-md py-component-md gap-layout-md"
    >
      <View className="gap-inline-xs">
        <Text className="text-content-primary text-sm font-medium">Bio</Text>
        <TextInput
          value={data.bio ?? ""}
          onChangeText={(v) => update("bio", v)}
          placeholder="Tell us about yourself..."
          placeholderTextColorClassName="accent-content-tertiary"
          cursorColorClassName="accent-action-primary"
          selectionColorClassName="accent-action-primary"
          multiline
          textAlignVertical="top"
          className="bg-surface-raised border border-default focus:border-focus rounded-xl border-continuous px-component-md py-component-sm text-content-primary text-base min-h-30"
        />
      </View>

      <View className="pb-safe-or-4">
        <Pressable
          onPress={() => router.push("/__WIZARD_ROUTE__/confirm")}
          accessibilityRole="button"
          className="bg-action-primary active:bg-action-primary-active border-continuous rounded-xl min-h-11 items-center justify-center py-component-sm"
        >
          <Text className="text-content-on-action text-base font-semibold">
            Next
          </Text>
        </Pressable>
      </View>
    </KeyboardAwareScrollView>
  );
}

// --- app/__WIZARD_ROUTE__/confirm.tsx ---

import { View, Text, ScrollView, Pressable } from "react-native";
import { useRouter } from "expo-router";
import { __USE_STORE__ } from "@/store/__STORE_NAME__";

export default function Confirm() {
  const router = useRouter();
  const { data, reset } = __USE_STORE__();

  const handleSubmit = () => {
    // TODO: submit data
    reset();
    router.dismissAll();
  };

  return (
    <ScrollView
      contentInsetAdjustmentBehavior="automatic"
      contentContainerClassName="px-component-md py-component-md gap-layout-md"
    >
      <Text className="text-content-primary text-2xl font-bold">
        Review
      </Text>

      <View className="bg-surface-raised rounded-xl border-continuous border border-default p-component-md gap-layout-sm">
        <View className="gap-inline-xs">
          <Text className="text-content-secondary text-sm">Name</Text>
          <Text className="text-content-primary text-base">
            {data.name || "--"}
          </Text>
        </View>
        <View className="border-t border-subtle" />
        <View className="gap-inline-xs">
          <Text className="text-content-secondary text-sm">Email</Text>
          <Text className="text-content-primary text-base">
            {data.email || "--"}
          </Text>
        </View>
        <View className="border-t border-subtle" />
        <View className="gap-inline-xs">
          <Text className="text-content-secondary text-sm">Bio</Text>
          <Text className="text-content-primary text-base">
            {data.bio || "--"}
          </Text>
        </View>
      </View>

      <View className="pb-safe-or-4">
        <Pressable
          onPress={handleSubmit}
          accessibilityRole="button"
          className="bg-action-primary active:bg-action-primary-active border-continuous rounded-xl min-h-11 items-center justify-center py-component-sm"
        >
          <Text className="text-content-on-action text-base font-semibold">
            Submit
          </Text>
        </Pressable>
      </View>
    </ScrollView>
  );
}
