module Manuring
  class NmpPoitouCharentes < ManuringApproach
    def estimated_needs(yields = nil)
      yields = estimate_expected_yield if yields.nil?
    end
  end
end
