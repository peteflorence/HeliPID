classdef PID < handle
    
    properties (GetAccess='public' , SetAccess='private')
        kp
        ki
        kd
        errSum
        lastErr
        lastTime
    end
    
    methods
        
        %Constructor
        %k = [kp,ki,kd]
        function obj = PID(k)
            obj.kp = k(1);
            obj.ki = k(2);
            obj.kd = k(3);
            obj.errSum = 0;
            obj.lastErr = 0;
        end
        
        %timeChange = (nowTime - lastTime)
        function Output = Compute(obj,Input,Setpoint)
            
            %How long since we last calculated
            if isempty(obj.lastTime)
                timeChange=1;
            else
                timeChange = now*100000 - obj.lastTime;
            end
            
            %Compute all the working error variables
            error = Setpoint - Input;
            obj.errSum = obj.errSum + (error * timeChange);
            dErr = (error - obj.lastErr) / timeChange;
            
            %Compute PID Output
            Output = obj.kp * error + obj.ki * obj.errSum + obj.kd * dErr;
            
            %Remember some variables for next time
            obj.lastErr = error;
            obj.lastTime = now*100000;
            
        end
        
    end
    
end
    