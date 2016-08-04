function calstruct = loadWaterCalibration()


rigid = db.getRigID();
if isempty(rigid) || rigid==0
	fprintf(1,'This is not a real rig, no calibration info on DB\n');
	calstruct = [];
	return;
end

dbc = db.labdb.getConnection();
caltab = dbc.query('select valve, volume, duration, calts from met.water_calibration where valid = 1 and rigid = %d',{rigid});

valve = unique(caltab.valve);

for vx = 1:numel(valve)
	thisvalve = caltab.valve == valve(vx);
	calstruct(vx).Table = [caltab.duration(thisvalve)*1000 caltab.volume(thisvalve)]; %#ok<*AGROW>
	caldates = caltab.calts(thisvalve);
	calstruct(vx).LastDateModified = datenum(caldates{1});
	calstruct(vx).CalibrationTargetRange = range(caltab.volume(thisvalve));
	pp = polyfit(calstruct(vx).Table(:,2), calstruct(vx).Table(:,1), 1);
	calstruct(vx).TrinomialCoeffs = [0 0 pp];
end

