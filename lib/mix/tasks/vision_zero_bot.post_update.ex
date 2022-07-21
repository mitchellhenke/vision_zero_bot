defmodule Mix.Tasks.VisionZeroBot.PostUpdate do
  use Mix.Task

  def run(_args) do
    Mix.Task.run("app.start")

    String.slice(System.fetch_env!("TWITTER_ACCESS_TOKEN"), 0, 10)
    |> IO.inspect
    String.slice(System.fetch_env!("TWITTER_ACCESS_TOKEN_SECRET"), 0, 10)
    |> IO.inspect
    String.slice(System.fetch_env!("TWITTER_CONSUMER_API_KEY"), 0, 10)
    |> IO.inspect
    String.slice(System.fetch_env!("TWITTER_CONSUMER_API_SECRET"), 0, 10)
    |> IO.inspect
    ExTwitter.configure(
      consumer_key: System.fetch_env!("TWITTER_ACCESS_TOKEN"),
      consumer_secret: System.fetch_env!("TWITTER_ACCESS_TOKEN_SECRET"),
      access_token: System.fetch_env!("TWITTER_CONSUMER_API_KEY"),
      access_token_secret: System.fetch_env!("TWITTER_CONSUMER_API_SECRET")
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
    Last week in Milwaukee (#{last_week_formatted}), there were #{last_week_total_fatalities} traffic fatalities and #{last_week_total_injuries} serious injuries.
    Since the beginning of the year, traffic violence has killed #{yearly_total_fatalities} people and seriously injured #{yearly_total_injuries} people in our city.
    #VisionZero #StopTrafficViolence
    """

    ExTwitter.update(tweet)
  end
end
