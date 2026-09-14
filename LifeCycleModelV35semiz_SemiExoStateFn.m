function prob = LifeCycleModelV35semiz_SemiExoStateFn(pbefore, pafter, yearsowned, downpayment, pbeforeprime, pafterprime, yearsownedprime, downpaymentprime, buyhouse, probhousepricerise, probhousepricefall, pbeforespacing, pafterspacing, maxpbefore, minpbefore, maxpafter, minpafter, mortgageduration)

% Boolean masks for the main decision branches
mask_hold  = (buyhouse == 4);
mask_buy   = (buyhouse > 0 & buyhouse < 4);
mask_nobuy = (buyhouse == 0);

% =========================================================
% 1. Probabilities for pbefore (probp1)
% =========================================================
% A. Hold -> fixed
probp1_hold = (pbeforeprime == pbefore);

% B. Buy -> interpolates pnew
pnew = pbefore .* pafter;
pnew_clamped = max(min(pnew, maxpbefore), minpbefore);
dist_p1 = abs(pbeforeprime - pnew_clamped);
probp1_buy = max(1 - dist_p1 ./ pbeforespacing, 0); % Linear interpolation hat function

% C. No Buy -> stochastic evolution
diff_p1 = pbeforeprime - pbefore;
probp1_nobuy = (abs(diff_p1 - pbeforespacing) < 1e-4) .* probhousepricerise + ...
    (abs(diff_p1) < 1e-4) .* (1 - probhousepricerise - probhousepricefall) + ...
    (abs(diff_p1 + pbeforespacing) < 1e-4) .* probhousepricefall;

% Edge cleanup for No Buy
probp1_nobuy = probp1_nobuy + (pbefore == maxpbefore & abs(diff_p1) < 1e-4) .* probhousepricefall;
probp1_nobuy = probp1_nobuy + (pbefore == minpbefore & abs(diff_p1) < 1e-4) .* probhousepricerise;

probp1 = mask_hold .* probp1_hold + mask_buy .* probp1_buy + mask_nobuy .* probp1_nobuy;

% =========================================================
% 2. Probabilities for pafter (probp2)
% =========================================================
% A. No Buy -> fixed
probp2_nobuy = (pafterprime == pafter);

% B. Buy -> set to 1
probp2_buy = (pafterprime == 1);

% C. Hold -> stochastic evolution
diff_p2 = pafterprime - pafter;
probp2_hold = (abs(diff_p2 - pafterspacing) < 1e-4) .* probhousepricerise + ...
    (abs(diff_p2) < 1e-4) .* (1 - probhousepricerise - probhousepricefall) + ...
    (abs(diff_p2 + pafterspacing) < 1e-4) .* probhousepricefall;

% Edge cleanup for Hold
probp2_hold = probp2_hold + (pafter == maxpafter & abs(diff_p2) < 1e-4) .* probhousepricefall;
probp2_hold = probp2_hold + (pafter == minpafter & abs(diff_p2) < 1e-4) .* probhousepricerise;

probp2 = mask_nobuy .* probp2_nobuy + mask_buy .* probp2_buy + mask_hold .* probp2_hold;

% =========================================================
% 3. Probabilities for yearsowned (proby)
% =========================================================
proby_reset = (yearsownedprime == 0);

proby_hold = (yearsownedprime == yearsowned + 1);
proby_hold(yearsowned == mortgageduration - 1 & yearsownedprime == 100) = 1;
proby_hold(yearsowned == 100 & yearsownedprime == 100) = 1;

proby = (mask_nobuy | mask_buy) .* proby_reset + mask_hold .* proby_hold;

% =========================================================
% 4. Probabilities for downpayment (probd)
% =========================================================
probd_nobuy = (downpaymentprime == 0.2);
probd_buy1  = (downpaymentprime == 0.2);
probd_buy2  = (downpaymentprime == 0.4);
probd_buy3  = (downpaymentprime == 0.6);
probd_hold  = (downpaymentprime == downpayment);

probd = mask_nobuy .* probd_nobuy + ...
    (buyhouse == 1) .* probd_buy1 + ...
    (buyhouse == 2) .* probd_buy2 + ...
    (buyhouse == 3) .* probd_buy3 + ...
    mask_hold .* probd_hold;

% =========================================================
% Final Combined Probability
% =========================================================
prob = probp1 .* probp2 .* proby .* probd;


end