function prob=LifeCycleModel35semiz_SemiExoStateFn_single(pbefore,pafter,yearsowned,downpayment,pbeforeprime,pafterprime,yearsownedprime,downpaymentprime,buyhouse, probhousepricerise, probhousepricefall,pbeforespacing, pafterspacing, maxpbefore, minpbefore,maxpafter, minpafter,mortgageduration)
% Note: assumes that in period 1 of model, pafter=1
% In periods where you buy a new house, there is zero probability that the
% house price changes.

single_0=single(0); single_1=single(1); neg_1=single(-1);

infeasible=single(-Inf); tiny=single(1e-4);

% Interpretation of buyhouse:
% =0, don't buy house
% =1, buy house with 20% deposit
% =2, buy house with 40% deposit
% =3, buy house with 60% deposit
% =4, hold house you own

prob=neg_1; % Just a placeholder (one that will cause errors if not overwritten)
probp1=neg_1;
probp2=single(Inf);
proby=neg_1;
probd=infeasible;

% First, the probabilities for pbefore, call these probp1
% If you don't own house, these evolve stochastically,
% If you own house (or buy one), these are fixed
if buyhouse==4
    % Fix pbefore
    if abs(pbeforeprime-pbefore)<tiny
        probp1=single_1;
    else
        probp1=single_0;
    end
elseif buyhouse==1 || buyhouse==2 || buyhouse==3
    % If this was first house, we would just fix pbefore
    % But to allow for changing house size, we need to set this to be 
    % pbefore=pbefore*pafter (note, before 1st house, pafter=1)
    % pbefore*pafter is likely off the grid, so then we need to linearly
    % interpolate back onto it.
    pnew=pbefore*pafter;
    if pnew>=maxpbefore % off top of grid
        if pbeforeprime==maxpbefore
            probp1=single_1; 
        else
            probp1=single_0;
        end
    elseif pnew<=minpbefore % off top of grid
        if pbeforeprime==minpbefore
            probp1=single_1; 
        else
            probp1=single_0;
        end
    % so we are between grid points
    elseif abs(pbeforeprime-pnew)<tiny % in case we hit grid point exactly
        probp1=single_1;
    elseif abs(pbeforeprime-pnew)+tiny<pbeforespacing % If this is one of the nearest grid points
        probp1=abs(pbeforeprime-pnew)/pbeforespacing; % linear interpolation for the probability weight
    else
        probp1=single_0;
    end
elseif buyhouse==0 % don't buy house
    % House price evolves stochastically
    % Either goes up one grid point, down one grid point, or stays
    if abs((pbeforeprime-pbefore)-pbeforespacing)<tiny % if (pbeforeprime-pbefore)==pbeforespacing
        probp1=probhousepricerise;
    elseif pbeforeprime==pbefore
        probp1=single_1-probhousepricerise-probhousepricefall;
    elseif abs((pbefore-pbeforeprime)-pbeforespacing)<tiny % if (pbeforeprime-pbefore)==-pbeforespacing
        probp1=probhousepricefall;
    else
        probp1=single_0;
    end
    % This formula will be wrong if we are already at the max/min grid point, so clean these up
    if pbefore==maxpbefore
        if pbeforeprime==pbefore
            probp1=single_1-probhousepricefall; % put the rise into staying in max
        end
    end
    if pbefore==minpbefore
        if pbeforeprime==pbefore
            probp1=single_1-probhousepricerise; % put the fall into staying in min
        end
    end

end

% Second, the probabilities for pafter, call these probp2
% If you don't own a house, these are fixed
% In the period you buy a house, these are set to 1
% If you own a house, these evolve stochastically
if buyhouse==0 % don't own a house
    % Fix pafter
    if pafterprime==pafter
        probp2=single_1;
    else
        probp2=single_0;
    end
elseif buyhouse==1 || buyhouse==2 || buyhouse==3
    % Set pafter=1
    if pafterprime==1
        probp2=single_1;
    else
        probp2=single_0;
    end
elseif buyhouse==4
    % House price evolves stochastically
    % Either goes up one grid point, down one grid point, or stays
    if abs((pafterprime-pafter)-pafterspacing)<tiny % if (pafterprime-pafter)==pafterspacing
        probp2=probhousepricerise;
    elseif pafterprime==pafter
        probp2=single_1-probhousepricerise-probhousepricefall;
    elseif abs((pafter-pafterprime)-pafterspacing)<tiny % if (pafterprime-pafter)==-pafterspacing
        probp2=probhousepricefall;
    else
        probp2=single_0;
    end
    % This formula will be wrong if we are already at the max/min grid point, so clean these up
    if pafter==maxpafter
        if pafterprime==pafter
            probp2=single_1-probhousepricefall; % put the rise into staying in max
        end
    end
    if pafter==minpafter
        if pafterprime==pafter
            probp2=single_1-probhousepricerise; % put the fall into staying in min
        end
    end
end


% Third, years owned.
% This is trivial, as just deterministically counts up, unless buyhouse==1, 
% in which case reverts to zero.
proby=single_0;
if buyhouse==0
    if yearsownedprime==0
        % Note, if we don't own house, then this is just ignored. 
        % (Give it value of 0 as seems sensible, but is not a number that will make sense)
        proby=single_1;
    end
elseif buyhouse==1 || buyhouse==2 || buyhouse==3
    if yearsownedprime==0
        proby=single_1;
    end
elseif buyhouse==4
    if yearsownedprime==yearsowned+1
        proby=single_1; % increment yearsowned counter
    end
    if yearsowned==mortgageduration-1 % need to deal specifically with end of mortgage
        if yearsownedprime==100
            proby=single_1;
        end
    end
    if yearsowned==100 % no mortgage is absorbing state
        if yearsownedprime==100
            proby=single_1;
        end
    end
end

if buyhouse==0
    % value of downpayment is anyway irrelevant
    if downpaymentprime==single(0.2)
        probd=single_1; % abitrary, but send it here
    else
        probd=single_0;
    end
elseif buyhouse==1
    if downpaymentprime==single(0.2)
        probd=single_1;
    else
        probd=single(0);
    end
elseif buyhouse==2
    if downpaymentprime==single(0.4)
        probd=single_1;
    else
        probd=single_0;
    end
elseif buyhouse==3
    if downpaymentprime==single(0.6)
        probd=single_1;
    else
        probd=single_0;
    end
elseif buyhouse==4 
    % already own house, so downpayment fraction remains constant
    if downpaymentprime==downpayment
        probd=single_1;
    else
        probd=single_0;
    end

end

% To debug if things don't sum to one, replace a given probability with uniform probabilty for that semiz grid
% probp1=1/5;
% probp2=1/5;
% proby=1/6;
% probd=1/3;


prob=probp1*probp2*proby*probd;


end