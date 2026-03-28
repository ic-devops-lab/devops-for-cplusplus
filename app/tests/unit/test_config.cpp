#include "config.hpp"

#include <gtest/gtest.h>

TEST(ConfigTests, ConfigPayloadContainsNodeId) {
  const lab::AppConfig cfg{"127.0.0.1", 9090, "test", "node-a"};
  const auto payload = lab::make_config_payload(cfg);
  EXPECT_EQ(payload.at("bind_address"), "127.0.0.1");
  EXPECT_EQ(payload.at("port"), 9090);
  EXPECT_EQ(payload.at("environment"), "test");
  EXPECT_EQ(payload.at("node_id"), "node-a");
}
