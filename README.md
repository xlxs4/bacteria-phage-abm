# Description

Was my final essay for the ABM course on SFI.

The course was broken down into the following:
1. What is Agent-Based Modeling?
   1. An Initial Exploration
   2. Introductory Models
   3. Complex Models
   4. Complexity, Emergence and Feedbacks
   5. Why use Agent-Based Modeling?
   6. When should you use Agent-Based Modeling?
   7. Comparing Agent-Based Modeling to Other Methods
   8. What Good is an Agent-Based Modeling?
2. Building a Simple Model
   1. Introduction to NetLogo
   2. Turtles, Patches and Links
   3. Code and Properties
   4. Heroes and Cowards
   5. Extending the Heroes and Cowards Model
3. Extending Models
   1. The El Farol Model
   2. Coloring Agents based on Success
   3. Understanding Rewards
   4. Histograms
   5. Advanced El Farol
4. Creating Agent-Based Models
   1. Design of the Model
   2. Seven Design Choices
   3. Beginning the Diffusion Model
   4. Networks
   5. Influentials and Analyzing the Model
5. The Components of an Agent-Based Model
   1. Architecture of an Agent-Based Model and Agents
   2. Agent Granularity, Other Types of Agents, and Agent Cognition
   3. Spatial and Network Environments
   4. 3D and GIS Environments and Interactions
   5. The Interface and Scheduling
6. Analyzing Agent-Based Models
   1. An Initial Investigation
   2. Statistics (BehaviorSpace)
   3. Graphs
   4. Networks and Environments
   5. Advanced Analysis
7. Verification, Validation and Replication
   1. Verification I
   2. Verification II
   3. Validation II
   4. Validation II
   5. Replication
8. History of Agent-Based Models and Classic Models
   1. Cellular Automata and Agent-Based Models
   2. Genetic Algorithms, John Holland and Complex Adaptive Systems
   3. Seymour Papert, Logo and the Turtle
   4. OOP
   5. Parallelism and Graphics
9. Advanced ABM
   1.  Big Data, Social Media and Agent-Based Modeling
   2.  Model Construction and Goals
   3.  Advanced NetLogo/Programming Constructs
   4.  Participatory Simulation and System Dynamics Modeling
   5.  Extensions

The rest is from the NetLogo model built-in wiki.

## WHAT IS IT?

This is a model simulating the coevolution dynamics between populations of bacteriophages and bacteria. Horizontal gene transfer, mutations, etc. are not modeled. There is some groundwork layed for incorporating the usage of antibiotics. The key part of this model is support for different environmental structures, heavily affecting the overall population dynamics.

### ELI5

Bacteria are everywhere, as well as the human organism. These bacteria help us in one way or another. Bacteria are single cells. There also exist bacteria that can potentially harm humans, and even prove lethal. In fact, before the discovery and development of antibiotics, they were one of the leading death causes. Antibiotics were and are used to keep these harmful bacteria away. The antibiotics work in two distinct ways: they either downright kill the bacteria, and/or render them unable to produce more bacteria. The bacteria, however, can mutate, and there is always the possibility of a mutation enabling the bacteria to survive the antibiotics attack. Because of the way antibiotics work, they effectively remove from the equation the bacteria populations that are unfit to survive in these conditions, and thus select for resistant bacteria. In other words, the only bacteria that survive are those that have evolved (through mutations, mostly) to develop resistance to said antibiotics. Because the rest of the bacteria die, there is less competition for the resistant bacteria, and, thus, the mutation is slowly but steadily "adopted", meaning that, eventually, all the descendant bacteria will be resistant. This is becoming an imposing problem to deal with, as the antibiotics at our disposal that are able to kill harmful bacteria are dwindling in numbers. In fact, there are some bacteria, called superbugs, that are resistant to almost all of the antibiotics available. It is estimated that by 2050, these bacteria will be everywhere, racking enough annual deaths to surpass cancer.

Bacteriophages (from here and on "phages") are viruses, extremely abundant in numbers. They have a single, simple job: find bacteria, use them to make more phages, and kill them in the process. This makes them an alternative to antibiotics for dealing with the bacteria. Additionally, they pose two great advantages when compared to the antibiotics. First, they each only target a very specific kind of bacteria, unlike antibiotics that kill a lot of bacteria that help us in the process. Second, they can also mutate and evolve; meaning as the bacteria are trying to evolve to resist them, so do they, in order to keep being able to kill them. Finally, the "cost" a bacterium has to afford to increase its likelihood of survival against the phage onslaught, it pays in being more prone to die because of the antibiotics. That is to say, a combination of phages and traditional antibiotics are a surefire way to get rid even of the most pesky bacteria. As of today, treating bacteria-induced illness with the use of phages has been experimentally demonstrated (in human patients) as viable.

This model simulates how the two populations interact: the bacteria try to grow, while the phages try to kill them. The more phages present, the harder it is for the bacteria to survive. Conversely, the less bacteria present, the harder it is for the phages to survive, due to them needing to infect the cells in order to remain alive and produce offspring. Many mainstream submodels are implemented, such as the logistic equation first proposed by Pierre Verhulst in 1845 to model bacteria growh. The key difference is that this model accounts for differences depending on the environmental structure. It turns out that the population dynamics between the two differ significantly depending on whether, say, they are inside a liquid growth medium, or inside a human tissue. By incorporating these differences, we can explore the role the variety of environmental structure can have on the bacteria-phage coevolution.

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
