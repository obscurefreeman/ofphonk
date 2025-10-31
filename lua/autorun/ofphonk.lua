AddCSLuaFile()

sound.Add( {
    name = "ofphonk.phonk",
    channel = CHAN_STATIC,
    volume = 1,
    level = 65,
    pitch = {95, 110},
    sound = {
        "ofphonk/1.ogg",
        "ofphonk/2.ogg",
        "ofphonk/3.ogg",
        "ofphonk/4.ogg",
        "ofphonk/5.ogg",
        "ofphonk/6.ogg",
        "ofphonk/7.ogg",
        "ofphonk/8.ogg",
        "ofphonk/9.ogg",
        "ofphonk/10.ogg",
        "ofphonk/11.ogg"
    } 
} )

if SERVER then
    util.AddNetworkString("OFPhonk_KillEvent")

    -- 移动到服务器端：定义timescale控制变量和参数
    local currentTimeScale = 1
    local targetTimeScale = 1
    local freezeDuration = 2.0
    local recoveryDuration = 1.0
    local nextAvailable = 0

    -- 在服务器端处理Kill事件，包括timescale的调节
    local function HandlePhonkKillEvent(attacker)
        print("[OFPhonk] 触发事件，攻击者：", attacker)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        if CurTime() < nextAvailable then return end
        nextAvailable = CurTime() + 3 -- 防止事件堆叠

        -- 设置目标TimeScale
        targetTimeScale = 0.05

        -- 通知客户端播放音效和开启黑白
        net.Start("OFPhonk_KillEvent")
        net.Send(attacker)

        -- 计时后，恢复速度
        timer.Simple(freezeDuration, function()
            targetTimeScale = 1
            print("[OFPhonk] 恢复速度中")
        end)

        -- 计时后，强制完全恢复（应答客户端实际只负责关黑白）
        timer.Simple(freezeDuration + recoveryDuration, function()
            currentTimeScale = 1
            targetTimeScale = 1
            game.SetTimeScale(1)
            print("[OFPhonk] 强制完全恢复")
        end)
    end

    hook.Add("OnNPCKilled", "OFPhonk_OnNPCKilled", function(npc, attacker, inflictor)
        HandlePhonkKillEvent(attacker)
    end)

    hook.Add("PlayerDeath", "OFPhonk_PlayerDeath", function(victim, inflictor, attacker)
        if victim ~= attacker then
            HandlePhonkKillEvent(attacker)
        end
    end)

    -- 服务器平滑推动timescale
    hook.Add("Think", "OFPhonk_TimeScaleUpdater", function()
        local FT = FrameTime()
        currentTimeScale = Lerp(FT * 5, currentTimeScale, targetTimeScale)
        -- 只有在当前TimeScale与目标TimeScale有显著差异，
        -- 并且当前游戏TimeScale不是由其他插件设置的低速状态时才进行设置
        -- 这里的检查是一个简单的尝试，可能无法完全避免所有冲突
        if math.abs(game.GetTimeScale() - currentTimeScale) > 0.01 and game.GetTimeScale() >= 0.1 then
            game.SetTimeScale(currentTimeScale)
        elseif game.GetTimeScale() == 1 and targetTimeScale < 1 then
            game.SetTimeScale(currentTimeScale)
        end
        print("[OFPhonk] 时间：", currentTimeScale)
    end)

elseif CLIENT then

    local nextAvailable = 0
    local bwEffect = false
    -- local phonkSoundChannel = nil -- 未用到可去除

    net.Receive("OFPhonk_KillEvent", function()
        if CurTime() < nextAvailable then return end
        nextAvailable = CurTime() + 3 -- 避免事件堆叠

        -- 启用黑白效果
        bwEffect = true

        -- 播放音效
        surface.PlaySound("ofphonk.phonk")

        -- 关闭黑白效果的计时由服务器freezeDuration和recoveryDuration决定，应与之同步
        local freezeDuration = 2.0
        local recoveryDuration = 1.0
        timer.Simple(freezeDuration + recoveryDuration, function()
            bwEffect = false
        end)
    end)

    -- Black-and-white screen drawing
    hook.Add("RenderScreenspaceEffects", "OFPhonk_BWEffect", function()
        if bwEffect then
            DrawColorModify({
                ["$pp_colour_addr"] = 0,
                ["$pp_colour_addg"] = 0,
                ["$pp_colour_addb"] = 0,
                ["$pp_colour_brightness"] = 0,
                ["$pp_colour_contrast"] = 1,
                ["$pp_colour_colour"] = 0,    -- makes it black & white
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })
        end
    end)

end