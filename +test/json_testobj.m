classdef json_testobj
    % Minimal value class used by test.test_json to exercise the classdef
    % branch of json.mdumps, which stores an object as its struct() contents
    % and records the original class name. Objects come back as plain structs,
    % so this cannot live in test.json_cases (which asserts round-trip
    % equality) and is checked separately.
    properties
        alpha = 1
        beta  = 'two'
        gamma = {3, [4 5]}
    end
    methods
        function obj = json_testobj(varargin)
            if nargin > 0
                obj.alpha = varargin{1};
            end
        end
    end
end
