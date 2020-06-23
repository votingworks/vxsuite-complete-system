# VotingWorks VBM System Overview

| Date       |  Description  |  Version | Author |
|------------|---------------|----------|--------|
| 2020-06-26 | Initial version | v0.1 | Ben Adida |

## TODO
Make sure to mention:
* operational procedures to maintain security of the system

## Purpose and Scope

VotingWorks VBM is a vote-by-mail solution for counties with up to
250,000 ballots to print, mail, and tabulate. It consists of:

* *Election Manager*: proofing ballots and, once all ballots are
   scanned, generating tabulation reports from cast-vote records.

* *Mail Ballot Manager*: generating individual ballots for individual
   voters based on a mailing list, then having those ballots printed,
   stuffed into envelopes along side instructions and a return
   envelope, mailed to voters, and tracked. When ballots are received
   by county officials, Mail Ballot Manager assists with signature
   verification
   
* *Ballot Scanner*: scan hand-marked ballots, produce cast-vote records.

Taken together, *Election Manager* and *Ballot Scanner* form a
straight-forward hand-marked paper ballot system that is independent
of all mailing functionality. They are the two components in scope for
evaluation and certification.

## Applicable Documents

* pointer to spec

## Software Overview

### Concept & Objectives

*Election Manager* and *Ballot Scanner* are based on a single core
hardware and software platform, with variability only in one of the attached
peripherals and specific application code.

### Design & Constraints (Goals)

The goals of VotingWorks VBM are:
* simple & foolproof for the user
* simple in architecture & code
* resilient to failure

### Technology

The single VotingWorks platform is:
* A minimal Linux installation as the baseline operating system.
* Chromium for UX rendering, using Electron as the execution environment.
* Node.js + TypeScript application code for all UX and most services.
* Python for some specific services.

## Software Standards & Conventions

VotingWorks coding follows modern approaches to developing quality software.

### Code Reviews

### Testing & Continuous Integration

### Automatic Linting


## Software Operating Environment

### Hardware Environment & Constraints

* 14" or 15" laptops
* full HD resolution
* minimum core i3 + 4GB RAM
* recommended core i5 + 8GB RAM for scanner laptop
* recommended HP Pavillion x360 or Lenovo Ideapad 14
* Fujitsu fi-7160 or fi-7600 as physical scanners
* HP LaserJet Pro M404n for election manager printing and proofing


### Software Environment

* Ubuntu Linux 18.04.4 LTS -- Desktop Edition, Minimal Install
* Node.js v12
* TypeScript
* Python 3.7
* React 16.13.1


## Software Functional Specification

Two separate components:
* election manager
* ballot scanner

### Configurations & Operating Modes

Election Manager State Transition between Modes

Ballot Scanner State Transition between Modes

### Software Functions

* all typesafe languages with proper exception handling
* all input/output errors handled in exception handling code

## Programming Specifications

### Programming Specifications Overview

* diagram of subcomponents within each system

### Programming Specifications Details

## System Database

ballot scanner database:
* election configuration
* templates
* scanned ballots
* interpreted CVRs

election manager database:
* election configuration
* CVRs for tabulation

## Interfaces

Election Manager:
* input of election configuration
* output of election package onto USB
* output of ballot layout via printer
* input of CVRs
* output of tabulation reports printed to printer.

Ballot Scanner:
* input of election configuration & templates via election package
* input of ballots via scanner
* output of CVRs to USB stick
  