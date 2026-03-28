#pragma once

#include <nlohmann/json.hpp>
#include <string>

namespace lab {

struct AppConfig {
  std::string bind_address{"0.0.0.0"};
  int port{8080};
  std::string environment{"dev"};
  std::string node_id{"node-local"};
};

AppConfig load_config_from_env();
nlohmann::json make_config_payload(const AppConfig& cfg);

} // namespace lab
