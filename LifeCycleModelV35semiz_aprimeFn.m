function aprime = LifeCycleModelV35semiz_aprimeFn(riskyshare, savings, u, r)

% Element-wise multiplication to support multidimensional tensor inputs
aprime = (1 + r) .* (1 - riskyshare) .* savings + (1 + r + u) .* riskyshare .* savings;


end