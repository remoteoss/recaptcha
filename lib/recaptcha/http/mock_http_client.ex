defmodule Recaptcha.Http.MockClient do
  @moduledoc """
  A HTTP client used for testing that will send a message to the process that is calling it with the
  arguments received, which allows to verify these values in the tests.
  """
  alias Recaptcha.Http

  def request_verification(body, options) do
    send(self(), {:request_verification, body, options})
    Http.request_verification(body, options)
  end
end
