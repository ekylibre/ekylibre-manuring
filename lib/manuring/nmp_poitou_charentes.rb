module Manuring

    class NmpPoitouCharentes < ManuringApproach

        def estimated_needs(yields=nil)
            if yields.nil?
                yields = estimate_expected_yield
            end
        end

    end
end