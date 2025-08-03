# gatekeeper

FastAPI-based API gateway that protects upstream services by requiring cryptographic authentication and fine-grained request filtering.

## Features

- **Challenge-Response Authentication**: Clients must solve a cryptographic challenge before receiving an API key.
- **API Key Management**: Time-limited API keys are issued after successful challenge verification.
- **Proxying Requests**: Authorized requests are forwarded to an upstream service.
- **Blacklist Middleware**: Requests to configured paths/methods can be blocked entirely.
- **Header Enforcement**: Configurable headers must be present (and optionally match expected values).

## Running

To run locally with Uvicorn:

```bash
uvicorn app.main:app --reload
```

To build and run with Docker:

```bash
docker build -t gatekeeper .
docker run -d --network host --name gatekeeper gatekeeper
```

> **Note:** The service expects a running Redis instance. You can run Redis however you prefer — for example, with Homebrew:

```bash
brew install redis
brew services start redis
```

## Example Flow

A typical request flow involves:

1. **Challenge Request**
   The client sends its ID to request a challenge string and challenge ID.

   > gatekeeper assumes the client ID is already registered, it does not handle user creation

2. **Challenge Signing**
   The client signs the received challenge using its ECC private key.

   > gatekeeper expects signatures using Elliptic Curve Cryptography (ECC). The [`curveauth-py`](https://github.com/HayesBarber/curveauth-py) or [`curveauth-dart`](https://github.com/HayesBarber/curveauth-dart) libraries can be used to handle key generation and signing.

3. **Challenge Verification**
   The client submits the signature, challenge ID, and client ID. If valid, gatekeeper returns a temporary API key.

4. **Authenticated Proxy Request**
   The client includes the API key, client id, and other required headers when making a request through gatekeeper. If all validations pass, the request is proxied to the upstream service.

## Configuration

Configuration is handled in `app/config.py`, which loads values from a `.env` file. Here's an example `.env` file:

```
# .env
CLIENT_ID_HEADER=x-client-id
API_KEY_HEADER=x-api-key
PROXY_PATH=/proxy
UPSTREAM_BASE_URL=http://localhost:8001
REQUIRED_HEADERS={"x-custom-header": "expected-value"}
BLACKLISTED_PATHS={"/admin": ["GET", "POST"]}
```

> **Note:** All configuration keys have defaults defined in `app/config.py`. For example, if a path is listed in `BLACKLISTED_PATHS` with an empty method list (`[]`), **all HTTP methods** to that path will be blocked.

## Testing

First, run the setup script to seed Redis with a test user, setup a dummy upstream API, and run gatekeeper itself:

```bash
python tests/scripts/setup.py
```

Then, in another terminal, run the tests:

```bash
pytest
```
