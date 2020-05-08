%parseargs   [opts] = parseargs(arguments, pairs, singles, ignore_unknowns)
%
% Variable argument parsing-- supersedes parseargs_example. This
% function is meant to be used in the context of other functions
% which have variable arguments. Typically, the function using
% variable argument parsing would be written with the following
% header:
%
%    function myfunction(args, ..., varargin)
%
% and would define the variables "pairs" and "singles" (in a
% format described below), and would then include the line
%
%       parseargs(varargin, pairs, singles);
%
% 'pairs' and 'singles' specify how the variable arguments should
% be parsed; their format is decribed below. It is best
% understood by looking at the example at the bottom of these help
% comments.
%
% varargin can be of two forms:
% 1) A cell array where odd entries are variable names and even entries are
%    the corresponding values
% 2) A struct where the fieldnames are the variable names and the values of
%    the fields are the values (for pairs) or the existence of the field
%    triggers acts as a single.
%
% pairs can be of two forms:
% 1) an n x 2 cell array where the first column are the variable names and
%    the 2nd column are the default values.
% 2) A struct where the fieldnames are the variable names and the values of
%    the fields are the values.
%
% PARSEARGS DOES NOT RETURN ANY VALUES; INSTEAD, IT USES ASSIGNIN
% COMMANDS TO CHANGE OR SET VALUES OF VARIABLES IN THE CALLING
% FUNCTION'S SPACE.
%
%
%
% PARAMETERS:
% -----------
%
% -arguments     The varargin list, I.e. a row cell array.
%
% -pairs         A cell array of all those arguments that are
%                specified by argument-value pairs. First column
%                of this cell array must indicate the variable
%                names; the second column must indicate
%                correponding default values.
%
% -singles       A cell array of all those arguments that are
%                specified by a single flag. The first column must
%                indicate the flag; the second column must
%                indicate the corresponding variable name that
%                will be affected in the caller's workspace; the
%                third column must indicate the value that that
%                variable will take upon appearance of the flag;
%                and the fourth column must indicate a default
%                value for the variable.
%
%
% Example:
% --------
%
% In "pairs", the first column defines both the variable name and the
% marker looked for in varargin, and the second column defines that
% variable's default value:
%
%   pairs = {'thingy'  20 ; ...
%            'blob'    'that'};
%
% In "singles", the first column is the flag to be looked for in varargin,
% the second column defines the variable name this flag affects, the third
% column defines the value the variable will take if the flag was found, and
% the last column defines the value the variable takes if the flag was NOT
% found in varargin.
%
%   singles = {'no_plot' 'plot_fg' '0' '1'; ...
%             {'plot'    'plot_fg' '1' '1'};
%
%
% Now for the function call from the user function:
%
%   parseargs({'blob', 'fuff!', 'no_plot'}, pairs, singles);
%
% This will set, in the caller space, thingy=20, blob='fuff!', and
% plot_fg=0. Since default values are in the second column of "pairs"
% and the fourth column of "singles", and in the call to
% parseargs 'thingy' was not specified, 'thingy' takes on its
% default value of 20.
%
% Note that the arguments to parseargs may be in any order-- the
% only ordering restriction is that whatever immediately follows
% pair names (e.g. 'blob') will be interpreted as the value to be
% assigned to them (e.g. 'blob' takes on the value 'fuff!');
%
% If you never use singles, you can just call "parseargs(varargin, pairs)"
% without the singles argument.
%


function [varargout] = parseargs(arguments, pairs, singles,ignore_unknowns)

if nargin < 3, singles = {}; end;
if nargin < 4, ignore_unknowns=false; end;

% This assigns all the default values for pairs.
if isstruct(pairs)
    out=pairs;
    fn=fieldnames(pairs);
    for fx=1:numel(fn)
        assignin('caller',fn{fx}, pairs.(fn{fx}));
    end
    pairs=fn;
else
    for i=1:size(pairs,1),
        assignin('caller', pairs{i,1}, pairs{i,2});
    end;
end
% This assigns all the default values for singles.
for i=1:size(singles,1),
    assignin('caller', singles{i,2}, singles{i,4});
end;
if isempty(singles), singles = {'', '', [], []}; nosingles=true; else nosingles=false; end;
if isempty(pairs),   pairs   = {'', []}; nopairs=true; else nopairs=false; end;


% Now we assign the value to those passed by arguments.
if numel(arguments)==1 && isstruct(arguments{1})
    arguments=arguments{1};
    fn=fieldnames(arguments);
    for arg=1:numel(fn)
        switch fn{arg}
            case pairs(:,1)
                assignin('caller',fn{arg}, arguments.(fn{arg}));
                out.(fn{arg})=arguments.(fn{arg});
            case singles(:,1)
                u = find(strcmp(fn{arg}, singles(:,1)));
                out.(fn{arg})=singles(:,1);
                assignin('caller', singles{u,2}, singles{u,3});
            otherwise
                if ~ignore_unknowns
                    fn{arg}
                    
                    mname = evalin('caller', 'mfilename');
                    error([mname ' : Didn''t understand above parameter']);
                end
        end
    end
    
else
    arg = 1;  while arg <= length(arguments),
        
        switch arguments{arg},
            
            case pairs(:,1),
                if arg+1 <= length(arguments)
                    assignin('caller', arguments{arg}, arguments{arg+1});
                    arg = arg+1;
                end;
                
            case singles(:,1),
                u = find(strcmp(arguments{arg}, singles(:,1)));
                assignin('caller', singles{u,2}, singles{u,3});
                
            otherwise
                if ~ignore_unknowns
                arguments{arg}
                mname = evalin('caller', 'mfilename');
                error([mname ' : Didn''t understand above parameter']);
                else
                    if nosingles
                    arg=arg+1;
                    elseif nopairs
                    % don't increment args.
                    else
                        error('Cannot use ignore_unknown and a mix of singles and pairs')
                    end
                   
                end
        end;
        arg = arg+1; end;
end
if nargout>0
    varargout{1}=out;
end
return;
