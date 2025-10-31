AddCSLuaFile()

-- 全局变量
OFPHONKRECOVERY = 0

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
    util.AddNetworkString("OFPhonk_RecoveryTime") -- 新增网络消息

    local freezeDuration = 4.0
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

        -- 设置全局恢复时间
        OFPHONKRECOVERY = SysTime() + soundDuration
        
        -- 通知客户端恢复时间
        net.Start("OFPhonk_RecoveryTime")
        net.WriteFloat(OFPHONKRECOVERY)
        net.Broadcast()

        -- 通知客户端播放音效和开启黑白，同时传递 randomSoundFile 和 soundDuration
        net.Start("OFPhonk_KillEvent")
        net.WriteString(randomSoundFile)
        net.WriteFloat(soundDuration) -- 发送音效时长
        net.Send(attacker)

        -- 在真实时间（不受 game.SetTimeScale 影响）后恢复速度
        hook.Add("Think", "OFPhonk_RecoveryThink", function()
            if SysTime() >= OFPHONKRECOVERY - 0.8 then
                game.SetTimeScale(1)
                print("[OFPhonk] 强制完全恢复，系统时间：", SysTime(), "应该消失的时间：", OFPHONKRECOVERY)
                hook.Remove("Think", "OFPhonk_RecoveryThink")
            end
        end)

        game.SetTimeScale(0)
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
    local lockView = false
    local lockedAngles = Angle(0, 0, 0)

    -- 接收服务器发送的恢复时间
    net.Receive("OFPhonk_RecoveryTime", function()
        OFPHONKRECOVERY = net.ReadFloat()
    end)

    net.Receive("OFPhonk_KillEvent", function()
        if CurTime() < nextAvailable then return end
        nextAvailable = CurTime() + 3 -- 避免事件堆叠

        -- 接收音效文件路径和时长
        local randomSoundFile = net.ReadString()
        local soundDuration = net.ReadFloat() -- 接收音效时长

        -- 启用黑白效果
        bwEffect = true

        -- 锁定视角
        local ply = LocalPlayer()
        if IsValid(ply) then
            lockedAngles = ply:EyeAngles()
            lockView = true
        end

        -- 播放音效
        surface.PlaySound(randomSoundFile)

        -- 使用全局恢复时间同步关闭黑白效果和解锁视角
        hook.Add("Think", "OFPhonk_ClientRecoveryThink", function()
            if SysTime() >= OFPHONKRECOVERY then
                bwEffect = false
                lockView = false
                hook.Remove("Think", "OFPhonk_ClientRecoveryThink")
                print("[OFPhonk] 客户端黑白效果已关闭")
            end
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

    -- 锁定玩家视角旋转
    hook.Add("CreateMove", "OFPhonk_LockView", function(cmd)
        if lockView then
            cmd:SetViewAngles(lockedAngles)
        end
    end)

end