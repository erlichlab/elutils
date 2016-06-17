function movie2struct(vo, stime, etime, varargin)
% movie2struct(vo, stime, etime, [inc_t,save_str])
% Inputs:
% vo        a video reader object (from output of VideoReader)
% stime     a list of times in seconds from beginning of video
% etime     a list of times in seconds from beginning of video (same length
%           as stime
% Optional Inputs
% inc_t     a logical vector the same length as stime which indicates that
%           the trial should be extracted. Default: All Trials
% save_str  the file name prefix to append to each file. Default the movie
% file name
%
% Output:
% Writes n files to disk (where n is sum of inc_t).  The ith file contains
% the frames from stime(i) to etime(i) as a single uint8 matrix of size [height width n_frames 3].

pairs={'save_str',[];...
       'inc_t',[];...
       };
   parseargs(varargin, pairs);
   
   if isempty(save_str)
       save_str=vo.Name;
       di=find(save_str=='.');
       save_str=save_str(1:di-1);
   end

   if isempty(inc_t)
       inc_t=ones(size(stime));
   end

fr=vo.FrameRate;
tot_f=vo.NumberOfFrames;


%get an extra 100 ms at the beginning and end

for tx=1:numel(stime)
    
    t_s_str=sprintf('%s_%d.mat',save_str,tx);
    
    if ~inc_t(tx) 
        continue;
    end
    
    if exist(t_s_str,'file')
      fprintf('File exists for trial %d, skipping\n',tx);
    end
    % This is the right thing to do, but it gives the wrong answer. GRR
        f_s=floor(stime(tx)*fr);
        f_e=ceil(etime(tx)*fr);
    
        if f_e>tot_f
            fprintf('Video is shorten than session.  Written first %d trials\n',tx);
            return;
        end
  %  f_s=floor(stime(tx)*30);
  %  f_e=ceil(etime(tx)*30);
    
    fprintf('Reading %d frames for trial %d\n',f_e-f_s,tx);
    m=read(vo, [f_s f_e]);
    
    start_time=stime(tx);
    end_time=etime(tx);
    
    save(t_s_str,'m','start_time','end_time','f_s','f_e');
    fprintf('\tTrial %d/%d done\n',tx,numel(stime));
    clear m t_m
end
