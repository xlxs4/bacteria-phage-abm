;; TODO: NEXT -> STATISTICS

;; TODO: secondary ROS killing
;; TODO: timing and amount of antibiotics applied (per location)
;;       should be given as input (the only input given)

;; FIXME: in simulations where the environment is structured instead of
;; well-mixed, the deployment of antibiotics could be non-homogeneous.
;; This mechanism is quite complex, but can provide a better balance
;; between stochasticity and heterogeneity in applying antibiotics
;; to spatially structured environments

breed [ bacteria bacterium ]
breed [ phages phage ]

bacteria-own [
  species       ;; intra-species infection more likely than inter-species
  phages-inside ;; count of phages that have infected the cell
]

phages-own [
  species
  kind          ;; different kinds showcase different behavior
  state         ;; inside a cell, or free in the environment?
  time-in-state ;; required to check against latent period and for decay
]

patches-own [
  antibiotic-count ;; TODO: not yet implemented
]

to setup
  clear-all
  ask patches [ set pcolor random-float 2 ] ;; for visual clarity

  ;; spawn the initial bacteria and phages
  ask n-of num-bacteria patches [ sprout-bacteria 1 ]
  ask n-of num-phages patches [ sprout-phages 1 ]

  ;; then, initialize them
  ask bacteria [
    initialize-bacterium
  ]

  ask phages [
    initialize-phage
  ]

  ;; TODO: antibiotic treatment schedule

  reset-ticks
end

;; convenience procedure with sensible defaults
;; the variables with the biggest impact on the simulations
;; seem to be diffuse? and latent-period
to use-default
  set num-bacteria 265
  set num-phages 148
  set environment "semi-solid"
  set diffuse? TRUE
  set a 0
  set b .08
  set m 27
  set α 8
  set κ .05
  set moi-proxy-radius 1
  set infection-distance 1
  set latent-period 5
  set burst-size 4
  set carrying-capacity 3 * num-bacteria
  set growth-rate .6
  set decay-factor .02
end

to go
  ;; TODO: collect population statistics


  ;; TODO: antibiotic application (if scheduled)

  ;; check if any bacteria are to die due to intrinsic/inherent causes
  ;; and have them die correspondingly
  ;; then, check if any bacteria are to die due to lysis
  bacteria-death

  ;; IMPORTANT
  ;; you can change the stop condition if you want,
  ;; but don't forget to have one in the first place
  ;; placement can be tricky
  if not any? phages [ stop ]

  ;; have every phage that has not infected a cell
  ask phages with [ state = "free" ] [
    ;; to search for local cells
    let neighboring-patches moore-offsets infection-distance
    let neighbor-cells bacteria at-points neighboring-patches

    ;; and try to infect them
    if any? neighbor-cells [ try-infect one-of neighbor-cells ]
    ;; if unsuccessful, update the time the phage has spent
    ;; outside of a cell; the more time outside, the more probable to decay
    if state = "free" [ tick-phage ]
  ]

  ;; TODO: resistance costs?
  ask bacteria [
    ;; have only the uninfected bacteria try to reproduce
    if not any? phages-inside [ grow ]
  ]

  ;; controls whether the bacteria and cells should diffuse in the environment
  ;; not bacteria nor phages can diffuse in a spatially-structured environment
  if diffuse? [
    ;; diffuse locally
    if environment = "semi-solid" [ ask bacteria [ _diffuse ] ]
    ;; diffuse across the world
    if environment = "well-mixed" [
      ask bacteria [
        let target-patch one-of patches with [ not any? bacteria-here ]
        if target-patch != nobody [ move-to target-patch ]
      ]
    ]
  ]

  if diffuse? [
    if environment = "semi-solid" [ ask phages [ _diffuse ] ]
    if environment = "well-mixed" [ ask phages [ move-to one-of patches ] ]
  ]

  ;; check if there are any phages outside of cells that might decay
  ;; have those that do decay die
  ask phages with [ state = "free" ] [ phage-decay ]

  ;;  TODO: antibiotics *dispersal* and decay
  tick
end

to initialize-bacterium
  set shape "circle"
  set species one-of [ "A" "B" ]
  set phages-inside no-turtles

  ifelse species = "A"
  [ set color cyan + 1]
  [ set color sky + 1 ]
end

to initialize-phage
  set shape "monster"
  set size .5
  set species one-of [ "A" "B" ]

  ;; feel free to experiment with the population distribution
  let _die-roll random-float 1
  ifelse _die-roll < .45
  [ set kind "temperate" ]
  [ ifelse _die-roll < .85
    [ set kind "virulent" ]
    [ set kind "deficient" ] ]

  if kind = "deficient" [ set color yellow ]
  if kind = "temperate" [ set color orange ]
  if kind = "virulent" [ set color magenta ]

  set state "free"
  set time-in-state 0
end

to-report p-death
  ;; TODO: incorporate local antibiotic concentration
  ;; use moore-offsets to measure antibiotic concentration nearby
  ;; similar to the mechanism used in p-adsorption, p-lysis...

  report a + ( ( 1 - a ) / ( 1 + exp ( - b * ( - m ) ) ) )
end

to-report p-adsorption [ cell ] ;; stochastic
  ;; count the phages near to this phage
  let neighboring-coor moore-offsets moi-proxy-radius
  let neighboring-patches patches at-points neighboring-coor
  let surrounding-phages count phages-on neighboring-patches

  let p-host 1
  ;; account for difference in species
  ifelse species = "A"
  [ ifelse [ species ] of cell = "A" [ set p-host .9 ]
    [ set p-host .1 ] ]
  [ ifelse [ species ] of cell = "A" [ set p-host .1 ]
      [ set p-host .9 ] ]

  let prob p-host / ( 1 + exp ( - surrounding-phages ) )
  report prob
end

to-report p-lysis ;; stochastic
  let neighboring-coor moore-offsets moi-proxy-radius
  let neighboring-patches patches at-points neighboring-coor
  let surrounding-phages count phages-on neighboring-patches

  report 1 / ( 1 + α * exp ( - surrounding-phages + κ ) )
end

to-report p-burst
  report .9 ;; TODO: make this stochastic?
end

to-report p-grow ;; stochastic
  let uninfected-bacteria count bacteria with [ not any? phages-inside ]

  let dN
  growth-rate *
  uninfected-bacteria *
  ( 1 - uninfected-bacteria / carrying-capacity )
  report dN / uninfected-bacteria
end

to-report p-phage-decay ;; stochastic
  report 1 - ( 1 * exp ( - decay-factor * time-in-state ) )
end

to-report moore-offsets [n]
  let result [ list pxcor pycor ] of patches with [ abs pxcor <= n and abs pycor <= n ]
  report result
end

to _diffuse
  ifelse is-bacterium? self
  [ diffuse-bacterium ]
  [ diffuse-phage ]
end

to diffuse-bacterium
  let radius 3
  let neighboring-coor moore-offsets radius
  let neighboring-patches patches at-points neighboring-coor

  ;; remember: only one bacterium can be present in each patch
  let target-patch one-of neighboring-patches with [ not any? bacteria-here ]
  if target-patch != nobody [ move-to target-patch ]
end

to diffuse-phage
  let radius 3
  let neighboring-coor moore-offsets radius
  let neighboring-patches patches at-points neighboring-coor

  ;; there can be more than one phages in the same patch
  move-to one-of neighboring-patches
end

to bacteria-death
  ;; see if any bacteria die from inherent causes
  ask bacteria [
    if random-float 1 < p-death [
      ask phages-inside [ die ]
      die
    ]
  ]
  ;; see if any bacteria die from lysis
  ask bacteria [
    if any? phages-inside [
      ask phages-inside [ tick-phage ]

      let can-burst get-can-burst phages-inside
      ask can-burst [
        try-burst
      ]

      if not any? phages-inside [ die ]
    ]
  ]
end

to tick-phage
  set time-in-state time-in-state + 1
end

to try-infect [ target-cell ]
  if random-float 1 < p-adsorption target-cell [
    if kind = "temperate" [
      try-lysis
    ]
    ;; since the lysogenic cycle is not yet implemented, if
    ;; the phage remains temperate, it simply does nothing
    if kind = "virulent" or kind = "induced-temperate" [ infect target-cell ]
  ]
end

to try-lysis
  if random-float 1 < p-lysis [
    set kind "induced-temperate"
    set color red
  ]
end

to infect [ target-cell ]
  set state "in-host"
  set time-in-state 0

  ask target-cell [
    set phages-inside (turtle-set phages-inside myself)
    set color scale-color ( violet + 1 ) ( count phages-inside ) 0 4
  ]
end

to-report get-can-burst [ p-inside ]
  let can-burst p-inside with [
    time-in-state >= latent-period and
    ( kind = "virulent" or kind = "induced-temperate" )
  ]
  report can-burst
end

to try-burst
  if is-turtle? myself [
    if random-float 1 < p-burst [ burst ]
  ]
end

to burst
  let radius 1
  if environment = "semi-solid" [ set radius 3 ]
  ;; spanning all of the grid
  if environment = "well-mixed" [ set radius max-pycor - 1 ]

  let neighboring-coor moore-offsets radius

  let target-patches [ ]
  repeat burst-size [
    let target one-of neighboring-coor
    set target-patches lput target target-patches
  ]

  ask patches at-points target-patches [
    sprout-phages 1 [ initialize-phage ]
  ]

  ask myself [
    ask phages-inside [ die ]
  ]
end

to grow
  let radius 1
  if environment = "semi-solid" [ set radius 3 ]

  let neighboring-coor moore-offsets radius
  let neighboring-patches patches at-points neighboring-coor

  let target-patch one-of neighboring-patches with [ not any? bacteria-here ]
  if target-patch != nobody [
    if random-float 1 < p-grow [
      ask target-patch [
        sprout-bacteria 1 [ initialize-bacterium ]
      ]
    ]
  ]
end

to phage-decay
  if random-float 1 < p-phage-decay [ die ]
end
@#$#@#$#@
GRAPHICS-WINDOW
156
10
610
465
-1
-1
13.52
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
10
100
144
133
num-bacteria
num-bacteria
0
1000
265.0
1
1
NIL
HORIZONTAL

BUTTON
11
10
66
43
NIL
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

BUTTON
11
47
66
80
NIL
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

SLIDER
10
139
143
172
num-phages
num-phages
0
1000
148.0
1
1
NIL
HORIZONTAL

CHOOSER
8
366
141
411
environment
environment
"well-mixed" "spatially structured" "semi-solid"
2

SLIDER
316
472
452
505
a
a
0
1
0.0
.01
1
NIL
HORIZONTAL

SLIDER
316
508
452
541
b
b
0
1
0.08
.01
1
NIL
HORIZONTAL

SLIDER
316
544
454
577
m
m
0
40
27.0
1
1
NIL
HORIZONTAL

CHOOSER
9
473
142
518
infection-distance
infection-distance
0 1 2
1

BUTTON
75
47
130
80
go-once
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
10
191
144
224
latent-period
latent-period
1
10
5.0
1
1
NIL
HORIZONTAL

PLOT
622
168
821
318
Uninfected bacteria
generations
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -11221820 true "" "plot count bacteria with [ not any? phages-inside ]"

PLOT
622
323
821
473
Infected bacteria
generations
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -8630108 true "" "plot count bacteria with [ any? phages-inside ]"

PLOT
622
10
822
160
Population count
generations
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"bacteria" 1.0 0 -13345367 true "" "plot count bacteria"
"deficient" 1.0 0 -1184463 true "" "plot count phages with [ kind = \"deficient\" ]"
"temperate" 1.0 0 -955883 true "" "plot count phages with [ kind = \"temperate\" ]"
"induced" 1.0 0 -2674135 true "" "plot count phages with [ kind = \"induced-temperate\" ]"
"virulent" 1.0 0 -5825686 true "" "plot count phages with [ kind = \"virulent\" ]"

SLIDER
10
229
144
262
burst-size
burst-size
3
8
4.0
1
1
NIL
HORIZONTAL

BUTTON
75
10
142
43
NIL
use-default
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
8
280
144
313
carrying-capacity
carrying-capacity
2 * num-bacteria
10 * num-bacteria
795.0
1
1
NIL
HORIZONTAL

SLIDER
8
318
143
351
growth-rate
growth-rate
0.2
1
0.6
.05
1
NIL
HORIZONTAL

SLIDER
471
472
609
505
decay-factor
decay-factor
.01
.2
0.02
.01
1
NIL
HORIZONTAL

SLIDER
158
473
295
506
α
α
0
100
8.0
1
1
NIL
HORIZONTAL

SLIDER
158
509
294
542
κ
κ
.01
.5
0.05
.01
1
NIL
HORIZONTAL

CHOOSER
8
526
143
571
moi-proxy-radius
moi-proxy-radius
1 2
0

SWITCH
8
423
140
456
diffuse?
diffuse?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This is a model simulating the coevolution dynamics between populations of bacteriophages and bacteria. Horizontal gene transfer, mutations, etc. are not modeled. There is some groundwork layed for incorporating the usage of antibiotics. The key part of this model is support for different environmental structures, heavily affecting the overall population dynamics.

### ELI5

Bacteria are everywhere, as well as the human organism. These bacteria help us in one way or another. Bacteria are single cells. There also exist bacteria that can potentially harm humans, and even prove lethal. In fact, before the discovery and development of antibiotics, they were one of the leading death causes. Antibiotics were and are used to keep these harmful bacteria away. The antibiotics work in two distinct ways: they either downright kill the bacteria, and/or render them unable to produce more bacteria. The bacteria, however, can mutate, and there is always the possibility of a mutation enabling the bacteria to survive the antibiotics attack. Because of the way antibiotics work, they effectively remove from the equation the bacteria populations that are unfit to survive in these conditions, and thus select for resistant bacteria. In other words, the only bacteria that survive are those that have evolved (through mutations, mostly) to develop resistance to said antibiotics. Because the rest of the bacteria die, there is less competition for the resistant bacteria, and, thus, the mutation is slowly but steadily "adopted", meaning that, eventually, all the descendant bacteria will be resistant. This is becoming an imposing problem to deal with, as the antibiotics at our disposal that are able to kill harmful bacteria are dwindling in numbers. In fact, there are some bacteria, called superbugs, that are resistant to almost all of the antibiotics available. It is estimated that by 2050, these bacteria will be everywhere, racking enough annual deaths to surpass cancer.

Bacteriophages (from here and on "phages") are viruses, extremely abundant in numbers. They have a single, simple job: find bacteria, use them to make more phages, and kill them in the process. This makes them an alternative to antibiotics for dealing with the bacteria. Additionally, they pose two great advantages when compared to the antibiotics. First, they each only target a very specific kind of bacteria, unlike antibiotics that kill a lot of bacteria that help us in the process. Second, they can also mutate and evolve; meaning as the bacteria are trying to evolve to resist them, so do they, in order to keep being able to kill them. Finally, the "cost" a bacterium has to afford to increase its likelihood of survival against the phage onslaught, it pays in being more prone to die because of the antibiotics. That is to say, a combination of phages and traditional antibiotics are a surefire way to get rid even of the most pesky bacteria. As of today, treating bacteria-induced illness with the use of phages has been experimentally demonstrated (in human patients) as viable.

This model simulates how the two populations interact: the bacteria try to grow, while the phages try to kill them. The more phages present, the harder it is for the bacteria to survive. Conversely, the less bacteria present, the harder it is for the phages to survive, due to them needing to infect the cells in order to remain alive and produce offspring. Many mainstream submodels are implemented, such as the logistic equation first proposed by Pierre Verhulst in 1845 to model bacteria growth. The key difference is that this model accounts for differences depending on the environmental structure. It turns out that the population dynamics between the two differ significantly depending on whether, say, they are inside a liquid growth medium, or inside a human tissue. By incorporating these differences, we can explore the role the variety of environmental structure can have on the bacteria-phage coevolution.

(Although not strictly relevant, I find the [TedEd talk by Bonnie Bassler](https://www.youtube.com/watch?v=KXWurAmtf78) to be a very pleasant and thought-provoking introduction to the basic gist of all this)

### INTRODUCTION

Different kinds of what can be classified as a microbial organism can be found in every natural, or natural-alike, environment; the human body not being an exception. The populations of microbial organisms are key factors in how the environments they inhabit are temporally shaped. Not only do said organisms contribute in forming the greater enclosing ecosystem they come to be a part of, but they can also significantly affect it in various ways, the most important of which being forcing the host to a “reaction-chain” of constant adaptation, thus driving evolution. A long-standing study focus, rising in popularity, is in regard to the interactions between bacteria and bacteriophages (or simply, phages). The phages predate on the bacteria, thereby having a regulatory role in the bacteria growth and overall population dynamics, while also forming the “rules” by which they adapt. Phages are both incredible predators, as well as the most abundant entities in nature. Pathogenic bacteria showcase an increasingly effective resistance to antibiotics. Furthermore, the development of new antibiotics has slowed down considerably, not being able to keep pace with the surge in the appearance of more potent, unaffected by current treatment, bacteria. Thus, there has been rekindled interest in utilizing phages in a controlled setting to provide an alternative of or complement to an antibiotic treatment. As the progress in this field can be considered at a nascent stage, modeling the bacteria-phage interactions is of paramount importance towards exploiting them to treat disease.

In brief, phages are infectious acellular entities that depend on the existence of bacterial cells to proliferate. In typical predator-prey fashion, the phage population growth depends on the respective bacteria population growth. The host bacteria evolve mechanisms to resist the phages, while, at the same time, the phage particles evolve new strategies to manage to infect them, in an asynchronous manner. The huge variety of existing bacteria and phage strains, the vast number of discrete states, the non-linearity of the pharmacodynamics and pharmacokinetics in play, coupled with the inherent stochasticity that characterizes evolution, among others, render the bacteria-phage coevolution system encompassing complex dynamics.

To elucidate the mechanisms underlying phage-bacteria interactions, a variety of experimental _in vitro_ and _in vivo_ approaches have been developed, on simplified and more complex environments; natural along with simulated ones. Mathematical modeling contributes in propelling all related research forward, as well as helps combat some inevitably arising technicalities. For example, there is limited knowledge of the antagonistic coevolution in nature, it is difficult to maintain target and control cultures in parallel to carry out experiments, and only few bacteria are even amenable to being cultured in a laboratory. While, through modeling, we can arrive to analytical solutions derived from using well-established techniques to explore parameter and solution space, the models often don’t scale well, failing to address spatial heterogeneity (very important since the dynamics are heavily affected by environment structure) and key processes that are stochastic in nature. The models occasionally fail to pinpoint the effects of individual mechanisms and highly-specialized cases, have limited resolution in tracking temporal dynamics and may end up being intractable, as the system under study increases in complexity. These are some of the reasons why the more popular modeling approaches (using delay differential equations, cellular automata, MCMC, etc.) can be unable to reproduce the observational data, and/or not be transferable to realistic scenarios.

The above can pave the way for an agent-based modeling approach to incorporate different mechanisms at the level of the individual, supporting local interactions. It can constitute a way to include low-level biological detail, while having the system-level dynamics that emerge from the local, independent interactions and decisions remain intact and easily accessible.

## HOW IT WORKS

### THINGS TO KNOW

* The phages can interact with the cells in two main ways, termed as the lysogenic and lytic cycle, respectively. In the, most common, lytic cycle, the phage tries to infect the cell. If successful, its genetic material (DNA / RNA) goes inside the cell and hijacks it, turning it into a phage-producing factory. The resources of the cell are spent to create more phages, and, eventually, the cell bursts (lysis) and the newly-made phages get released in the environment to infect more cells.
The lysogenic cycle is more complex, and it was decided to not incorporate it in the model.

* The bacteria can also die even if not being infected by a myriad of other reasons, ageing being an example

* If a phage infects a cell, it cannot infect other cells. If/when it bursts, it will have died in the process

* The same cell can be infected by more than one phages

* A cell cannot reproduce if it is infected

* The phages try to infect cells close to them

* The phages will eventually die if they remain outside a cell for too long

* Both the phages and the cells can diffuse, meaning they can move in the environment. How exactly depends on the specific structure the environment has

* The phages can be of different kinds. Three are selected in this model: There are the "virulent" phages, which only enter the lytic cycle upon a successful infection. Put simply, if they manage to infect a cell, they immediately "start working towards" having more phages produces and the cell to ultimately die. Then, there are the "temperate" phages, phages that start at the lysogenic cycle (in this model, they just remain inside the bacteria), but that can transition to the lytic cycle. Lastly, there are the "deficient" phages, phages that cannot infect a cell, for various reasons

* The probability of a phage to infect a cell depends on its species, on the cell's species, and the amount of locally present phages

* The probability of a temperate phage to transition into the lytic cycle mainly depends on the amount of locally present phages

* The probability of a phage to burst, killing the infected cell and releasing the other phages into the environment is currently fixed

* The probability of a cell to reproduce depends on its growth rate, the amount of other uninfected bacteria present (because they compete for resources), and the maximum possible amount of uninfected bacteria (because the resources eventually run out and can only support that many cells)

* A cell can only reproduce if the new cell can occupy a patch without any other cells. The area checked depends on the environment structure

* The probability of a phage to decay depends greatly on the time it has spend not being inside a cell

* After lysis, the area in which the phages get released depends on the environment structure


### FLOWCHART

#### INITIAL SETUP

* Setup Environment
  * Bacteria species/types
  * Phage species/types
  * ...

#### MAIN CYCLE

* Collect Population Statistics (TODO)
* Antibiotic Application (TODO)
  (if scheduled)
* Bacterial Death
  * Calculate probability of death
    * Intrinsic
    * Antibiotics (TODO)
    * Phage induction and lysis
  * Release lysed phage into the environment
  * Remove cells; free resources
* Phage Infection
  Decision between lytic and lysogenic cycle for temperate phage
* Selection and Reproduction
  Probability of reproduction
* Randomise Cell Locations
  (essentially dispersal, see diffuse?)
* Environment Update
  * Phage *dispersal* and decay
  * Antibiotics *dispersal* and decay (TODO)

### NOTES

* After a successful infection, the lysis-lysogen decision depends on the viral concentration in the surrounding locations (Moore distance of 1), which is then used as a proxy for the MOI (under the assumption that if a sensitive bacterium is surrounded by a given number of phages, they will very likely co-infect the cell)

#### STOCHASTIC PROCESSES

Parametrizable:
* P(reproduction)
  * growth rate
  * resistance costs (TODO)
* P(infection)
  * adsorption probability
  * infection distance

---

Influenced by state variables:
* Lysis-lysogeny decision (2 parameters define a logistic curve as a function of the local viral concentration, **lysogeny alpha** and **lysogeny kappa**)
* Prophage induction decision (2 parameters define a logistic curve as a function of the local antibiotic concentration, **induction alpha**, and **induction kappa**)
* Probability of bacterial death and sensitivity to antibiotics (3 parameters define the death function of bacteria, which is a function of the concentration of antibiotics in the bacterium's location, **death curve A**, **death curve B** and **death curve M**)
* Probability of phage elimination (per phage, one parameter defines an exponential decay as a function of phage time outside any bacterial host, **phage decay lambda**)
* Antibiotic decay (per location, one parameter per antibiotic defines an exponential decay as a function of iterations passed since the antibiotic was deployed in a specific location, **antibiotic decay lambda**) (TODO)

#### DETERMINISTIC-COULD BECOME STOCHASTIC

* The distance used for reproduction and diffusion in semi-solid environments (fixed at Moore 3)
* The infection distance for phage to infect a bacterial cell (fixed by **infection distance** parameter, set as Moore distance)
* The number of phage offspring after burst (fixed by **burst size** parameter)
* The distance neighborhood used for the viral concentration assessment in the lysis-lysogoeny decision (fixed at Moore distance 1)

### COLLECTIVES

Collective entities are emergent from the model from the groups of individual cells, but no individual decisions take these collectives into account. The collective entities resulting from the simulations have no state variables or properties, and are meant to evaluate dynamics occuring at the population level resulting from individual mechanisms. They can be assessed at different levels which are, from the highest to lowest level:
* Number of total bacteria or the number of total phage
* Number of each phage kind
* Bacteria in a given cellular state (for now uninfected vs. infected)

## HOW TO USE IT

The code tab also contains some comments to hopefully help you browse and play around.
You can use and build upon the reporters provided to collect additional statistics from running the simulation. These reporters can also help you running BehaviorSpace, as an example.

### INTERFACE

* setup:
  clears/resets/frees whatever necessary, spawns the agents (bacteria and phages) and initializes them. Also paints the patches for better visual clarity
* go:
  runs the main cycle forever; refer to FLOWCHART
* use-default:
  sets sensible defaults for all the parameters that are customizable through the interface
* go-once:
  runs the main cycle just for one tick

---

* num-bacteria:
  the _initial_ count of bacteria to spawn in the world
* num-phages:
  the _initial_ count of phages to spawn in the world

---

* latent-period:
  the amount of ticks that need to pass while a phage is inside (has infected) a cell, before it can try to burst, killing the cell through lysis and releasing additional phages in the environment
* burst-size:
  the amount of phages that get released in the environment when a cell bursts (lysis)

---

* carrying-capacity:
  the maximum amount of bacteria that can exist in the world. Used as the "ceiling" parameter in the logistic equation controlling bacteria growth (reproduction)
* growth-rate:
  the rate at which a cell reproduces (per tick)

---

* environment:
  spatially structured, semi-solid or well-mixed. From the former to the latter, varying levels of limitations exerted on the phage and cell function. Diffusion of the agents severly affected by the environment choice. Additionally affected is the area in which the cells reproduce, and many more. See DETAILS

---

* diffuse?:
  should the cells and phages diffuse (move) in the environment, or should they remain in place? Note that in the case of the spatially structured environment, there is no diffusion taking place regardless of this variable's value

---

* infection-distance:
  how far will the free phages look in order to find a cell to try and infect? Moore neighborhood

---

* moi-proxy-radius:
  how far will the phage look in order to count the phages nearby and use it as an approximation for the total amount of phages in the environment?

---

* α:
  one of the two parameters to tune the logistic equation used to model whether the phage will enter the lytic cycle (try to burst) or remain in the lysogenic (currently implemented as doing nothing)
* κ:
  one of the two parameters to tune the logistic equation used to model whether the phage will enter the lytic cycle (try to burst) or remain in the lysogenic (currently implemented as doing nothing)

---

* a:
  one of the three parameters to tune the logistic equation used to model whether the cell will die for reasons other than lysis. This parameter controls the minimal probability of death in the absence of antibiotics present (intrinsic death rate)
* b:
  one of the three parameters to tune the logistic equation used to model whether the cell will die for reasons other than lysis. This parameter controls the rate of increase in the death probability as the antibiotic concentration increases
* m:
  one of the three parameters to tune the logistic equation used to model whether the cell will die for reasons other than lysis. This parameter controls the minimum inhibitory concentration of the drug needed to affect bacteria death rate
---

* decay-factor:
  a parameter to tune how fast will a phage decay while outside a cell

---

* population count:
  monitors the present count of bacteria (uninfected _and_ infected), as well as that of the four possible kinds of phages
* uninfected bacteria:
  monitors the present count of uninfected bacteria; bacteria without phages inside
* infected bacteria:
  monitors the present count of infected bacteria; bacteria that will inevitably die due to lysis

## THINGS TO NOTICE

Notice how the population counts tend to oscillate but usually remain within some lower and upper bounds. Notice how the different environment structures affect these oscillations. Depending on the model parameters, it is possible for the simulation to stop, because there are no more phages present. This can happen either because the amount of phages slowly declines and they cannot infect enough cells to outweigh their eventual decay, or because the bacteria have all died, meaning the phages have nothing to infect and will, eventually, die as well. Try to identify the parameters that have the biggest impact on how the dynamics play out. You can start with the latent period and with togglilng the diffuse? variable. If you keep all the parameters the same across different environment structures, it is very unlikely that the model will keep running in all three cases. If for example you have a set of parameters that tend to maintain the population counts relatively steady with smooth oscillations, the spatially structured environment may prove too difficult for the organisms to survive. Vice-versa, if a "steady-state" can be reached in the spatially structured environment, the oscillations in the other environment types will be more abrupt. The latent period seems to account for a lot of how these oscillations turn out to be. Also notice the count of the deficient phages and compare it to the counts of the other kinds of phages.

## THINGS TO TRY

There are easy-to-adjust parameters that are not accessible through the Interface tab. As an example, try editing the code to change the probabability distrubution governing how much of the total phage population will be of what kind. You can also try to do some more invasive changes. For example, how would the model behave, if the infected bacteria could also reproduce? Or if there could be more than one cell in the same patch?

## EXTENDING THE MODEL

Besides implementing the antibiotic application, you can try to go a step further and implement the lysogenic cycle. In the lysogenic cycle the DNA/RNA of the phage enters the cell. The cell carries on like nothing has happened, but when it reproduces, the new cells also carry the same genetic material that can some time in the future hijack and kill the cell. You could even incorporate both the phages and the bacteria having genes, to incorporate mutations, horizontal gene transfer, transduction, and, generally, evolution. For a simpler idea, when a phage infects a cell, in reality it ceases to exist. This isn't reflected in the model. Or, maybe when the transition from the lysogenic to the lytic cycle happens, the phage's ticks (time-in-state) should be reset. Or, say a cell is infected by phage 1. In the next tick, it also get infected by phage 2. Phage 1 has been for enough time in the cell (time-in-state >= latent-period) to try and burst. It doesn't immediately succeed. Eventually, when it does, the (time-in-state >= latent-period) also holds true for the other phage. Should the amount of phages released in the environment be doubled? The possibilities are endless... ;)

## CREDITS AND REFERENCES

Mainly inspired by and based on the work of 
`de Sousa, J. A. M., & Rocha, E. P. (2019). Environmental structure drives resistance to phages and antibiotics during phage therapy and to invading lysogens during colonisation. Scientific reports, 9(1), 1-13.`
that I managed to come across halfway through.
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

monster
false
0
Polygon -7500403 true true 75 150 90 195 210 195 225 150 255 120 255 45 180 0 120 0 45 45 45 120
Circle -16777216 true false 165 60 60
Circle -16777216 true false 75 60 60
Polygon -7500403 true true 225 150 285 195 285 285 255 300 255 210 180 165
Polygon -7500403 true true 75 150 15 195 15 285 45 300 45 210 120 165
Polygon -7500403 true true 210 210 225 285 195 285 165 165
Polygon -7500403 true true 90 210 75 285 105 285 135 165
Rectangle -7500403 true true 135 165 165 270

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
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
