defmodule Pesapal do
  @moduledoc """
  Documentation for `Pesapal`.
  """
  @sandbox_url "https://cybqa.pesapal.com/pesapalv3/api"
  @live_url "https://pay.pesapal.com/v3/api"

  # Get credentials from config
  @config Application.get_all_env(:pesapal)

  @doc """
  Get Config

  ## Examples

      iex> Pesapal.config()
      %{}
  """
  def config(key \\ nil, default \\ nil) do
    if key do
      get_in(@config, [key])
    else
      @config
    end
  end

  @doc """
  Get full url based if sandbox or live

  ## Examples

      iex> Pesapal.get_url("/pesapalv3/PostPesapalDirectOrderV4")
      "https://cybqa.pesapal.com/pesapalv3/pesapalv3/PostPesapalDirectOrderV4"
  """
  def get_url(url) do
    base_url = if is_live(), do: @live_url, else: @sandbox_url
    "#{base_url}#{url}"
  end

  defp is_live do
    get_in(@config, [:live]) == :live
  end
end
