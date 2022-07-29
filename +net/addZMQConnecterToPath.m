function addZMQConnecterToPath()
clear java
jcp = javaclasspath('-all');

jarfile = 'jeromq.jar';

if isempty(cell2mat(regexp(jcp,jarfile)))
    % Mysql is not on the path
    this_file = mfilename('fullpath');
    [this_path] = fileparts(this_file);
    javaaddpath(fullfile(this_path, jarfile));
end

end