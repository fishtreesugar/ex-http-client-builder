defmodule HttpbinClient do
  @moduledoc """
  Directly request to httpbin
  """

  @default_headers [
    {"accept", "application/json"}
  ]

  @pools %{
    default: [
      size: 23,
      count: 3
    ]
  }

  require Logger

  use HttpClientBuilder,
    headers: @default_headers,
    pools: @pools,
    base_url_getter: &base_url/0,
    runtime_headers_getter: &headers/0

  def base_url, do: "https://httpbin.org"

  def headers, do: [{"content-type", "application/json"}]

  # expose for testing
  def pools_opts do
    @pools
  end

  def get_endpoint(params, headers \\ []) do
    get("/get", params: params, headers: headers)
  end

  def post_endpoint(params, body, headers \\ []) do
    post("/post", params: params, body: body, headers: headers)
  end

  def put_endpoint(params, body, headers \\ []) do
    put("/put", params: params, body: body, headers: headers)
  end

  def delete_endpoint(body, headers \\ []) do
    delete("/delete", body: body, headers: headers)
  end

  def patch_endpoint(body, headers \\ []) do
    patch("/patch", body: body, headers: headers)
  end

  def timeout_soon_endpoint(params, headers \\ []) do
    get("/get", params: params, headers: headers, receive_timeout: 1)
  end

  def do_request(method, url = "/post", opts) do
    Logger.info("override spercific path #{url}")

    super(method, url, opts)
  end

  def do_request(method, url, opts) do
    super(method, url, opts)
  end
end
