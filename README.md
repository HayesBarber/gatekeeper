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
# install deps first
pip install -r requirements.txt

# run the app
uvicorn app.main:app --reload
```

To build and run with Docker:

```bash
# build the image
docker build -t gatekeeper .

# run it
docker run -d --network host --env-file .gatekeeper.env --name gatekeeper gatekeeper
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

   > gatekeeper assumes the client ID and public key are already registered, it does not handle user creation

2. **Challenge Signing**
   The client signs the received challenge using its ECC private key.

   > gatekeeper expects signatures using Elliptic Curve Cryptography (ECC). The [`curveauth-py`](https://github.com/HayesBarber/curveauth-py) or [`curveauth-dart`](https://github.com/HayesBarber/curveauth-dart) libraries can be used to handle key generation and signing.
   > Signature verification expects a base64-encoded signature and a base64-encoded raw public key.

3. **Challenge Verification**
   The client submits the signature, challenge ID, and client ID. If valid, gatekeeper returns a temporary API key.

4. **Authenticated Proxy Request**
   The client includes the API key, client id, and any other required headers when making a request through gatekeeper. If all validations pass, the request is proxied to the upstream service.

   ```bash
   curl http://localhost:8000/proxy/echo \
     -H "x-api-key: your-api-key" \
     -H "x-requestor-id: your-client-id"
   ```

## Configuration

Gatekeeper is configured via a **YAML file (`gatekeeper.yaml`)**.

Configuration loading is defined in `app/config.py`.

### Configuration Fields

- `client_id_header`  
  Name of the header used to identify the client for challenge requests and API-keyed proxy calls

- `api_key_header`  
  Name of the header containing the API key used to authenticate proxied requests

- `proxy_path`  
  URL prefix that marks requests to be forwarded to an upstream

- `upstreams`  
  Mapping of request path prefix → upstream base URL  
  Example: `"/api/v1": "http://localhost:8081"`

  - Gatekeeper also loads upstream mappings dynamically from Redis under the `upstreams` namespace
  - Redis-defined upstreams take precedence over values defined in YAML
  - `proxy_path` is stripped from the incoming request before resolving an upstream
  - The remaining path is matched using longest-prefix match against `upstreams`
  - The matched prefix is removed before constructing the final upstream URL

- `required_headers`  
  Mapping of header → expected value  
  Use `null` to require presence only

- `blacklisted_paths`  
  Mapping of path → list of allowed HTTP methods (`GET`, `POST`, etc.)

  - Empty list (`[]`) disables all methods for that path

- `otel_enabled`  
  Enables OpenTelemetry instrumentation (default: `false`)

  When enabled, Gatekeeper exposes counters and histograms for challenge flow, proxy behavior, and error cases. Metrics can be exported to any OTLP-compatible collector.

### Example `gatekeeper.yaml`

```yaml
proxy_path: /proxy
client_id_header: x-client-id
api_key_header: x-api-key
otel_enabled: true

upstreams:
  "": http://localhost:8080
  /home-api: http://localhost:8081
  /api/v2: http://localhost:8082

required_headers:
  x-custom-header: expected-value

blacklisted_paths:
  /admin:
    - GET
    - POST
```

## Example: how a proxied request resolves

- Settings:

  - PROXY_PATH = /proxy
  - UPSTREAMS = { "/home-api": "http://localhost:8081", "": "http://localhost:8080" }

- Incoming request to gatekeeper:
  - URL: http://localhost:8000/proxy/home-api/health
  - After removing PROXY_PATH -> "/home-api/health"
  - Longest-prefix match -> "/home-api" -> upstream base "http://localhost:8081"
  - Remaining (trimmed) path -> "/health"
  - Forwarded request to upstream -> http://localhost:8081/health

The empty-string key ("") in UPSTREAMS acts as the default fallback and will match any path not matched by a longer prefix.

## gk CLI

The gatekeeper CLI (`gk`) is a CLI client for interacting with gatekeeper instances.

See the full [gk README](./gk/README.md) for usage, commands, and setup details.

## Testing

Run the tests using pytest:

```bash
pytest
```
