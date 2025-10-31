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

    local freezeDuration = 2.0
    local recoveryDuration = 1.0
    local nextAvailable = 0

    -- 立即暂停时间，过期后直接恢复
    local function HandlePhonkKillEvent(attacker)
        print("[OFPhonk] 触发事件，攻击者：", attacker)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        if CurTime() < nextAvailable then return end
        nextAvailable = CurTime() + 3 -- 防止事件堆叠

        -- 立即暂停时间
        game.SetTimeScale(0.01)

        -- 通知客户端播放音效和开启黑白
        net.Start("OFPhonk_KillEvent")
        net.Send(attacker)

        -- 在真实时间（不受 game.SetTimeScale 影响）后恢复速度
        local realRecoveryTime = SysTime() + freezeDuration + recoveryDuration
        timer.Create("OFPhonk_RecoveryTimer", 0.01, 0, function() -- 使用一个非常小的间隔来检查
            if SysTime() >= realRecoveryTime then
                game.SetTimeScale(1)
                print("[OFPhonk] 强制完全恢复")
                timer.Remove("OFPhonk_RecoveryTimer")
            end
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