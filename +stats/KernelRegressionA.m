classdef KernelRegressionA
properties 
  event_times
  spiketimes
  kernel_dof = 50
  kernel_bins = 100
  kernel_bin_size = 0.025 % seconds  
  kernel_smoothing = 10
  kernel_smoothing_style = 'normal'
  trial_weights
  kernels
  core_kernel_matrix
  weighted_kernel_matrix

end
  
properties (Dependent)
  number_of_events
end

methods

  function obj = KernelRegressionA(e, s)
       obj.event_times = e;
       obj.spiketimes = s;
       obj.trial_weights = ones(size(e));

  end
  
  function obj = run(obj)
      generateCoreKernel(obj);
      generateWeightedKernels(obj);
      fit(obj);
  end
  
  function obj = generateCoreKernel(obj)
    % To do the kernel regression we need a regression matrix to specify 
    % where each element of the kernel influences the firing rate.
    % We will start with the
    % assumption that all kernels have the same length: kernel_bins.
    % However, there can be fewer degrees of freedom than bins.
    
    assert(mod(obj.kernel_bins, obj.kernel_dof)==0,'kernel_bins must be an integer multiple of kernel_dof.');
    
    % Initialize the matrix to be the right size.
    obj.core_kernel_matrix = zeros(obj.kernel_bins, obj.kernel_dof);
    
    % Put ones every where they should be.
    bins_per_dof = obj.kernel_bins/ obj.kernel_dof;
    tmpA = repmat(1:obj.kernel_bins:numel(obj.core_kernel_matrix),bins_per_dof,1) + (0:(bins_per_dof-1))';
    idx = tmpA + (0:bins_per_dof:(obj.kernel_bins-1));
    obj.core_kernel_matrix(idx(:)) = 1;
    
    % Apply smoothing
    if obj.kernel_smoothing > 0 
       switch obj.kernel_smoothing_style
           case 'normal'
               smooth_krn = normpdf(-obj.kernel_smoothing:obj.kernel_smoothing, 0, 1)';
           case 'box'
               smooth_krn = ones(obj.kernel_smoothing,1);
           otherwise
               error('Do not know how to smooth using %s');
       end
       
       obj.core_kernel_matrix = conv2(obj.core_kernel_matrix, smooth_krn, 'same');
       obj.core_kernel_matrix = obj.core_kernel_matrix ./ sum(obj.core_kernel_matrix,2);
       
    end
    
  end

  function number_of_events = get.number_of_events(obj)
    number_of_events = size(obj.event_times, 2);
  end
  
   
end


end
