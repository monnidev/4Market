# 4Market

- Tests should be improved, invariant tests should be added
- We could add erc20s, appeal system, other types of markets, web ui, tests, fees, a deposit to prevent spam, bad stuff (ownable, uups)
- Resolver can be a eoa, an oracle, a llm....
- Consider rewriting in yul with differential testing


## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Quickstart](#quickstart)

## Introduction

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
forge make
```