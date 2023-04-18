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

The recommended way to mock responses from `recaptcha` is to create a module implementing a `request_verification/2`
function, and pass it to recaptcha's `:http_client` config, for example:

```elixir
defmodule RecaptchaMock do
	def request_verification(query_string, _opts) do
		# You can pattern-match against the secret and recaptcha response provided to `Recaptcha.verify/1` in the `query_string` in 
		# case you want different responses in your tests.
    response =
      cond do
        String.contains?(query_string, "response=zero_score") ->
          %{"success" => true, "score" => 0.0, "challenge_ts" => "timestamp", "hostname" => "localhost"}

        true ->
          %{"success" => true, "score" => 1.0, "challenge_ts" => "timestamp", "hostname" => "localhost"}
      end

		{:ok, response}
	end
end
```

And then, on your config:

```elixir
config :recaptcha, http_client: RecaptchaMock
```

This allows you to run tests without network, but you can still run automated tests against Recaptcha's servers by
following [Google's
guide](https://developers.google.com/recaptcha/docs/faq#id-like-to-run-automated-tests-with-recaptcha.-what-should-i-do).

## Contributing

Check out [CONTRIBUTING.md](/CONTRIBUTING.md) if you want to help.

## Copyright and License

Copyright (c) 2016 Samuel Seay

This library is released under the MIT License. See the [LICENSE.md](./LICENSE.md) file
for further details.
