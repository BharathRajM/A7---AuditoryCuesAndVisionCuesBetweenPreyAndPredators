extensions [array vid]
globals
[
  dir
  val
  flock-color-list
  tick-counter
  flock-lifetime-counter
  record
]

breed [ preys prey ]
breed [ flock-holders flock-holder ] ; A placeholder entity that stores flock data and can be queried easily with certain functions

preys-own [
  flockmates ;; set of all nearby fishes
  nearest-neighbor ;;neares neighbor of flock
  speed ;;
  delay-list
  is-in-flock ; simple boolean variable that is used to determine if the turtle is in a flock
  flock-reference ; variable that references the flock-holder to which this turtle belongs
]


flock-holders-own [
  flock-members
  flock-color
  creation-time
]

to setup
  clear-all
  set record False ; For use when recording a video with netlogo
  set flock-lifetime-counter [] ; sets up a list variable to record flock lifetimes when they disperse
  set flock-color-list ( list grey orange brown yellow green lime turquoise cyan sky violet magenta pink ) ; sets up a list of appropriate flock colours
  create-preys population ; creates flocking turtles
  [
    set size 1
    set color blue
    setxy random-xcor random-ycor
    set speed 0.5
    set delay-list array:from-list n-values 100 [0]
    set is-in-flock False
  ]

  set tick-counter 0 ; sets the tick counter variable
  reset-ticks
  if record ; if recording, initialize the recorder and get some initial-state frames
  [
    if not ( vid:recorder-status = "recording" )
    [
      ( vid:start-recorder 640 480 )
    ]
    repeat 30
    [
      vid:record-view
    ]
  ]
end

to go
  if record and ( vid:recorder-status = "recording" ) ;capture current frame if recording
  [
    vid:record-view
  ]
  set tick-counter ( tick-counter + 1 ) ; increase global tick counter variable
  ask flock-holders with [ count flock-members = 0 ] [ die ] ; ask flock-holders with no members to die
  ifelse flock-color-on ; sets the colors of the turtles appropriately
  [
    if count flock-holders > 0
    [
      ask flock-holders
      [
        ifelse flock-color-on
        [
          ask flock-members [ set color ( [ flock-color ] of myself ) ]
        ]
        [
          ask flock-members [ set color blue ]
        ]
      ]
    ]
    ask preys with [ is-in-flock = False ] [ set color blue ]
  ]
  [ ask preys [ set color blue ] ]
  ask preys
  [
    flock ; basic flocking behaviour
    add-error      ;;add some random noise to the flock
    evaluate-flock ; runs the flock-evaluation method
  ]

  ask preys [ fd speed ] ; turtles move forward

  tick
  if record and tick-counter = 1000 ; saves the video after 1000 ticks and stops recording
  [
    vid:save-recording "demo-video-no-latency.mp4"
    vid:reset-recorder
  ]
  ;if tick-counter = 1000 [ stop ] ; uncomment this line if you want to end the simulation after a certain number of ticks
end

to flock
  find-flockmates ; find nearby flockmates
  if any? flockmates
  [
    find-nearest-neighbor
    ;;should test this
    ;; nearest neighbor in cone radius-vision and angle-field_of_view
    if any? preys in-cone vision fov
    [
      ifelse distance nearest-neighbor < minimum-separation
      [separate]
      [align
        cohere]

      adjust-prey-speed
    ]
  ]
end

to evaluate-flock
  if flock-reference = Nobody [ set is-in-flock False ] ; make sure anything not in a flock doesn't think it is in a flock
  if is-in-flock = True ; checking to see if a flock has died out
  [
    if get-flock-size flock-reference < 2 ; is the turtle the only one in the flock?
    [
      if verbose = True [ print "Flock has dwindled to nothing" ]
      ask flock-reference ; has no more members, so is removed.
      [
        ask flock-members
        [
          set flock-reference nobody ; clear any remaining flock members of association with this flock
          set is-in-flock False
        ]
        let lifetime ( tick-counter - creation-time )
        set flock-lifetime-counter insert-item 0 flock-lifetime-counter lifetime
        die
      ]
      set is-in-flock False ; no longer in a flock
    ]
  ]
  if is-in-flock = True
  [
    let x-cord item 0 ( flock-center flock-reference )
    let y-cord item 1 ( flock-center flock-reference )
    if ( distancexy x-cord y-cord ) > ( vision * flock-detection-range) or subtract-headings ( average-schoolmate-heading ( [ flock-members ] of flock-reference ) ) heading > 60; checking to see if turtle has splintered from rest of flock, if so, remove it from the flock
    [
      ask other preys in-radius 1 with [ flock-reference = [ flock-reference ] of myself ]
      [
        if ( distancexy ( item 0 ( flock-center flock-reference ) ) ( item 1 ( flock-center flock-reference ) ) ) > ( vision * flock-detection-range) or subtract-headings ( average-schoolmate-heading ( [ flock-members ] of flock-reference ) ) heading > flock-max-angle-devation
        [
          if verbose = True [ type "Turtle " type [ who ] of self print " has strayed from the flock" ]
          ask flock-reference [ remove-from-flock myself ]; remove myself from my old flock
          set flock-reference nobody
          set is-in-flock False
        ]
      ]
      if verbose = True [ type "Turtle " type [ who ] of self print " has strayed from the flock" ]
      ask flock-reference [ remove-from-flock myself ]; remove myself from my old flock
      set flock-reference nobody
      set is-in-flock False
    ]
  ]
  ifelse is-in-flock = True ; is turtle in a flock?
  [
    if verbose = True [ type "Turtle " type [ who ] of self type "is in flock " print [ who ] of [ flock-reference ] of self ]
    if any? other preys in-radius vision with [ is-in-flock = True ] with [ flock-reference != [ flock-reference ] of myself ]; check for nearby turtles that are in different flocks
    [
      if verbose = True [ print "There are other nearby flocks" ]
      let current-school-size ( get-flock-size [ flock-reference ] of self )
      if verbose = True [ type "I am part of a school of " print current-school-size ]
      let temp-list turtle-set other preys in-radius vision with [ is-in-flock = True ] with [ flock-reference != [ flock-reference ] of myself ] with [ ( get-flock-size flock-reference ) >= current-school-size ] with [ subtract-headings ( average-schoolmate-heading [ flock-members ] of flock-reference ) heading < 60]; are any nearby turtles in different, larger flocks that I am alligned with? if so, add them to a list
      if count temp-list > 0 ; does the list have any members?
      [
        if verbose = True [ print "Found a bigger flock" ]
        ask flock-reference [ remove-from-flock myself ]; remove myself from my old flock
        set flock-reference [ flock-reference ] of ( max-one-of temp-list [ get-flock-size flock-reference ] ); join the biggest flock on this list
        ask flock-reference [ add-to-flock myself ] ; add myself to the new flock
        set is-in-flock True ; sets it to true in case it wasn't for some reason.
      ]
    ]
  ]
  [
    if verbose = True [ type "Turtle " type [ who ] of self print " is not in a flock" ]
    ifelse any? other preys in-radius vision with [ is-in-flock = True ] ; are there any pre-existing flocks the turtle can join?
    [
      if verbose = True [ print "There are nearby flocks" ]
      let potential-flock turtle-set other preys in-radius vision with [ is-in-flock = True ] ; grab any nearby turtles that are already in a flock
      set potential-flock potential-flock with [ flock-reference != Nobody ]
      set potential-flock potential-flock with [ subtract-headings ( average-schoolmate-heading ( [ flock-members ] of flock-reference ) ) heading < 60]; remove any that are not aligned with this turtle
      if count potential-flock > 0
      [
        if verbose = True [ print "There are nearby flocks that I am aligned with" ]
        set flock-reference [ flock-reference ] of ( max-one-of potential-flock [ get-flock-size flock-reference ] ); join the biggest flock on this list
        ask flock-reference [ add-to-flock myself ] ; add myself to the new flock
        set is-in-flock True ; turtle is now in a flock
      ]
    ]
    [ ; if there are no pre-existing flocks, turtle starts its own
      let potential-flock turtle-set other preys in-radius vision with [ is-in-flock = False ] ; Grab any nearby turtles not already in a flock
      set potential-flock potential-flock with [ subtract-headings ( average-schoolmate-heading potential-flock ) heading < 60]; remove any that that are not aligned with this turtle
      if count potential-flock > 0
      [
        if visualize-flock-creation = True
        [
          set color green
          ask potential-flock [ set color green ]
          wait 0.25
          set color blue
          ask potential-flock [ set color blue ]
        ]
        if verbose = True [ type "Number of nearby potential flockmates " print count potential-flock ]
        hatch-flock-holders 1 ; create a new flock-holder
        [
          set size 0
          set color black ; sets the new flock's placeholder color to the background
          set flock-color one-of flock-color-list ; sets the flock colors
          set flock-members potential-flock ; adds the list of members to the new flock
          set creation-time tick-counter
          ask flock-members
          [
            set flock-reference myself ; asks the new flock members to add the new flock as their flock-reference
            set is-in-flock True ; all these turtles are now in a flock
          ]
        ]
      ]
    ]
  ]
end

to adjust-prey-speed
  ;;If the schoolmate is moving faster then speed up or else go back to speed .1
  ifelse max [speed] of flockmates > speed + .1
  [ set speed speed + .1] ;;speed up if any flockmate is moving faster
  [ if speed > min-speed
    [ set speed .1 ] ]
end

to find-flockmates
  ;; finds the fishes in the given radius of patches
  set flockmates other preys in-radius vision
end

to find-nearest-neighbor
  ;; finds the nearest neighbour
  set nearest-neighbor min-one-of flockmates [distance myself]
end

to separate
  ;; if there is a nearest neighbor in the flock in the 60degree field of view withini the minimum separation distance
  ;; then slow this turtle down or turn
  ifelse member? nearest-neighbor flockmates in-cone minimum-separation 60
  [
    if speed > min-speed
    [set speed speed - .1 ] ;;set speed speed - .1]
  ]
  [ rt cap-value ( ( separate-coefficient / 100 ) * ( subtract-headings heading ( towards nearest-neighbor ) ) ) ( max-turn * -1 ) max-turn ;;turns away from nearest neighbor
  ]
end

to align
  ;;turtle procedure where it almost goes near it's flockmate but never touches it
  set-delay cap-value ( (align-coefficient / 100) * (subtract-headings ( average-schoolmate-heading flockmates ) heading ) ) ( max-turn * -1 ) max-turn ;; asmpytotic approach to perfect alignment
  rt get-delay latency
end

;;to add noise to the flock
to add-error
  ;; adds error to the heading
  let err (-0.5 + random-float 1) * Noise
  set heading heading + err;
end

to remove-from-flock [ target ] ; removes a turtle from a flock-holder's flock-member list
  set flock-members flock-members with [ self != target ]
end

to add-to-flock [ target ] ; adds a turtle to a flock-holder's flock-member list
  set flock-members ( turtle-set flock-members target )
end

to set-delay [ value ]
  ;Adds a delay to reaction time by storing the desired heading in an array
  ;This function shifts all of the values in this array over by 1
  ;then adds the latest input to the top of the array
  ;This occurs every tick, meaning each element of the array is an older input
  let i ( latency )
  while [ i > -1 ]
  [
    ifelse i != 0
    [
      array:set delay-list i ( array:item delay-list ( i - 1 ) )
    ]
    [
    array:set delay-list i value
    ]
    set i ( i - 1 )
  ]
end

to-report get-delay [ delay-value ]
  ;This function pulls an input value from the array of delayed inputs at a specified delay value
  ;Effectively, this pulls the input value from (delay-value) ticks ago out of the array
  report array:item delay-list delay-value
end

to-report average-flock-heading-deviation
  ;; averages the difference in heading of turtles in the flock from the average heading of the flock
  let average-flock-heading average-schoolmate-heading flock-members
  let sum-deviation sum [ subtract-headings heading average-flock-heading ] of flock-members
  report ( sum-deviation / ( count flock-members ) )
end

to-report get-flock-size [ flock-ref ] ; counts number of members in a flock
  if flock-ref = nobody [ report 0 ]
  ask flock-ref
  [
    set val count flock-members
  ]
  report val
end

to-report average-schoolmate-heading [ schoolmates ] ; determines the average heading of all members in a flock
  ;;This is a function to help align, but is used for reporting data as well
  let x-component sum [dx] of schoolmates
  let y-component sum [dy] of schoolmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

to cohere
  ;; asymptotic approach to center the pack
  rt cap-value ( ( cohere-coefficient / 100 ) * ( subtract-headings average-heading-towards-flockmates heading ) ) ( max-turn * -1 ) max-turn
end

to-report average-heading-towards-flockmates
  ;;This is helpful to cohere
  let x-component mean [sin (towards myself + 180)] of flockmates
  let y-component mean [cos (towards myself + 180)] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

to-report flock-center [ flock-ref ] ; determines the approximate center of a flock
  let x-cord mean [ xcor ] of [ flock-members ] of flock-ref
  let y-cord mean [ ycor ] of [ flock-members ] of flock-ref
  report ( list x-cord y-cord )
end

to-report average-distance-from-flockmates [ schoolmates ] ; determines the average distance between a turtle and an agent set of turtles
  let turtle-list [ self ] of schoolmates
  let value 0
  foreach ( range count schoolmates )
  [
    x -> set value ( value + ( distance ( item x turtle-list ) ) )
  ]
  set value ( value / ( count schoolmates ) )
  report value
end

to-report average-flock-spread [ schoolmates ] ; determines the average distance between all turtles in an agentset
  let value 0
  ask schoolmates
  [
    set value ( value + ( average-distance-from-flockmates ( other schoolmates ) ) )
  ]
  set value ( value / ( count schoolmates ) )
  report value
end

to-report cap-value [ value minval maxval ] ; standard capping function, returns the value as long as it is within a threshold, otherwise returns the maximum or minimum threshold value
  ifelse value > maxval
  [
    report maxval
  ]
  [
    if value < minval
    [
      report minval
    ]
    report value
  ]
end

to-report flock-velocity ; determines the average speed of a flock
  if count flock-members = 0 [ report 0 ]
  let x-cord mean [ dx * speed ] of flock-members
  let y-cord mean [ dy * speed ] of flock-members
  let result ( sqrt ( ( x-cord ^ 2 ) + ( y-cord ^ 2 ) ) )
  report result
end

to-report average-flock-lifetime ; reports the average flock lifetime
  ifelse empty? flock-lifetime-counter [ report 0 ] [ report mean flock-lifetime-counter ]
end

to-report average-flock-size ; reports the average flock size
  let result mean ( [ count flock-members ] of flock-holders )
  report result
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
740
541
-1
-1
12.732
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
111
16
174
49
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
24
17
88
50
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
21
145
193
178
population
population
0
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
22
271
194
304
Noise
Noise
0
100
8.0
1
1
Degrees
HORIZONTAL

SLIDER
20
359
192
392
fov
fov
0
360
205.0
1
1
Degrees
HORIZONTAL

SLIDER
21
226
193
259
latency
latency
0
99
0.0
1
1
ticks
HORIZONTAL

BUTTON
24
72
87
105
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
19
411
191
444
vision
vision
1
15
3.0
1
1
patches
HORIZONTAL

SLIDER
19
455
200
488
minimum-separation
minimum-separation
0
5
1.0
0.25
1
patches
HORIZONTAL

SLIDER
21
318
193
351
min-speed
min-speed
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
20
578
192
611
separate-coefficient
separate-coefficient
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
19
498
191
531
align-coefficient
align-coefficient
1
50
30.0
1
1
NIL
HORIZONTAL

SLIDER
19
539
191
572
cohere-coefficient
cohere-coefficient
1
30
10.0
1
1
NIL
HORIZONTAL

MONITOR
1182
74
1290
119
Number of Flocks
count flock-holders
0
1
11

SWITCH
758
35
939
68
visualize-flock-creation
visualize-flock-creation
1
1
-1000

SWITCH
759
75
862
108
verbose
verbose
1
1
-1000

SWITCH
763
450
894
483
flock-color-on
flock-color-on
0
1
-1000

MONITOR
1155
23
1266
68
Largest Flock Size
count [ flock-members ] of max-one-of flock-holders [ count flock-members ]
0
1
11

SLIDER
758
310
931
343
flock-detection-range
flock-detection-range
0
10
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
758
262
948
295
flock-max-angle-devation
flock-max-angle-devation
0
180
120.0
1
1
NIL
HORIZONTAL

PLOT
1010
177
1210
327
average flock heading deviation
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ average-flock-heading-deviation ] of flock-holders"

PLOT
1012
340
1212
490
average flock velocity
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ flock-velocity ] of flock-holders"

MONITOR
1011
124
1146
169
Average flock velocity
mean [ flock-velocity ] of flock-holders
3
1
11

PLOT
1232
177
1432
327
Average flock size
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ count flock-members ] of flock-holders"

PLOT
1238
345
1438
495
Average flock lifetime
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot average-flock-lifetime"

MONITOR
1010
22
1146
67
Maximum flock-lfietime
max flock-lifetime-counter
0
1
11

MONITOR
1011
75
1176
120
Average Flock Spread
mean [ average-flock-spread flock-members ] of flock-holders
3
1
11

SLIDER
21
188
193
221
max-turn
max-turn
0
90
5.0
1
1
degrees
HORIZONTAL

TEXTBOX
761
20
911
38
Debugging Tools
11
0.0
1

TEXTBOX
762
232
912
250
Flock Detection Parameters
11
0.0
1

TEXTBOX
27
123
177
141
Model Parameters
11
0.0
1

TEXTBOX
765
423
915
441
Flock Visualization
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

The model explores how the school structure of a fish is affected based on each fish's vision and the reaction time in terms of latency. The flocks cerated do not have any specific leader, but every individual in the flock follows the same set of rules

## HOW IT WORKS

Every individual follows three rules : "Separation", "Alignment" and "Cohesion".

"Separation" means that the individual avoid getting too close to another individual.

"Alignment" means that the individual moves in the same direction as the nearby individuals.

"Cohesion" means that the individual tend to get closer and move towards nearby neighbours.

The above rules are preceeded by the factors - Latency and vision.

Latency is the delay in the reaction time after an individual perceives another individual in it's vicinity.

Vision is the range of vicinity for each individual

All of the above affects the overall behaviour of each individual.

## HOW TO USE IT

Firstly, determine the parameters you would like to observe in the simulation.

The primary parameters are:
preyPop - it is the number of fishes you would like to see in the model.
Latency - the latency in the reaction time in terms of seconds
Vision - it is the distance that each individual can see 360 degrees around it
fov - it is the field of view in terms of degrees from the head of the individual.

The other parameters are built on top of these parameters and to toggle visualizations.

The default parameters generate beautiful results as well.
## THINGS TO NOTICE

The model forms schools where there is no central leader handling the school behaviour.

The latency influences how fast or slowly each individual joins a school or not. Higher the latency, later the fish will react and it may not have the school in it's radius of vision to follow and join.

The dynamic behaviour of school influences on how fishes stay in the school and how fishes tend to leave a school. There is no certainity that a particular fish will remain in the same school forever.

## THINGS TO TRY

Toggle the switches for visualization of schools and observe how other sliders make or break schools.

You can see how the delay, vision and the field of view sliders affect the overall behaviour of a flock.


## EXTENDING THE MODEL
It would be interesting to see the behaviour after addition of predators and add intelligence to them. We can extend this model with predators and observe predator strategies for hunting of school of fish.


## NETLOGO FEATURES

The colors of the flock changes almost all the time, but sometimes the code which detects different flocks fails to catch on with the dynamic flocks and hence many flocks might have the same color.

## CREDITS AND REFERENCES

Referred the models given for practical assignments
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>order-parameter</metric>
    <enumeratedValueSet variable="latency">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="10"/>
      <value value="20"/>
      <value value="40"/>
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preyPop">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fov">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="0"/>
      <value value="7"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noise">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predPop">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 2" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>mean [ average-flock-heading-deviation ] of flock-holders</metric>
    <metric>mean [ count flock-members ] of flock-holders</metric>
    <metric>mean [ flock-velocity ] of flock-holders</metric>
    <metric>average-flock-lifetime</metric>
    <metric>count flock-holders</metric>
    <metric>max flock-lifetime-counter</metric>
    <metric>mean [ average-flock-spread flock-members ] of flock-holders</metric>
    <enumeratedValueSet variable="latency">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="10"/>
      <value value="20"/>
      <value value="40"/>
      <value value="80"/>
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flock-detection-range">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="align-coefficient">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fov">
      <value value="205"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cohere-coefficient">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-prey-speed">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predPop">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preyPop">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flock-color-on">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="separate-coefficient">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-separation">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualize-flock-creation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flock-max-angle-devation">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noise">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@