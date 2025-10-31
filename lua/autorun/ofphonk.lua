AddCSLuaFile()

local phonkSounds = {
    "ofphonk/1.wav",
    "ofphonk/2.wav",
    "ofphonk/3.wav",
    "ofphonk/4.wav",
    "ofphonk/5.wav",
    "ofphonk/6.wav",
    "ofphonk/7.wav",
    "ofphonk/8.wav",
    "ofphonk/9.wav",
    "ofphonk/10.wav",
    "ofphonk/11.wav"
}

if SERVER then
    util.AddNetworkString("OFPhonk_KillEvent")

    local freezeDuration = 2.0
    local nextAvailable = 0

    -- 立即暂停时间，过期后直接恢复
    local function HandlePhonkKillEvent(attacker)
        print("[OFPhonk] 触发事件，攻击者：", attacker)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        if CurTime() < nextAvailable then return end
        nextAvailable = CurTime() + 3 -- 防止事件堆叠

        local randomSoundFile = phonkSounds[math.random(1, #phonkSounds)]

        -- 获取音效时长
        local soundDuration = SoundDuration(randomSoundFile)
        if soundDuration <= 0 then soundDuration = freezeDuration end -- 如果获取失败，使用默认值

        print("[OFPhonk] 音频名称：", randomSoundFile,"[OFPhonk] 音频长度：", soundDuration)

        -- 通知客户端播放音效和开启黑白，同时传递 randomSoundFile 和 soundDuration
        net.Start("OFPhonk_KillEvent")
        net.WriteString(randomSoundFile)
        net.WriteFloat(soundDuration) -- 发送音效时长
        net.Send(attacker)

        -- 在真实时间（不受 game.SetTimeScale 影响）后恢复速度
        local realRecoveryTime = SysTime() + soundDuration
        timer.Create("OFPhonk_RecoveryTimer", 0.01, 0, function() -- 使用一个非常小的间隔来检查
            if SysTime() >= realRecoveryTime then
                game.SetTimeScale(1)
                -- print("[OFPhonk] 强制完全恢复，经过时间：", math.abs(SysTime()-realRecoveryTime))
                timer.Remove("OFPhonk_RecoveryTimer")
            end
        end)

        game.SetTimeScale(0.01)
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

        -- 接收音效文件路径和时长
        local randomSoundFile = net.ReadString()
        local soundDuration = net.ReadFloat() -- 接收音效时长

        -- 启用黑白效果
        bwEffect = true

        -- 播放音效
        surface.PlaySound(randomSoundFile)

        -- 关闭黑白效果的计时由音效时长决定
        timer.Simple(soundDuration, function()
            bwEffect = false
        end)
        print("[OFPhonk] 音频长度：", soundDuration)
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