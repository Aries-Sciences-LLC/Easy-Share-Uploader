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

#include "Firestore/core/src/firebase/firestore/util/autoid.h"

#include <ctype.h>

#include <gtest/gtest.h>

using firebase::firestore::util::CreateAutoId;

TEST(AutoId, IsSane) {
  for (int i = 0; i < 50; i++) {
    std::string auto_id = CreateAutoId();
    EXPECT_EQ(20, auto_id.length());
    for (int pos = 0; pos < 20; pos++) {
      char c = auto_id[pos];
      EXPECT_TRUE(isalpha(c) || isdigit(c))
          << "Should be printable ascii character: '" << c << "' in \""
          << auto_id << "\"";
    }
  }
}