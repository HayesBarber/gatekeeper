# `gk` — Gatekeeper CLI

A command-line interface for managing and interacting with Gatekeeper

## Overview

`gk` allows you to make requests to a gatekeeper instance, and managing the api keys behind the scenes.

You can:
• Manage API keys and instances
• Generate and store cryptographic key pairs
• Activate and switch between gatekeeper instances
• Make proxied requests to upstream services that are sitting behind gatekeeper

All persistent data (API keys, keypairs, configuration) is stored in the `~/.gk` directory.
