/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_UTIL_SECURE_RANDOM_H_
#define FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_UTIL_SECURE_RANDOM_H_

#include <stdint.h>

#include <limits>

namespace firebase {
namespace firestore {
namespace util {

// A "secure" pseudorandom number generator, suitable for generating
// unguessable identifiers. This exists because
//
//   * std::mt19937 is blazing fast but its outputs can be guessed once enough
//     previous outputs have been observed.
//   * std::random_device isn't guaranteed to come from a secure PRNG or be
//     fast.
//
// The implementation satisfies the C++11 UniformRandomBitGenerator concept and
// delegates to an implementation that generates high quality random values
// quickly with periodic reseeding.
class SecureRandom {
 public:
  // C++11 UniformRandomBitGenerator interface
  using result_type = uint32_t;

  static constexpr result_type min() {
    return std::numeric_limits<result_type>::min();
  }

  static constexpr result_type max() {
    return std::numeric_limits<result_type>::max();
  }

  result_type operator()();
};

}  // namespace util
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_UTIL_SECURE_RANDOM_H_
