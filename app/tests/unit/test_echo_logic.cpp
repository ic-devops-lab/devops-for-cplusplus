#include "echo_logic.hpp"

#include <gtest/gtest.h>

TEST(EchoLogicTests, HealthPayloadIsOk) {
  const auto payload = lab::make_health_payload();
  EXPECT_EQ(payload.at("status"), "ok");
  EXPECT_EQ(payload.at("service"), "autonomy-cicd-lab");
}

TEST(EchoLogicTests, EchoPayloadMirrorsMessage) {
  const auto payload = lab::make_echo_payload({{"message", "hello"}, {"metadata", {{"source", "test"}}}});
  EXPECT_EQ(payload.at("received"), "hello");
  EXPECT_EQ(payload.at("length"), 5);
  EXPECT_EQ(payload.at("metadata").at("source"), "test");
}

TEST(EchoLogicTests, EchoPayloadRequiresMessage) {
  EXPECT_THROW(lab::make_echo_payload({{"wrong_key", "hello"}}), std::invalid_argument);
}
