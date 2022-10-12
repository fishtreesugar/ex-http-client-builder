defmodule HttpClientBuilderTest do
  use ExUnit.Case

  alias HttpbinClient
  import ExUnit.CaptureLog

  setup do
    {:ok, _pid} = start_supervised(HttpbinClient)
    {:ok, _pid} = start_supervised(HttpbinClient2)
    :ok
  end

  test "returns child_spec with pools opts" do
    child_spec_with_pools_opts = %{
      id: HttpbinClient,
      start: {Finch, :start_link, [[name: HttpbinClient, pools: HttpbinClient.pools_opts()]]},
      type: :supervisor
    }

    child_spec_with_pools_opts2 = %{
      id: HttpbinClient2,
      start: {Finch, :start_link, [[name: HttpbinClient2, pools: HttpbinClient.pools_opts()]]},
      type: :supervisor
    }

    assert HttpbinClient.child_spec([]) == child_spec_with_pools_opts
    assert HttpbinClient2.child_spec([]) == child_spec_with_pools_opts2
  end

  @tag :httpbin
  test "multiple client could work together" do
    params = %{"foo" => "bar", "baz" => "quux"}

    with {:ok, resp1} <- HttpbinClient.get_endpoint(params),
         {:ok, resp2} <- HttpbinClient2.get_endpoint(params) do
      resp_body1 = Jason.decode!(resp1.body)
      resp_body2 = Jason.decode!(resp2.body)

      assert Map.get(resp_body1, "args") == Map.get(resp_body2, "args")
    else
      {:error, _error} -> assert false
    end
  end

  @tag :httpbin
  test "request to httpbin get endpoint" do
    params = %{"foo" => "bar", "baz" => "quux"}

    case HttpbinClient.get_endpoint(params) do
      {:ok, resp} ->
        resp_body = Jason.decode!(resp.body)
        assert Map.get(resp_body, "args") == params

      {:error, _error} ->
        assert false
    end
  end

  @tag :httpbin
  test "request to httpbin get endpoint with encoded array query params" do
    params = %{"foo" => [1, "2"], "baz" => "quux"}

    case HttpbinClient.get_endpoint(params) do
      {:ok, resp} ->
        resp_body = Jason.decode!(resp.body)

        assert Map.get(resp_body, "args") == %{
                 # Note: This's httpbin's style not plug's style
                 # plug returns "foo" => ["1", "2"]
                 "foo[]" => ["1", "2"],
                 "baz" => "quux"
               }

      {:error, _error} ->
        assert false
    end
  end

  @tag :httpbin
  test "request to httpbin post endpoint" do
    params = %{"foo" => "bar", "baz" => "quux"}
    body = %{"this" => "is", "a" => "body"}

    log =
      capture_log(fn ->
        case HttpbinClient.post_endpoint(params, Jason.encode!(body)) do
          {:ok, resp} ->
            resp_body = Jason.decode!(resp.body)

            assert Map.get(resp_body, "args") == params
            assert Map.get(resp_body, "json") == body

          {:error, _error} ->
            assert false
        end
      end)

    assert log =~ "override spercific path /post"
  end

  @tag :httpbin
  test "request to httpbin put endpoint" do
    params = %{"foo" => "bar", "baz" => "quux"}
    body = %{"this" => "is", "a" => "body"}

    case HttpbinClient.put_endpoint(params, Jason.encode!(body)) do
      {:ok, resp} ->
        resp_body = Jason.decode!(resp.body)

        assert Map.get(resp_body, "args") == params
        assert Map.get(resp_body, "json") == body

      {:error, _error} ->
        assert false
    end
  end

  @tag :httpbin
  test "request to httpbin delete endpoint" do
    body = %{"this" => "is", "a" => "body"}

    case HttpbinClient.delete_endpoint(Jason.encode!(body)) do
      {:ok, resp} ->
        resp_body = Jason.decode!(resp.body)

        assert Map.get(resp_body, "json") == body

      {:error, _error} ->
        assert false
    end
  end

  @tag :httpbin
  test "request to httpbin patch endpoint" do
    body = %{"this" => "is", "a" => "body"}

    case HttpbinClient.patch_endpoint(Jason.encode!(body)) do
      {:ok, resp} ->
        resp_body = Jason.decode!(resp.body)

        assert Map.get(resp_body, "json") == body

      {:error, _error} ->
        assert false
    end
  end

  @tag :httpbin
  test "request with custom header" do
    custom_header_name = "X-Custom-Header"
    custom_header_value = "FTW"

    log =
      capture_log(fn ->
        case HttpbinClient.post_endpoint(nil, nil, [{custom_header_name, custom_header_value}]) do
          {:ok, resp} ->
            resp_body = Jason.decode!(resp.body)
            assert get_in(resp_body, ["headers", custom_header_name]) == custom_header_value

          {:error, _error} ->
            assert false
        end
      end)

    assert log =~ "override spercific path /post"
  end

  @tag :httpbin
  test "handle timeout" do
    case HttpbinClient.timeout_soon_endpoint(nil) do
      {:ok, _resp} ->
        assert false, "Should be timeout"

      {:error, %{reason: reason}} ->
        assert reason == :timeout
    end
  end
end
