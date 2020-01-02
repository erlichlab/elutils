function D = poisson_glm_test(varargin)

inpd = @utils.inputordefault;
args = varargin;

[krn_bin_size, args] = inpd('krn_bin_size',0.1,args);
[kernel, args]       = inpd('kernel',[],args);
[n_trials, args]     = inpd('n_trials',200,args);
[pre, args]          = inpd('pre',-1,args);
[post, args]         = inpd('post',2,args);



%% Does splitting up the bins change the CI?
true_rate = 10;
imp = @(x)zeros(size(x))+true_rate;
dur = 100;
spks = stats.inhomopoissrnd(imp, 'post',dur);
scale = exp(linspace(log(0.001), log(dur/2), 8));
bins = floor(dur./scale);
lambda = scale*0;
lowci = scale*0;
highci = scale*0;
for sx = 1:numel(scale)
    n = hist(spks, bins(sx));
    [this_lambda,ci] = poissfit(n);
    
    lambda(sx) = this_lambda*bins(sx)/dur;
    lowci(sx) = ci(1)*bins(sx)/dur;
    highci(sx) = ci(2)*bins(sx)/dur;
    % Does fitglm give the same results as poissfit?
    mdl = fitglm(ones(size(n(:))),n(:),'Distribution','poisson','Intercept',false,'Link','identity');
    % We need to specify 'Link', 'identity' because the default link for
    % the poisson distribution is y~log(x). 
    mdlmu = mdl.Coefficients.Estimate;
    mdllow = mdl.Coefficients.Estimate - mdl.Coefficients.SE*1.96;
    mdlhigh = mdl.Coefficients.Estimate - mdl.Coefficients.SE*1.96;
    
    fprintf(1,'fitglm %.3f [%.3f %.3f]\n', mdl.Coefficients.Estimate==this_lambda,'
end
    
    
figure(1); clf
ax = draw.jaxes([0.1 0.1 0.3 0.3]);
draw.errorplot(ax, bins, lambda, abs(lowci-lambda), highci-lambda);
ax.XScale = 'log'; ax.YLim = [0 1.2*true_rate]; ax.XLim = [0.8*min(dur./scale) 1.2*max(dur./scale)];
ax.XTick = 10.^[-1 0 1 2 3];
ylabel(ax,'\lambda (mean \pm ci)')
xlabel('# of bins')
draw.xhairs(ax,'r:',0,true_rate);

title(ax,{'Bin size/# does not effect' 'mean+ci of poisson lambda'})

% Continue from above. 



%%

end