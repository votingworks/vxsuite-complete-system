# VotingWorks VBM Security

| Date       |  Description  |  Version | Author |
|------------|---------------|----------|--------|
| 2020-06-26 | Initial version | v0.1 | Ben Adida |


## Overview

This document covers the security design and implementation of the
VotingWorks Vote-by-Mail (VBM) product. The components covered are:

* the Election Manager, which is used for generation and proofing of ballots, as well as for tabulation reporting.
* the Ballot Scanner, which is used for scanning and adjudicating ballots.

## Access Control

* username & password for each component
* default password and instructions to change it

## Physical Security Security

* mention only central count, no polling place support.
* recommendation to keep laptops under lock and key.
* ballots are paper
* 

## Software Security

* no custom firmware: all COTS equipment
* all software can be rebuilt from public sources available at `github.com/votingworks`
* compartmentalization of permissions with UX running under a very limited user
** protects against introduction of bad software.
* TO COMPLETE & CHECK: UX user runs with no direct write permissions, can only read.
* installation process --> using trust chains for Ubuntu Linux package installation, as well as github hashes. Explain how this ensures only the expected software is installed.
* no root access for anything

## Telecommunication and Data Transmission Security

* no networking involved in any device: networking is turned off
* no shared environments: dedicated hardware and individual components.
* election definitions are transported only via local USB sticks
* files are hashed with hashes visible to the user for verification
* incomplete election returns: no, only at election manager is the tally produced.

## Additional Security Aspects


