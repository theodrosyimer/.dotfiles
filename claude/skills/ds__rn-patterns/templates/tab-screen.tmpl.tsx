// Part 1: Tab layout file — app/(tabs)/_layout.tsx
// import { NativeTabs } from 'expo-router'
//
// export default function TabLayout() {
//   return (
//     <NativeTabs>
//       <NativeTabs.Screen
//         name="index"
//         options={{ title: 'Home', tabBarIcon: { sfSymbol: 'house' } }}
//       />
//       <NativeTabs.Screen
//         name="__TAB_NAME__"
//         options={{ title: '__TAB_TITLE__', tabBarIcon: { sfSymbol: 'star' } }}
//       />
//     </NativeTabs>
//   )
// }

// Part 2: Individual tab screen — app/(tabs)/__TAB_NAME__.tsx
import { ScrollView, View, Text } from "react-native";
import { Stack } from "expo-router/stack";

export default function __TAB_NAME__() {
  return (
    <>
      <Stack.Screen options={{ title: "__TAB_TITLE__" }} />
      {/* contentInsetAdjustmentBehavior="automatic" handles safe area for both
          top (native header) and bottom (tab bar) — no SafeAreaView needed.
          Each tab is an independent scroll context. */}
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        contentContainerClassName="px-component-md py-component-md gap-layout-md"
      >
        <View className="gap-layout-sm">
          <Text className="text-content-primary text-2xl font-bold">
            __TAB_TITLE__
          </Text>
          <Text className="text-content-secondary text-base">
            {/* Tab description */}
          </Text>
        </View>

        <View className="bg-surface-raised rounded-xl border-continuous p-component-md gap-layout-sm">
          <Text className="text-content-primary text-lg font-semibold">
            {/* Section heading */}
          </Text>
          <Text className="text-content-secondary text-base">
            {/* Section body */}
          </Text>
        </View>

        <View className="bg-surface-raised rounded-xl border-continuous p-component-md gap-layout-sm">
          <Text className="text-content-primary text-lg font-semibold">
            {/* Another section */}
          </Text>
          <Text className="text-content-secondary text-base">
            {/* Section body */}
          </Text>
        </View>
      </ScrollView>
    </>
  );
}
