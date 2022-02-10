

Rounds_Interval = 5000
FriendlyFire = false

Start_Points = 250

Flag_Model = "nanos-world::SM_Bottle_01"
Flag_Scale = Vector(15, 15, 15)
Flags_Remove_Points_Interval_ms = 2000

Bottles_Collision_Model = "nanos-world::SM_Cube"
Bottles_Collision_Scale = Vector(0.3, 0.8, 0.27)

Bottle_Model = "nanos-world::SM_Bottle"
Bottles_Life_Span = 20
Bottle_Scale = Vector(2, 2, 2)
Bottle_Relative_Location = Vector(-5, -15, -45)
Shoot_Force = 5000
Bottles_Damage_Multiplier = 4

Flags_Text_Offset = Vector(0, 0, 200)

Weapon_Given = "nanos-world::SK_FlareGun"
Weapon_Ammo_Bag = 2000
Weapon_Cadence = 0.2

Flags_Capture_Timer_ms = 1000
Flags_Capture_Multiplier = 5

Speed_Multiplier = 1.2

Music_Played_At_Percentage_Remaining = 20
Music_path = "package///" .. Package.GetPath() .. "/Client/sounds/bottlefield.ogg"