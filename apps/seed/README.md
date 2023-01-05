# Seed

A module for seeding the simulation. 

The entities involved in the simulation
are initialized using some external process,
currently [rattle-snake](https://github.com/joedaws/rattle-snake). 
The external process initializes a `sqlite` database
holding the information about the different entities
in tables. 

When the `cosmos` simulation starts up, it loads entities
from a specified `sqlite` database file. The `Seed` module 
is responsible for loading entities from a specific database
file.

