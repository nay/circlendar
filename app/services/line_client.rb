class LineClient
  TOKEN_URL = "https://api.line.me/oauth2/v2.1/token"
  PROFILE_URL = "https://api.line.me/v2/profile"

  def initialize
    setting = Setting.instance
    @channel_id = setting.line_channel_id
    @channel_secret = setting.line_channel_secret
  end

  def authorize_url(state:, redirect_uri:)
    params = {
      response_type: "code",
      client_id: @channel_id,
      redirect_uri: redirect_uri,
      state: state,
      scope: "profile openid"
    }
    "https://access.line.me/oauth2/v2.1/authorize?#{params.to_query}"
  end

  def get_access_token(code:, redirect_uri:)
    uri = URI.parse(TOKEN_URL)
    response = Net::HTTP.post_form(uri, {
      grant_type: "authorization_code",
      code: code,
      redirect_uri: redirect_uri,
      client_id: @channel_id,
      client_secret: @channel_secret
    })

    body = JSON.parse(response.body)
    raise "LINE token error: #{body['error_description']}" unless response.is_a?(Net::HTTPSuccess)

    body["access_token"]
  end

  def get_profile(access_token)
    uri = URI.parse(PROFILE_URL)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    body = JSON.parse(response.body)
    raise "LINE profile error: #{body['message']}" unless response.is_a?(Net::HTTPSuccess)

    { user_id: body["userId"], display_name: body["displayName"] }
  end
end
