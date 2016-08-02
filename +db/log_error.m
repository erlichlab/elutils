function log_error(err, varargin)
% log_error(err,['force_save',false])
% logs an error to the errors table

force_save = utils.inputordefault('force_save', false, varargin);

if nargin == 0
	err = lasterror();
end

sqlS.rigid = db.getRigID();
if isempty(sqlS.rigid)
	if force_save
		sqlS.rigid = 0;
	else
		fprintf(1,'Error logging by default only works on real rigs. Use [force_save, 1] to override');
		return
	end
end
sqlS.ip = db.get_ip();
sqlS.message = err.message;
sqlS.identifier = err.identifier;
tmp = json.mdumps(err.stack,'compress',false);

if ~isempty(tmp)
	sqlS.stack=tmp;
end
	

dbc = db.labdb.getConnection();

dbc.saveData('met.error_log', sqlS);