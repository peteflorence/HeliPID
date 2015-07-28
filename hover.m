hover_throttle = 100;

C = s107Controller(hover_throttle);%in initPIDs() , choose PID k's parameters for each PID

state=mygets();

XYZhover =state(1:3); %maybe something else

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
while nnz(state) == 0
    state = mygets;
end

data= C.computeControl(state, XYZhover);

XYZhover = state(1:3);

disp('Got inital state.');

while true
    state = mygets;    %from vicon
    if nnz(state)~=0
        data= C.computeControl(state, XYZhover);
    end
        
    QS.write(round(data'));
    p=[num2str(state)];
    e_pos=[num2str((state(1:3)-XYZhover)')];
    stick=[num2str(round(data'))];
%    disp([ e_pos ' -> ' stick]);
    disp(stick);

   % pause (0.1) ;
end
QS.close();

