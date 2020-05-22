# Description

This is the folder, where all the tests go.

Those are subdivided in two categories:

 - General
 - Function

## General Tests

General tests are function generic and test for general policies.

These test scan answer questions such as:

 - Is my module following my style guides?
 - Does any of my scripts have a syntax error?
 - Do my scripts use commands I do not want them to use?
 - Do my commands follow best practices?
 - Do my commands have proper help?

Basically, these allow a general module health check.

These tests are already provided as part of the template.

## Function Tests

A healthy module should provide unit and integration tests for the commands & components it ships.
Only then can be guaranteed, that they will actually perform as promised.

However, as each such test must be specific to the function it tests, there cannot be much in the way of templates.