classdef KernelRegressionA
properties 
  event_times
  spiketimes
  kernel_dof = 50
  kernel_bins = 100
  kernel_bin_size = 2 % seconds  
  kernel_smoothing = 5
  trial_weights
  kernel
  core_kernels
  weighted_kernels

end
  
properties (Dependent)
  number_of_events
end

methods

  function obj = KernelRegressionA(e, s)
       obj.event_times = e;
       obj.spiketimes = s;

  end

  function obj = generateCoreKernels(obj)

  end

  function number_of_events = get.number_of_events(obj)
    number_of_events = size(event_times, 2);
  end
end


end
