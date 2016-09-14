function calstruct = loadWaterCalibration(rigid)

if nargin == 0 
    [rigid, roomid] = db.getRigID();
    if isempty(rigid) || rigid==0 || isnan(roomid)
        fprintf(1,'This is not a real rig, no calibration info on DB\n');
        calstruct = fake_cal_struct;
        return;
    end
end
dbc = db.labdb.getConnection();
caltab = dbc.query('select valve, volume, duration, calts from met.water_calibration where valid = 1 and rigid = %d',{rigid});

if isempty(caltab)
	calstruct = [];
	return;
end

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

function fakes = fake_cal_struct()

	fakes(1).Table = [200 10; 300 15; 400 20];
	fakes(1).LastDateModified = now();
	fakes(1).CalibrationTargetRange = [10 20];
	pp = polyfit(fakes(1).Table(:,2), fakes(1).Table(:,1), 1);
	fakes(1).TrinomialCoeffs = [0 0 pp];
