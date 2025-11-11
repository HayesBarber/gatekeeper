# `gk` — Gatekeeper CLI

A command-line interface for managing and interacting with Gatekeeper

## Overview

`gk` allows you to make requests to a gatekeeper instance, and managing the api keys behind the scenes.

You can:

- Manage API keys and instances
- Generate and store cryptographic key pairs
- Activate and switch between gatekeeper instances
- Make proxied requests to upstream services that are sitting behind a gatekeeper instance

## Data Storage

All persistent data (API keys, keypairs, configuration) is stored securely in the `~/.gk` directory.
Sensitive files such as API keys and keypairs are encrypted using Fernet symmetric encryption.
File and directory permissions are restricted to the current user (`700` for directories, `600` for files) to prevent unauthorized access.

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

### Add an Instance

```bash
gk add
```

- The CLI will prompt for the needed input
- The instance will be saved, and a keypair will be generated for it
- As gatekeeper does not handle user creation, you will need to add the client ID and public key on the server

---

### List Instances

```bash
gk list
```

- Displays all gatekeeper instances

---

### Activate an Instance

```bash
gk activate base_url
```

- Sets the instance with `base_url` as active

---

### Make a Proxied Request

```bash
gk proxy GET /your/upstream/endpoint
```

- An API key will be fetched as needed

---

### Fetch an API key

```bash
gk apikey
```

- Fetches a new API key
- This will happen automatically when doing a `gk proxy` if the current key is expired

---

### Generate keypair

```bash
gk keygen
```

- Generates an ECC keypair
- This will happen automatically when doing `gk add`
- This command by itself does not associate the keypair with a gatekeeper instance
