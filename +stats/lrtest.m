function [p, teststat] = lrtest(varargin)
% Based on https://statlect.com/fundamentals-of-statistics/likelihood-ratio-test

    if isnumeric(varargin{1})
        % Assume we are doing the form of fullLL, redLL, dof
        fLL = varargin{1};
        rLL = varargin{2};
        dof = varargin{3};
        varargin = varargin(4:end);
    elseif isobject(varargin{1})
        if ismethod(varargin{1},'fixedEffects')
            % This is a mixed effect model
            error('Mixed-Effects models not get implemented.\n Use compare');

        end
        % Assume we were passed in model objects.
        m1 = varargin{1};
        m2 = varargin{2};
        m1_params = m1.NumEstimatedCoefficients;
        m2_params = m2.NumEstimatedCoefficients;
        if m1_params > m2_params
            fullm = m1;
            redm = m2;
        else
            fullm = m2;
            redm = m1;
        end

        dof = fullm.NumEstimatedCoefficients - redm.NumEstimatedCoefficients;
        fLL = fullm.LogLikelihood;
        rLL =  redm.LogLikelihood;
        
        varargin = varargin(3:end);
    end

if dof==0
    error('Models are not nested - same number of free params');
end
teststat = 2*(fLL - rLL);
p=1-chi2cdf(teststat, dof);
fprintf('Full Model log likelihood:\t %.3f\n', fLL);
fprintf('Reduced Model log likelihood:\t %.3f\n', rLL);
fprintf('Extra parameters in full model:\t %d\n', dof);
fprintf('\t\tChi-Sqr Test, \tp=%.4f\n', p);