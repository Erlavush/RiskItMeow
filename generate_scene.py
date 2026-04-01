import os

lines = []
lines.append('[gd_scene load_steps=2 format=3 uid="uid://bw4n3n3d8h1p2"]')
lines.append("")
lines.append('[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_grass"]')
lines.append('albedo_color = Color(0.3, 0.7, 0.3, 1)')
lines.append("")
lines.append('[node name="World" type="Node3D"]')
lines.append("")
lines.append('[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]')
lines.append('transform = Transform3D(0.866025, -0.433013, 0.25, 0, 0.5, 0.866025, -0.5, -0.75, 0.433013, 0, 10, 0)')
lines.append('shadow_enabled = true')
lines.append("")
lines.append('[node name="Camera3D" type="Camera3D" parent="."]')
lines.append('transform = Transform3D(0.707107, -0.353553, 0.612372, 0, 0.866025, 0.5, -0.707107, -0.353553, 0.612372, 8, 8, 8)')
lines.append('current = true')
lines.append('fov = 60.0')
lines.append("")
lines.append('[node name="GroundBlocks" type="Node3D" parent="."]')
lines.append("")

idx = 0
for x in range(-5, 5):
    for z in range(-5, 5):
        lines.append(f'[node name="GrassBlock_{idx}" type="CSGBox3D" parent="GroundBlocks"]')
        lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x+0.5}, -0.5, {z+0.5})')
        lines.append('material = SubResource("StandardMaterial3D_grass")')
        lines.append("")
        idx += 1

with open("z:/RiskItMeow/risk-it-meow/scenes/main.tscn", "w") as f:
    f.write("\n".join(lines))

print("Created 10x10 blocks in viewport successfully!")
