import { Host, ContextMenu, Button, Divider } from "@expo/ui/swift-ui";
import type { ContextMenuAction, ContextMenuProps } from "./context-menu.types";

function __COMPONENT_NAME__({
  actions,
  children,
  preview,
}: ContextMenuProps) {
  const standardActions = actions.filter((a) => a.role !== "destructive");
  const destructiveActions = actions.filter((a) => a.role === "destructive");

  return (
    <Host matchContents>
      <ContextMenu>
        <ContextMenu.Trigger>{children}</ContextMenu.Trigger>

        <ContextMenu.Items>
          {standardActions.map((action) => (
            <Button
              key={action.label}
              label={action.label}
              onPress={action.onPress}
              {...(action.systemImage !== undefined && {
                systemImage: action.systemImage,
              })}
            />
          ))}
          {destructiveActions.length > 0 && <Divider />}
          {destructiveActions.map((action) => (
            <Button
              key={action.label}
              label={action.label}
              role="destructive"
              onPress={action.onPress}
              {...(action.systemImage !== undefined && {
                systemImage: action.systemImage,
              })}
            />
          ))}
        </ContextMenu.Items>

        {!!preview && (
          <ContextMenu.Preview>{preview}</ContextMenu.Preview>
        )}
      </ContextMenu>
    </Host>
  );
}

export { __COMPONENT_NAME__ };
