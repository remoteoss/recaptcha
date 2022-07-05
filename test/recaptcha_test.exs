defmodule RecaptchaTest do
  use ExUnit.Case, async: true

  setup do
    [bypass: Bypass.open()]
  end

  @success_response ~s<{
    "success": true,
    "challenge_ts": "1656931794",
    "hostname": "localhost",
    "action": "verify",
    "score": 0.7
  }>

  test "When the supplied g-recaptcha-response is invalid, multiple errors are returned", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/recaptcha/api/siteverify", fn conn ->
      response = ~s<{"success": false, "error-codes": ["invalid-input-response", "invalid-input-secret"]}>
      Plug.Conn.resp(conn, 200, response)
    end)

    assert {:error, messages} = Recaptcha.verify("not_valid", url: verify_url(bypass.port))
    assert messages == [:invalid_input_response, :invalid_input_secret]
  end

  test "When a valid response is supplied, a success response is returned", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/recaptcha/api/siteverify", fn conn ->
      Plug.Conn.resp(conn, 200, @success_response)
    end)

    assert {:ok, %{challenge_ts: _, hostname: _}} = Recaptcha.verify("valid_response", url: verify_url(bypass.port))
  end

  test "When an invalid response is supplied, an error response is returned", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/recaptcha/api/siteverify", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"success": false, "error-codes": ["invalid-input-response"]}>)
    end)

    assert {:error, [:invalid_input_response]} = Recaptcha.verify("invalid_response", url: verify_url(bypass.port))
  end

  test "When secret is not overridden the configured secret is used", %{bypass: bypass} do
    expected_body = "response=valid_response&secret=#{Recaptcha.Config.get_env(:recaptcha, :secret)}"

    Bypass.expect_once(bypass, "POST", "/recaptcha/api/siteverify", fn conn ->
      Plug.Conn.resp(conn, 200, @success_response)
    end)

    Recaptcha.verify("valid_response", url: verify_url(bypass.port))

    assert_received {:request_verification, ^expected_body, _}
  end

  test "When the timeout is overridden that config is passed to verify/2 as an option", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/recaptcha/api/siteverify", fn conn ->
      Plug.Conn.resp(conn, 200, @success_response)
    end)

    Recaptcha.verify("valid_response", timeout: 25_000, url: verify_url(bypass.port))

    assert_received {:request_verification, _, opts}
    assert opts[:timeout] == 25_000
  end

  test "Passes other options to the http client", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/recaptcha/api/siteverify", fn conn ->
      Plug.Conn.resp(conn, 200, @success_response)
    end)

    Recaptcha.verify("valid_response", timeout: 25_000, recv_timeout: 5_000, url: verify_url(bypass.port))

    assert_received {:request_verification, _, opts}
    assert opts[:timeout] == 25_000
    assert opts[:recv_timeout] == 5_000
  end

  test "Remote IP is used in the request body when it is passed into verify/2 as an option", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/recaptcha/api/siteverify", fn conn ->
      Plug.Conn.resp(conn, 200, @success_response)
    end)

    Recaptcha.verify("valid_response", remote_ip: "192.168.1.1", url: verify_url(bypass.port))

    assert_received {:request_verification, "response=valid_response&secret=test_secret&remote_ip=192.168.1.1", _}
  end

  test "Adding unsupported options does not append them to the request body", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/recaptcha/api/siteverify", fn conn ->
      Plug.Conn.resp(conn, 200, @success_response)
    end)

    Recaptcha.verify("valid_response", unsupported_option: "not_valid", url: verify_url(bypass.port))

    assert_received {:request_verification, "response=valid_response&secret=test_secret", _}
  end

  defp verify_url(port), do: "http://localhost:#{port}/recaptcha/api/siteverify"
end
