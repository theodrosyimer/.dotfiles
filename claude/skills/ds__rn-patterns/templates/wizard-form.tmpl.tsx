import { View, Text, TextInput, Pressable } from "react-native";
import { KeyboardAwareScrollView } from "react-native-keyboard-controller";
import { EaseView } from "react-native-ease/uniwind";
import { Stack } from "expo-router/stack";
import { useState, useCallback } from "react";

type __FORM_DATA__ = {
  email?: string;
  name?: string;
  bio?: string;
};

const STEPS = ["__STEP_1_TITLE__", "__STEP_2_TITLE__", "__STEP_3_TITLE__"];

function ProgressDots({ current, total }: { current: number; total: number }) {
  return (
    <View className="flex-row gap-inline-sm items-center justify-center py-component-sm">
      {Array.from({ length: total }, (_, i) => (
        <View
          key={i}
          className={`w-2.5 h-2.5 rounded-full border-continuous ${
            i === current
              ? "bg-action-primary"
              : i < current
                ? "bg-action-primary opacity-50"
                : "bg-surface-sunken"
          }`}
        />
      ))}
    </View>
  );
}

function StepField({
  label,
  value,
  onChangeText,
  placeholder,
  multiline,
}: {
  label: string;
  value: string;
  onChangeText: (text: string) => void;
  placeholder: string;
  multiline?: boolean;
}) {
  return (
    <View className="gap-inline-xs">
      <Text className="text-content-primary text-sm font-medium">{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColorClassName="accent-content-tertiary"
        cursorColorClassName="accent-action-primary"
        selectionColorClassName="accent-action-primary"
        multiline={multiline}
        {...(!!multiline && { textAlignVertical: "top" as const })}
        className={`bg-surface-raised border border-default focus:border-focus rounded-lg border-continuous px-component-md py-component-sm text-content-primary text-base ${
          !!multiline && "min-h-30"
        }`}
      />
    </View>
  );
}

export default function __SCREEN_NAME__() {
  const [step, setStep] = useState(0);
  const [data, setData] = useState<__FORM_DATA__>({});

  const update = useCallback(
    (field: keyof __FORM_DATA__, value: string) =>
      setData((prev) => ({ ...prev, [field]: value })),
    [],
  );

  const handleSubmit = () => {
    // TODO: submit form data
  };

  return (
    <>
      <Stack.Screen options={{ title: STEPS[step] }} />
      <ProgressDots current={step} total={STEPS.length} />

      <EaseView
        key={step}
        initialAnimate={{ opacity: 0, translateX: 20 }}
        animate={{ opacity: 1, translateX: 0 }}
        transition={{ type: "timing", duration: 250, easing: "easeOut" }}
        className="flex-1"
      >
        <KeyboardAwareScrollView
          bottomOffset={20}
          keyboardShouldPersistTaps="handled"
          contentContainerClassName="px-component-md py-component-md gap-layout-md"
        >
          {step === 0 && (
            <StepField
              label="Email"
              value={data.email ?? ""}
              onChangeText={(v) => update("email", v)}
              placeholder="you@example.com"
            />
          )}

          {step === 1 && (
            <>
              <StepField
                label="Name"
                value={data.name ?? ""}
                onChangeText={(v) => update("name", v)}
                placeholder="Your name"
              />
              <StepField
                label="Bio"
                value={data.bio ?? ""}
                onChangeText={(v) => update("bio", v)}
                placeholder="Tell us about yourself..."
                multiline
              />
            </>
          )}

          {step === 2 && (
            <View className="gap-layout-md">
              <View className="gap-inline-xs">
                <Text className="text-content-secondary text-sm">Email</Text>
                <Text className="text-content-primary text-base">
                  {data.email ?? "—"}
                </Text>
              </View>
              <View className="gap-inline-xs">
                <Text className="text-content-secondary text-sm">Name</Text>
                <Text className="text-content-primary text-base">
                  {data.name ?? "—"}
                </Text>
              </View>
              <View className="gap-inline-xs">
                <Text className="text-content-secondary text-sm">Bio</Text>
                <Text className="text-content-primary text-base">
                  {data.bio ?? "—"}
                </Text>
              </View>
            </View>
          )}
        </KeyboardAwareScrollView>
      </EaseView>

      <View className="flex-row gap-inline-sm px-component-md pb-safe-or-4 pt-component-sm border-t border-subtle bg-surface-default">
        {step > 0 && (
          <Pressable
            onPress={() => setStep((s) => s - 1)}
            accessibilityRole="button"
            className="bg-action-secondary active:bg-action-secondary-active rounded-lg border-continuous flex-1 min-h-11 items-center justify-center"
          >
            <Text className="text-content-primary text-base font-semibold">
              Back
            </Text>
          </Pressable>
        )}
        <Pressable
          onPress={step < STEPS.length - 1 ? () => setStep((s) => s + 1) : handleSubmit}
          accessibilityRole="button"
          className="bg-action-primary active:bg-action-primary-active active:opacity-90 rounded-lg border-continuous flex-1 min-h-11 items-center justify-center"
        >
          <Text className="text-content-on-action text-base font-semibold">
            {step < STEPS.length - 1 ? "Next" : "Submit"}
          </Text>
        </Pressable>
      </View>
    </>
  );
}
