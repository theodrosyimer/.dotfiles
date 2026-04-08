import { View, Text, Pressable, RefreshControl } from 'react-native'
import { FlashList } from '@shopify/flash-list'
import { withUniwind } from 'uniwind'
import { Image as ExpoImage } from 'expo-image'
import { Link } from 'expo-router'
import { Stack } from 'expo-router/stack'
import { memo, useState, useCallback } from 'react'

const Image = withUniwind(ExpoImage)

type __ITEM_TYPE__ = {
  id: string
  title: string
  imageUrl: string
}

const __ITEM_COMPONENT__ = memo(function __ITEM_COMPONENT__({
  id,
  title,
  imageUrl,
}: {
  id: string
  title: string
  imageUrl: string
}) {
  return (
    <Link href={`__ITEM_HREF__/${id}`} asChild>
      <Pressable className="bg-surface-raised rounded-xl border-continuous p-component-md flex-row gap-inline-md items-center">
        <Image
          source={{ uri: imageUrl }}
          recyclingKey={id}
          className="h-12 w-12 rounded-lg border-continuous"
        />
        <Text className="text-content-primary text-base font-medium flex-1">
          {title}
        </Text>
      </Pressable>
    </Link>
  )
})

export default function __SCREEN_NAME__() {
  const [refreshing, setRefreshing] = useState(false)
  const [items] = useState<__ITEM_TYPE__[]>([])

  const onRefresh = useCallback(() => {
    setRefreshing(true)
    // TODO: fetch data
    setRefreshing(false)
  }, [])

  const renderItem = useCallback(({ item }: { item: __ITEM_TYPE__ }) => {
    return (
      <__ITEM_COMPONENT__
        id={item.id}
        title={item.title}
        imageUrl={item.imageUrl}
      />
    )
  }, [])

  return (
    <>
      <Stack.Screen options={{ title: '__SCREEN_TITLE__' }} />
      <FlashList
        data={items}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        contentInsetAdjustmentBehavior="automatic"
        contentContainerClassName="px-component-md py-component-md"
        ItemSeparatorComponent={() => <View className="h-2" />}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        ListEmptyComponent={
          <View className="items-center justify-center py-component-md">
            <Text className="text-content-tertiary text-base">
              No items yet
            </Text>
          </View>
        }
      />
    </>
  )
}
