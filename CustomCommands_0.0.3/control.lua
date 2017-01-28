if not cc then cc = {} end
if not cc.commands then cc.commands = {} end

script.on_event("cc-toggle-gui", function(event)
  local player = game.players[event.player_index]
  if cc.gui_is_open(player) then
    cc.close_gui(player)
  else
    cc.open_gui(player)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local player = game.players[event.player_index]
  local element = event.element
  if element.type == "button" then
    if element.name == "cc_send_cmd" then
      cc.parse(player, element.parent.cc_cmd.text)
    elseif not (element.name == "") and string.match(element.name, "cc%_suggest%_") then
      local text = string.sub(element.name, 12)
      element.parent.parent.parent.cc_cmd_frame.cc_cmd.text = text
    end
  end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
  local player = game.players[event.player_index]
  if cc.gui_is_open(player) and event.element.name == "cc_cmd" then
    local flow = event.element.parent.parent.cc_cmd_flow
    if flow.cc_cmd_suggest then
      flow.cc_cmd_suggest.destroy()
    end
    local text = event.element.text
    if text == "" then return end
    text = string.gsub(text, "%p", "%%%0")
    local matches = {}
    for k,v in pairs(cc.commands) do
      for cmd,desc in pairs(v) do
        if string.match(k.. ":" .. cmd, text) then
          table.insert(matches, {name = k..":"..cmd, description = desc})
        end
      end
    end
    if #matches > 0 then
      local suggest = flow.add({type = "scroll-pane", name = "cc_cmd_suggest", style = "cc-scroll-pane", direction = "vertical"})
      suggest.add({type = "label", name = "cc_suggestions", caption = " Suggested:"})
      for _,match in pairs(matches) do
        suggest.add({type = "button", name = "cc_suggest_" .. match.name, caption = match.name, tooltip = match.description})
      end
    end
  end
end)

function cc.open_gui(player)
  local ui = player.gui.center.add({type = "frame", name = "cc_gui",direction = "vertical"})
  local cmd_line = ui.add({type = "frame", name = "cc_cmd_frame", direction = "horizontal"})
  cmd_line.add({type = "textfield", name = "cc_cmd"})
  cmd_line.add({type = "button", name = "cc_send_cmd", caption = "Send"})
  ui.add({type = "flow", name = "cc_cmd_flow", direction = "vertical"})
end

function cc.close_gui(player)
   player.gui.center.cc_gui.destroy()
end

function cc.gui_is_open(player)
  if player.gui.center.cc_gui then
    return true
  else
    return false
  end
end

function cc.parse(player, text)
  if text == "" then return end
  local interface = string.match(text, "[%w%-%_]+")
  local command = string.match(text, "%:[%w%-%_]+") or ""
  if command then
    command = string.sub(command, 2)
  end
  for k,v in pairs(cc.commands) do
    if interface == k then
      for cmd,desc in pairs(v) do
        if command == cmd then
          local args = {}
          local s = string.sub(text, string.len(interface..":"..command) + 1)
          for w in string.gmatch(s, "[%w%p%_%-]+") do
            table.insert(args, w)
          end
          remote.call(k, cmd, player, args)
          break
        end
      end
      break
    end
  end
end

function cc.register_command(interface, command)
  if not cc.commands[interface] then cc.commands[interface] = {} end
  if not cc.commands[interface][command] then
    cc.commands[interface][command] = ""
  end
end

function cc.register_descriptions(data)
  for k,v in pairs(data) do
    if cc.commands[k] then
      for _,i in pairs(v) do
        if cc.commands[k][i.command] then
          cc.commands[k][i.command] = i.description
        end
      end
    end
  end
end

function cc.search_for_commands()
  local interfaces = remote.interfaces
  for k,v in pairs(interfaces) do
    if string.match(k, "^cc%_[%w%_%-]+") then
      for cmd,i in pairs(v) do
        cc.register_command(k, cmd)
      end
    end
  end
end

function cc.search_for_descriptions()
  local interfaces = remote.interfaces
  for k,v in pairs(interfaces) do
    if string.match(k, "^ccd%_[%w%_%-]+") then
      cc.register_descriptions(remote.call(k, "descriptions"))
    end
  end
end

function cc.start()
  cc.search_for_commands()
  cc.search_for_descriptions()
end

script.on_init(cc.start)
script.on_load(cc.start)