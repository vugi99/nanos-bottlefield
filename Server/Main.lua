
Package.RequirePackage("rounds")

local Flags_SM = {}
local Flags_Triggers = {}

local Teams_Points = {}

INIT_ROUNDS({
    ROUND_TYPE = "TEAMS",
    ROUND_TEAMS = {
        {},
        {},
    },

    ROUND_START_CONDITION = {"PLAYERS_NB", 2},
    ROUND_END_CONDITION = {"REMAINING_PLAYERS", 1},

    SPAWN_POSSESS = {"CHARACTER", {}},
    SPAWNING = {"TEAM_SPAWNS", TEAMS_SPAWNS},

    WAITING_ACTION = {"FREECAM"},

    PLAYER_OUT_CONDITION = {"DEATH"},
    PLAYER_OUT_ACTION = {"RESPAWN"},

    ROUNDS_INTERVAL_ms = Rounds_Interval,

    CAN_JOIN_DURING_ROUND = true,
})

local r_events = {
    "RoundEnding",
    "RoundStart",
    "RoundPlayerSpawned",
    "RoundPlayerOut",
    "RoundPlayerWaiting",
    "RoundPlayerJoined",
    "RoundPlayerOutDeath",
}

for k, v in pairs(r_events) do
    Events.Subscribe(v, function(...)
        print("bottlefield :", v, ...)
    end)
end

Package.Subscribe("Load", function()
    for i, v in ipairs(FLAGS) do
        local SM = StaticMesh(
            v.location - Vector(0, 0, 100),
            Rotator(0, 0, 0),
            Flag_Model
        )
        SM:SetScale(Flag_Scale)
        table.insert(Flags_SM, SM)
        SM:SetValue("CapturedBy", {0, 0}, true)

        local Trigger = Trigger(v.location, Rotator(), Vector(v.capture_radius), TriggerType.Sphere, true, Color.YELLOW)
        Trigger:Subscribe("BeginOverlap", function(trigger, actor)
            if actor.GetPlayer then
                local ply = actor:GetPlayer()
                if ply then
                    local team = ply:GetValue("PlayerTeam")
                    if team then
                        table.insert(Flags_Triggers[i].in_zone[team], ply)
                        --print("Player added in zone", i)
                    end
                end
            end
        end)

        Trigger:Subscribe("EndOverlap", function(trigger, actor)
            if actor.GetPlayer then
                local ply = actor:GetPlayer()
                if ply then
                    for k2, v2 in pairs(Flags_Triggers[i].in_zone) do
                        for k3, v3 in pairs(v2) do
                            if v3 == ply then
                                table.remove(Flags_Triggers[i].in_zone[k2], k3)
                                --print("Player removed from zone", i)
                                break
                            end
                        end
                    end
                end
            end
        end)

        table.insert(Flags_Triggers, {
            trigger = Trigger,
            in_zone = {
                {},
                {},
            },
        })
    end
end)

function BottleGun()
    local weapon = Weapon(Vector(), Rotator(), Weapon_Given)
    weapon:SetAmmoSettings(Weapon_Ammo_Bag, 0)
	weapon:SetDamage(0)
	weapon:SetRecoil(0)
	weapon:SetSightTransform(Vector(0, 0, -4), Rotator(0, 0, 0))
	weapon:SetLeftHandTransform(Vector(0, 1, -5), Rotator(0, 60, 100))
	weapon:SetRightHandOffset(Vector(-25, -5, 0))
	weapon:SetHandlingMode(HandlingMode.SingleHandedWeapon)
	weapon:SetCadence(Weapon_Cadence)
	weapon:SetSoundDry("nanos-world::A_Pistol_Dry")
	weapon:SetSoundZooming("nanos-world::A_AimZoom")
	weapon:SetSoundAim("nanos-world::A_Rattle")
	weapon:SetSoundFire("nanos-world::A_Whoosh")
	weapon:SetAnimationCharacterFire("nanos-world::A_Mannequin_Sight_Fire_Pistol")
	weapon:SetParticlesBarrel("nanos-world::P_Weapon_BarrelSmoke")
	weapon:SetCrosshairMaterial("nanos-world::MI_Crosshair_Square")
	weapon:SetUsageSettings(true, false)

    weapon:SetValue("BottleGun", true, false)

    return weapon
end

Events.Subscribe("RoundPlayerSpawned", function(ply)
    local char = ply:GetControlledCharacter()
    char:SetCanDrop(false)
    char:SetSpeedMultiplier(Speed_Multiplier)

    if ply:GetValue("PlayerTeam") == 1 then
        char:SetMaterialColorParameter("Tint", Color.AZURE)
    elseif ply:GetValue("PlayerTeam") == 2 then
        char:SetMaterialColorParameter("Tint", Color.RED)
    end

    local weapon = BottleGun()
    char:PickUp(weapon)
end)

Weapon.Subscribe("Fire", function(weapon, char)
    if weapon:GetValue("BottleGun") then
        local control_rotation = char:GetControlRotation()
        local forward_vector = control_rotation:GetForwardVector()
        local spawn_location = weapon:GetLocation() + forward_vector * 100

        local prop = Prop(spawn_location, weapon:GetRotation() + Rotator(0, -90, 0), Bottles_Collision_Model, CollisionType.Normal, true, false, false)
        prop:SetLifeSpan(Bottles_Life_Span)
        prop:SetScale(Bottles_Collision_Scale)
        prop:SetValue("BottleShooter", char:GetPlayer():GetID(), false)

        local bottle = Prop(spawn_location, weapon:GetRotation() + Rotator(0, -90, 0), Bottle_Model, CollisionType.NoCollision, true, false, false)
        bottle:SetScale(Bottle_Scale)
        bottle:AttachTo(prop, AttachmentRule.SnapToTarget, "", 0)
        bottle:SetRelativeLocation(Bottle_Relative_Location)

        bottle:SetVisibility(false)
        prop:SetVisibility(false)
        bottle:SetVisibility(true)

        prop:AddImpulse(forward_vector * Shoot_Force, true)
    end
end)

local APPLY_MULT_DAMAGE = false
Character.Subscribe("TakeDamage", function(char, damage, bone, damage_type, from_direction, instigator, causer)
    if not APPLY_MULT_DAMAGE then
        --print("TakeDamage", damage, char, damage_type, instigator, causer)
        if causer then
            if char:GetHealth() - damage > 0 then
                APPLY_MULT_DAMAGE = true
                char:ApplyDamage(damage * (Bottles_Damage_Multiplier - 1), bone, damage_type, from_direction, instigator, causer)
            end
        end
    else
        APPLY_MULT_DAMAGE = false
    end
end)

Events.Subscribe("RoundPlayerOutDeath", function(char, last_damage_taken, last_bone_damage, damage_type_reason, hit_from_direction, instigator, causer)
    if causer then
        local shooter_id = causer:GetValue("BottleShooter")
        if shooter_id then
            local shooter
            for k, v in pairs(Player.GetPairs()) do
                if v:GetID() == shooter_id then
                    shooter = v
                end
            end
            if shooter then
                if shooter == char:GetPlayer() then
                    Server.BroadcastChatMessage(shooter:GetAccountName() .. " got bottled")
                else
                    Server.BroadcastChatMessage(shooter:GetAccountName() .. " killed " .. char:GetPlayer():GetAccountName())
                end
            end
        end
    end
end)

function CaptureCalc(team, captured_percentage_add, captured_value)
    local new_captured_value = {captured_value[1], captured_value[2]}
    local oppositeTeam = 2
    if team == 2 then
        oppositeTeam = 1
    end
    if new_captured_value[1] == 0 then
        new_captured_value[1] = team
        new_captured_value[2] = clamp(0, 0, 100, captured_percentage_add * Flags_Capture_Multiplier)
    elseif new_captured_value[1] == oppositeTeam then
        if (new_captured_value[2] - captured_percentage_add * Flags_Capture_Multiplier < 0) then
            new_captured_value[1] = team
            new_captured_value[2] = (new_captured_value[2] - captured_percentage_add * Flags_Capture_Multiplier) * -1
        else
            new_captured_value[2] = clamp(new_captured_value[2], 0, 100, (captured_percentage_add * Flags_Capture_Multiplier) * -1)
        end

        if new_captured_value[2] == 0 then
            new_captured_value[1] = 0
        end
    elseif new_captured_value[1] == team then
        new_captured_value[2] = clamp(new_captured_value[2], 0, 100, captured_percentage_add * Flags_Capture_Multiplier)
    end
    return new_captured_value
end

Timer.SetInterval(function()
    for k, v in pairs(Flags_Triggers) do
        local flag_sm = Flags_SM[k]
        local captured_value = flag_sm:GetValue("CapturedBy")
        local team1_players_in_it = table_count(v.in_zone[1])
        local team2_players_in_it = table_count(v.in_zone[2])


        local new_captured_value
        if team1_players_in_it > team2_players_in_it then
            local captured_percentage_add = team1_players_in_it - team2_players_in_it

            new_captured_value = CaptureCalc(1, captured_percentage_add, captured_value)
        elseif team1_players_in_it < team2_players_in_it then
            local captured_percentage_add = team2_players_in_it - team1_players_in_it

            new_captured_value = CaptureCalc(2, captured_percentage_add, captured_value)
        end

        --[[if new_captured_value then
            print(NanosUtils.Dump(captured_value), NanosUtils.Dump(new_captured_value))
        end]]--
        if (new_captured_value and (new_captured_value[1] ~= captured_value[1] or new_captured_value[2] ~= captured_value[2])) then
            --print("SetValue")
            flag_sm:SetValue("CapturedBy", new_captured_value, true)
        end
    end
end, Flags_Capture_Timer_ms)

function Check0PointsRemaining()
    if (Teams_Points[1] == 0 or Teams_Points[2] == 0) then
        RoundEnd()
    end
end

Events.Subscribe("RoundStart", function()
    Teams_Points[1] = Start_Points
    Teams_Points[2] = Start_Points

    Events.BroadcastRemote("UpdateTeamsPoints", Teams_Points)

    for k, v in pairs(Flags_SM) do
        v:SetValue("CapturedBy", {0, 0}, true)
    end
end)

Events.Subscribe("RoundPlayerJoined", function(ply)
    Events.CallRemote("UpdateTeamsPoints", ply, Teams_Points)
    Server.BroadcastChatMessage(ply:GetAccountName() .. " Joined")
end)

Events.Subscribe("RoundPlayerOut", function(ply)
    local team = ply:GetValue("PlayerTeam")
    if team then
        if Teams_Points[team] > 0 then
            Teams_Points[team] = Teams_Points[team] - 1
            Events.BroadcastRemote("UpdateTeamsPoints", Teams_Points)
            Check0PointsRemaining()
        end
    end
end)

Timer.SetInterval(function()
    if Teams_Points[1] then
        local team1_cflags = 0
        local team2_cflags = 0
        for k, v in pairs(Flags_SM) do
            local capturedby = v:GetValue("CapturedBy")
            if capturedby then
                if capturedby[2] == 100 then
                    if capturedby[1] == 1 then
                        team1_cflags = team1_cflags + 1
                    elseif capturedby[1] == 2 then
                        team2_cflags = team2_cflags + 1
                    end
                end
            end
        end

        --print(team1_cflags, team2_cflags)

        if team1_cflags > team2_cflags then
            Teams_Points[2] = clamp(Teams_Points[2], 0, Start_Points, -(team1_cflags - team2_cflags))
            Events.BroadcastRemote("UpdateTeamsPoints", Teams_Points)
            Check0PointsRemaining()
        elseif team2_cflags > team1_cflags then
            Teams_Points[1] = clamp(Teams_Points[1], 0, Start_Points, -(team2_cflags - team1_cflags))
            Events.BroadcastRemote("UpdateTeamsPoints", Teams_Points)
            Check0PointsRemaining()
        end
    end
end, Flags_Remove_Points_Interval_ms)

Events.Subscribe("RoundEnding", function()
    Teams_Points = {}
    for k, v in pairs(Flags_Triggers) do
        Flags_Triggers[k].in_zone = {{}, {}}
    end
end)

Character.Subscribe("Destroy", function(char)
    local ply = char:GetPlayer()
    if ply then
        for k, v in pairs(Flags_Triggers) do
            for k2, v2 in pairs(v.in_zone) do
                for k3, v3 in pairs(v2) do
                    if v3 == ply then
                        table.remove(Flags_Triggers[k].in_zone[k2], k3)
                        --print("Removed Character Destroy")
                        break
                    end
                end
            end
        end
    end
end)

Player.Subscribe("Destroy", function(ply)
    Server.BroadcastChatMessage(ply:GetAccountName() .. " Left")
end)

Weapon.Subscribe("Drop", function(weapon, char, was_triggered_by_player)
    weapon:Destroy()
end)

Vehicle.Subscribe("CharacterAttemptEnter", function(veh, char, seat)
    return false
end)