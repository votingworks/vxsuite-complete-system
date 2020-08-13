# Vx Complete System

This repository is used to download a set of components (bms, bas,
ems, bsd, module-\*) that are consistent with each other in terms of
compatibility and versioning. This repository has all the components
and scripts to run each machine (BMD, BAS, BSD, EMS).

## Hardware and OS

Pick a machine with FHD resolution and the ability to install Linux.
Install Ubuntu 18.04.4+ Desktop, minimal installation. Software update.

## Install VotingWorks Software

```
sudo apt install git make
git clone https://github.com/votingworks/vxsuite-complete-system
cd vxsuite-complete-system
make node
```

Then pull down all of the code. You can rerun these commands to pull
the latest version of the code.

```
make checkout
make build
```

## Run in Development

You can now run the services needed for any of the systems as follows:

```
bash run-election-manager.sh
```

```
bash run-bsd.sh
```

```
bash run-bmd.sh
```

```
bash run-bas.sh
```

Once the services are running, start the Kiosk Browser:

```
bash run-kiosk-browser.sh
```

You're good to go. You can exit the Kiosk Browser with Ctrl-W.

## Configuring for Production

To configure and lock down the machine for production use, nothing
this is an irreversible process:

```
cd vxsuite-complete-system
bash setup-machine.sh
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

