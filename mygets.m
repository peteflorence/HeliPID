function state=mygets()
    state=getS('192.168.20.53', 4401, 2);
    state=state(:,1);
end
