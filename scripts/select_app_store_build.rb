#!/usr/bin/env ruby

require "json"
require "spaceship"

BUNDLE_ID = "io.github.drenderyga-del.floatdoro"
PLATFORM = Spaceship::ConnectAPI::Platform::MAC_OS

version_string = ARGV.fetch(0)
build_number = ARGV.fetch(1)
api_key_path = ENV.fetch("APP_STORE_API_KEY_JSON")

unless version_string.match?(/\A[0-9]+(?:\.[0-9]+){1,2}\z/)
  abort("Invalid marketing version: #{version_string}")
end

unless build_number.match?(/\A[0-9]+\z/)
  abort("Invalid build number: #{build_number}")
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
abort("Expected editable version #{version_string}, found #{version.version_string}") unless version.version_string == version_string
abort("App Store version already has a submission") unless version.app_store_version_submission.nil?
abort("App Store version is not configured for manual release") unless version.release_type == "MANUAL"

builds = Spaceship::ConnectAPI::Build.all(
  app_id: app.id,
  version: version_string,
  build_number: build_number,
  platform: PLATFORM
)
build = builds.find { |candidate| candidate.version == build_number }
abort("Build #{version_string} (#{build_number}) not found") unless build
abort("Build #{version_string} (#{build_number}) is not valid: #{build.processing_state}") unless build.processing_state == "VALID"

current_build = version.respond_to?(:build) ? version.build : nil
changed = current_build&.id != build.id
version.select_build(build_id: build.id) if changed

verified_version = Spaceship::ConnectAPI::AppStoreVersion.get(
  app_store_version_id: version.id,
  includes: "appStoreVersionSubmission,build"
)
verified_build = verified_version.respond_to?(:build) ? verified_version.build : nil
abort("Build selection verification failed") unless verified_build&.id == build.id

puts(
  JSON.pretty_generate(
    {
      "changed" => changed,
      "version" => verified_version.version_string,
      "build_number" => verified_build.version,
      "build_processing_state" => verified_build.processing_state,
      "release_type" => verified_version.release_type,
      "submission_present" => !verified_version.app_store_version_submission.nil?
    }
  )
)
