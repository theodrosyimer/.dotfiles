import { View, Text, TextInput, Pressable } from "react-native";
import {
  KeyboardAwareScrollView,
  KeyboardToolbar,
} from "react-native-keyboard-controller";
import { Stack } from "expo-router/stack";
import { useState } from "react";

export default function __SCREEN_NAME__() {
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [bio, setBio] = useState("");

  const handleSubmit = () => {
    // TODO: validate and submit form
  };

  return (
    <>
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
      <KeyboardAwareScrollView
        bottomOffset={20}
        keyboardShouldPersistTaps="handled"
        contentContainerClassName="px-component-md py-component-md gap-layout-md"
      >
        <View className="gap-layout-sm">
          <Text className="text-content-primary text-2xl font-bold">
            __SCREEN_TITLE__
          </Text>
        </View>

        <View className="gap-inline-xs">
          <Text className="text-content-primary text-sm font-medium">
            First Name
          </Text>
          <TextInput
            value={firstName}
            onChangeText={setFirstName}
            placeholder="First name"
            placeholderTextColorClassName="accent-content-tertiary"
            cursorColorClassName="accent-action-primary"
            selectionColorClassName="accent-action-primary"
            autoComplete="given-name"
            className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
          />
        </View>

        <View className="gap-inline-xs">
          <Text className="text-content-primary text-sm font-medium">
            Last Name
          </Text>
          <TextInput
            value={lastName}
            onChangeText={setLastName}
            placeholder="Last name"
            placeholderTextColorClassName="accent-content-tertiary"
            cursorColorClassName="accent-action-primary"
            selectionColorClassName="accent-action-primary"
            autoComplete="family-name"
            className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
          />
        </View>

        <View className="gap-inline-xs">
          <Text className="text-content-primary text-sm font-medium">
            Email
          </Text>
          <TextInput
            value={email}
            onChangeText={setEmail}
            placeholder="you@example.com"
            placeholderTextColorClassName="accent-content-tertiary"
            cursorColorClassName="accent-action-primary"
            selectionColorClassName="accent-action-primary"
            keyboardType="email-address"
            autoCapitalize="none"
            autoComplete="email"
            className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
          />
        </View>

        <View className="gap-inline-xs">
          <Text className="text-content-primary text-sm font-medium">
            Phone
          </Text>
          <TextInput
            value={phone}
            onChangeText={setPhone}
            placeholder="+1 (555) 000-0000"
            placeholderTextColorClassName="accent-content-tertiary"
            cursorColorClassName="accent-action-primary"
            selectionColorClassName="accent-action-primary"
            keyboardType="phone-pad"
            autoComplete="tel"
            className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base"
          />
        </View>

        <View className="gap-inline-xs">
          <Text className="text-content-primary text-sm font-medium">Bio</Text>
          <TextInput
            value={bio}
            onChangeText={setBio}
            placeholder="Tell us about yourself..."
            placeholderTextColorClassName="accent-content-tertiary"
            cursorColorClassName="accent-action-primary"
            selectionColorClassName="accent-action-primary"
            multiline
            textAlignVertical="top"
            className="bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-sm py-component-sm text-content-primary text-base min-h-30"
          />
        </View>

        <Pressable
          onPress={handleSubmit}
          accessibilityRole="button"
          className="bg-action-primary active:bg-action-primary-active border-continuous rounded-xl min-h-11 items-center justify-center py-component-sm"
        >
          <Text className="text-content-on-action text-base font-semibold">
            Submit
          </Text>
        </Pressable>
      </KeyboardAwareScrollView>

      {/* Prev/Next/Done toolbar above the keyboard for field navigation */}
      <KeyboardToolbar />
    </>
  );
}
