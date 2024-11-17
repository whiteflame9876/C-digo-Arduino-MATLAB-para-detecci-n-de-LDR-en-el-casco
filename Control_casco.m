% Inicializar conexión con Arduino
arduinoObj = arduino('COM3', 'Uno', 'Libraries', 'Servo');

% Configurar los pines de los LDRs y de los servomotores
ldrArribaPin = 'A0';  %Detecta Luz Arriba 
ldrAbajoPin = 'A1';  %Detecta Luz Abajo   
ldrDerechaPin = 'A2';   %Detecta Luz Derecha
ldrIzquierdaPin = 'A3';   %Detecta Luz Izquierda 
ldrSensor = 'A4';   %Detecta Intensidad de Luz

servo1Pin = 'D3'; % Servo 1 para Arriba y Abajo
servo2Pin = 'D5'; % Servo 2 para Derecha y Izquierda

% Crear objetos para los servomotores
servo1Obj = servo(arduinoObj, servo1Pin);
servo2Obj = servo(arduinoObj, servo2Pin);

% Inicializar ambos servos en 90°
fprintf('Inicio\n');
writePosition(servo1Obj, 0.5);
writePosition(servo2Obj, 0.5);
pause(2); % Esperar segundos para asegurar la posición inicial

% Inicializar variables de intentos maximos de correcion
intentos = 0;
maxIntentos = 2;

while true
    % Leer valores de los LDRs
    ldrAdelanteValue = readVoltage(arduinoObj, ldrAdelantePin);   %Lectura Sensor 1
    ldrAtrasValue = readVoltage(arduinoObj, ldrAtrasPin);   %Lectura Sensor 2
    ldrDerechaValue = readVoltage(arduinoObj, ldrDerechaPin);     %Lectura Sensor 3
    ldrIzquierdaValue = readVoltage(arduinoObj, ldrIzquierdaPin);     %Lectura Sensor 4
    % Leer el valor ADC del LDR
    ldrValue = readVoltage(arduinoObj, ldrSensor); % Lee el voltaje (necesario para convertirlo a ADC)

    
    % Imprimir valores leídos para depuración
    fprintf('Adelante: %.2f V, Atras: %.2f V, Derecha: %.2f V, Izquierda: %.2f V\n', ...
            ldrAdelanteValue, ldrAtrasValue, ldrDerechaValue, ldrIzquierdaValue);
    
    % Encontrar el valor máximo y su dirección correspondiente
    [minValue, minIndex] = min([ldrAdelanteValue, ldrAtrasValue, ldrDerechaValue, ldrIzquierdaValue]);
    directions = {'Adelante', 'Atras', 'Derecha', 'Izquierda'};
    maxDirection = directions{minIndex};
    
    %% Solicitar el valor de X al usuario
    %x = input('Por favor, ingrese el valor de X: ');

    % Convertir el voltaje al valor ADC (0-1023 para un ADC de 10 bits)
    x = round(ldrValue * 1023 / 5);  % Escalamos de 0-5V a 0-1023
    
    % Calcular el valor de la ecuación f(x)
    f_x = -8.037*10.^{-7}*x.^3+0.0009344*x.^2-0.3971*x+107;
    
    % Escalar f(x) para que esté entre 0 y 1
    % (Asumiendo que f(x) está dentro de un rango conocido)
    f_x_scaled = (f_x /(732));  % Normalizar entre 0 y 1
    
    % Imprimir el valor de X y f(x)
    fprintf('Valor de X: %.2f, Valor de f(x): %.2f, Valor escalado: %.2f\n', x, f_x, f_x_scaled);
    
    % Mover los servomotores de acuerdo a la dirección y el valor de f(x)
    switch maxDirection
        case 'Adelante'
            writePosition(servo1Obj, 0.5 + f_x_scaled); % Mover servo 1 según f_x escalado
            fprintf('Moviendo servo 1 hacia: Adelante (f(x) escalado)\n');
            fprintf('Valor escalado: %.2f \n',f_x_scaled);
        case 'Atras'
            writePosition(servo1Obj, 0.5 - (f_x_scaled)); % Mover servo 1 según f_x escalado invertido
            fprintf('Moviendo servo 1 hacia: Atras (f(x) escalado invertido)\n');
            fprintf('Valor escalado: %.2f \n',(f_x_scaled));
        case 'Derecha'
            writePosition(servo2Obj, 0.5 + f_x_scaled); % Mover servo 2 según f_x escalado
            fprintf('Moviendo servo 2 hacia: Derecha (f(x) escalado)\n');
            fprintf('Valor escalado: %.2f \n',f_x_scaled);
        case 'Izquierda'
            writePosition(servo2Obj, 0.5 - (f_x_scaled)); % Mover servo 2 según f_x escalado invertido
            fprintf('Moviendo servo 2 hacia: Izquierda (f(x) escalado invertido)\n');
            fprintf('Valor escalado: %.2f \n',(f_x_scaled));
    end

    %(Aqui van los códigos de anexo 2, 3 y 4)
    % Leer el valor de "number" de la extensión

    % Condicion para ver si el BER es bajo

    % Verificar el valor de "number"
    if number < 0.001
        fprintf('El valor de number es %.6f. Manteniendo posición original y ejecutando extensión.\n', number);
        continue; % Regresar al principio del loop sin mover los servos
        
    else
        % Incrementar el número de intentos
        intentos = intentos + 1;
        fprintf('Número mayor a 0.001. Intento: %d\n', intentos);
    end

    % Verificar si se han excedido los intentos de corrección
    if intentos >= maxIntentos
        fprintf('Se han alcanzado los %d intentos. Deteniendo ejecución y moviendo servos a 90°.\n', maxIntentos);
        writePosition(servo1Obj, 0.5);
        writePosition(servo2Obj, 0.5);
        break; % Salir del loop
    end
    
    % Si "number" es mayor a 0.001 y no se han excedido los intentos, se sigue con la lógica
    fprintf('Intento %d. El valor de number es %.6f.\n', intentos + 1, number);


    pause(5); % Esperar 5 segundos antes de la siguiente lectura
    %Reiniciar servos posicion incial
    writePosition(servo1Obj, 0.5);
    writePosition(servo2Obj, 0.5);
    fprintf('Reinicio de los servos\n');
    fprintf('Nueva Trama\n');
end
