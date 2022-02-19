# Vx Complete System

This repository is used to download a set of components that are consistent with each other in terms of compatibility and versioning. This repository has all the components and scripts to run each machine (BMD, BAS, BSD, EMS).

## Developing vxsuite through kiosk-browser
If you are developing a change in [vxsuite](https://github.com/votingworks/vxsuite) and want to test it through kiosk-browser to mimic production, follow the steps below. Only do this *after* you have run the `setup-dev` script in vxsuite, which will install node and other dependencies.

```sh
make checkout
make build-kiosk-browser
# If you are using debian bullseye add your user to the lpadmin group
sudo usermod -aG lpadmin $USER
# run whatever apps and services you are testing in vxsuite
KIOSK_BROWSER_ALLOW_DEVTOOLS=true ./run-scripts/run-kiosk-browser.sh
```
When kiosk-browser is running, you can type `Ctrl+Shift+I` in order to open developer tools, and `Ctrl+W` to close the window. You can also `Alt+Tab` to navigate back to the terminal and `Ctrl+C` to quit kiosk-browser.


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

### Election Manager (VxAdmin)

This command will run all software services needed for election manager:

```
./run.sh election-manager
```

### Ballot Scanner (VxCentralScan)

This command will run all software services needed for ballot scanner:

```
SCAN_WORKSPACE=/tmp ./run.sh bsd
```

You may replace `/tmp` with any persistent path you like.

### Precinct Scanner (VxScan)

This requires some other packages to be installed that, unfortunately, are not
public. If you have access, go to https://github.com/votingworks/plustekctl and
follow the install instructions. Once you've done that, this command will run
all software services needed for precinct scanner:

```
SCAN_WORKSPACE=/tmp ./run.sh precinct-scanner
```

You may replace `/tmp` with any persistent path you like.

### Ballot Marking Device (VxMark/VxPrint)

There are 3 modes:

- `MarkOnly`: the BMD is used just for electronic marking and stores the ballot on the smart card
- `PrintOnly`: this is the print station that takes a smart card with a ballot on it and prints it
- `MarkAndPrint`: the more classic BMD, mark on the screen and immediately print the ballot.

The default mode is `MarkAndPrint`.

This command will run all software services needed for the
ballot-marking device, in the given mode. Make sure to substitute your
chosen mode (`MarkOnly`, `PrintOnly`, `MarkAndPrint`) in the command:

```
VX_APP_MODE="<mode>" ./run.sh bmd
```

### Encoder (VxEncode)

This command will run all software services needed for the smart-card encoder:

```
./run.sh bas
```

## Configuring for Production

To configure and lock down the machine for production use, noting
this is an irreversible process:

```
cd vxsuite-complete-system
bash setup-machine.sh
```

## High-level Contracts

Each front-end system, e.g. `bmd`, `bas`, etc., and each
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
