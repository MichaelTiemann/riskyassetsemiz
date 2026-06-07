function F=LifeCycleModel35semiz_ReturnFn_single(savings,buyhouse,hprime,h,a,pbefore,pafter,yearsowned,olddownpayment,z,w,r,sigma,agej,Jr,pension,kappa_j,sigma_h,f_htc,minhouse,rentprice,houseservices,mortgageduration)
% Note: riskyasset, so first inputs are (d,a,z,...)
% vfoptions.refine_d: only decisions d1,d3 are input to ReturnFn (and this model has no d1)

single_0=single(0); single_1=single(1); infeasible=single(-Inf);

%% First, deal with house and mortgage aspects
if buyhouse==6
    relevantdownpayment=olddownpayment;
else
    relevantdownpayment=0.2*buyhouse;
end

% Value of existing house, and amount of mortgage outstanding
% Note: make first mortgage payment is same year you buy house (this could
% be changed to be making a mortgage payment on the previous house)
housevalueatpurchase=single_0; % if buyhouse==0, need to create or gpu objects
if buyhouse==6
    housevalueatpurchase=h*pbefore;
elseif buyhouse>0
    housevalueatpurchase=h*pbefore*pafter; 
    % note: if this is your first house, pafter=1. 
    % Note pbefore next period will become pbefore*pafter.
end
if buyhouse>0
    originalmortgage=(single_1-relevantdownpayment)*housevalueatpurchase;

    % The following formula is used to calculate the fixed monthly payment (P)
    % required to fully amortize a loan of L dollars over a term of n months 
    % at a monthly interest rate of c. [If the quoted rate is 6%, for example, 
    % c is .06/12 or .005].
    % P = L[c(1 + c)n]/[(1 + c)n - 1]
    % The next formula is used to calculate the remaining loan balance (B) of 
    % a fixed payment loan after p months.
    % B = L[(1 + c)n - (1 + c)p]/[(1 + c)n - 1]
    
    if yearsowned<20 % still paying mortgage
        mortgagepayment=originalmortgage*(r*(single_1+r)*mortgageduration)/((single_1+r)*mortgageduration-single_1);
        outstandingdebt=originalmortgage*((single_1+r)*mortgageduration - (single_1+r)*(yearsowned+single_1))/((single_1+r)*mortgageduration-single_1);
    else
        outstandingdebt=single_0;
        mortgagepayment=single_0;
    end
else % don't own a house
    % housevalueatpurchase=0;
    % originalmortgage=0;
    outstandingdebt=single_0;
    mortgagepayment=single_0;
end
% NOTE: It is possible that I am one period out in the above formulas for
% the mortgage. I haven't thought about it carefully.

% How much money do we get from change in house
% [price of house changes, so is not just hprime-h]
costofnewhouse=single_0;
if hprime~=h
    costofnewhouse=relevantdownpayment*pbefore*pafter*hprime-outstandingdebt;
    % downpayment*pbefore*pafter*hprime is what the new house costs us this
    % period (the rest is a mortgage)
    % outstandingdebt is what our old mortgage was (note, we take on a new
    % mortgage)
end

% Make buying/selling a house costly/illiquid
htc=single_0; % house transaction cost
if hprime~=h
    htc=f_htc*pbefore*pafter*(h+hprime);
end

% Housing services (based on house size, not house price)
if h==0
    s=0.5*houseservices*minhouse;
    rentalcosts=rentprice;
else
    s=houseservices*h;
    rentalcosts=single_0;
end


%% Now for the budget constraint and utility

F=infeasible;
if agej<Jr % If working age
    c=w*kappa_j*z+a-savings-costofnewhouse-htc-rentalcosts-mortgagepayment; 
    % Note: costofnewhouse is just the amount we pay this period (rest becomes mortgage obligation)
    % Note: to calculate wealth you would need the value of house, subtract
    % the outstanding mortgage debt, then add a
else % Retirement
    c=pension+a-savings-costofnewhouse-htc-rentalcosts-mortgagepayment; % give a rent subsidy to elderly for no good reason-rentalcosts;
end

if c>0
    F=(((c^(single_1-sigma_h))*(s^sigma_h))^(single_1-sigma))/(single_1-sigma); % The utility function
end


%% Ban pensioners from negative assets
if agej>=Jr && savings<0
    F=infeasible;
end

%% buyhouse must match hprime and h
if hprime==0
    if ~(buyhouse==0) % must be: don't own a house
        F=infeasible;
    end
elseif hprime==h
    if ~(buyhouse==4) % must be: keep house
        F=infeasible;
    end
else
    if ~(buyhouse>0 && buyhouse<4) % must be: buy a house
        F=infeasible;
    end
end


end
