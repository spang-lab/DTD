#pragma once
#include "config.hpp"

namespace dtd {
  namespace models {
    mat invxtgx(mat const & x, vec const & g);
    class GoertlerModel {
    private:
      int m_ngenes;
      mat m_x, m_y, m_c;
    public:
      GoertlerModel(mat x, mat y, mat c) : m_x(x), m_y(y), m_c(c) {}
      ftype eval(vec const & g) const;
      void grad(vec & gr, vec const & g) const;
      std::size_t dim() const {
        return static_cast<std::size_t>(m_ngenes);
      }
    };
  }
}
