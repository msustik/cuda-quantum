
/****************************************************************-*- C++ -*-****
 * Copyright (c) 2022 - 2025 NVIDIA Corporation & Affiliates.                  *
 * All rights reserved.                                                        *
 *                                                                             *
 * This source code and the accompanying materials are made available under    *
 * the terms of the Apache License 2.0 which accompanies this distribution.    *
 ******************************************************************************/

#pragma once

#include "common/ExecutionContext.h"
#include "cudaq/qis/qarray.h"
#include "cudaq/qis/qvector.h"
#include <vector>

namespace cudaq {
/// @brief The `create` gate
// U|0> -> |1>, U|1> -> |2>, ..., and U|d> -> |d>
template <std::size_t Levels>
void create(qudit<Levels> &q) {
  getExecutionManager()->apply("create", {}, {}, {{q.n_levels(), q.id()}});
}

/// @brief The `annihilate` gate
// U|0> -> |0>, U|1> -> |0>, ..., and U|d> -> |d-1>
template <std::size_t Levels>
void annihilate(qudit<Levels> &q) {
  getExecutionManager()->apply("annihilate", {}, {}, {{q.n_levels(), q.id()}});
}

/// @brief The `plus` gate
// U|0> -> |1>, U|1> -> |2>, ..., and U|d> -> |0>
template <std::size_t Levels>
void plus(cudaq::qudit<Levels> &q) {
  cudaq::getExecutionManager()->apply("plus", {}, {}, {{q.n_levels(), q.id()}});
}

/// @brief The `phase shift` gate
template <std::size_t Levels>
void phase_shift(cudaq::qudit<Levels> &q, const double &phi) {
  cudaq::getExecutionManager()->apply("phase_shift", {phi}, {},
                                      {{q.n_levels(), q.id()}});
}

/// @brief The `beam splitter` gate
template <std::size_t Levels>
void beam_splitter(cudaq::qudit<Levels> &q, cudaq::qudit<Levels> &r,
                   const double &theta) {
  cudaq::getExecutionManager()->apply(
      "beam_splitter", {theta}, {},
      {{q.n_levels(), q.id()}, {r.n_levels(), r.id()}});
}

/// @brief Measure a qudit
template <std::size_t Levels>
int mz(cudaq::qudit<Levels> &q) {
  return cudaq::getExecutionManager()->measure({q.n_levels(), q.id()});
}

/// @brief Measure a vector of qudits
template <std::size_t Levels>
std::vector<int> mz(cudaq::qvector<Levels> &q) {
  std::vector<int> ret;
  for (auto &qq : q)
    ret.emplace_back(mz(qq));
  return ret;
}
} // namespace cudaq
