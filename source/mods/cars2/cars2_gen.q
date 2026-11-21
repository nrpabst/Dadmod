dadmod_car_hearse_setup = {
control_type = dadmod_car_hearse
model = "veh\\Veh_Hearse\\Veh_Hearse.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(36.0,28.0,1.4e+02)
(-36.0,28.0,1.4e+02)
(36.0,28.0,-44.0)
]
[
(26.0,48.0,58.0)
(-26.0,48.0,58.0)
(26.0,48.0,4.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.5
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.5
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_woodie_setup = {
control_type = dadmod_car_woodie
model = "veh\\Veh_Woodie\\Veh_Woodie.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(36.0,28.0,1.4e+02)
(-36.0,28.0,1.4e+02)
(36.0,28.0,-44.0)
]
[
(26.0,48.0,58.0)
(-26.0,48.0,58.0)
(26.0,48.0,4.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.5
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.5
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_sedan_setup = {
control_type = dadmod_car_sedan
model = "veh\\Veh_Sedan\\Veh_Sedan.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(29.0,3e+01,118.0)
(-29.0,3e+01,118.0)
(29.0,3e+01,-44.0)
]
[
(24.0,56.0,65.0)
(-24.0,56.0,65.0)
(24.0,56.0,0.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -21
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_smart_setup = {
control_type = dadmod_car_smart
model = "veh\\Veh_Smart_car\\Veh_Smart_Car.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(29.0,3e+01,118.0)
(-29.0,3e+01,118.0)
(29.0,3e+01,-44.0)
]
[
(24.0,56.0,65.0)
(-24.0,56.0,65.0)
(24.0,56.0,0.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -21
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_hippyvan_setup = {
control_type = dadmod_car_hippyvan
model = "veh\\veh_HippyVan\\veh_HippyVan.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_benzvan_setup = {
control_type = dadmod_car_benzvan
model = "veh\\veh_Benz_Van\\veh_Benz_Van.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_minivan_setup = {
control_type = dadmod_car_minivan
model = "veh\\Veh_Minivan\\Veh_Minivan.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_oldvan_setup = {
control_type = dadmod_car_oldvan
model = "veh\\Veh_OldVan\\Veh_OldVan.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_suv_setup = {
control_type = dadmod_car_suv
model = "veh\\Veh_SUV\\Veh_SUV.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_rust_setup = {
control_type = dadmod_car_rust
model = "veh\\veh_rust\\veh_rust.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(36.0,28.0,1.4e+02)
(-36.0,28.0,1.4e+02)
(36.0,28.0,-44.0)
]
[
(26.0,48.0,58.0)
(-26.0,48.0,58.0)
(26.0,48.0,4.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.5
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.5
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_liberty_setup = {
control_type = dadmod_car_liberty
model = "veh\\veh_liberty\\veh_liberty.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(29.0,3e+01,118.0)
(-29.0,3e+01,118.0)
(29.0,3e+01,-44.0)
]
[
(24.0,56.0,65.0)
(-24.0,56.0,65.0)
(24.0,56.0,0.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -21
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_bcntaxi_setup = {
control_type = dadmod_car_bcntaxi
model = "veh\\veh_barcelona_taxi\\veh_barcelona_taxi.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(33.0,25.0,1.5e+02)
(-33.0,25.0,1.5e+02)
(33.0,25.0,-65.0)
]
[
(28.0,55.0,62.0)
(-28.0,55.0,62.0)
(28.0,55.0,-2.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.5
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.5
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -20
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -20
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_neon_setup = {
control_type = dadmod_car_neon
model = "veh\\Veh_NeonType\\Veh_NeonType.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -22
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(29.0,3e+01,118.0)
(-29.0,3e+01,118.0)
(29.0,3e+01,-44.0)
]
[
(24.0,56.0,65.0)
(-24.0,56.0,65.0)
(24.0,56.0,0.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -21
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -21
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -16
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_dctruck_setup = {
control_type = dadmod_car_dctruck
model = "veh\\Veh_DCShoeTruck\\Veh_DCShoeTruck.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_tourbus_setup = {
control_type = dadmod_car_tourbus
model = "veh\\Veh_TourBus\\Veh_TourBus.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -15
mass = 2943
moment_of_inertia = (6e+06,2e+07,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(39.5,25.0,212.0)
(-39.5,25.0,212.0)
(39.5,25.0,-85.0)
]
[
(27.0,64.0,115.0)
(-27.0,64.0,115.0)
(27.0,64.0,-28.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 2.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.7
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.7
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_atv_setup = {
control_type = dadmod_car_atv
model = "veh\\Veh_ATV\\Veh_ATV.mdl"
sounds = SE_ATV
make_skater_visible
skater_pos = (-0.65,-2.0,4.07)
skater_anim = Ped_Baha_Drive
suspension_center_of_mass = -21
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.6
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 25
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(37.0,3e+01,41.0)
(-37.0,3e+01,41.0)
(37.0,3e+01,-36.0)
]
[
(12.0,64.0,16.0)
(-12.0,64.0,16.0)
(12.0,64.0,-28.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 14
moment = 3570
spring_rate = 200
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -20
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -20
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -20
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 1.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -20
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 1.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_mardi_setup = {
control_type = dadmod_car_mardi
model = "veh\\Veh_Mardi\\Veh_Mardi.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_duck_setup = {
control_type = dadmod_car_duck
model = "veh\\Veh_Duck\\veh_duck.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_sub_setup = {
control_type = dadmod_car_sub
model = "veh\\veh_sub\\veh_sub.mdl"
suspension_center_of_mass = (0.0,-1e+01,0.0)
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 10
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(42.0,12.0,8e+01)
(-42.0,12.0,8e+01)
(42.0,12.0,-8e+01)
]
[
(22.0,38.0,4.0)
(-22.0,38.0,4.0)
(22.0,46.0,-76.0)
]
]
engine = {
drive_torque = 550
drag_torque = 450
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
6
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 100
damping_rate = 16
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = 0
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = 0
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_car_streetcar_setup = {
control_type = dadmod_car_streetcar
model = "veh\\veh_streetcar\\veh_streetcar.mdl"
sounds = NY_JunkCar
skater_pos = (0.0,0.0,0.0)
suspension_center_of_mass = -15
mass = 2943
moment_of_inertia = (6e+06,2e+07,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(39.5,25.0,212.0)
(-39.5,25.0,212.0)
(39.5,25.0,-85.0)
]
[
(27.0,64.0,115.0)
(-27.0,64.0,115.0)
(27.0,64.0,-28.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 2.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.7
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.7
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_prop_cone_setup = {
control_type = dadmod_prop_cone
dadmod_prop_model = "Mdl_Cone\\Mdl_Cone.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}
dadmod_prop_cart_setup = {
control_type = dadmod_prop_cart
dadmod_prop_model = "veh\\Veh_Trolley\\veh_trolley.mdl"
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
make_skater_visible
skater_pos = (-10.81,1.0,26.18)
skater_anim = Ped_SIT_Idle
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}
dadmod_prop_scooter_setup = {
control_type = dadmod_prop_scooter
dadmod_prop_model = "veh\\Veh_Scooter\\Veh_Scooter.mdl"
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
make_skater_visible
skater_pos = (-10.81,1.0,26.18)
skater_anim = Ped_SIT_Idle
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}
dadmod_prop_robot_setup = {
control_type = dadmod_prop_robot
dadmod_prop_model = "veh\\veh_smallrobot\\veh_smallrobot.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}
dadmod_prop_robot2_setup = {
control_type = dadmod_prop_robot2
dadmod_prop_model = "veh\\veh_smallrobot2\\veh_smallrobot2.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}
dadmod_prop_chest_setup = {
control_type = dadmod_prop_chest
dadmod_prop_model = "gameobjects\\pickups\\treasure_chest\\treasure_chest.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}
dadmod_prop_bike_setup = {
control_type = dadmod_prop_bike
dadmod_prop_model = "veh\\Veh_CopperBike\\Veh_CopperBike.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}
dadmod_prop_mini_setup = {
control_type = dadmod_prop_mini
dadmod_prop_model = "veh\\Veh_Mini\\Veh_Mini.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -24
mass = 2943
moment_of_inertia = (6e+06,5e+06,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.7
body_spring = 1200
collision_control = 0.25
max_steering_angle = 18
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 0.5
in_air_slerp_velocity_cutoff = 350
vert_correction
colliders = [
[
(25.0,25.0,58.0)
(-25.0,25.0,58.0)
(25.0,25.0,-6e+01)
]
[
(25.0,48.0,56.0)
(-25.0,48.0,56.0)
(25.0,48.0,1e+01)
]
]
engine = {
drive_torque = 350
drag_torque = 300
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
9
6
2.5
0.75
0
]
}
all_wheels = {
radius = 9
moment = 3570
spring_rate = 200
damping_rate = 40
static_friction = 4.0
min_static_grip_velocity = 8
max_static_grip_velocity = 20
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
}
Wheels = [
{
max_draw_y_offset = -12
steering = left
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = right
drive = Yes
brake_torque = 2000
dynamic_friction = 2.8
handbrake_throttle_friction = 3
handbrake_locked_friction = 3
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
{
max_draw_y_offset = -12
steering = fixed
drive = Yes
brake_torque = 1000
dynamic_friction = 3.5
handbrake_throttle_friction = 2.0
handbrake_locked_friction = 2.0
}
]
}
dadmod_prop_halfpipe_setup = {
control_type = dadmod_prop_halfpipe
dadmod_prop_model = "veh\\Veh_Half_Pipe\\Veh_Half_Pipe.mdl"
skater_pos = (0.0,0.0,0.0)
model = "veh\\veh_limo\\veh_limo.mdl"
sounds = NY_JunkCar
suspension_center_of_mass = -15
mass = 2943
moment_of_inertia = (6e+06,2e+07,6e+06)
body_restitution = 0.3
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.25
max_steering_angle = 30
constant_rotational_damping = 2000000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 5
in_air_slerp_time_delay = 1
in_air_slerp_velocity_cutoff = 350
colliders = [
[
(39.5,25.0,212.0)
(-39.5,25.0,212.0)
(39.5,25.0,-85.0)
]
[
(27.0,64.0,115.0)
(-27.0,64.0,115.0)
(27.0,64.0,-28.0)
]
]
engine = {
drive_torque = 400
drag_torque = 800
upshift_rpm = 5000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [
4
3
1.5
0.65
0
]
}
all_wheels = {
radius = 13
moment = 3570
spring_rate = 200
damping_rate = 28
static_friction = 2.0
min_static_grip_velocity = 8
max_static_grip_velocity = 12
min_dynamic_grip_velocity = 30
handbrake_torque = 3000
brake_torque = 2000
}
Wheels = [
{
max_draw_y_offset = -25.7
steering = left
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -25.7
steering = right
drive = Yes
dynamic_friction = 2.8
handbrake_throttle_friction = 3.5
handbrake_locked_friction = 4.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -26
steering = fixed
drive = Yes
dynamic_friction = 3.5
handbrake_throttle_friction = 3.0
handbrake_locked_friction = 1.0
}
]
}
dadmod_c2_cams = {
JunkerCar = { d = 240 h = 55 a = 3.2 }
RallyCar = { d = 255 h = 58 a = 4.0 }
ImpalaCar = { d = 255 h = 58 a = 3.0 }
PoliceCar = { d = 290 h = 66 a = 3.6 }
TaxiNY = { d = 345 h = 78 a = 3.2 }
SecurityCart = { d = 240 h = 55 a = 3.5 }
GardnersCart = { d = 240 h = 55 a = 3.5 }
ElCaminoCar = { d = 255 h = 58 a = 3.2 }
LadaCar = { d = 250 h = 57 a = 3.6 }
MiniBajaCar = { d = 240 h = 55 a = 4.0 }
LimoCar = { d = 320 h = 73 a = 2.6 }
TaurusCar = { d = 250 h = 57 a = 3.4 }
PickupTruck = { d = 290 h = 66 a = 3.0 }
WranglerCar = { d = 240 h = 55 a = 3.2 }
SportsCar = { d = 240 h = 55 a = 4.4 }
Forklift = { d = 240 h = 55 a = 3.5 }
dadmod_car_hearse = { d = 290 h = 66 a = 3.0 }
dadmod_car_woodie = { d = 270 h = 62 a = 3.0 }
dadmod_car_sedan = { d = 255 h = 58 a = 3.4 }
dadmod_car_smart = { d = 220 h = 52 a = 3.8 }
dadmod_car_hippyvan = { d = 290 h = 72 a = 2.8 }
dadmod_car_benzvan = { d = 300 h = 74 a = 2.8 }
dadmod_car_minivan = { d = 280 h = 66 a = 3.0 }
dadmod_car_oldvan = { d = 280 h = 68 a = 2.8 }
dadmod_car_suv = { d = 300 h = 70 a = 3.0 }
dadmod_car_rust = { d = 260 h = 60 a = 3.2 }
dadmod_car_liberty = { d = 255 h = 58 a = 3.4 }
dadmod_car_bcntaxi = { d = 270 h = 62 a = 3.2 }
dadmod_car_neon = { d = 250 h = 57 a = 3.6 }
dadmod_car_dctruck = { d = 380 h = 90 a = 2.4 }
dadmod_car_tourbus = { d = 470 h = 110 a = 2.2 }
dadmod_car_atv = { d = 220 h = 52 a = 4.0 }
dadmod_car_mardi = { d = 420 h = 100 a = 2.4 }
dadmod_car_duck = { d = 420 h = 100 a = 2.4 }
dadmod_car_sub = { d = 330 h = 80 a = 2.6 }
dadmod_car_streetcar = { d = 470 h = 110 a = 2.2 }
dadmod_prop_cone = { d = 130 h = 34 a = 4.0 }
dadmod_prop_cart = { d = 170 h = 42 a = 3.8 }
dadmod_prop_scooter = { d = 170 h = 42 a = 4.0 }
dadmod_prop_robot = { d = 150 h = 38 a = 4.0 }
dadmod_prop_robot2 = { d = 160 h = 40 a = 4.0 }
dadmod_prop_chest = { d = 140 h = 36 a = 4.0 }
dadmod_prop_bike = { d = 190 h = 48 a = 3.8 }
dadmod_prop_mini = { d = 210 h = 50 a = 3.8 }
dadmod_prop_halfpipe = { d = 700 h = 170 a = 2.2 }
}
dadmod_c2_extra_map = {
dadmod_car_hearse = dadmod_car_hearse_setup
dadmod_car_woodie = dadmod_car_woodie_setup
dadmod_car_sedan = dadmod_car_sedan_setup
dadmod_car_smart = dadmod_car_smart_setup
dadmod_car_hippyvan = dadmod_car_hippyvan_setup
dadmod_car_benzvan = dadmod_car_benzvan_setup
dadmod_car_minivan = dadmod_car_minivan_setup
dadmod_car_oldvan = dadmod_car_oldvan_setup
dadmod_car_suv = dadmod_car_suv_setup
dadmod_car_rust = dadmod_car_rust_setup
dadmod_car_liberty = dadmod_car_liberty_setup
dadmod_car_bcntaxi = dadmod_car_bcntaxi_setup
dadmod_car_neon = dadmod_car_neon_setup
dadmod_car_dctruck = dadmod_car_dctruck_setup
dadmod_car_tourbus = dadmod_car_tourbus_setup
dadmod_car_atv = dadmod_car_atv_setup
dadmod_car_mardi = dadmod_car_mardi_setup
dadmod_car_duck = dadmod_car_duck_setup
dadmod_car_sub = dadmod_car_sub_setup
dadmod_car_streetcar = dadmod_car_streetcar_setup
dadmod_prop_cone = dadmod_prop_cone_setup
dadmod_prop_cart = dadmod_prop_cart_setup
dadmod_prop_scooter = dadmod_prop_scooter_setup
dadmod_prop_robot = dadmod_prop_robot_setup
dadmod_prop_robot2 = dadmod_prop_robot2_setup
dadmod_prop_chest = dadmod_prop_chest_setup
dadmod_prop_bike = dadmod_prop_bike_setup
dadmod_prop_mini = dadmod_prop_mini_setup
dadmod_prop_halfpipe = dadmod_prop_halfpipe_setup
}
dadmod_c2_push_map = {
JunkerCar = TransCarSetup
RallyCar = CustomCarSetup
ImpalaCar = ImpalaCarSetup
TaxiNY = TaxiNYSetup
PoliceCar = PoliceCarSetup
SecurityCart = SecurityCartSetup
GardnersCart = GardnersCartSetup
ElCaminoCar = ElCaminoCarSetup
Blimp = BlimpSetup
LadaCar = LadaCarSetup
MiniBajaCar = MiniBajaCarSetup
LimoCar = LimoCarSetup
Forklift = ForkliftSetup
RCCar = RCCarSetup
TaurusCar = TaurusCarSetup
PickupTruck = PickupTruckSetup
WranglerCar = WranglerCarSetup
SportsCar = SportsCarSetup
OffroadCar = OffroadCarSetup
dadmod_car_hearse = { model = "veh\\Veh_Hearse\\Veh_Hearse.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_woodie = { model = "veh\\Veh_Woodie\\Veh_Woodie.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_sedan = { model = "veh\\Veh_Sedan\\Veh_Sedan.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_smart = { model = "veh\\Veh_Smart_car\\Veh_Smart_Car.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_hippyvan = { model = "veh\\veh_HippyVan\\veh_HippyVan.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_benzvan = { model = "veh\\veh_Benz_Van\\veh_Benz_Van.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_minivan = { model = "veh\\Veh_Minivan\\Veh_Minivan.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_oldvan = { model = "veh\\Veh_OldVan\\Veh_OldVan.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_suv = { model = "veh\\Veh_SUV\\Veh_SUV.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_rust = { model = "veh\\veh_rust\\veh_rust.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_liberty = { model = "veh\\veh_liberty\\veh_liberty.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_bcntaxi = { model = "veh\\veh_barcelona_taxi\\veh_barcelona_taxi.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_neon = { model = "veh\\Veh_NeonType\\Veh_NeonType.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_dctruck = { model = "veh\\Veh_DCShoeTruck\\Veh_DCShoeTruck.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_tourbus = { model = "veh\\Veh_TourBus\\Veh_TourBus.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_atv = { model = "veh\\Veh_ATV\\Veh_ATV.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_mardi = { model = "veh\\Veh_Mardi\\Veh_Mardi.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_duck = { model = "veh\\Veh_Duck\\veh_duck.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_sub = { model = "veh\\veh_sub\\veh_sub.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_car_streetcar = { model = "veh\\veh_streetcar\\veh_streetcar.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_cone = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_cart = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_scooter = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_robot = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_robot2 = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_chest = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_bike = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_mini = { model = "veh\\Veh_SDKart_Security\\Veh_SDKart_Security.mdl" skater_pos = (0.0,0.0,0.0) }
dadmod_prop_halfpipe = { model = "veh\\veh_limo\\veh_limo.mdl" skater_pos = (0.0,0.0,0.0) }
}
dadmod_c2_sounds = {
dadmod_snd_JunkerCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_RallyCar = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_ImpalaCar = {
EngineSound = LowriderLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_PoliceCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 135
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_TaxiNY = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_SecurityCart = {
EngineSound = SD_CartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_GardnersCart = {
EngineSound = SD_CartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_ElCaminoCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_LadaCar = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 65
MaxEnginePitch = 135
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_MiniBajaCar = {
EngineSound = AU_KartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_LimoCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 105
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_TaurusCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_PickupTruck = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_WranglerCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_SportsCar = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 75
MaxEnginePitch = 160
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_Forklift = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_Blimp = {
EngineSound = SJ_BlimpEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_hearse = {
EngineSound = LowriderLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 105
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_woodie = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_sedan = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_smart = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_hippyvan = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_benzvan = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_minivan = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_oldvan = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_suv = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_rust = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_liberty = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_bcntaxi = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 65
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_neon = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 145
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_dctruck = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 100
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_tourbus = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 45
MaxEnginePitch = 95
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_atv = {
EngineSound = AU_KartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_mardi = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 100
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_duck = {
EngineSound = FerryEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_sub = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_streetcar = {
EngineSound = TramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_cone = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 90
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_cart = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 85
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_scooter = {
EngineSound = SK6_BA_Scooter_Engine
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_robot = {
EngineSound = ZooTramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_robot2 = {
EngineSound = ZooTramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_chest = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 80
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_bike = {
EngineSound = MotoIdle01
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 145
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_mini = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_halfpipe = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 95
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
}
dadmod_c2_car_sounds = {
JunkerCar = dadmod_snd_JunkerCar
RallyCar = dadmod_snd_RallyCar
ImpalaCar = dadmod_snd_ImpalaCar
PoliceCar = dadmod_snd_PoliceCar
TaxiNY = dadmod_snd_TaxiNY
SecurityCart = dadmod_snd_SecurityCart
GardnersCart = dadmod_snd_GardnersCart
ElCaminoCar = dadmod_snd_ElCaminoCar
LadaCar = dadmod_snd_LadaCar
MiniBajaCar = dadmod_snd_MiniBajaCar
LimoCar = dadmod_snd_LimoCar
TaurusCar = dadmod_snd_TaurusCar
PickupTruck = dadmod_snd_PickupTruck
WranglerCar = dadmod_snd_WranglerCar
SportsCar = dadmod_snd_SportsCar
Forklift = dadmod_snd_Forklift
Blimp = dadmod_snd_Blimp
dadmod_car_hearse = dadmod_snd_dadmod_car_hearse
dadmod_car_woodie = dadmod_snd_dadmod_car_woodie
dadmod_car_sedan = dadmod_snd_dadmod_car_sedan
dadmod_car_smart = dadmod_snd_dadmod_car_smart
dadmod_car_hippyvan = dadmod_snd_dadmod_car_hippyvan
dadmod_car_benzvan = dadmod_snd_dadmod_car_benzvan
dadmod_car_minivan = dadmod_snd_dadmod_car_minivan
dadmod_car_oldvan = dadmod_snd_dadmod_car_oldvan
dadmod_car_suv = dadmod_snd_dadmod_car_suv
dadmod_car_rust = dadmod_snd_dadmod_car_rust
dadmod_car_liberty = dadmod_snd_dadmod_car_liberty
dadmod_car_bcntaxi = dadmod_snd_dadmod_car_bcntaxi
dadmod_car_neon = dadmod_snd_dadmod_car_neon
dadmod_car_dctruck = dadmod_snd_dadmod_car_dctruck
dadmod_car_tourbus = dadmod_snd_dadmod_car_tourbus
dadmod_car_atv = dadmod_snd_dadmod_car_atv
dadmod_car_mardi = dadmod_snd_dadmod_car_mardi
dadmod_car_duck = dadmod_snd_dadmod_car_duck
dadmod_car_sub = dadmod_snd_dadmod_car_sub
dadmod_car_streetcar = dadmod_snd_dadmod_car_streetcar
dadmod_prop_cone = dadmod_snd_dadmod_prop_cone
dadmod_prop_cart = dadmod_snd_dadmod_prop_cart
dadmod_prop_scooter = dadmod_snd_dadmod_prop_scooter
dadmod_prop_robot = dadmod_snd_dadmod_prop_robot
dadmod_prop_robot2 = dadmod_snd_dadmod_prop_robot2
dadmod_prop_chest = dadmod_snd_dadmod_prop_chest
dadmod_prop_bike = dadmod_snd_dadmod_prop_bike
dadmod_prop_mini = dadmod_snd_dadmod_prop_mini
dadmod_prop_halfpipe = dadmod_snd_dadmod_prop_halfpipe
}
script dadmod_cars_load_sound
    LoadSound "Vehicles\\Vehicle_Tire_Loop"
    switch <c>
    case JunkerCar
        LoadSound "Shared\\Auto\\_8CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: JunkerCar engine _8CylinderEngineLoop (Shared/Auto/_8CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case RallyCar
        LoadSound "Shared\\Auto\\_4CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: RallyCar engine _4CylinderEngineLoop (Shared/Auto/_4CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case ImpalaCar
        LoadSound "Shared\\Auto\\LowriderLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: ImpalaCar engine LowriderLoop (Shared/Auto/LowriderLoop), tires Vehicle_Tire_Loop"
    case PoliceCar
        LoadSound "Shared\\Auto\\_8CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: PoliceCar engine _8CylinderEngineLoop (Shared/Auto/_8CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case TaxiNY
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: TaxiNY engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case SecurityCart
        LoadSound "SD\\SD_CartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: SecurityCart engine SD_CartLoop (SD/SD_CartLoop), tires Vehicle_Tire_Loop"
    case GardnersCart
        LoadSound "SD\\SD_CartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: GardnersCart engine SD_CartLoop (SD/SD_CartLoop), tires Vehicle_Tire_Loop"
    case ElCaminoCar
        LoadSound "Shared\\Auto\\_8CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: ElCaminoCar engine _8CylinderEngineLoop (Shared/Auto/_8CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case LadaCar
        LoadSound "Shared\\Auto\\MiniEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: LadaCar engine MiniEngineLoop (Shared/Auto/MiniEngineLoop), tires Vehicle_Tire_Loop"
    case MiniBajaCar
        LoadSound "AU\\AU_KartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: MiniBajaCar engine AU_KartLoop (AU/AU_KartLoop), tires Vehicle_Tire_Loop"
    case LimoCar
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: LimoCar engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case TaurusCar
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: TaurusCar engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case PickupTruck
        LoadSound "Shared\\Auto\\_8CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: PickupTruck engine _8CylinderEngineLoop (Shared/Auto/_8CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case WranglerCar
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: WranglerCar engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case SportsCar
        LoadSound "Shared\\Auto\\_4CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: SportsCar engine _4CylinderEngineLoop (Shared/Auto/_4CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case Forklift
        LoadSound "Shared\\Auto\\ParadeFloatEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: Forklift engine ParadeFloatEngineLoop (Shared/Auto/ParadeFloatEngineLoop), tires Vehicle_Tire_Loop"
    case Blimp
        LoadSound "SJ\\SJ_BlimpEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: Blimp engine SJ_BlimpEngineLoop (SJ/SJ_BlimpEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_hearse
        LoadSound "Shared\\Auto\\LowriderLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_hearse engine LowriderLoop (Shared/Auto/LowriderLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_woodie
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_woodie engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_sedan
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_sedan engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_smart
        LoadSound "Shared\\Auto\\MiniEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_smart engine MiniEngineLoop (Shared/Auto/MiniEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_hippyvan
        LoadSound "Shared\\Auto\\CarLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_hippyvan engine CarLoop (Shared/Auto/CarLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_benzvan
        LoadSound "Shared\\Auto\\UKBusEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_benzvan engine UKBusEngineLoop (Shared/Auto/UKBusEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_minivan
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_minivan engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_oldvan
        LoadSound "Shared\\Auto\\CarLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_oldvan engine CarLoop (Shared/Auto/CarLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_suv
        LoadSound "Shared\\Auto\\_8CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_suv engine _8CylinderEngineLoop (Shared/Auto/_8CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_rust
        LoadSound "Shared\\Auto\\CarLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_rust engine CarLoop (Shared/Auto/CarLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_liberty
        LoadSound "Shared\\Auto\\_6CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_liberty engine _6CylinderEngineLoop (Shared/Auto/_6CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_bcntaxi
        LoadSound "Shared\\Auto\\_4CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_bcntaxi engine _4CylinderEngineLoop (Shared/Auto/_4CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_neon
        LoadSound "Shared\\Auto\\_4CylinderEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_neon engine _4CylinderEngineLoop (Shared/Auto/_4CylinderEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_dctruck
        LoadSound "Shared\\Auto\\UKBusEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_dctruck engine UKBusEngineLoop (Shared/Auto/UKBusEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_tourbus
        LoadSound "Shared\\Auto\\UKBusEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_tourbus engine UKBusEngineLoop (Shared/Auto/UKBusEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_atv
        LoadSound "AU\\AU_KartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_atv engine AU_KartLoop (AU/AU_KartLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_mardi
        LoadSound "Shared\\Auto\\ParadeFloatEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_mardi engine ParadeFloatEngineLoop (Shared/Auto/ParadeFloatEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_duck
        LoadSound "Shared\\Misc\\FerryEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_duck engine FerryEngineLoop (Shared/Misc/FerryEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_sub
        LoadSound "Shared\\Auto\\UKBusEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_sub engine UKBusEngineLoop (Shared/Auto/UKBusEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_car_streetcar
        LoadSound "Shared\\Auto\\TramEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_car_streetcar engine TramEngineLoop (Shared/Auto/TramEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_cone
        LoadSound "BO\\ShoppingCartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_cone engine ShoppingCartLoop (BO/ShoppingCartLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_cart
        LoadSound "BO\\ShoppingCartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_cart engine ShoppingCartLoop (BO/ShoppingCartLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_scooter
        LoadSound "Vehicles\\SK6_BA_Scooter_Engine" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_scooter engine SK6_BA_Scooter_Engine (Vehicles/SK6_BA_Scooter_Engine), tires Vehicle_Tire_Loop"
    case dadmod_prop_robot
        LoadSound "Shared\\Auto\\ZooTramEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_robot engine ZooTramEngineLoop (Shared/Auto/ZooTramEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_robot2
        LoadSound "Shared\\Auto\\ZooTramEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_robot2 engine ZooTramEngineLoop (Shared/Auto/ZooTramEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_chest
        LoadSound "BO\\ShoppingCartLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_chest engine ShoppingCartLoop (BO/ShoppingCartLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_bike
        LoadSound "Terrains\\MotoX\\MotoIdle01" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_bike engine MotoIdle01 (Terrains/MotoX/MotoIdle01), tires Vehicle_Tire_Loop"
    case dadmod_prop_mini
        LoadSound "Shared\\Auto\\MiniEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_mini engine MiniEngineLoop (Shared/Auto/MiniEngineLoop), tires Vehicle_Tire_Loop"
    case dadmod_prop_halfpipe
        LoadSound "Shared\\Auto\\ParadeFloatEngineLoop" vol = 100 dropoff = 150 PosUpdateWithDoppler
        THUGRECOMP_Log text = "cars2: dadmod_prop_halfpipe engine ParadeFloatEngineLoop (Shared/Auto/ParadeFloatEngineLoop), tires Vehicle_Tire_Loop"
    default
        THUGRECOMP_Log text = "cars2: no engine sound entry for this car"
    endswitch
endscript
script dadmod_cars_boot_maps
    Change VehicleSetupMapping = {
JunkerCar = TransCarSetup
RallyCar = CustomCarSetup
ImpalaCar = ImpalaCarSetup
TaxiNY = TaxiNYSetup
PoliceCar = PoliceCarSetup
SecurityCart = SecurityCartSetup
GardnersCart = GardnersCartSetup
ElCaminoCar = ElCaminoCarSetup
Blimp = BlimpSetup
LadaCar = LadaCarSetup
MiniBajaCar = MiniBajaCarSetup
LimoCar = LimoCarSetup
Forklift = ForkliftSetup
RCCar = RCCarSetup
TaurusCar = TaurusCarSetup
PickupTruck = PickupTruckSetup
WranglerCar = WranglerCarSetup
SportsCar = SportsCarSetup
OffroadCar = OffroadCarSetup
dadmod_car_hearse = dadmod_car_hearse_setup
dadmod_car_woodie = dadmod_car_woodie_setup
dadmod_car_sedan = dadmod_car_sedan_setup
dadmod_car_smart = dadmod_car_smart_setup
dadmod_car_hippyvan = dadmod_car_hippyvan_setup
dadmod_car_benzvan = dadmod_car_benzvan_setup
dadmod_car_minivan = dadmod_car_minivan_setup
dadmod_car_oldvan = dadmod_car_oldvan_setup
dadmod_car_suv = dadmod_car_suv_setup
dadmod_car_rust = dadmod_car_rust_setup
dadmod_car_liberty = dadmod_car_liberty_setup
dadmod_car_bcntaxi = dadmod_car_bcntaxi_setup
dadmod_car_neon = dadmod_car_neon_setup
dadmod_car_dctruck = dadmod_car_dctruck_setup
dadmod_car_tourbus = dadmod_car_tourbus_setup
dadmod_car_atv = dadmod_car_atv_setup
dadmod_car_mardi = dadmod_car_mardi_setup
dadmod_car_duck = dadmod_car_duck_setup
dadmod_car_sub = dadmod_car_sub_setup
dadmod_car_streetcar = dadmod_car_streetcar_setup
dadmod_prop_cone = dadmod_prop_cone_setup
dadmod_prop_cart = dadmod_prop_cart_setup
dadmod_prop_scooter = dadmod_prop_scooter_setup
dadmod_prop_robot = dadmod_prop_robot_setup
dadmod_prop_robot2 = dadmod_prop_robot2_setup
dadmod_prop_chest = dadmod_prop_chest_setup
dadmod_prop_bike = dadmod_prop_bike_setup
dadmod_prop_mini = dadmod_prop_mini_setup
dadmod_prop_halfpipe = dadmod_prop_halfpipe_setup
}
    Change PlayerVehicleSounds = {
#"Default" = {
EngineSound = CarLoop
MinEngineVol = 150
MaxEngineVol = 180
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 50
BottomRPM = 60
TopRPM = 100
}
{
DownshiftPoint = 10
UpshiftPoint = 75
BottomRPM = 40
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 100
BottomRPM = 20
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
SE_ATV = {
EngineSound = CarLoop
MinEngineVol = 150
MaxEngineVol = 180
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 50
BottomRPM = 60
TopRPM = 100
}
{
DownshiftPoint = 10
UpshiftPoint = 75
BottomRPM = 40
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 100
BottomRPM = 20
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
NY_JunkCar = {
EngineSound = CarLoop
MinEngineVol = 150
MaxEngineVol = 180
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 50
BottomRPM = 60
TopRPM = 100
}
{
DownshiftPoint = 10
UpshiftPoint = 75
BottomRPM = 40
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 100
BottomRPM = 20
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
BO_Gurney = {
EngineSound = ShoppingCartLoop
MinEngineVol = 0
MaxEngineVol = 80
MinEnginePitch = 80
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 1
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 200
}
BO_Segway = {
EngineSound = SK6_BO_JesseRide_Loop
MinEngineVol = 150
MaxEngineVol = 180
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 100
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
BA_SteveOBull = {
EngineSound = SK6_BA_SteveOElecLoop
MinEngineVol = 0
MaxEngineVol = 70
MinEnginePitch = 50
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 100
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
BE_PaulieWheelchair = {
EngineSound = SK6_BE_Paulie_Loop
MinEngineVol = 0
MaxEngineVol = 70
MinEnginePitch = 50
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 100
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
AU_AborigineCart = {
EngineSound = AU_KartLoop
MinEngineVol = 90
MaxEngineVol = 120
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 100
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
NO_Trike = {
EngineSound = SK6_NO_TrikeSqueak
MinEngineVol = 0
MaxEngineVol = 70
MinEnginePitch = 50
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 100
BottomRPM = 0
TopRPM = 100
}
]
TireSound = Silent_Vehicle_Tire_Loop
FullTireSlipVelocity = 1500
MinTireVol = 0
MaxTireVol = 300
MinTirePitch = 80
MaxTirePitch = 100
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_JunkerCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_RallyCar = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_ImpalaCar = {
EngineSound = LowriderLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_PoliceCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 135
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_TaxiNY = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_SecurityCart = {
EngineSound = SD_CartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_GardnersCart = {
EngineSound = SD_CartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_ElCaminoCar = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_LadaCar = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 65
MaxEnginePitch = 135
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_MiniBajaCar = {
EngineSound = AU_KartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_LimoCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 105
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_TaurusCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_PickupTruck = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_WranglerCar = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_SportsCar = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 75
MaxEnginePitch = 160
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_Forklift = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_Blimp = {
EngineSound = SJ_BlimpEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_hearse = {
EngineSound = LowriderLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 105
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_woodie = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_sedan = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_smart = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_hippyvan = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_benzvan = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_minivan = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_oldvan = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 55
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_suv = {
EngineSound = #"_8CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_rust = {
EngineSound = CarLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_liberty = {
EngineSound = #"_6CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 125
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_bcntaxi = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 65
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_neon = {
EngineSound = #"_4CylinderEngineLoop"
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 145
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_dctruck = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 100
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_tourbus = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 45
MaxEnginePitch = 95
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_atv = {
EngineSound = AU_KartLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_mardi = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 100
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_duck = {
EngineSound = FerryEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_sub = {
EngineSound = UKBusEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_car_streetcar = {
EngineSound = TramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 60
MaxEnginePitch = 110
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_cone = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 90
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_cart = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 85
MaxEnginePitch = 120
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_scooter = {
EngineSound = SK6_BA_Scooter_Engine
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 150
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_robot = {
EngineSound = ZooTramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 80
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_robot2 = {
EngineSound = ZooTramEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 130
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_chest = {
EngineSound = ShoppingCartLoop
MinEngineVol = 40
MaxEngineVol = 110
MinEnginePitch = 80
MaxEnginePitch = 115
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_bike = {
EngineSound = MotoIdle01
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 145
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_mini = {
EngineSound = MiniEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 70
MaxEnginePitch = 140
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
dadmod_snd_dadmod_prop_halfpipe = {
EngineSound = ParadeFloatEngineLoop
MinEngineVol = 120
MaxEngineVol = 190
MinEnginePitch = 50
MaxEnginePitch = 95
MinEngineRPM = 0
MaxEngineRPM = 100
Gears = [
{
DownshiftPoint = 0
UpshiftPoint = 35
BottomRPM = 30
TopRPM = 100
}
{
DownshiftPoint = 25
UpshiftPoint = 60
BottomRPM = 45
TopRPM = 100
}
{
DownshiftPoint = 50
UpshiftPoint = 82
BottomRPM = 55
TopRPM = 100
}
{
DownshiftPoint = 72
UpshiftPoint = 100
BottomRPM = 60
TopRPM = 100
}
]
TireSound = Vehicle_Tire_Loop
FullTireSlipVelocity = 1100
MinTireVol = 0
MaxTireVol = 220
MinTirePitch = 85
MaxTirePitch = 110
CollideSound = { BonkMetal_11 minVol = 100 MaxVel = 300 minPitch = 80 maxPitch = 120 }
FullCollision = 5000
}
}
endscript
dadmod_c2_physfix = {
SportsCar = {
mass = 4400
moment_of_inertia = (40000000.0,5600000.0,40000000.0)
suspension_center_of_mass = (0.0,-22.0,30.0)
colliders = [
[
(36.0,26.0,125.0)
(-36.0,26.0,125.0)
(36.0,26.0,-35.0)
]
[
(26.0,44.0,70.0)
(-26.0,44.0,70.0)
(26.0,44.0,0.0)
]
]
body_restitution = 0.2
body_friction = 0.2
body_wipeout_friction = 0.4
body_spring = 1200
collision_control = 0.3
max_steering_angle = 38
constant_rotational_damping = 200000
quadratic_rotational_damping = 0.0001
in_air_slerp_strength = 8
in_air_slerp_time_delay = 0.3
engine = {
drive_torque = 600
drag_torque = 600
upshift_rpm = 6000
differential_ratio = 5
reverse_torque_ratio = 1
gear_ratios = [ 4.2 3 1.8 0.9 0 ]
}
all_wheels = {
radius = 11
moment = 3570
spring_rate = 455
damping_rate = 60
static_friction = 2.6
min_static_grip_velocity = 4
max_static_grip_velocity = 8
min_dynamic_grip_velocity = 18
handbrake_torque = 4000
brake_torque = 2930
}
Wheels = [
{
max_draw_y_offset = -25
steering = left
drive = No
brake_torque = 3200
dynamic_friction = 2.6
handbrake_throttle_friction = 2.2
handbrake_locked_friction = 2.2
}
{
max_draw_y_offset = -25
steering = right
drive = No
brake_torque = 3200
dynamic_friction = 2.6
handbrake_throttle_friction = 2.2
handbrake_locked_friction = 2.2
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
brake_torque = 2130
dynamic_friction = 1.5
handbrake_throttle_friction = 1.2
handbrake_locked_friction = 1.0
}
{
max_draw_y_offset = -21
steering = fixed
drive = Yes
brake_torque = 2130
dynamic_friction = 1.5
handbrake_throttle_friction = 1.2
handbrake_locked_friction = 1.0
}
]
}
}
script dadmod_cars_extra_items
    dadmod_cars_item_x t = "Hearse" c = dadmod_car_hearse
    dadmod_cars_item_x t = "Woodie Wagon" c = dadmod_car_woodie
    dadmod_cars_item_x t = "Sedan" c = dadmod_car_sedan
    dadmod_cars_item_x t = "Smart Car" c = dadmod_car_smart
    dadmod_cars_item_x t = "Hippie Van" c = dadmod_car_hippyvan
    dadmod_cars_item_x t = "Delivery Van" c = dadmod_car_benzvan
    dadmod_cars_item_x t = "Minivan" c = dadmod_car_minivan
    dadmod_cars_item_x t = "Old Van" c = dadmod_car_oldvan
    dadmod_cars_item_x t = "SUV" c = dadmod_car_suv
    dadmod_cars_item_x t = "Rust Bucket" c = dadmod_car_rust
    dadmod_cars_item_x t = "Liberty" c = dadmod_car_liberty
    dadmod_cars_item_x t = "Barcelona Taxi" c = dadmod_car_bcntaxi
    dadmod_cars_item_x t = "Neon" c = dadmod_car_neon
    dadmod_cars_item_x t = "Box Truck" c = dadmod_car_dctruck
    dadmod_cars_item_x t = "Tour Bus" c = dadmod_car_tourbus
    dadmod_cars_item_x t = "ATV" c = dadmod_car_atv
    dadmod_cars_item_x t = "Parade Float" c = dadmod_car_mardi
    dadmod_cars_item_x t = "Duck Boat" c = dadmod_car_duck
    dadmod_cars_item_x t = "Submarine" c = dadmod_car_sub
    dadmod_cars_item_x t = "Streetcar" c = dadmod_car_streetcar
endscript
script dadmod_cars_prop_items
    dadmod_cars_item_x t = "Traffic Cone" c = dadmod_prop_cone
    dadmod_cars_item_x t = "Shopping Cart" c = dadmod_prop_cart
    dadmod_cars_item_x t = "Scooter" c = dadmod_prop_scooter
    dadmod_cars_item_x t = "Small Robot" c = dadmod_prop_robot
    dadmod_cars_item_x t = "Robot 2" c = dadmod_prop_robot2
    dadmod_cars_item_x t = "Treasure Chest" c = dadmod_prop_chest
    dadmod_cars_item_x t = "Copper Bike" c = dadmod_prop_bike
    dadmod_cars_item_x t = "Mini Car" c = dadmod_prop_mini
    dadmod_cars_item_x t = "Half Pipe" c = dadmod_prop_halfpipe
endscript
