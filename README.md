# Vx Complete System

This repository is used to download a set of components that are consistent with each other in terms of compatibility and versioning. This repository has all the components and scripts to run each machine (BMD, BAS, BSD, EMS).

## Hardware and OS

Pick a machine with FHD (1920x1080) resolution and the ability to install Linux.
Install [Ubuntu 18.04.4+ Desktop](https://releases.ubuntu.com/18.04.5/), minimal
installation. Software update.

## Install VotingWorks Software

```
sudo apt update
sudo apt install git make
git clone https://github.com/votingworks/vxsuite-complete-system
cd vxsuite-complete-system
make node
```

Then pull down all of the code. You can re-run these commands to pull
the latest version of the code.

```
make checkout
make build
```

## Run in Test Mode

You now have a test machine that can run any of the VxSuite components
(election manager, ballot scanner, BMD, or encoder). _You can only run
one component at a time_.

To run a VxSuite component, you need to run

- all the services needed for that component
- Kiosk Browser, the front-end Kiosk system that displays the user interface

### Election Manager

This command will run all software services needed for election manager:

```
bash run-election-manager.sh
```

### Ballot Scanner

This command will run all software services needed for ballot scanner:

```
bash run-bsd.sh
```

### Precinct Scanner

This command will run all software services needed for precinct scanner:

```
bash run-precinct-scanner.sh
```

### Ballot Marking Device

There are 3 modes:

- `VxMark`: the BMD is used just for electronic marking and stores the ballot on the smart card
- `VxPrint`: this is the print station that takes a smart card with a ballot on it and prints it
- `VxMark + VxPrint`: the more classic BMD, mark on the screen and immediately print the ballot.

The default mode is Mark.

This command will run all software services needed for the
ballot-marking device, in the given mode. Make sure to substitute your
chosen mode (`VxMark`, `VxPrint`, `VxMark + VxPrint`) in the command:

```
VX_APP_MODE="<mode>" bash run-bmd.sh
```

### Encoder

This command will run all software services needed for the smart-card encoder:

```
bash run-bas.sh
```

### Kiosk Browser

Once the services are running, start the Kiosk Browser:

```
bash run-kiosk-browser.sh
```

You're good to go. You can exit the Kiosk Browser with Ctrl-W.

## Configuring for Production

To configure and lock down the machine for production use, noting
this is an irreversible process:

```
cd vxsuite-complete-system
bash setup-machine.sh
```

## High-level Contracts

Each front-end system, e.g. `bms`, `bas`, etc., and each
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
