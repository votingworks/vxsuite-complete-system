# Vx Complete System

This repository is used to download a set of components (bms, bas,
ems, bsd, module-\*) that are consistent with each other in terms of
compatibility and versioning. This repository has all the components
and scripts to run each machine (BMD, BAS, BSD, EMS).

## Quick HOWTO

Start with Ubuntu 18.0.4 minimal installation with a network connection.

```
sudo apt install git make
git clone https://github.com/votingworks/vxsuite-complete-system
cd vxsuite-complete-system
make checkout
make node
make build
```

## High-level Contracts

Each front-end system, `bms`, `bas`, `ems`, and `bsd`, and each
module, e.g. `module-smartcards`, `module-scan`, etc., should be an
application that can be built using `make build`, and then run using
`make run`.

## Code Layout & Build

Each component is a git submodule. We use submodules here because they
are exactly what we need: a pointer to a particular commit of each of
the combined repositories.

We use git submodules here for the components, for the express purpose
that we never want to update one of the components without explicitly
checking that all the modules work well together.

