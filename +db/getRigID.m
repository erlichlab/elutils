function [id, roomid] = getRigID()

dbc = db.labdb.getConnection();

[id, roomid] = dbc.get('select rigid, roomid from met.rigs where ipaddr="%s"',{db.get_ip()});

if isempty(id)
	id = 0;
end