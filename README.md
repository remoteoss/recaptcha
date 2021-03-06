# Recaptcha


[![Last Updated](https://img.shields.io/github/last-commit/remoteoss/recaptcha.svg)](https://img.shields.io/github/last-commit/remoteoss/recaptcha.svg)

A simple Elixir package for implementing [reCAPTCHA] in Elixir applications. Forked from [samueljseay/recaptcha](https://github.com/samueljseay/recaptcha) and [bounceapp/recaptcha](https://github.com/Bounceapp/recaptcha).

[reCAPTCHA]: http://www.google.com/recaptcha

## Migration from 1.x to 2.x

### Breaking Changes

1. Template functionality is now in a separate module: `Recaptcha.Template`. Please note: in future templating may move to a Phoenix specific package.
2. `verify` API has changed, see the code for documentation of the new API.

Most other questions about 2.x should be answered by looking over the documentation and the code. Please raise an issue
if you have any problems with migrating.

## Migration from 3.x to 4.x

- Now requires Elixir version 1.13 or later
- The reCATPCHA widget has been removed. If you need this widget we suggest you inline it in your
  project from the previous version of this library.

## Installation

Add `:recaptcha` to your `mix.exs` dependencies:

```elixir
  defp deps do
    [
      {:recaptcha, github: "remoteoss/recaptcha"},
    ]
  end
```

List `:recaptcha` as an application dependency:

```elixir
  def application do
    [
      extra_applications: [:recaptcha]
    ]
  end
```

Run `mix do deps.get, compile`

## Config

By default the public and private keys are loaded via the `RECAPTCHA_PUBLIC_KEY` and `RECAPTCHA_PRIVATE_KEY` environment variables.

```elixir
config :recaptcha,
  public_key: {:system, "RECAPTCHA_PUBLIC_KEY"},
  secret: {:system, "RECAPTCHA_PRIVATE_KEY"}
```

### JSON Decoding

By default `reCaptcha` will use `Jason` to decode JSON responses, this can be changed as such:

```elixir
config :recaptcha, :json_library, Poison
```

## Usage


Recaptcha provides the `verify/2` method. Below is an example using a Phoenix controller action:

```elixir
def create(conn, params) do
  case Recaptcha.verify(params["g-recaptcha-response"]) do
    {:ok, response} -> do_something
    {:error, errors} -> handle_error
  end
end
```

`verify` method sends a `POST` request to the reCAPTCHA API and returns 2 possible values:

`{:ok, %Recaptcha.Response{challenge_ts: timestamp, hostname: host}}` -> The captcha is valid, see the [documentation](https://developers.google.com/recaptcha/docs/verify#api-response) for more details.

`{:error, errors}` -> `errors` contains atomised versions of the errors returned by the API, See the [error documentation](https://developers.google.com/recaptcha/docs/verify#error-code-reference) for more details. Errors caused by timeouts in HTTPoison or Jason encoding are also returned as atoms. If the recaptcha request succeeds but the challenge is failed, a `:challenge_failed` error is returned.

`verify` method also accepts a keyword list as the third parameter with the following options:

Option                  | Action                                                 | Default
:---------------------- | :----------------------------------------------------- | :------------------------
`timeout`               | Time to wait before timeout                            | 5000 (ms)
`secret`                | Private key to send as a parameter of the API request  | Private key from the config file
`remote_ip`             | Optional. The user's IP address, used by reCaptcha     | no default


## Testing

In order to test your endpoints you should set the secret key to the following value in order to receive a positive result from all queries to the Recaptcha engine.

```elixir
config :recaptcha,
  secret: "6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe"
```

Setting up tests without network access can be done also. When configured as such a positive or negative result can be generated locally.

```elixir
config :recaptcha,
  http_client: Recaptcha.Http.MockClient,
  secret: "6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe"


  {:ok, _details} = Recaptcha.verify("valid_response")

  {:error, _details} = Recaptcha.verify("invalid_response")

```

## Contributing

Check out [CONTRIBUTING.md](/CONTRIBUTING.md) if you want to help.

## Copyright and License

Copyright (c) 2016 Samuel Seay

This library is released under the MIT License. See the [LICENSE.md](./LICENSE.md) file
for further details.
