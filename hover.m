% Run init_serial.m if you haven't already, or if you need to otherwise...
% !


hover_throttle = 100;

C = s107Controller(hover_throttle);%in initPIDs() , choose PID k's parameters for each PID

% Calibrate [P I D] controllers
pitch=1; yaw=2;z=3;
C.PIDs(pitch) = PID([1/100 0 0]);
C.PIDs(yaw) = PID([15 0 0]);
C.PIDs(z) = PID([70 0 20]);

%C.PIDs(x) = PID([0 0 0]);W
%C.PIDs(y) = PID([0 0 0]);
%C.PIDs(z) = PID([1 0 0.75]);

%QS.writeLadyBird(data');

% wait for init...
disp('Waiting for inital state...');
state=mygets(); % get 6 DOF, Vicon data (x, y, z, roll, pitch, yaw in Vicon format...)
while nnz(state) == 0
    state = mygets;
end


scale = 1;
XYZhover = state(1:3) + scale*[0;0;1]; %maybe something else
data = C.computeControl(state, XYZhover);

disp('Got inital state.');

while true
    state = mygets;    %from vicon
    if nnz(state)~=0
        data = C.computeControl(state, XYZhover);
    end
        
    QS.write(round(data'));
    p=[num2str(state)];
    e_pos=[num2str((state(1:3)-XYZhover)')];
    stick=[num2str(round(data'))];
%    disp([ e_pos ' -> ' stick]);
    % disp(stick); For debugging

   % pause (0.1) ; For debugging
end
QS.close();

