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
    
    hook.Add("OnNPCKilled", "OFPhonk_OnNPCKilled", function(npc, attacker, inflictor)
        if IsValid(attacker) and attacker:IsPlayer() then
            net.Start("OFPhonk_KillEvent")
            net.Send(attacker)
        end
    end)

    hook.Add("PlayerDeath", "OFPhonk_PlayerDeath", function(victim, inflictor, attacker)
        if IsValid(attacker) and attacker:IsPlayer() and victim ~= attacker then
            net.Start("OFPhonk_KillEvent")
            net.Send(attacker)
        end
    end)
else -- CLIENT

    local nextAvailable = 0
    local bwEffect = false
    local phonkSoundChannel = nil
    local freezeEndTime = 0

    net.Receive("OFPhonk_KillEvent", function()
        if CurTime() < nextAvailable then return end
        nextAvailable = CurTime() + 3 -- To avoid stacking up events

        -- Black and white effect
        bwEffect = true
        freezeEndTime = CurTime() + 2

        -- "Pause": block input and movement
        hook.Add("StartCommand", "OFPhonk_FreezeTime", function(ply, cmd)
            if bwEffect and ply == LocalPlayer() then

            end
        end)

        -- 播放
        surface.PlaySound("ofphonk.phonk")

        -- Remove effect after 2 seconds
        timer.Simple(3, function()
            bwEffect = false
            hook.Remove("StartCommand", "OFPhonk_FreezeTime")
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


