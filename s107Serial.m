
classdef s107Serial < handle

    
    properties (Constant)
        % modes for Arduino writing format
        ASCII_MODE = 1;
        BINARY_MODE = 2;
        NO_ARDUINO_MODE = 1; % Demo, move bird manually by hand 
        
        % Remote control stick range values
        CHANNEL_MIN = 1000;   %low position
        CHANNEL_MAX = 2000;    %high position
        CHANNEL_RANGE = s107Serial.CHANNEL_MAX - s107Serial.CHANNEL_MIN;
       
        % Arduino range values
        CHANNEL_ARDUINO_MIN = 0;
        CHANNEL_ARDUINO_MAX = 127;
        CHANNEL_ARDUINO_RANGE = s107Serial.CHANNEL_ARDUINO_MAX - s107Serial.CHANNEL_ARDUINO_MIN;
        
        RANGES_RATIO = s107Serial.CHANNEL_ARDUINO_RANGE / s107Serial.CHANNEL_RANGE;
        
        % Arduino special start-bit for beginning of communication
        % message
        START_BIT = 255;
    end
    
    properties
        s;  %serial object
        
        %DEVO7E Remote Controller properties 
        portNo = 4;
        mode = s107Serial.ASCII_MODE;   %set data in ASCII/BINARY format
        
        % Defaults for Arduino
        terminator =10; % [] or 0
        timeout = 10;
        inputBufferSize = 1000;            
        readAsyncMode = 'manual';
        dataBits=8;
        parity='none';
        flowControl='none';
        stopBits=1;
        baudRate=115200;        
    end

    
    methods (Static)
        function test()
            Q=s107Serial();
            Q.open();
            disp('xa');
            pause
            %fwrite(Q.s, uint16([255,10,10,10,10]));  %% 10,10,10,10
            Q.writeLadyBird([1500, 1500, 1500, 1500]);pause(5);
            Q.writeLadyBird([1500, 1500, 1500, 1600]);
            %Q.writeLadyBird([2000, 2000, 1000, 1000]);
            Q.close();
        end
        
        %convert data from CHANNEL-Range to ARDUINO-Range
        function newVal = convertRange(oldVal)
            newVal = (oldVal - s107Serial.CHANNEL_MIN);
            newVal = newVal * (s107Serial.RANGES_RATIO);
            newVal = int64(newVal + s107Serial.CHANNEL_ARDUINO_MIN);
        end
        
        function closeAll(portNo)
            if nargin==1
                serials=instrfind('Port',['COM' num2str(portNo)]);
            else
                serials=instrfind;
            end
            if not(isempty(serials))
                fclose(serials);
            end
            delete (serials);
            clear serials;
            udps=instrfind('Name', 'UDP-192.168.20.53');
            delete(udps);
            clear udps;
        end
        
        
    end
    
    methods
        
        %clear input & output buffers
        function flush(obj)
            flushinput(obj.s);
            flushoutput(obj.s);
        end
        
        
        %Open the serial
        function open(obj)
            s107Serial.closeAll(obj.portNo);
            %fclose('all');
            %obj.close();

            %create serial object
            %obj.s = serial(['COM', num2str(obj.portNo)]);
            %disp(['COM', num2str(obj.portNo)]);

            obj.s = serial('/dev/cu.usbmodem1451');
            
            
            obj.s.Terminator =obj.terminator; % [] or 0
            obj.s.Timeout = obj.timeout;
            obj.s.InputBufferSize = obj.inputBufferSize;            
            obj.s.ReadAsyncMode = obj.readAsyncMode;
            obj.s.DataBits=obj.dataBits;
            obj.s.Parity=obj.parity;
            obj.s.flowControl=obj.flowControl;
            obj.s.StopBits=obj.stopBits;
            obj.s.BaudRate = obj.baudRate;        
            fopen(obj.s);%open the serial
            %disp('Press R+ on the remote controller');
            %pause;
        end
        
        
        
        %write to Arduino
        %toSend = [pitch,roll,throttle,yaw] in ARDUINO-Range
        function write(obj, toSend)
            switch obj.mode
                case s107Serial.BINARY_MODE
                    %toSend(4)=70;
                    toSend = char(['Z' [toSend(3) toSend(2) toSend(1)]]);  %correct?
                    fwrite(obj.s, toSend, 'char', 'sync');
                    str_back = fscanf(obj.s);
                case s107Serial.ASCII_MODE
                    %disp('final pitch')
                    %disp(toSend(1))
                    %disp('final throttle')
                    %disp(toSend(3))
                    %disp('final yaw')
                    %disp(toSend(4))
                    toSend = ['Z' num2str(toSend(3)) ',' num2str(toSend(4)) ',' num2str(toSend(1)) ','];
                    disp(toSend)
                    fprintf(obj.s, '%s', num2str(toSend));
                    %fprintf(obj.s, 't,%s\n', num2str(toSend(3)));
                    %while true
                    %disp(fgetl(obj.s));
                    %end
                    %disp(fscanf(obj.s));
                case s107Serial.NO_ARDUINO_MODE
                otherwise
                    error('Error writing data to Arduino');
            end
        end
        
        function testWrite(obj)
            while true
                disp('kaka')
                fprintf(obj.s, 't,60\n');
                disp(fscanf(obj.s, '%s'));
                pause(10);
            end
        end
        %write data to ladybird
        %data = [pitch,roll,throttle,yaw] in CHANNEL-Range
        function writeLadyBird(obj,data)
            %if sum(data>obj.CHANNEL_MAX)+sum(data<obj.CHANNEL_MIN)>0
             %   data
              %  error('data error');
            %end
            converted=zeros(4,1);
            converted(1) = obj.convertRange(data(1));
            converted(2) = obj.convertRange(data(2));
            converted(3) = obj.convertRange(data(3));
            converted(4) = obj.convertRange(data(4));
            obj.write(converted);
        end
     
        
        %Close the serial
        function close(obj)
            %clear input & output buffers
            fprintf(obj.s, '0,63,63,\n');
            obj.flush();

            %close serial
            fclose(obj.s);
        end
        
    end
end