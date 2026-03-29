#include "config.hpp"
#include "echo_logic.hpp"
#include "version.hpp"

#include <httplib.h>
#include <iostream>
#include <nlohmann/json.hpp>

using nlohmann::json;

namespace {

void json_response(httplib::Response &res, int status, const json &payload) {
  res.status = status;
  res.set_header("Content-Type", "application/json");
  res.set_content(payload.dump(), "application/json");
}

} // namespace

int main() {
  lab::AppConfig cfg;
  try {
    cfg = lab::load_config_from_env();
  } catch (const std::exception &ex) {
    std::cerr << "Configuration error: " << ex.what() << std::endl;
    return 2;
  }

  httplib::Server server;

  server.Get("/health", [](const httplib::Request &, httplib::Response &res) {
    json_response(res, 200, lab::make_health_payload());
  });

  server.Get("/version", [](const httplib::Request &, httplib::Response &res) {
    json_response(
        res, 200,
        lab::make_version_payload(lab::app_version(), lab::git_commit()));
  });

  server.Get("/config",
             [cfg](const httplib::Request &, httplib::Response &res) {
               json_response(res, 200, lab::make_config_payload(cfg));
             });

  server.Post("/echo", [](const httplib::Request &req, httplib::Response &res) {
    try {
      const auto body = json::parse(req.body);
      json_response(res, 200, lab::make_echo_payload(body));
    } catch (const std::exception &ex) {
      json_response(res, 400, {{"error", ex.what()}});
    }
  });

  std::cout << "Starting server on " << cfg.bind_address << ':' << cfg.port
            << std::endl;
  if (!server.listen(cfg.bind_address, cfg.port)) {
    std::cerr << "Failed to start server" << std::endl;
    return 1;
  }

  return 0;
}
