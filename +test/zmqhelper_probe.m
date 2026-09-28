classdef zmqhelper_probe < net.zmqhelper
    % A net.zmqhelper whose socket handle can be swapped, for the teardown
    % cases that need a socket which fails to close.
    %
    % net.zmqhelper keeps that property write-protected on purpose -- a
    % publicly assignable handle to a live java socket is how close() could
    % be left with a socket it could neither close nor prove closed -- so
    % the tests inherit the seam rather than the class leaving a door open
    % for everyone.

    methods
        function obj = zmqhelper_probe(varargin)
            obj@net.zmqhelper(varargin{:});
        end

        function replacesocket(obj, jsocket)
            obj.socket = jsocket;
        end
    end
end
