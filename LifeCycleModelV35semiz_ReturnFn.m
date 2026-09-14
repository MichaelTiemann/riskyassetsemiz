function F = LifeCycleModelV35semiz_ReturnFn(savings, buyhouse, hprime, h, a, pbefore, pafter, yearsowned, olddownpayment, z, w, r, sigma, agej, Jr, pension, kappa_j, sigma_h, f_htc, minhouse, rentprice, houseservices, mortgageduration)

% --- 1. House and Mortgage Setup ---
is_hold = (buyhouse == 4);
is_buy  = (buyhouse > 0 & buyhouse < 4);

% Relevant downpayment (FIXED: buyhouse == 6 changed to buyhouse == 4)
relevantdownpayment = olddownpayment .* is_hold + (0.2 .* buyhouse) .* is_buy;

% Value of existing house
housevalueatpurchase = (h .* pbefore) .* is_hold + (h .* pbefore .* pafter) .* is_buy;

% Mortgage calculations
originalmortgage = (1 - relevantdownpayment) .* housevalueatpurchase;
is_paying = (yearsowned < 20) & (buyhouse > 0);

mortgagepayment = originalmortgage .* (r .* (1+r) .* mortgageduration) ./ ((1+r) .* mortgageduration - 1) .* is_paying;
outstandingdebt = originalmortgage .* ((1+r) .* mortgageduration - (1+r) .* (yearsowned+1)) ./ ((1+r) .* mortgageduration - 1) .* is_paying;

% --- 2. Cost of New House & Transaction Costs ---
moved = (hprime ~= h);
costofnewhouse = (relevantdownpayment .* pbefore .* pafter .* hprime - outstandingdebt) .* moved;
htc = f_htc .* pbefore .* pafter .* (h + hprime) .* moved;

% --- 3. Housing Services ---
is_renter = (h == 0);
s = (houseservices .* h .* ~is_renter) + (0.5 .* houseservices .* minhouse .* is_renter);
rentalcosts = rentprice .* is_renter;

% --- 4. Budget Constraint & Consumption ---
if agej < Jr % Working age (Scalar evaluation, safe for 'if')
    c = w .* kappa_j .* z + a - savings - costofnewhouse - htc - rentalcosts - mortgagepayment;
else % Retirement
    c = pension + a - savings - costofnewhouse - htc - rentalcosts - mortgagepayment;
end

% --- 5. NaN Shield & Utility Evaluation ---
valid_c = (c > 0);
c_safe = c;
c_safe(~valid_c) = 1;

F = (((c_safe.^(1 - sigma_h)) .* (s.^sigma_h)).^(1 - sigma)) ./ (1 - sigma);
F(~valid_c) = -Inf; % Punish negative consumption

% --- 6. Apply Absolute Constraints ---
% A. Ban pensioners from negative assets
if agej >= Jr
    F(savings < 0) = -Inf;
end

% B. Enforce logical consistency between hprime and buyhouse
invalid_nobuy = (hprime == 0 & buyhouse ~= 0);
invalid_hold  = (hprime == h & buyhouse ~= 4);
invalid_buy   = (hprime ~= h & hprime > 0 & ~is_buy);

F(invalid_nobuy | invalid_hold | invalid_buy) = -Inf;


end