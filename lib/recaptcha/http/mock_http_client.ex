defmodule Recaptcha.Http.MockClient do
  @moduledoc """
  A mock HTTP client used for testing.
  """
  alias Recaptcha.Http

  def request_verification(body, options \\ [])

  def request_verification(
        "response=valid_response&secret=6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe" = body,
        options
      ) do
    send(self(), {:request_verification, body, options})

    {:ok,
     %{
       "success" => true,
       "challenge_ts" => "timestamp",
       "hostname" => "localhost",
       "score" => 1.0,
       "action" => "mock"
     }}
  end

  def request_verification(
        "response=invalid_response&secret=6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe" = body,
        options
      ) do
    send(self(), {:request_verification, body, options})
    {:error, [:"invalid-input-response"]}
  end

  # This clause is used to simulate reCAPTCHA's API returning multiple error codes as the old test
  # wasn't working anymore and I was not able to make the API trigger multiple error codes manually,
  # even though the `error-codes` field in the response is a list of errors.
  def request_verification("response=not_valid&secret=test_secret" = body, options) do
    send(self(), {:request_verification, body, options})
    {:error, [:invalid_input_response, :invalid_input_secret]}
  end

  # every other match is a pass through to the real client
  def request_verification(body, options) do
    send(self(), {:request_verification, body, options})
    Http.request_verification(body, options)
  end
end
