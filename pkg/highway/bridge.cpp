#include <hwy/abort.h>
#include <hwy/base.h>
#include <hwy/targets.h>

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

namespace hwy {
namespace {

// Highway's upstream abort.cc pulls in libc++ even when the rest of the
// library is compiled with HWY_NO_LIBCXX. Ghostty only needs Highway's dynamic
// dispatch/runtime target selection, so we provide the tiny Warn/Abort surface
// that targets.cc/per_target.cc expect and keep the package free of libc++.
WarnFunc g_warn_func = nullptr;
AbortFunc g_abort_func = nullptr;

// Mirror the upstream behavior closely enough for Highway's internal callers:
// format into a fixed buffer, fall back to a generic error if formatting fails,
// and then dispatch to either the registered hook or stderr.
void format_message(const char* format, va_list args, char* buffer, size_t size) {
  const int written = vsnprintf(buffer, size, format, args);
  if (written < 0) {
    snprintf(buffer, size, "%s", "failed to format highway message");
  }
}

}  // namespace

WarnFunc& GetWarnFunc() {
  return g_warn_func;
}

AbortFunc& GetAbortFunc() {
  return g_abort_func;
}

WarnFunc SetWarnFunc(WarnFunc func) {
  // Highway documents these setters as thread-safe. Using the compiler builtin
  // keeps that guarantee without depending on std::atomic.
  return __atomic_exchange_n(&g_warn_func, func, __ATOMIC_SEQ_CST);
}

AbortFunc SetAbortFunc(AbortFunc func) {
  return __atomic_exchange_n(&g_abort_func, func, __ATOMIC_SEQ_CST);
}

void Warn(const char* file, int line, const char* format, ...) {
  char message[1024];
  va_list args;
  va_start(args, format);
  format_message(format, args, message, sizeof(message));
  va_end(args);

  if (WarnFunc func = g_warn_func) {
    func(file, line, message);
    return;
  }

  fprintf(stderr, "%s:%d: %s\n", file, line, message);
}

HWY_NORETURN void Abort(const char* file, int line, const char* format, ...) {
  char message[1024];
  va_list args;
  va_start(args, format);
  format_message(format, args, message, sizeof(message));
  va_end(args);

  if (AbortFunc func = g_abort_func) {
    func(file, line, message);
  } else {
    fprintf(stderr, "%s:%d: %s\n", file, line, message);
  }

  abort();
}

}  // namespace hwy

extern "C" {

// Zig reads HWY_SUPPORTED_TARGETS via this C shim so it can keep its target
// enum in sync with the vendored Highway build without parsing C++ headers.
int64_t hwy_supported_targets() {
  return HWY_SUPPORTED_TARGETS;
}
}
