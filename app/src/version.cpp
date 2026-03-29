#include "version.hpp"

#include <cstdlib>

namespace lab {

std::string app_version() {
#ifdef APP_VERSION
  return APP_VERSION;
#else
  return "0.0.0-dev";
#endif
}

std::string git_commit() {
  const char *value = std::getenv("GIT_COMMIT");
  return value == nullptr ? "unknown" : std::string(value);
}

} // namespace lab
