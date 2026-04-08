import { View, Text, TextInput, Pressable } from "react-native";
import {
  KeyboardChatScrollView,
  KeyboardStickyView,
} from "react-native-keyboard-controller";
import { FlashList } from "@shopify/flash-list";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import * as Haptics from "expo-haptics";
import { Stack } from "expo-router/stack";
import { memo, useState, useCallback } from "react";

const Image = withUniwind(ExpoImage);

type __MESSAGE_TYPE__ = {
  id: string;
  text: string;
  senderName: string;
  senderAvatar?: string;
  isMe: boolean;
  timestamp: number;
};

function Avatar({ uri, name }: { uri?: string; name: string }) {
  return !!uri ? (
    <Image
      source={{ uri }}
      contentFit="cover"
      className="w-8 h-8 rounded-full border-continuous"
    />
  ) : (
    <View className="w-8 h-8 bg-surface-overlay rounded-full items-center justify-center">
      <Text className="text-content-secondary text-xs font-semibold">
        {name.substring(0, 2).toUpperCase()}
      </Text>
    </View>
  );
}

const MessageBubble = memo(function MessageBubble({
  text,
  senderName,
  senderAvatar,
  isMe,
}: {
  text: string;
  senderName: string;
  senderAvatar?: string;
  isMe: boolean;
}) {
  return (
    <View
      className={`flex-row gap-inline-sm px-component-md py-component-sm ${
        isMe ? "flex-row-reverse" : ""
      }`}
    >
      {!isMe && <Avatar uri={senderAvatar} name={senderName} />}
      <View
        className={`rounded-xl border-continuous px-component-md py-component-sm max-w-[75%] ${
          isMe ? "bg-action-primary" : "bg-surface-raised"
        }`}
      >
        {!isMe && (
          <Text className="text-content-secondary text-xs font-medium mb-1">
            {senderName}
          </Text>
        )}
        <Text
          className={
            isMe
              ? "text-content-on-action text-base"
              : "text-content-primary text-base"
          }
        >
          {text}
        </Text>
      </View>
    </View>
  );
});

function ChatInput({ onSend }: { onSend: (text: string) => void }) {
  const [text, setText] = useState("");

  const handleSend = useCallback(() => {
    const trimmed = text.trim();
    if (!trimmed) return;
    if (process.env.EXPO_OS === "ios") {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
    onSend(trimmed);
    setText("");
  }, [text, onSend]);

  return (
    <KeyboardStickyView offset={{ closed: 0, opened: 0 }}>
      <View className="flex-row items-end gap-inline-sm px-component-md py-component-sm border-t border-default bg-surface-default pb-safe-offset-1">
        <TextInput
          value={text}
          onChangeText={setText}
          placeholder="Message..."
          placeholderTextColorClassName="accent-content-tertiary"
          multiline
          className="flex-1 bg-surface-raised border border-default focus:border-focus rounded-xl border-continuous px-component-md py-component-sm text-content-primary text-base max-h-30"
        />
        <Pressable
          onPress={handleSend}
          accessibilityRole="button"
          className="bg-action-primary active:bg-action-primary-active rounded-full border-continuous min-h-11 min-w-11 items-center justify-center"
        >
          <Text className="text-content-on-action text-base font-semibold">
            Send
          </Text>
        </Pressable>
      </View>
    </KeyboardStickyView>
  );
}

export default function __SCREEN_NAME__() {
  const [messages] = useState<__MESSAGE_TYPE__[]>([]);

  const handleSend = useCallback((text: string) => {
    // TODO: send message
  }, []);

  const renderItem = useCallback(({ item }: { item: __MESSAGE_TYPE__ }) => {
    return (
      <MessageBubble
        text={item.text}
        senderName={item.senderName}
        senderAvatar={item.senderAvatar}
        isMe={item.isMe}
      />
    );
  }, []);

  return (
    <>
      <Stack.Screen options={{ title: "__SCREEN_TITLE__" }} />
      <View className="flex-1 bg-surface-default">
        <KeyboardChatScrollView inverted keyboardLiftBehavior="always">
          <FlashList
            inverted
            data={messages}
            renderItem={renderItem}
            keyExtractor={(item) => item.id}
            contentContainerClassName="py-component-sm"
            ListEmptyComponent={
              <View className="items-center justify-center py-component-md">
                <Text className="text-content-tertiary text-base">
                  No messages yet
                </Text>
              </View>
            }
          />
        </KeyboardChatScrollView>
        <ChatInput onSend={handleSend} />
      </View>
    </>
  );
}
