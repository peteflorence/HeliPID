% The Vicon returns 6 coordinates (x,y,z,pitch,roll,yaw)
% where pitch,roll, and yaw are the angle around the x-axis, y-axis, z-axis
% respectively. pitch and yaw are between -pi and pi while roll is -pi/2 to
% pi/2
function S = getS(ip,port,n)

    u = udp(ip, port);
    set(u, 'LocalPort', 4012);
    set(u, 'ByteOrder', 'littleEndian');
    set(u, 'Timeout', 2);
    
    fopen(u);
    
    finishup = onCleanup(@() fclose(u));    
    
    count = 0;
    while(count ~= n*6)
        flushinput(u);
        flushoutput(u);
        fwrite(u, 'S', 'char');
        [ S, count ] = fread(u, n*6, 'float64');
    end
    
    S = reshape(S,6,n);
    S(3,:)=S(3,:)/1000;
%    S = S(1:6,:)';
    
    flushinput(u);
    flushoutput(u);
%    0
     fclose(u);
 %    1
     delete(u);
  %   2
     clear u;
   %  3
end
