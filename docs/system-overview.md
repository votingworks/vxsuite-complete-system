# VotingWorks VBM System Overview

| Date       |  Description  |  Version | Author |
|------------|---------------|----------|--------|
| 2020-06-26 | Initial version | v0.1 | Ben Adida |

## TODO
Make sure to mention:
* operational procedures to maintain security of the system

## Purpose and Scope

## Applicable Documents

## Software Overview

### Concept & Objectives

### Design & Constraints (Goals)

* simple & foolproof for the user
* simple in architecture & code
* resilient to failure

### Technology

* COTS & OSS operating system & application environment
** Linux
** Chromium
** Node.js + Typescript
** Python

## Software Standards & Conventions

* code reviews
* testing & CI
* automatic linting

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
* Typescript
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
