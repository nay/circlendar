require "rails_helper"

RSpec.describe "FactoryBot のファクトリ" do
  it "すべてのファクトリとトレイトで、検証の通るレコードを作れる" do
    expect { FactoryBot.lint(traits: true) }.not_to raise_error
  end
end
