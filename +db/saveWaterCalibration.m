function result = saveWaterCalibration(varargin)
% result = saveWaterCalibration(LiquidCal)
% result = saveWaterCalibration(valve, duration, volume)
%



rigid = utils.inputordefault('rigid',db.getRigID(),varargin);
if isempty(rigid) || rigid==0
    fprintf(1,'This is not a real rig, not saving to DB\n');
    result = 1;
    return;
end

if nargin ==1 && isstruct(varargin{1})
	calstruct = varargin{1};
	nvalves = numel(calstruct);


    calind = 1;

    for vx = 1:nvalves
        thistab = calstruct(vx).Table;
        for cx = 1:size(thistab,1)
            sqlS(calind).rigid = rigid; %#ok<*AGROW>
            sqlS(calind).valve = vx;
            sqlS(calind).duration = thistab(cx,1)/1000; % Use seconds in the DB.
            sqlS(calind).volume = thistab(cx,2); % In microliters
            sqlS(calind).valid = 1;
            calind = calind + 1;
        end
    end

    dbc = db.labdb.getConnection();
    dbc.saveData('met.water_calibration',sqlS)
    result = 0; % Saved
elseif nargin==3
    % We have a time and a volume.
   
	sqlS.rigid = rigid; %#ok<*AGROW>
	sqlS.valve = varargin{1};
    sqlS.duration = varargin{2}/1000; % Use seconds in the DB.
    sqlS.volume = varargin{3}; % In microliters
    sqlS.valid = 1;
    dbc = db.labdb.getConnection();
    dbc.saveData('met.water_calibration',sqlS)
    result = 0; % Saved

end
    