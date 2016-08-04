function result = saveWaterCalibration(calstruct)

nvalves = numel(calstruct);


calind = 1;
rigid = db.getRigID();
if isempty(rigid) || rigid==0
	frprintf(1,'This is not a real rig, not saving to DB\n')
	result = 1;
    return;
end

for vx = 1:nvalves
	thistab = calstruct(vx).Table;
	for cx = 1:size(thistab,1)
		sqlS(calind).rigid = rigid; %#ok<*AGROW>
		sqlS(calind).valve = vx;
		sqlS(calind).duration = thistab(cx,1)/1000; % Use seconds in the DB.
		sqlS(calind).volume = thistab(cx,2); % In microliters
        calind = calind + 1;
	end
end

dbc = db.labdb.getConnection();
dbc.saveData('met.water_calibration',sqlS)
result = 0; % Saved
