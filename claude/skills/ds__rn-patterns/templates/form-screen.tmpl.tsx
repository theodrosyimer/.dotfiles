import { View, Text, TextInput, Pressable } from 'react-native'
import { KeyboardAwareScrollView } from 'react-native-keyboard-controller'
import { Stack } from 'expo-router/stack'
import { useState } from 'react'
import { button } from '@/ui/variants/button'

export default function __SCREEN_NAME__() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({})

  const handleSubmit = () => {
    const nextErrors: { email?: string; password?: string } = {}

    if (!email) {
      nextErrors.email = 'Email is required'
    }
    if (!password) {
      nextErrors.password = 'Password is required'
    }

    if (Object.keys(nextErrors).length > 0) {
      setErrors(nextErrors)
      return
    }

    setErrors({})
    // TODO: submit form
  }

  return (
    <>
      <Stack.Screen options={{ title: '__SCREEN_TITLE__' }} />
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
            Email
          </Text>
          <TextInput
            value={email}
            onChangeText={setEmail}
            placeholder="you@example.com"
            placeholderTextColorClassName="accent-content-tertiary"
            keyboardType="email-address"
            autoCapitalize="none"
            autoComplete="email"
            className={`bg-surface-raised border border-default focus:border-focus rounded-xl border-continuous px-component-md py-component-sm text-content-primary text-base ${
              !!errors.email && 'border-status-error-border'
            }`}
          />
          {!!errors.email && (
            <Text className="text-status-error-text text-sm">
              {errors.email}
            </Text>
          )}
        </View>

        <View className="gap-inline-xs">
          <Text className="text-content-primary text-sm font-medium">
            Password
          </Text>
          <TextInput
            value={password}
            onChangeText={setPassword}
            placeholder="Enter password"
            placeholderTextColorClassName="accent-content-tertiary"
            secureTextEntry
            autoComplete="password"
            className={`bg-surface-raised border border-default focus:border-focus rounded-xl border-continuous px-component-md py-component-sm text-content-primary text-base ${
              !!errors.password && 'border-status-error-border'
            }`}
          />
          {!!errors.password && (
            <Text className="text-status-error-text text-sm">
              {errors.password}
            </Text>
          )}
        </View>

        <Pressable
          onPress={handleSubmit}
          accessibilityRole="button"
          className={button({ intent: 'primary', size: 'md' }) + ' active:opacity-90 border-continuous'}
        >
          <Text className="text-content-on-action text-base font-semibold text-center">
            Submit
          </Text>
        </Pressable>
      </KeyboardAwareScrollView>
    </>
  )
}
