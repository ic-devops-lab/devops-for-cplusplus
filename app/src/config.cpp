#include "config.hpp"

#include <cstdlib>
#include <stdexcept>

namespace {

std::string get_env_or_default(const char* key, const std::string& fallback) {
  const char* value = std::getenv(key);
  return value == nullptr ? fallback : std::string(value);
}

int get_int_env_or_default(const char* key, int fallback) {
  const char* value = std::getenv(key);
  if (value == nullptr) {
    return fallback;
  }
  try {
    return std::stoi(value);
  } catch (...) {
    throw std::runtime_error(std::string("invalid integer for env var: ") + key);
  }
}

} // namespace

namespace lab {

AppConfig load_config_from_env() {
  AppConfig cfg;
  cfg.bind_address = get_env_or_default("APP_BIND_ADDRESS", cfg.bind_address);
  cfg.port = get_int_env_or_default("APP_PORT", cfg.port);
  cfg.environment = get_env_or_default("APP_ENV", cfg.environment);
  cfg.node_id = get_env_or_default("APP_NODE_ID", cfg.node_id);
  return cfg;
}

nlohmann::json make_config_payload(const AppConfig& cfg) {
  return {
      {"bind_address", cfg.bind_address},
      {"port", cfg.port},
      {"environment", cfg.environment},
      {"node_id", cfg.node_id},
  };
}

} // namespace lab
