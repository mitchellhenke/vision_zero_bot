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
    today = Date.utc_today()

    cond do
      System.get_env("SCHEDULE") == "WEEKLY" ->
        crashes = get_crashes(today.year)

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

        tweet = """
        Since the beginning of the year, traffic violence has killed #{yearly_total_fatalities} people and seriously injured #{yearly_total_injuries} people in our city.
        #VisionZero #StopTrafficViolence
        """

        ExTwitter.update(tweet)
        post_to_mastodon(tweet)

      System.get_env("SCHEDULE") == "YEARLY" ->
        last_year_crashes = get_crashes(today.year - 1)

        yearly_total_fatalities =
          Enum.map(last_year_crashes, fn crash ->
            get_in(crash, ["properties", "totfatl"])
          end)
          |> Enum.sum()

        yearly_total_injuries =
          Enum.map(last_year_crashes, fn crash ->
            get_in(crash, ["properties", "totinj"])
          end)
          |> Enum.sum()

        tweet = """
        In #{today.year - 1}, traffic violence killed #{yearly_total_fatalities} people and seriously injured #{yearly_total_injuries} people in our city.
        #VisionZero #StopTrafficViolence
        """

        ExTwitter.update(tweet)
        post_to_mastodon(tweet)
    end
  end

  def get_crashes(year) do
    url =
      "https://transportal.cee.wisc.edu/partners/community-maps/crash/public/crashesKML.do?filetype=json&startyear=#{year}&injsvr=K&injsvr=A&county=milwaukee"

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
  end

  def post_to_mastodon(content) do
    access_token = System.fetch_env!("MASTODON_ACCESS_TOKEN")
    headers = [{"authorization", "Bearer #{access_token}"}]

    body =
      %{
        status: content
      }
      |> Jason.encode!()

    headers = [{"content-type", "application/json"}, {"authorization", "Bearer #{access_token}"}]

    response =
      with req <- Finch.build(:post, "https://botsin.space/api/v1/statuses", headers, body),
           {:ok, resp = %{status: status, headers: _headers, body: body}} <-
             Finch.request(req, MyFinch),
           true <- status == 200,
           {:ok, json} <- Jason.decode(body),
           {:ok, _id} <- Map.fetch(json, "id") do
        resp
      end
  end
end
