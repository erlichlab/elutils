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
scale = [0.1, 0.5, 1, 2, 5, 10, 50, 100];
lambda = scale*0;
lowci = scale*0;
highci = scale*0;
for sx = 1:numel(scale)
    n = hist(spks, dur/scale(sx));
    [this_lambda,ci] = poissfit(n);
    
    lambda(sx) = this_lambda/scale(sx);
    lowci(sx) = ci(1)/scale(sx);
    highci(sx) = ci(2)/scale(sx);
end
    
    
figure(1); clf
ax = draw.jaxes;
draw.errorplot(ax, dur./scale, lambda, abs(lowci-lambda), highci-lambda);
ax.XScale = 'log'; ax.YLim = [0 1.2*true_rate]; ax.XLim = [0.8*min(dur./scale) 1.2*max(dur./scale)];
ylabel(ax,'\lambda (mean \pm ci)')
xlabel('# of bins')
draw.xhairs(ax,'r:',0,true_rate);

title(ax,{'Bin size has no effect of mean or conf. int.','of poisson lambda'})



%%

end