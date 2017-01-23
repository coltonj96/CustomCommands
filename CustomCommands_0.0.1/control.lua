if not cc then cc = {} end
if not cc.players then cc.players = {} end
if not cc.commands then cc.commands = {} end

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.players[event.player_index]
  cc.players[event.player_index] = false
end)

script.on_event(defines.events.on_player_left_game, function(event)
  local player = game.players[event.player_index]
  cc.players[event.player_index] = nil
end)

script.on_event("cc-toggle-gui", function(event)
  local player = game.players[event.player_index]
  if cc.players[event.player_index] then
    cc.close_gui(player)
  else
    cc.open_gui(player)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local player = game.players[event.player_index]
  if cc.players[event.player_index] and event.element.name == "cc_send_cmd" then
    cc.parse(player, event.element.parent.cc_cmd.text)
  end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
  local player = game.players[event.player_index]
  if cc.players[event.player_index] and event.element.name == "cc_cmd" then
    local flow = event.element.parent.parent.cc_cmd_flow
    if flow.cc_cmd_suggest then
      flow.cc_cmd_suggest.destroy()
    end
    local text = event.element.text
    if text == "" then return end
    local matches = {}
    for k,v in pairs(cc.commands) do
      if string.match(k, text) then
        table.insert(matches, k)
      end
    end
    if #matches > 0 then
      local suggest = flow.add({type = "scroll-pane", name = "cc_cmd_suggest", style = "cc-scroll-pane", direction = "vertical"})
      suggest.add({type = "label", name = "cc_suggestions", caption = " Suggested:"})
      for _,match in pairs(matches) do
        suggest.add({type = "label", name = "cc_suggest_" .. match, caption = match})
      end
    end
  end
end)

function cc.open_gui(player)
  cc.players[player.index] = true
  local ui = player.gui.center.add({type = "frame", name = "cc_gui",direction = "vertical"})
  local cmd_line = ui.add({type = "frame", name = "cc_cmd_frame", direction = "horizontal"})
  cmd_line.add({type = "textfield", name = "cc_cmd"})
  cmd_line.add({type = "button", name = "cc_send_cmd", caption = "Send"})
  ui.add({type = "flow", name = "cc_cmd_flow", direction = "vertical"})
end

function cc.close_gui(player)
   cc.players[player.index] = false
   player.gui.center.cc_gui.destroy()
end

function cc.parse(player, text)
  if text == "" then return end
  local cmd = string.lower(string.gmatch(text, "[%w%-%_]+")())
  for k,v in pairs(cc.commands) do
    if cmd == k then
      local args = {}
      local s = string.sub(text, string.len(cmd) + 1)
      for w in string.gmatch(s, "[%w%p%_%-]+") do
        table.insert(args, w)
      end
      if #args == 0 then
        remote.call(v, k, {player})
      else
        remote.call(v, k, {player, args})
      end
      break;
    end
  end
end

function cc.get_items()
  return game.item_prototypes
end

function cc.register_command(command, interface)
  if not cc.commands[command] then
    cc.commands[command] = interface
  else
    local matches = {}
    for k,v in pairs(cc.commands) do
      if string.match(command, k.."%d*") then
        table.insert(matches, k)
      end
    end
    cc.commands[command..tostring(#matches + 1)] = interface
  end
end

remote.add_interface("custom_commands", {register_command = cc.register_command})