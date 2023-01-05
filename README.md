# Beings

An elixir app for simulating a large collection of eldrich beings floating through the cosmos, living the social
lives that eldrich beings apparently have.

## Running the simulation

From the root directory of this project use

``` shell
PORT=4321 mix run --no-halt 
```

to run the simulation with default configuration.

## Goals 

- [x] Define a suitable cosmos where these beings can live and roam.
- [x] Define the data and functions the beings. 
- [ ] Build a visualization tool for the simulation.
- [ ] parameterize the social connections of beings.

## Research

- [ ] Checkout this elixir GUI library called
[scenic](https://hexdocs.pm/scenic/overview_general.html)


## Streams

### January 11, 2023

- high level architecture diagram

### January 4, 2023

- unified the structure of nodes in the generator and 
  the application
- Added `new_node` function to the `Seed` application
  and wrote tests to check that it creates them appropriately.
- Found UI tool `Scenic` that we will explore to see
  if it will create a suitable visualization

### December 28, 2022

Added a new app/module `Seed` which will be
responsible for loading initial state for 
the simulation from a provided sqlite file.
This way I can continue to use the 
[rattle-snake](https://github.com/joedaws/rattle-snake)
project to generate sqlite files and not 
have to migrate those procedural scripts into
elixir.
