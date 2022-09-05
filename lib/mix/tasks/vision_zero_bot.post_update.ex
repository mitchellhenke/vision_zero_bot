defmodule Mix.Tasks.VisionZeroBot.PostUpdate do
  use Mix.Task

  def run(_args) do
    Mix.Task.run("app.start")

    api_key = System.fetch_env!("TWITTER_CONSUMER_API_KEY")
    api_key_secret = System.fetch_env!("TWITTER_CONSUMER_API_SECRET")
    access_token = System.fetch_env!("TWITTER_ACCESS_TOKEN")
    access_token_secret = System.fetch_env!("TWITTER_ACCESS_TOKEN_SECRET")
    :crypto.hash(:sha512, api_key) |> Base.encode32() |> IO.inspect(label: "api_key")
    :crypto.hash(:sha512, api_key_secret) |> Base.encode32() |> IO.inspect(label: "api_key_secret")
    :crypto.hash(:sha512, access_token_secret) |> Base.encode32() |> IO.inspect(label: "access_token_secret")
    :crypto.hash(:sha512, access_token) |> Base.encode32() |> IO.inspect(label: "access_token")

    ExTwitter.configure(
      consumer_key: api_key,
      consumer_secret: api_key_secret,
      access_token: access_token,
      access_token_secret: access_token_secret
    )

    Finch.start_link(name: MyFinch)

    url =
      "https://transportal.cee.wisc.edu/partners/community-maps/crash/public/crashesKML.do?filetype=json&startyear=2022&injsvr=K&injsvr=A&county=milwaukee"

    today = Date.utc_today()

    crashes =
      with req <- Finch.build(:get, url),
           {:ok, %{body: body}} <- Finch.request(req, MyFinch),
           {:ok, map} <- Jason.decode(body),
           {:ok, features} <- Map.fetch(map, "features") do
        features
      end
      |> Enum.map(fn feature ->
        update_in(feature, ["properties", "date"], fn string_date ->
          [month, day, year] = String.split(string_date, "/")

          Date.new!(
            String.to_integer(year),
            String.to_integer(month),
            String.to_integer(day)
          )
        end)
        |> update_in(["properties", "totfatl"], &String.to_integer/1)
        |> update_in(["properties", "totinj"], &String.to_integer/1)
      end)
      |> Enum.filter(fn feature ->
        get_in(feature, ["properties", "muniname"]) == "MILWAUKEE"
      end)

    one_week_ago = Date.add(today, -7)

    last_week =
      Enum.filter(crashes, fn crash ->
        Date.compare(get_in(crash, ["properties", "date"]), one_week_ago) in [:gt, :eq]
      end)

    last_week_total_fatalities =
      Enum.map(last_week, fn crash ->
        get_in(crash, ["properties", "totfatl"])
      end)
      |> Enum.sum()

    last_week_total_injuries =
      Enum.map(last_week, fn crash ->
        get_in(crash, ["properties", "totinj"])
      end)
      |> Enum.sum()

    yearly_total_fatalities =
      Enum.map(crashes, fn crash ->
        get_in(crash, ["properties", "totfatl"])
      end)
      |> Enum.sum()

    yearly_total_injuries =
      Enum.map(crashes, fn crash ->
        get_in(crash, ["properties", "totinj"])
      end)
      |> Enum.sum()

    last_week_formatted =
      "#{Calendar.strftime(one_week_ago, "%m/%d")}-#{Calendar.strftime(today, "%m/%d")}"

    tweet = """
    Since the beginning of the year, traffic violence has killed #{yearly_total_fatalities} people and seriously injured #{yearly_total_injuries} people in our city.
    #VisionZero #StopTrafficViolence
    """

    ExTwitter.update(tweet)
  end
end
