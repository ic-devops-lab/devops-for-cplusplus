#include "echo_logic.hpp"

#include <stdexcept>

namespace lab {

nlohmann::json make_health_payload() {
  return {
      {"status", "ok"},
      {"service", "autonomy-cicd-lab"},
  };
}

nlohmann::json make_version_payload(const std::string& version, const std::string& git_commit) {
  return {
      {"version", version},
      {"git_commit", git_commit},
  };
}

nlohmann::json make_echo_payload(const nlohmann::json& request_body) {
  if (!request_body.is_object()) {
    throw std::invalid_argument("request body must be a JSON object");
  }

  if (!request_body.contains("message")) {
    throw std::invalid_argument("missing required field: message");
  }

  nlohmann::json response = {
      {"received", request_body.at("message")},
      {"length", request_body.at("message").is_string() ? request_body.at("message").get<std::string>().size() : 0},
  };

  if (request_body.contains("metadata")) {
    response["metadata"] = request_body.at("metadata");
  }

  return response;
}

} // namespace lab
