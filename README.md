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


## Streams

### December 28, 2022

Added a new app/module `Seed` which will be
responsible for loading initial state for 
the simulation from a provided sqlite file.
This way I can continue to use the 
[rattle-snake](https://github.com/joedaws/rattle-snake)
project to generate sqlite files and not 
have to migrate those procedural scripts into
elixir.
