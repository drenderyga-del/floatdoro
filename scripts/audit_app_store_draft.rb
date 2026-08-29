#!/usr/bin/env ruby

require "digest"
require "json"
require "spaceship"

BUNDLE_ID = "io.github.drenderyga-del.floatdoro"
PLATFORM = Spaceship::ConnectAPI::Platform::MAC_OS
DESKTOP_SCREENSHOT_TYPE = Spaceship::ConnectAPI::AppScreenshotSet::DisplayType::APP_DESKTOP

version_string = ARGV.fetch(0)
build_number = ARGV.fetch(1)
api_key_path = ENV.fetch("APP_STORE_API_KEY_JSON")
project_dir = File.expand_path("..", __dir__)

unless version_string.match?(/\A[0-9]+(?:\.[0-9]+){1,2}\z/)
  abort("Invalid marketing version: #{version_string}")
end

unless build_number.match?(/\A[0-9]+\z/)
  abort("Invalid build number: #{build_number}")
end

def text_file(*components)
  File.read(File.join(*components), encoding: "UTF-8").strip
end

checks = []
record = lambda do |scope, name, actual, expected|
  checks << {
    "scope" => scope,
    "name" => name,
    "ok" => actual == expected
  }
end

token = Spaceship::ConnectAPI::Token.from_json_file(api_key_path)
Spaceship::ConnectAPI.token = token

app = Spaceship::ConnectAPI::App.find(BUNDLE_ID)
abort("App not found for bundle ID #{BUNDLE_ID}") unless app

version = app.get_edit_app_store_version(
  platform: PLATFORM,
  includes: "appStoreVersionSubmission,build"
)
abort("No editable macOS App Store version found") unless version

build = version.respond_to?(:build) ? version.build : nil
build ||= version.get_build

record.call("version", "marketing version", version.version_string, version_string)
record.call("version", "selected build", build&.version, build_number)
record.call("version", "build processing state", build&.processing_state, "VALID")
record.call("version", "manual release", version.release_type, "MANUAL")
record.call("version", "not submitted", version.app_store_version_submission.nil?, true)
record.call(
  "version",
  "editable state",
  ["PREPARE_FOR_SUBMISSION", "READY_FOR_REVIEW"].include?(version.app_version_state),
  true
)
record.call(
  "version",
  "copyright",
  version.copyright.to_s.strip,
  "2026 drenderyga-del"
)

app_info = app.fetch_edit_app_info || app.fetch_latest_app_info
app_info_localizations = app_info ? app_info.get_app_info_localizations : []
version_localizations = version.get_app_store_version_localizations

record.call("app info", "primary category", app_info&.primary_category&.id, "PRODUCTIVITY")
record.call("app info", "secondary category", app_info&.secondary_category&.id, "UTILITIES")

screenshots = {}

["en-US", "ru"].each do |locale|
  metadata_dir = File.join(project_dir, "app-store", "metadata", locale)
  release_notes = File.join(project_dir, "app-store", "release-notes", version_string, "#{locale}.txt")
  app_info_localization = app_info_localizations.find { |item| item.locale == locale }
  version_localization = version_localizations.find { |item| item.locale == locale }

  record.call(locale, "localization exists", !app_info_localization.nil? && !version_localization.nil?, true)
  next unless app_info_localization && version_localization

  record.call(locale, "name", app_info_localization.name.to_s.strip, text_file(metadata_dir, "name.txt"))
  record.call(locale, "subtitle", app_info_localization.subtitle.to_s.strip, text_file(metadata_dir, "subtitle.txt"))
  record.call(
    locale,
    "privacy URL",
    app_info_localization.privacy_policy_url.to_s.strip,
    "https://drenderyga-del.github.io/floatdoro/privacy.html"
  )
  record.call(locale, "description", version_localization.description.to_s.strip, text_file(metadata_dir, "description.txt"))
  record.call(locale, "keywords", version_localization.keywords.to_s.strip, text_file(metadata_dir, "keywords.txt"))
  record.call(
    locale,
    "promotional text",
    version_localization.promotional_text.to_s.strip,
    text_file(metadata_dir, "promotional-text.txt")
  )
  record.call(
    locale,
    "support URL",
    version_localization.support_url.to_s.strip,
    "https://drenderyga-del.github.io/floatdoro/support.html"
  )
  record.call(
    locale,
    "marketing URL",
    version_localization.marketing_url.to_s.strip,
    "https://drenderyga-del.github.io/floatdoro/"
  )
  record.call(locale, "release notes", version_localization.whats_new.to_s.strip, text_file(release_notes))

  screenshot_set = version_localization
                   .get_app_screenshot_sets(includes: "appScreenshots")
                   .find { |item| item.screenshot_display_type == DESKTOP_SCREENSHOT_TYPE }
  remote_screenshots = screenshot_set&.app_screenshots || []
  expected_screenshot_files = Dir[File.join(project_dir, "app-store", "screenshots", locale, "*.jpg")].sort
  expected_checksums = expected_screenshot_files.map { |file| Digest::MD5.file(file).hexdigest }
  remote_checksums = remote_screenshots.map { |item| item.source_file_checksum.to_s.downcase }

  record.call(locale, "desktop screenshot count", remote_screenshots.length, 4)
  record.call(locale, "desktop screenshot order and content", remote_checksums, expected_checksums)
  record.call(
    locale,
    "desktop screenshot processing",
    remote_screenshots.all?(&:complete?),
    true
  )
  record.call(
    locale,
    "desktop screenshot dimensions",
    remote_screenshots.map { |item| [item.image_asset&.fetch("width", nil), item.image_asset&.fetch("height", nil)] },
    Array.new(4, [2880, 1800])
  )

  screenshots[locale] = remote_screenshots.map do |item|
    {
      "file_name" => item.file_name,
      "checksum" => item.source_file_checksum,
      "state" => item.asset_delivery_state&.fetch("state", nil),
      "width" => item.image_asset&.fetch("width", nil),
      "height" => item.image_asset&.fetch("height", nil)
    }
  end
end

review_detail = version.fetch_app_store_review_detail
record.call(
  "review",
  "review notes",
  review_detail&.notes.to_s.strip,
  text_file(project_dir, "app-store", "metadata", "en-US", "review-notes.txt")
)
record.call("review", "demo account not required", review_detail&.demo_account_required, false)

report = {
  "ready" => checks.all? { |check| check["ok"] },
  "app" => {
    "id" => app.id,
    "bundle_id" => app.bundle_id,
    "primary_locale" => app.primary_locale
  },
  "version" => {
    "id" => version.id,
    "version_string" => version.version_string,
    "state" => version.app_version_state,
    "release_type" => version.release_type,
    "build_number" => build&.version,
    "build_processing_state" => build&.processing_state,
    "submission_present" => !version.app_store_version_submission.nil?
  },
  "checks" => checks,
  "screenshots" => screenshots
}

puts(JSON.pretty_generate(report))
