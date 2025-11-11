# `gk` — Gatekeeper CLI

A command-line interface for managing and interacting with Gatekeeper

## Overview

`gk` allows you to make requests to a gatekeeper instance, and managing the api keys behind the scenes.

You can:
• Manage API keys and instances
• Generate and store cryptographic key pairs
• Activate and switch between gatekeeper instances
• Make proxied requests to upstream services that are sitting behind gatekeeper

All persistent data (API keys, key pairs, configuration) is stored in the `~/.gk` directory.

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
