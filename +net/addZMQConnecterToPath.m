function addZMQConnecterToPath()
% Puts the bundled jeromq jar on MATLAB's dynamic java class path.
%
% The version lives in the filename deliberately. javaaddpath entries
% survive `clear all` and cannot be reliably unloaded within a session, so
% a generic "jeromq.jar" made it impossible to tell which build was
% actually loaded -- and because every jeromq release defines the same
% org.zeromq.* packages, the first jar on the path wins and the second is
% ignored in silence.

jarfile = 'jeromq-0.6.0.jar';

jarpath = fullfile(fileparts(mfilename('fullpath')), jarfile);
jcp = javaclasspath('-all');

if any(strcmp(jcp, jarpath))
    return
end

% Some other jeromq already loaded would shadow ours, so say so rather
% than adding a jar that will never be used.
shadow = jcp(~cellfun('isempty', regexp(jcp, 'jeromq[^/\\]*\.jar$', 'once')));
if ~isempty(shadow)
    warning('net:addZMQConnecterToPath:shadowed', ...
        ['jeromq is already on the java class path:\n  %s\n' ...
         'Those classes take precedence over %s. Restart MATLAB to switch.'], ...
        strjoin(shadow, sprintf('\n  ')), jarfile);
    return
end

javaaddpath(jarpath);

end
