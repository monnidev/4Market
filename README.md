## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Quickstart](#quickstart)
- [FourMarket Contract](#fourmarket-contract)
  - [Purpose](#fourmarket-contract-purpose)
  - [How It Works](#fourmarket-contract-how-it-works)
- [Market Contract](#market-contract)
  - [Purpose](#market-contract-purpose)
  - [Key Features](#market-contract-key-features)
- [Token Contract](#token-contract)
  - [Purpose](#token-contract-purpose)
  - [Key Features](#token-contract-key-features)
- [User Actions](#user-actions)
- [Summary](#summary)
- [Note](#note)


## Introduction

This document provides a brief overview of the `FourMarket`, `Market`, and `Token` smart contracts. These contracts form a decentralized prediction market platform where users can create markets, place bets on outcomes, and receive rewards based on the actual results.

## Prerequisites

Before setting up the project, ensure you have the following installed:

- **Git**: Version control system for cloning and managing repositories.
  - **Installation**: Follow the official [Git installation guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).
  - **Verification**: Run `git --version` in your terminal. You should see output like `git version x.x.x`.

- **Foundry**: A blazing fast, portable, and modular toolkit for Ethereum application development written in Rust.
  - **Installation**: Use the command provided at [Foundry's official website](https://getfoundry.sh/).
  - **Verification**: Run `forge --version` in your terminal. Expected output is similar to `forge x.x.x`.

- **Yarn**: Fast, reliable, and secure dependency management for JavaScript projects.
  - **Installation**: Follow the [Yarn installation guide](https://yarnpkg.com/getting-started/install).
    ```bash
    # Install Yarn globally using npm
    npm install --global yarn
    ```
  - **Verification**: Run the following command to confirm installation:
    ```bash
    yarn --version
    ```


## Quickstart

Follow the steps below to set up the project locally:

```bash
# Clone the repository
git clone https://github.com/monnidev/4Market.git

# Navigate to the project directory
cd 4Market

# Compile
forge build
```

# FourMarket, Market, and Token Contracts Overview

---

## FourMarket Contract

### Purpose

- Acts as a factory and registry for creating and managing individual prediction markets.
- Allows users to create new markets with specific parameters.

### How It Works

- **Create Market**: Users call the `createMarket()` function with the desired parameters:
  - `_question`: The question or event for the market.
  - `_details`: Additional information about the market.
  - `_deadline`: Timestamp when betting closes.
  - `_resolutionTime`: Time window for resolving the market.
  - `_resolver`: Address responsible for resolving the market.

- **Market Registry**: Newly created markets are stored in the `markets` mapping with a unique `marketId`.

---

## Market Contract

### Purpose

- Represents an individual prediction market.
- Handles bet placement, market resolution, and reward distribution.

### Key Features

- **Bet Placement**:
  - Users place bets by sending Ether and specifying an outcome (`Yes` or `No`).
  - Bets can only be placed before the `i_deadline`.
  - Users receive `YesToken` or `NoToken` representing their stake.

- **Market Resolution**:
  - After the betting deadline, the designated `i_resolver` can resolve the market by calling `resolve()` with the final outcome.
  - Resolution must occur within the `i_resolutionTime` window.

- **Reward Distribution**:
  - Users can claim rewards by calling `distribute()` after the market is resolved.
  - Rewards are proportional to their stake in the winning outcome.
  - Tokens are burned upon claiming rewards.

- **Inactivity Cancellation**:
  - If the market is not resolved within the resolution window, anyone can call `inactivityCancel()` to cancel the market.
  - Users can then retrieve their original bets.

### User Actions

- **For Participants**:
  - **Place a Bet**:
    1. Call `bet(outcomeType _betOutcome)` with your chosen outcome.
    2. Send the amount of Ether you wish to bet.
  - **Claim Rewards**:
    1. After the market is resolved, call `distribute()` to claim your rewards.

- **For Market Creators**:
  - **Create a Market**:
    1. Call `createMarket()` on the `FourMarket` contract with the desired parameters.
    2. Set yourself or another trusted entity as the `i_resolver`.

- **For Resolvers**:
  - **Resolve the Market**:
    1. After the betting deadline and within the resolution window, call `resolve(outcomeType _finalResolution)` with the actual outcome.

---

## Token Contract

### Purpose

- ERC20 tokens representing users' stakes in a market outcome.
- Two types: `YesToken` and `NoToken`.

### Key Features

- **Minting**:
  - Only the market contract (`i_deployer`) can mint tokens when users place bets.

- **Burning**:
  - Tokens are burned when users claim rewards.

---

## Summary

- **Participants**: Place bets on market outcomes and claim rewards based on actual results.
- **Creators**: Use the `FourMarket` contract to create new markets.
- **Resolvers**: Responsible for setting the final outcome of a market within the specified resolution window.

---

## Note

- The `Token` contract no longer mints an initial token upon deployment. This means that initial token supplies start at zero, and calculations involving total supply should account for this to avoid division by zero errors.

---
