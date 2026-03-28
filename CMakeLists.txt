cmake_minimum_required(VERSION 3.20)
project(autonomy_cicd_lab VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(BUILD_TESTING "Build tests" ON)
option(ENABLE_WARNINGS_AS_ERRORS "Treat warnings as errors" OFF)

include(FetchContent)

FetchContent_Declare(
  httplib
  GIT_REPOSITORY https://github.com/yhirose/cpp-httplib.git
  GIT_TAG v0.16.2
)

FetchContent_Declare(
  nlohmann_json
  GIT_REPOSITORY https://github.com/nlohmann/json.git
  GIT_TAG v3.11.3
)

FetchContent_MakeAvailable(httplib nlohmann_json)

add_library(echo_core
  app/src/config.cpp
  app/src/echo_logic.cpp
  app/src/version.cpp
)

target_include_directories(echo_core PUBLIC app/include)
target_link_libraries(echo_core PUBLIC nlohmann_json::nlohmann_json)

target_compile_options(echo_core PRIVATE -Wall -Wextra -Wpedantic)
if(ENABLE_WARNINGS_AS_ERRORS)
  target_compile_options(echo_core PRIVATE -Werror)
endif()

add_executable(echo_server app/src/main.cpp)
target_link_libraries(echo_server PRIVATE echo_core httplib::httplib)
target_compile_options(echo_server PRIVATE -Wall -Wextra -Wpedantic)
if(ENABLE_WARNINGS_AS_ERRORS)
  target_compile_options(echo_server PRIVATE -Werror)
endif()

target_compile_definitions(echo_server PRIVATE APP_VERSION="${PROJECT_VERSION}")

include(GNUInstallDirs)
install(TARGETS echo_server RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES infra/systemd/echo-service.service DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/systemd/system)
install(FILES manifests/releases.sample.json DESTINATION share/autonomy-cicd-lab)

if(BUILD_TESTING)
  enable_testing()
  FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.14.0
  )
  FetchContent_MakeAvailable(googletest)

  add_executable(unit_tests
    app/tests/unit/test_echo_logic.cpp
    app/tests/unit/test_config.cpp
  )
  target_link_libraries(unit_tests PRIVATE echo_core GTest::gtest_main)
  target_compile_options(unit_tests PRIVATE -Wall -Wextra -Wpedantic)

  include(GoogleTest)
  gtest_discover_tests(unit_tests)
endif()
