function id = getRigID()

dbc = db.labdb.getConnection();

id = dbc.get('select rigid from met.rigs where ipaddr="%s"',{db.get_ip()});