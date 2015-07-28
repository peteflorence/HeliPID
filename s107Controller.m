classdef s107Controller < handle
    
    properties(Constant)
        % These are the order of the four channles that the Arduino and
        % Devo7 uses.
        pitch = 1;
        yaw = 2;
        throttle = 3;
        
        epsilon = 0.0001;
    end
    
    properties
        PIDs = PID([0 0 0]);%init just for declaring type
        hover_throttle;
    end
    
    methods
        
        %Constructor
        function obj = s107Controller(hover_throttle)
            obj.hover_throttle = hover_throttle;
            obj.initPIDs();
        end
        
        function initPIDs(obj)
            obj.PIDs(obj.pitch) = PID([4 5 6]);
            obj.PIDs(obj.yaw) = PID([7 8 9]);
            obj.PIDs(obj.throttle) = PID([1 0 0]);
            %obj.PIDs(obj.yaw) = PID([1 2 3]);
        end
        
        % gets xyz coordinates and return values that corresponds to angels
        % between -infinity to infinity
        function [pitchVal, rollVal, yawVal]=convertXYZ2Angles(obj, xyz)
            %xyz(xyz==0)=obj.epsilon;
%             pitchVal= xyz(1)/xyz(3);
%             rollVal= xyz(2)/xyz(3);
%             yawVal= xyz(1)/xyz(2);

            pitchVal= xyz(1)/sqrt(xyz(2)^2+xyz(3)^2);
            rollVal=  xyz(2)/sqrt(xyz(1)^2+xyz(3)^2);
            yawVal= inf;

        end
        
        %xyz1,xyz2 are 1x3 matrix
        %xyz1 is where the robot is, and xyz2 is where the robot should go
        %Output: [pitch,roll,throttle,yaw] in the range [1000 2000]
        function Output = computeControl(obj,state1,xyz2)
            
            xyz1=state1(1:3);
            %xyz2=state2(1:3);
            
            rot1=state1(4:6);
            %rot2=state2(4:6);
            
            %R= angle2dcm(rot1(1) ,rot1(2) ,rot1(3) );
            R = angle2dcm(rot1(3), 0, 0);
            
            %compute position error
            e_pos = R*(xyz2 - xyz1);

%            e_pos(abs(e_pos)<1e-4)=0;

            %set error for each channel
            
            % compute yaw angle pointing to the desired location
            dist_from_xy_desired = norm(xyz1(1:2) - xyz2(1:2));
            yaw_angle_desired = atan2(xyz1(2) - xyz2(2), xyz1(1) - xyz2(1));
            yaw_angle_desired = wrapToPi(yaw_angle_desired);
            yaw_angle_actual = wrapToPi(state1(6));
            disp(['Dist: ' num2str(dist_from_xy_desired) ', Yaw desired: ' num2str(rad2deg(yaw_angle_desired)) ' deg actual yaw: ' num2str(rad2deg(yaw_angle_actual))]);
            
            yaw_error1 = yaw_angle_desired - yaw_angle_actual;
            yaw_error2 = yaw_angle_desired - (yaw_angle_actual + 2*pi);
            
            if (abs(yaw_error1) < abs(yaw_error2))
                yaw_error = yaw_error1;
            else
                yaw_error = yaw_error2;
            end
            yaw_error = wrapToPi(yaw_error);
            
            rad2deg(yaw_error)
            
            e_pos(obj.yaw) = yaw_error;
            e_pos(obj.pitch) = dist_from_xy_desired;
            
            % compute how much to change x,y,z in order to get to xyz2
            new_pos = zeros(3,1);
            for i=1:3
                new_pos(i) = obj.PIDs(i).Compute(0,e_pos(i));
            end
            RR = angle2dcm(rot1(3), rot1(2), rot1(1));
            if (RR(3,3) > .1)
                throttle_vector_comp = 1/RR(3,3);
            else
                throttle_vector_comp = 10;
            end
            %gravity_comp = 0.4;
            %new_pos(3) = (new_pos(3) + gravity_comp) * throttle_vector_comp;
            %new_pos'
            
            % Compute how much to change the pitch,.. in order to get to xyz2
            % Note that the outputs numbers are unbounded reals
            [pitchVal,rollVal,~] = obj.convertXYZ2Angles(new_pos);
            %pitchVal
            %rollVal
            % Translate the changes in angels to channels
            Output=zeros(4,1);
            
            if (abs(yaw_error) < 0.5) % if yaw error < threshold, then start pitching
                Output(obj.pitch)= 63 - new_pos(obj.pitch);
            else
                Output(obj.pitch) = 63;
            end
            
            %Output(obj.roll)=63+500*rollVal;
            Output(obj.throttle) = obj.hover_throttle + new_pos(3);
            Output(obj.yaw)=63 + new_pos(obj.yaw); % don't change
            
            % for each of: pitch, roll, throttle, yaw
            for i = 1:4
                if i == s107Controller.throttle
                    %throttle
                    if Output(s107Controller.throttle)>127
                        Output(s107Controller.throttle) = 127;
                    end
                    if Output(s107Controller.throttle)<0
                        Output(s107Controller.throttle) = 0;
                    end
                else
                    if Output(i)<0
                        Output(i)= 0;
                    end
                    if Output(i)>127
                        Output(i)= 127;
                    end
                end % if
           end % for
        end
        
    end
end