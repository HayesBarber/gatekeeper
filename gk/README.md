# `gk` — Gatekeeper CLI

A command-line interface for managing and interacting with Gatekeeper

## Overview

`gk` allows you to make requests to a gatekeeper instance, and managing the api keys behind the scenes.

You can:

- Manage API keys and instances
- Generate and store cryptographic key pairs
- Activate and switch between gatekeeper instances
- Make proxied requests to upstream services that are sitting behind gatekeeper

All persistent data (API keys, keypairs, configuration) is stored in the `~/.gk` directory.

## Installation

1. Clone the repo:

```bash
git clone https://github.com/HayesBarber/gatekeeper.git
```

2. Install dependencies:

```bash
pip install -r gk.requirements.txt
```

3. Install the package in editable mode:

```bash
pip install -e .
```

This exposes the `gk` command globally.

## Usage

### Add an instance

```bash
gk add
```

- The CLI will prompt for the needed input
- The instance will be saved, and a keypair will be generated for it
- As gatekeeper does not handle user creation, you will need to add the client ID and public key on the server

---

### List instances

```bash
gk list
```

- Displays all gatekeeper instances

---

### Make a proxied request

```bash
gk proxy GET /your/upstream/endpoint
```

- An API key will be fetched as needed
