function is_normal_workspace(ws)
    return ws ~= nil and ws.id ~= nil and ws.id >= 1
end

function workspace_window_count(workspace_id)
    local windows = hl.get_workspace_windows(tostring(workspace_id))
    if windows == nil then
        return 0
    end

    return #windows
end

function last_occupied_workspace_id()
    local last = 1

    for _, ws in pairs(hl.get_workspaces()) do
        if is_normal_workspace(ws) then
            if workspace_window_count(ws.id) > 0 and ws.id > last then
                last = ws.id
            end
        end
    end

    return last
end

function lower_workspace_bound()
    return last_occupied_workspace_id() + 1
end

function active_workspace_id()
    local ws = hl.get_active_workspace()
    if not is_normal_workspace(ws) then
        return nil
    end

    return ws.id
end

function focus_workspace_niri_like(direction)
    local current = active_workspace_id()
    if current == nil then
        return
    end

    local target = current + direction
    local lower_bound = lower_workspace_bound()

    if target < 1 then
        return
    end

    if target > lower_bound then
        return
    end

    hl.dispatch(hl.dsp.focus({
        workspace = tostring(target),
        on_current_monitor = true,
    }))
end

function move_window_to_workspace_niri_like(direction)
    local current = active_workspace_id()
    if current == nil then
        return
    end

    local target = current + direction
    local lower_bound = lower_workspace_bound()

    if target < 1 then
        return
    end

    if target > lower_bound then
        return
    end

    hl.dispatch(hl.dsp.window.move({
        workspace = tostring(target),
        follow = true,
    }))
end
