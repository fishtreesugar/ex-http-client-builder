defmodule HttpClientBuilder do
  @moduledoc """
  A set of helpers for building HTTP client with finch easily.
  """

  defmacro __using__(client_opts \\ []) do
    case client_opts[:base_url_getter] do
      # absent
      nil ->
        :ok

      # anonymous function
      {:fn, _, _} ->
        :ok

      # function capture
      {:&, _, _} ->
        :ok

      _ ->
        raise ":base_url_getter option is not a nullary anonymous function or function capture "
    end

    case client_opts[:runtime_headers_getter] do
      # absent
      nil ->
        :ok

      # anonymous function
      {:fn, _, _} ->
        :ok

      # function capture
      {:&, _, _} ->
        :ok

      _ ->
        raise ":runtime_headers_getter option is not a nullary anonymous function or function capture "
    end

    quote do
      def child_spec(opts) do
        default_pools = %{:default => [size: 50]}
        pools = Keyword.get(unquote(client_opts), :pools, default_pools)

        %{
          id: __MODULE__,
          start: {Finch, :start_link, [[name: __MODULE__, pools: pools]]},
          type: :supervisor
        }
      end

      defp split_opts(opts) do
        {params, rest_opts} = Keyword.pop(opts, :params)

        default_headers = Keyword.get(unquote(client_opts), :headers, [])
        {headers, rest_opts} = Keyword.pop(rest_opts, :headers, default_headers)

        default_request_opts = Keyword.get(unquote(client_opts), :request_opts, [])
        {body, request_opts} = Keyword.pop(rest_opts, :body, nil)

        final_request_opts =
          if Enum.empty?(request_opts), do: default_request_opts, else: request_opts

        {params, headers, body, final_request_opts}
      end

      def get(url, opts \\ []) do
        do_request(:get, url, opts)
      end

      def post(url, opts \\ []) do
        do_request(:post, url, opts)
      end

      def put(url, opts \\ []) do
        do_request(:put, url, opts)
      end

      def delete(url, opts \\ []) do
        do_request(:delete, url, opts)
      end

      def patch(url, opts \\ []) do
        do_request(:patch, url, opts)
      end

      @doc """
      If `base_url_getter` option passed, it accept url's path,
      otherwise it accept full url. be careful when overriding this function for specific endpoint
      """
      def do_request(method, url_or_path, opts) do
        {params, compile_time_headers, body, request_opts} = split_opts(opts)

        url = build_url(url_or_path, params)

        headers =
          if unquote(client_opts)[:runtime_headers_getter] do
            (unquote(client_opts)[:runtime_headers_getter].() ++ compile_time_headers)
            |> dedup_headers()
          else
            compile_time_headers
          end

        method
        |> Finch.build(url, headers, body)
        |> Finch.request(__MODULE__, request_opts)
      end

      defp build_url(url_or_path, params) do
        base_url_getter = unquote(client_opts)[:base_url_getter]
        base_url = if base_url_getter, do: base_url_getter.(), else: ""
        query = if is_nil(params), do: "", else: "?" <> Plug.Conn.Query.encode(params)

        base_url <> url_or_path <> query
      end

      defp dedup_headers(headers) do
        headers
        |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, k, v) end)
        |> Map.to_list()
      end

      defoverridable get: 2, post: 2, put: 2, delete: 2, patch: 2, do_request: 3, build_url: 2
    end
  end
end
