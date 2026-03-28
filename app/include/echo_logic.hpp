#pragma once

#include <nlohmann/json.hpp>
#include <string>

namespace lab {

nlohmann::json make_health_payload();
nlohmann::json make_version_payload(const std::string& version, const std::string& git_commit = "unknown");
nlohmann::json make_echo_payload(const nlohmann::json& request_body);

} // namespace lab
