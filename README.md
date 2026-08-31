# VxSuite Complete System

VxSuite is the VotingWorks paper-ballot voting system. This repo contains the scripts necessary to create a production machine. The bulk of the voting system source code lives in the separate [vxsuite](https://github.com/votingworks/vxsuite) repo.

## Production Machines

The entry point for creating a production machine, after all dependencies have been installed and source code has been built, is the `setup-machine.sh` script. This script is irreversible and should not be run on your development machine.

## Development

View our contribution guidelines [here](https://github.com/votingworks/contribution-guidelines).

### VxSuite Development

If you are developing in [vxsuite](https://github.com/votingworks/vxsuite), it's often helpful to run via [kiosk-browser](https://github.com/votingworks/kiosk-browser) to mimic production.

First, build and install kiosk-browser per instructions in [kiosk-browser](https://github.com/votingworks/kiosk-browser).

Then, in one terminal, run the relevant VxSuite app per instructions in [vxsuite](https://github.com/votingworks/vxsuite).

And in another terminal, run in this repo:

```sh
KIOSK_BROWSER_ALLOW_DEVTOOLS=true ./run-scripts/run-kiosk-browser.sh
```

When kiosk-browser is running, you can type `Ctrl+Shift+I` in order to open developer tools, and `Ctrl+W` to close the window. You can also `Alt+Tab` to navigate back to the terminal and `Ctrl+C` to quit kiosk-browser.

## License

All files are licensed under GNU GPL v3.0 only. Refer to the [license file](./LICENSE) for
more information.
