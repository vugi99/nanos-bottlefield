
Package.Require("Sh_Funcs.lua")
Package.Require("Config.lua")

Package.RequirePackage("rounds")

local GameNearEndSound

local Teams_Points = nil

local tick_canvas = Canvas(
  true,
  Color(0, 0, 0, 0),
  0,
  true
)

tick_canvas:Subscribe("Update", function(self, width, height)
    local ply = Client.GetLocalPlayer()
    if ply then
        local team = ply:GetValue("PlayerTeam")
        if team then
            self:DrawText("Team " .. tostring(team), Vector2D(2, math.floor(Client.GetViewportSize().Y * 0.3)), FontType.Roboto, 15, Color.WHITE, 0, false, true, Color(0, 0, 0, 0), Vector2D(), false, Color.WHITE)

            for k, v in pairs(StaticMesh.GetPairs()) do
                local captured_by = v:GetValue("CapturedBy")
                if captured_by then
                    local loc = v:GetLocation()
                    local project = Client.ProjectWorldToScreen(loc + Flags_Text_Offset)
                    if (project and project ~= Vector2D(-1, -1)) then
                        local text = GetTextFromCapturedBy(captured_by)
                        local text_color = Color.WHITE
                        if team == captured_by[1] then
                            text_color = Color.AZURE
                        elseif (captured_by[1] ~= 0 and team ~= captured_by[1]) then
                            text_color = Color.RED
                        end
                        self:DrawText(text, project, FontType.OpenSans, 20, text_color, 0, true, true, Color(0, 0, 0, 0), Vector2D(), true, Color.BLACK)
                    end
                end
            end
        end

        if Teams_Points then
            self:DrawText("Points : " .. tostring(Teams_Points[1]) .. " / " .. tostring(Teams_Points[2]), Vector2D(2, math.floor(Client.GetViewportSize().Y * 0.4)), FontType.Roboto, 14, Color.WHITE, 0, false, true, Color(0, 0, 0, 0), Vector2D(), false, Color.WHITE)

            for i = 1, 2 do
                if Teams_Points[i] == 0 then
                    local lost_team = 1
                    if i == 1 then
                        lost_team = 2
                    end
                    self:DrawText("TEAM " .. tostring(lost_team) .. " WON", Vector2D(math.floor(Client.GetViewportSize().X * 0.5), math.floor(Client.GetViewportSize().Y * 0.5)), FontType.Roboto, 20, Color.WHITE, 0, true, true, Color(0, 0, 0, 0), Vector2D(), false, Color.WHITE)
                end
            end
        end
    end
end)

function GetTextFromCapturedBy(captured_by)
    local text = tostring(captured_by[1]) .. " (" .. tostring(captured_by[2]) .. "%)"
    if captured_by[1] == 0 then
        text = tostring(captured_by[1])
    end
    return text
end

Events.Subscribe("UpdateTeamsPoints", function(points)
    if points[1] then
        Teams_Points = points
        local points_percentage = Start_Points * Music_Played_At_Percentage_Remaining / 100
        if (Teams_Points[1] <= points_percentage or Teams_Points[2] <= points_percentage) then
            if not GameNearEndSound then
                GameNearEndSound = Sound(
                    Vector(),
                    Music_path,
                    true,
                    false,
                    SoundType.Music,
                    1,
                    1,
                    400,
                    3600,
                    AttenuationFunction.Linear,
                    false,
                    SoundLoopMode.Forever
                )
            end
        elseif GameNearEndSound then
            GameNearEndSound:Destroy()
            GameNearEndSound = nil
        end
    end
end)