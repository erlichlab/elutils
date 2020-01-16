classdef KernelRegressionA
properties 
  baseline_per_trial = false
  core_kernel % this is the matrix for a single kernel. Will use it as a convolution kernel
  core_kernel_matrix % This is the core_kernel convolued with the event times.
  event_times
  kernel_bin_size = 0.01 % seconds  
  kernel_dof = 50
  kernel_duration = 2 % seconds
  kernel_smoothing = 3
  kernel_smoothing_style = 'normal'
  kernel_weights % The result of the kernel estimation step.
  spiketimes
  trial_types
  trial_weights % The result of the trial weight estimation step
  weighted_kernel_matrix % core_kernel_matrix multiplied by trial_weights

end
  
properties (Dependent)
  number_of_events
  kernel_bins
  kernels % Combine the kernel_weights with core_kernel to get the kernels
  total_time_steps
end

methods

  function obj = KernelRegressionA(e, s, t)
    obj.event_times = e;
    obj.spiketimes = s;
    if nargin < 3
      obj.trial_types = col(1:size(e,1));
    else
      obj.trial_types = t;
      % This allows you to fit fewer than # of trial trial_weights. Eg. if you want to assume the weights on 
      % the same trial type is the same. 
    end      
    obj.trial_weights = ones(numel(unique(obj.trial_types)),1);
  end
  
  function obj = run(obj)
    generateCoreKernel(obj);
    generateKernelMatrix(obj);
    generateCoreWeights(obj);
    generateWeightMatrix(obj);
    fit(obj);
  end
  
  function obj = generateCoreKernel(obj) % tested, OK
    % To do the kernel regression we need a regression matrix to specify 
    % where each element of the kernel influences the firing rate.
    % We will start with the
    % assumption that all kernels have the same length: kernel_duration.
    
    % Initialize the matrix to be the right size.
    obj.core_kernel = zeros(obj.kernel_bins, obj.kernel_dof);
    obj.kernel_weights = ones(size(obj.event_times,2), obj.kernel_dof);

    % Put ones every where they should be.
    bins_per_dof = obj.kernel_bins/ obj.kernel_dof;
    tmpA = repmat(1:obj.kernel_bins:numel(obj.core_kernel),bins_per_dof,1) + (0:(bins_per_dof-1))';
    idx = tmpA + (0:bins_per_dof:(obj.kernel_bins-1));
    obj.core_kernel(idx(:)) = 1;
    
    % Apply smoothing
    if obj.kernel_smoothing > 0 
       smooth_factor = obj.kernel_smoothing * bins_per_dof;
       switch obj.kernel_smoothing_style
           case 'normal'
               smooth_krn = normpdf(-(5*smooth_factor):(5*smooth_factor), 0, smooth_factor)';
           case 'box'
               smooth_krn = ones(smooth_factor,1);
           otherwise
               error('Do not know how to smooth using %s');
       end
       
       obj.core_kernel = conv2(obj.core_kernel, smooth_krn, 'same');
       obj.core_kernel = obj.core_kernel ./ sum(obj.core_kernel,2);
       
    end
    
  end
  
  function obj = generateKernelMatrix(obj)
    % Initialize a matrix that is [session_duration / bin_size x # of
    % kernels * kernel_bins + 1] (the one is for baseline). o
    if obj.baseline_per_trial
      % Should baseline be allowed to vary for different trials of the same trial_type? I guess yes.
      obj.core_kernel_matrix = zeros(obj.total_time_steps, obj.number_of_events*obj.kernel_bins + size(obj.event_times,1));
    else
      obj.core_kernel_matrix = zeros(obj.total_time_steps, obj.number_of_events*obj.kernel_bins + 1);
    end
    
    
    kernel_matrix = zeros(obj.total_time_steps, obj.number_of_events*obj.kernel_bins); 
    % just for the kernels. Deal with the baseline later
    
    row_offset = floor(obj.kernel_bins/2);
    col_offset = floor(obj.kernel_dof/2);
    krn_offset = obj.kernel_dof;
    event_index = floor((obj.event_times - min(obj.event_times(:))) /obj.kernel_bin_size); % Converts event_times to indices
        
    idx = sub2ind(size(kernel_matrix), row_idx, col_idx);
    kernel_matrix(idx) = 1;
    kernel_matrix = conv2(kernel_matrix, obj.core_kernel, 'same');
    
  end
  

  function number_of_events = get.number_of_events(obj)
    number_of_events = size(obj.event_times, 2);
  end
  

  function total_time_steps = get.total_time_steps(obj)
    total_time_steps = (max(obj.event_times(:)) - min(obj.event_times(:))) ./ obj.kernel_bin_size + obj.kernel_bins;
  end
  
  function kernel_bins = get.kernel_bins(obj)
    kernel_bins = obj.kernel_duration/obj.kernel_bin_size;
    assert(rem(kernel_bins,1)==0, 'The kernel_duration should be an integer multiple of kernel_bin_size');
  end
  
  function kernels = get.kernels(obj)
    % tested, OK
    kernels = obj.kernel_weights * obj.core_kernel';
  end
   
end


end

function y = col(x)
  y = x(:);
end
