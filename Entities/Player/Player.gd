extends Node2D

#External classes
var bodyPrefab = preload("res://Entities/Player/Body.tscn")

#Control
var left = false
var right = false
var slowDown = false
var up = false
var growButton = false
var canGrow = true

#Movement Attributes
var maxSpeed = 7
var normalSpeed = 3
var minSpeed = 1
var torque = 6
var speedPhase = 1

#GUI
var minEnergyValue = 5
var maxEnergyValue = 50
var currentEnergy = 0

var blood = 0
var humans = 0
var robots = 0

#Code control
var tired = false
var dead = true

func _ready():
	$Mouth/Mouth/MouthAnimation.get_animation("Mouth").set_loop(true)
	$Mouth/Mouth/MouthAnimation.play("Mouth")
	$Mouth.setPlayer(self)
	currentEnergy = maxEnergyValue
	$Head.setBodies(self, $Mouth, $Body)
	$Body.setBodies(self, $Head, $Tail)
	$Tail.setBodies(self, $Body, null)

func letsStart():
	dead = false

func _physics_process(delta):
	if dead:
		return
	#Keyboard input update
	get_input()
	#Regarding the angle we get the normalised speed (adjusted to one, cause we will increase it depending on the speed)
	var vel = Vector2(sin($Mouth.rotation), -cos($Mouth.rotation)).normalized()
	if up && !tired && currentEnergy > minEnergyValue:
		vel = vel*maxSpeed
		speedPhase = 2
		currentEnergy -= 1
	elif slowDown && !tired && currentEnergy > minEnergyValue:
		vel = vel*minSpeed
		speedPhase = 0
		currentEnergy -= 1
	else:
		vel = vel*normalSpeed
		speedPhase = 1
		currentEnergy += 1
		if currentEnergy > maxEnergyValue:
			currentEnergy = maxEnergyValue
	if currentEnergy == minEnergyValue:
		$SpeedCooldown.start()
		tired = true
	if growButton:
		grow()
	#Because we are playing with the orientation to calculate the speed, we will rotate the head to calculate the new speed direction
	if right:
		$Mouth.rotation_degrees+=torque
	elif left:
		$Mouth.rotation_degrees-=torque
	
	#Update GUI
	get_parent().get_node("GUI").updateGUI(currentEnergy, tired, blood, humans, robots, getPoints())
	
	#If we collide either we lost or we ate something
	var collisionObject = $Mouth.move_and_collide(vel)
	if(collisionObject != null):
		print(collisionObject.get_collider().get_name())
		var enemyType = collisionObject.get_collider()
		if "Enemy" in enemyType.get_name():
			enemyType.die()
			eatHuman()
		elif "Sentry" in enemyType.get_name():
			enemyType.die()
			eatRobot()
		elif "CollisionLayer" in enemyType.get_name():
			die()
		
	updateBody()

func get_input():
	left = Input.is_action_pressed("ui_left")
	right = Input.is_action_pressed("ui_right")
	slowDown = Input.is_action_pressed("ui_down")
	up = Input.is_action_pressed("ui_up")
	
	
func canGrowAgain():
	canGrow = true

func _on_SpeedCooldown_timeout():
	tired = false

func updateBody():
	$Tail.updateBody()

func grow(number):
	if canGrow:
		$WaitUntilNewGrouth.start()
		canGrow = false
		for n in number:
			_grow()
		
func _grow():
	var body = bodyPrefab.instance()
	#We need to call Body all the bodies so we can easily identify them
	body.set_name("Body")
	$Tail.player.add_child(body)
	
	var prevBody = $Tail.previous
	body.setBodies(self, prevBody, $Tail)
	#Dirty temporal fix
	body.global_position.x = 10000
	prevBody.setNext(body)
	$Tail.setBodies(self, body, null)

func eatBlood():
	blood += 1
	grow(1)

func eatHuman():
	humans += 1
	grow(4)

func eatRobot():
	robots += 1
	maxEnergyValue += 5
	grow(8)

func getPoints():
	return blood + 2*robots + 4*humans

func startTimer():
	$Start.stop()
	$Start.start()

func die():
	dead = true
	get_parent().get_node("GUI").showMainMenu()
	get_tree().paused = true
	self.queue_free()