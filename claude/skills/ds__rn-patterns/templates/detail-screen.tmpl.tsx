import { ScrollView, View, Text, Pressable } from "react-native";
import { Stack, Link } from "expo-router";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import { useSafeAreaInsets } from "react-native-safe-area-context";

const Image = withUniwind(ExpoImage);

type Related__DETAIL_TYPE__ = {
  id: string;
  title: string;
  href: string;
};

const relatedItems: Related__DETAIL_TYPE__[] = [];

export default function __SCREEN_NAME__() {
  const { bottom } = useSafeAreaInsets();

  return (
    <>
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
      <View className="flex-1 bg-surface-default">
        <ScrollView
          contentInsetAdjustmentBehavior="automatic"
          contentContainerClassName="pb-[120px]"
        >
          {/* Hero image with gradient overlay */}
          <View className="relative">
            <Image
              source={{ uri: "__HERO_IMAGE_URL__" }}
              placeholder={{ blurhash: "LGF5]+Yk^6#M@-5c,1J5@[or[Q6." }}
              contentFit="cover"
              priority="high"
              className="w-full h-72"
            />
            <View
              className="absolute inset-x-0 bottom-0 h-24"
              style={{
                experimental_backgroundImage:
                  "linear-gradient(to top, var(--color-surface-default), transparent)",
              }}
            />
          </View>

          {/* Content */}
          <View className="px-component-md gap-layout-md -mt-6">
            <View className="gap-layout-sm">
              <Text className="text-content-primary text-3xl font-bold">
                __SCREEN_TITLE__
              </Text>
              <Text className="text-content-secondary text-base leading-relaxed">
                {/* Description */}
              </Text>
            </View>

            {/* Metadata row */}
            <View className="flex-row gap-inline-md items-center">
              <Text className="text-content-tertiary text-sm">
                {/* Metadata label */}
              </Text>
              <Text className="text-content-tertiary text-sm">
                {/* Metadata value */}
              </Text>
            </View>

            {/* Related items */}
            {!!relatedItems.length && (
              <View className="gap-layout-sm">
                <Text className="text-content-primary text-lg font-semibold">
                  Related
                </Text>
                {relatedItems.map((item) => (
                  <Link key={item.id} href={item.href as never} asChild>
                    <Pressable className="bg-surface-raised rounded-xl border-continuous p-component-md min-h-[44px] justify-center">
                      <Link.Trigger>
                        <Text className="text-content-primary text-base font-medium">
                          {item.title}
                        </Text>
                      </Link.Trigger>
                      <Link.Preview />
                      <Link.Menu />
                    </Pressable>
                  </Link>
                ))}
              </View>
            )}
          </View>
        </ScrollView>

        {/* Bottom CTA */}
        <View
          className="absolute inset-x-0 bottom-0 bg-surface-default border-t border-default px-component-md pt-component-sm"
          style={{ paddingBottom: bottom }}
        >
          <Pressable
            accessibilityRole="button"
            className="bg-action-primary active:bg-action-primary-active border-continuous rounded-xl min-h-11 items-center justify-center py-component-sm"
          >
            <Text className="text-content-on-action text-base font-semibold">
              {/* CTA label */}
            </Text>
          </Pressable>
        </View>
      </View>
    </>
  );
}
