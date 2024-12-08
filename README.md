# Logic Expression Parser

A Swift package for parsing, manipulating, and analyzing logical expressions. This tool provides functionality for both generating truth tables from logical expressions and creating minimal logical formulas from truth tables.

## Features

- Parse logical expressions with support for:
  - AND (`*`), OR (`+`), NOT (`~`) operators
  - Parentheses for grouping
  - Variable names
  - Multiple outputs
- Generate truth tables from logical expressions
- Create minimal logical formulas from truth tables
- Simplify logical expressions using:
  - Idempotent Law (A + A = A)
  - Absorption Law (A + AB = A)
  - Complement Law (A + ~A = 1)
  - De Morgan's Laws (~(A + B) = ~A * ~B)

## Command Line Tool Usage

The package provides a command-line tool `lparser` with two main commands:

### 1. Generate Truth Table (`table`)

Convert a logical expression to a truth table:
