defmodule Pesapal.RequestManager do
  use HTTPoison.Base

  require Logger

  @user_agent "pesapal"

  def process_request_url(url), do: get_api_url(url)

  def process_request_body(body) do
    Logger.debug("Mpesa.RequestManager.Request_Body #{inspect(body)}")
    body |> Jason.encode!()
  end

  def process_response(%HTTPoison.Response{status_code: code, body: body} = response)
      when code in 200..299 do
    Logger.debug("Mpesa.RequestManager.Process_Response.OK #{code} #{inspect(response)}")

    result = Jason.decode!(body)

    case result["error"] do
      nil -> result
      _ -> {:error, result["error"]}
    end
  end

  def process_response(response) do
    Logger.debug("Mpesa.RequestManager.Process_Response #{inspect(response)}")
    IO.inspect(response)
  end

  # def process_response(%HTTPoison.Error{reason: reason}) do
  #   Logger.error("Mpesa.RequestManager.Process_Response #{inspect(reason)}")
  #   reason
  # end

  @doc """
  Generate auth token

  ## Examples

      iex> Pesapal.authenticate()
      %{:ok, %{token: "blah", expiryDate: "blah"}}
  """
  def authenticate() do
    body = %{"consumer_key" => Pesapal.config(:key), "consumer_secret" => Pesapal.config(:secret)}

    headers = set_headers("application/json")
    __MODULE__.post("/Auth/RequestToken", body, headers)
  end

  @doc """
  Register IPN url

  type: (string) POST or GET

  ## Examples

      iex> Pesapal.register_ipn("POST")
      %{}
  """
  def register_ipn(type \\ "POST") do
    body = %{
      "url" => Pesapal.config(:ipn_url),
      "ipn_notification_type" => type
    }

    headers =
      set_headers("application/json")
      |> set_auth_header()

    __MODULE__.post("/URLSetup/RegisterIPN", body, headers)
  end

  @doc """
    Submit create order request

    order_no: (string|int) unique order number
    amount: (float) amount to be paid
    description: (string) description of the order
    ipn_id: (string) unique IPN id see Pesapal.IPN
    customer: (map) customer details either email_address or phone_number is required
    currency: (string) currency to be used default is KES

    ## Examples

        iex> Pesapal.create_order("123456", 200, "Order 123456", "123456", %{email_address: "
  """
  @spec create_order(String.t(), float(), String.t(), String.t(), Map.t(), String.t()) :: any()
  def create_order(order_no, amount, description, ipn_id, customer, currency \\ "KES") do
    body = %{
      "id" => order_no,
      "currency" => currency,
      "amount" => amount,
      "description" => description,
      "callback_url" => Pesapal.config(:ipn_url),
      "notification_id" => ipn_id,
      "billing_address" => customer
    }

    __MODULE__.post("/Transactions/SubmitOrderRequest", body, set_headers() |> set_auth_header())
  end

  @doc """
    Command_id: use "SalaryPayment", "BusinessPayment", "PromotionPayment"
    amount: eg 200
    partyb: your number eg 254718101442

  """
  def order_status(order_id) do
    url = "/Transactions/GetTransactionStatus?orderTrackingId=#{order_id}"
    headers = set_headers()

    __MODULE__.post(url, %{}, headers)
  end

  defp set_headers(accept \\ "*/*") do
    []
    |> Keyword.put(:"Content-Type", "application/json")
    |> Keyword.put(:Accept, accept)
  end

  defp set_auth_header(headers) do
    case authenticate() do
      {:ok, result} ->
        Keyword.put(headers, :Authorization, "Bearer #{result["token"]}")

      {:error, %HTTPoison.Response{body: body}} ->
        Logger.error("Mpesa.RequestManager.SET_HEADER #{inspect(body)}")
        headers
    end
  end

  defp get_api_url(url) do
    if Pesapal.is_live() do
      Pesapal.get_url("/v3/api") <> url
    else
      Pesapal.get_url("/pesapalv3/api") <> url
    end
  end
end
