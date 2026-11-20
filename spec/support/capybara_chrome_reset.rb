# Chrome 158 から、Capybara 3.40.0 の reset! が送る Storage.clearDataForOrigin の origin: "*" が受け付けられなくなったため、
# "*" を使わない命令に置き換える。Capybara が直った版を出したら消す。
# https://github.com/teamcapybara/capybara/issues/2865
module ChromeResetWithoutWildcardOrigin
  private

  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    super("Network.clearBrowserCookies")
    super(cmd, { origin: Capybara.current_session.server.base_url, storageTypes: "local_storage" }) if params[:storageTypes].include?("local_storage")
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeResetWithoutWildcardOrigin)
