# Tab Expansion

## Description

Modern Tab Expansion was opened to users with the module `Tab Expansion Plus Plus` (TEPP).

It allows you to define, what options a user is offered when tabbing through input options. This can save a lot of time for the user and is considered a key element in user experience.

The `PSFramework` offers a simplified way of offering just this, as the two example files show.

## Concept

Custom tab completion is defined in two steps:

 - Define a scriptblock that is run when the user hits `TAB` and provides the strings that are his options.
 - Assign that scriptblock to the parameter of a command. You can assign the same scriptblock multiple times.

## Structure

Import order matters. In order to make things work with the default scaffold, follow those rules:

 - All scriptfiles _defining_ completion scriptblocks like this: `*.tepp.ps1`
 - Put all your completion assignments in `assignment.ps1`