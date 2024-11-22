# VxSuite Complete System

VxSuite is the VotingWorks paper-ballot voting system. This repo links compatible versions of its two key submodules and includes the scripts necessary to create a production machine.

## Submodules

Those two submodules are:

- [vxsuite](https://github.com/votingworks/vxsuite) — Contains the bulk of the voting system source code
- [kiosk-browser](https://github.com/votingworks/kiosk-browser) — A generic Electron-based kiosk-mode browser that runs our app frontends in production

## Production Machines

The entry point for creating a production machine, after all dependencies have been installed and source code has been built, is the `setup-machine.sh` script. This script is irreversible and should not be run on your development machine.

## VxSuite Development

If you are developing in [vxsuite](https://github.com/votingworks/vxsuite), it's often helpful to run via [kiosk-browser](https://github.com/votingworks/kiosk-browser) to mimic production.

It's recommended that you clone [vxsuite](https://github.com/votingworks/vxsuite) separately rather than using the submodule in this repo. In one terminal, run the relevant VxSuite app per instructions in [vxsuite](https://github.com/votingworks/vxsuite).

Then in another terminal, run kiosk-browser:

```sh
# Only needed once or whenever kiosk-browser is updated
make checkout
make build-kiosk-browser

KIOSK_BROWSER_ALLOW_DEVTOOLS=true ./run-scripts/run-kiosk-browser.sh
```

When kiosk-browser is running, you can type `Ctrl+Shift+I` in order to open developer tools, and `Ctrl+W` to close the window. You can also `Alt+Tab` to navigate back to the terminal and `Ctrl+C` to quit kiosk-browser.

## License

All files are licensed under GNU GPL v3.0 only. Refer to the [license file](./LICENSE) for
more information.
