clear;


QS = s107Serial();
%QS.mode = QuadSerial.NO_ARDUINO_MODE ;
QS.mode = s107Serial.BINARY_MODE;

QS.open();

% disable deleteion bug in getS
warning('off', 'MATLAB:class:DestructorError');