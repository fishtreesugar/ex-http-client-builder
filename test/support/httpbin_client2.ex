defmodule HttpbinClient2 do
  @moduledoc """
  For test multiple client in one supervisor tree
  """

  @default_headers [
    {"accept", "application/json"},
    {"content-type", "application/json"}
  ]

  @pools %{
    default: [
      size: 23,
      count: 3
    ]
  }

  use HttpClientBuilder, headers: @default_headers, pools: @pools

  # expose for testing
  def pools_opts do
    @pools
  end

  def get_endpoint(params, headers \\ []) do
    get("https://httpbin.org/get", params: params, headers: headers)
  end

  def post_endpoint(params, body, headers \\ []) do
    post("https://httpbin.org/post", params: params, body: body, headers: headers)
  end

  def put_endpoint(params, body, headers \\ []) do
    put("https://httpbin.org/put", params: params, body: body, headers: headers)
  end

  def delete_endpoint(body, headers \\ []) do
    delete("https://httpbin.org/delete", body: body, headers: headers)
  end
end
