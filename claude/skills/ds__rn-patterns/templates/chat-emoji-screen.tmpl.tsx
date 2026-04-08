import { View, Text, TextInput, Pressable, ScrollView } from "react-native";
import {
  KeyboardChatScrollView,
  KeyboardStickyView,
  KeyboardExtender,
  OverKeyboardView,
} from "react-native-keyboard-controller";
import { FlashList } from "@shopify/flash-list";
import { withUniwind } from "uniwind";
import { Image as ExpoImage } from "expo-image";
import { EaseView } from "react-native-ease/uniwind";
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

function SuggestionChips({
  suggestions,
  onSelect,
}: {
  suggestions: string[];
  onSelect: (value: string) => void;
}) {
  return (
    <KeyboardExtender enabled={suggestions.length > 0}>
      <ScrollView
        horizontal
        keyboardShouldPersistTaps="always"
        contentContainerClassName="gap-inline-sm px-component-md py-component-sm"
      >
        {suggestions.map((suggestion, index) => (
          <EaseView
            key={suggestion}
            initialAnimate={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{
              type: "spring",
              damping: 15,
              stiffness: 200,
              delay: index * 30,
            }}
          >
            <Pressable
              onPress={() => {
                if (process.env.EXPO_OS === "ios") {
                  Haptics.selectionAsync();
                }
                onSelect(suggestion);
              }}
              className="bg-surface-raised border border-default rounded-lg border-continuous px-component-sm py-inline-xs"
            >
              <Text className="text-content-primary text-sm">
                {suggestion}
              </Text>
            </Pressable>
          </EaseView>
        ))}
      </ScrollView>
    </KeyboardExtender>
  );
}

const __EMOJI_LIST__ = [
  "😀", "😂", "🥹", "😍", "🤔", "👍", "👎", "🎉",
  "🔥", "❤️", "💯", "🙏", "👀", "🚀", "✅", "⭐",
];

function EmojiPicker({
  visible,
  onSelect,
}: {
  visible: boolean;
  onSelect: (emoji: string) => void;
}) {
  return (
    <OverKeyboardView visible={visible}>
      <View className="h-64 bg-surface-raised border-t border-subtle">
        <ScrollView contentContainerClassName="flex-row flex-wrap gap-inline-sm px-component-md py-component-sm">
          {__EMOJI_LIST__.map((emoji) => (
            <Pressable
              key={emoji}
              onPress={() => {
                if (process.env.EXPO_OS === "ios") {
                  Haptics.selectionAsync();
                }
                onSelect(emoji);
              }}
              className="w-10 h-10 items-center justify-center"
            >
              <Text className="text-2xl">{emoji}</Text>
            </Pressable>
          ))}
        </ScrollView>
      </View>
    </OverKeyboardView>
  );
}

function ChatInput({
  text,
  onChangeText,
  showEmoji,
  onToggleEmoji,
  onSend,
}: {
  text: string;
  onChangeText: (value: string) => void;
  showEmoji: boolean;
  onToggleEmoji: () => void;
  onSend: () => void;
}) {
  return (
    <KeyboardStickyView offset={{ closed: 0, opened: 0 }}>
      <View className="flex-row items-end gap-inline-sm px-component-md py-component-sm border-t border-default bg-surface-default pb-safe-offset-1">
        <Pressable
          onPress={onToggleEmoji}
          accessibilityRole="button"
          className="min-h-11 min-w-11 items-center justify-center"
        >
          <Image
            source={showEmoji ? "sf:keyboard" : "sf:face.smiling"}
            className="w-6 h-6"
            tintColorClassName="accent-content-secondary"
          />
        </Pressable>
        <TextInput
          value={text}
          onChangeText={onChangeText}
          placeholder="Message..."
          placeholderTextColorClassName="accent-content-tertiary"
          multiline
          className="flex-1 bg-surface-raised border border-default focus:border-focus rounded-xl border-continuous px-component-md py-component-sm text-content-primary text-base max-h-30"
        />
        <Pressable
          onPress={onSend}
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
  const [text, setText] = useState("");
  const [showEmoji, setShowEmoji] = useState(false);
  const [suggestions] = useState<string[]>([]);

  const handleSend = useCallback(() => {
    const trimmed = text.trim();
    if (!trimmed) return;
    if (process.env.EXPO_OS === "ios") {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
    // TODO: send message
    setText("");
  }, [text]);

  const handleToggleEmoji = useCallback(() => {
    setShowEmoji((prev) => !prev);
  }, []);

  const handleEmojiSelect = useCallback((emoji: string) => {
    setText((prev) => prev + emoji);
  }, []);

  const handleSuggestionSelect = useCallback((value: string) => {
    setText(value);
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
        <KeyboardChatScrollView
          inverted
          keyboardLiftBehavior="always"
          freeze={showEmoji}
        >
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
        <SuggestionChips
          suggestions={suggestions}
          onSelect={handleSuggestionSelect}
        />
        <ChatInput
          text={text}
          onChangeText={setText}
          showEmoji={showEmoji}
          onToggleEmoji={handleToggleEmoji}
          onSend={handleSend}
        />
        <EmojiPicker visible={showEmoji} onSelect={handleEmojiSelect} />
      </View>
    </>
  );
}
