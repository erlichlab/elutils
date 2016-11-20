function cmtid = log_comment(tabname, comment,varargin)

	dbc = utils.inputordefault('dbc',[],varargin);

	if isempty(dbc)
		dbc = db.labdb.getConnection();
	elseif ischar(dbc)
		dbc = db.labdb.getConnection(dbc);
	end


	D.exttable = tabname;
	D.comment = comment;
	dbc.saveData('met.comments',D);
	cmtid = dbc.last_insert_id();

end
