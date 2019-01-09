function [experid, expername] = getExperimenter(exper_info)
%     get_experid_from_info(exper_info):
%     input:
%     a string that will match something about an experimenter. Could be firstname, gitlabuser, or netid
%     output:
%     the ID for that experimenter in the database.
%     e.g. id = get_experid_from_info('jerlich') % returns 10
dbc = db.labdb.getConnection();
dbc.use('met');
if nargin==0
    exper_info=0;
end

if isnumeric(exper_info)
    if exper_info==0
        % Try based on first name
        [~,uname]=system('git config user.name');
        
        uname = strtrim(uname);
        firstname = strtok(uname,' ');
        [experid, expername] = db.getExperimenter(firstname);
        if experid>0
            return;
        end
        
        % Try based on email handle
        [~,umail]=system('git config user.email');
        
        umail = strtrin(umail);
        mailname = strtok(umail,'@');
        [experid, expername] = db.getExperimenter(mailname);
        
    else
        [experid, expername] = dbc.get('select experid, concat(firstname," ",lastname) as name from experimenters where experid = %d',{exper_info});
    end
else
    
    
    
    eid = dbc.query('select experid, concat(firstname," ",lastname) as name from experimenters where Firstname like "%s%%"', {exper_info});
    if numel(eid) > 0
        experid = eid.experid;
        expername = eid.name{1};
        return;
    end
    
    eid = dbc.query('select experid, concat(firstname," " ,lastname) as name from experimenters where gitlabuser="%s"', {exper_info});
    if numel(eid) > 0
        experid = eid.experid;
        expername = eid.name{1};
        return;
    end
    
    eid = dbc.query('select experid, concat(firstname," ",lastname) as name from experimenters where netid="%s"', {exper_info});
    if numel(eid) > 0
        experid = eid.experid;
        expername = eid.name;
        return;
    end
    
    error('Could not match a unique experimenter to the supplied information')
end

expername = expername{1};
