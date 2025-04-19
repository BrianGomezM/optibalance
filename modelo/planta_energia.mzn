include "globals.mzn";

% ----------------------------
% DATOS DEL PROBLEMA
% ----------------------------
int: numero_plantas;       % Total de plantas generadoras
int: numero_clientes;      % Total de clientes a atender
int: numero_dias;          % Días del periodo a planificar

set of int: PLANTAS = 1..numero_plantas;
set of int: CLIENTES = 1..numero_clientes;
set of int: DIAS = 1..numero_dias;

% Costos y capacidades de cada planta
array[PLANTAS] of float: costos;                 % Costo por MW en cada planta
array[PLANTAS] of float: capacidades;            % Máxima producción diaria por planta
array[PLANTAS] of float: porcentaje_regimen_alto; % % de capacidad que define régimen alto
array[PLANTAS] of float: umbral_regimen_alto = [capacidades[p] * porcentaje_regimen_alto[p] / 100.0 | p in PLANTAS];
array[PLANTAS] of int: max_dias_consecutivos_regimen; % Límite de días en régimen alto

float: G; % porcentaje mínimo de demanda a satisfacer (ej: 50.0)

% Demanda de cada cliente por día y lo que pagan por MW
array[CLIENTES, DIAS] of float: demanda;
array[CLIENTES] of float: pagos;

% ----------------------------
% VARIABLES DE DECISIÓN
% ----------------------------
% Cuánto produce cada planta para cada cliente cada día
array[PLANTAS, CLIENTES, DIAS] of var 0.0..10000.0: produccion;

% ----------------------------
% FUNCIÓN OBJETIVO: Maximizar ganancia
% ----------------------------
var float: ingresos = sum(p in PLANTAS, s in CLIENTES, i in DIAS)(
    produccion[p,s,i] * pagos[s] % Dinero que recibimos
);

var float: costos_totales = sum(p in PLANTAS, s in CLIENTES, i in DIAS)(
    produccion[p,s,i] * costos[p] % Dinero que gastamos
);

var float: ganancia_neta = ingresos - costos_totales; % Lo que queremos maximizar

% ----------------------------
% RESTRICCIONES DEL PROBLEMA
% ----------------------------

% 1. Validación de parámetros
constraint assert(G >= 0.0 /\ G <= 100.0, "G debe estar entre 0 y 100");
constraint forall(p in PLANTAS)(capacidades[p] >= 0.0);
constraint forall(p in PLANTAS)(porcentaje_regimen_alto[p] >= 0.0 /\ porcentaje_regimen_alto[p] <= 100.0);

% 2. No superar capacidad máxima de cada planta
constraint forall(p in PLANTAS, i in DIAS)(
    sum(s in CLIENTES)(produccion[p,s,i]) <= capacidades[p]
);

% 3. Cubrir al menos G% de la demanda de cada cliente
constraint forall(s in CLIENTES, i in DIAS)(
    sum(p in PLANTAS)(produccion[p,s,i]) >= (G / 100.0) * demanda[s,i]
);

% 4. No exceder demanda del cliente
constraint forall(s in CLIENTES, i in DIAS)(
    sum(p in PLANTAS)(produccion[p,s,i]) <= demanda[s,i]
);

% 5. Controlar días consecutivos en régimen alto
constraint forall(p in PLANTAS where max_dias_consecutivos_regimen[p] > 0)(
    forall(i in 1..numero_dias-1)(
        sum(k in 0..1)(
            bool2int(sum(s in CLIENTES)(produccion[p,s,i+k]) >= umbral_regimen_alto[p])
        ) <= 1 + bool2int(max_dias_consecutivos_regimen[p] > 1)
    )
);

constraint forall(p in PLANTAS, i in DIAS)(
    sum(s in CLIENTES)(produccion[p,s,i]) <= 0.99 * capacidades[p]
);

% -----------------------------------------------------------
% RESTRICCIONES EXTRA (REDUNDANTES Y ROMPIMIENTO DE SIMETRÍA)
% -----------------------------------------------------------

% Para evitar que una planta produzca más de lo posible en todo el periodo
% (Es redundante pero ayuda al solver)
constraint forall(p in PLANTAS)(
    sum(i in DIAS, c in CLIENTES)(produccion[p,c,i]) <= capacidades[p] * numero_dias
);


% Calculamos prioridad según lo que paga cada cliente
% (Clientes que pagan más tienen mayor prioridad)
array[CLIENTES] of float: prioridad_cliente = [pagos[c] / sum(k in CLIENTES)(pagos[k]) | c in CLIENTES];

% Variable para ordenar clientes (de mayor a menor prioridad)
array[1..numero_clientes] of var CLIENTES: CLIENTES_ORDENADOS;

% Restricción para mantener el orden correcto
constraint forall(i in 1..numero_clientes-1)(
    prioridad_cliente[CLIENTES_ORDENADOS[i]] >= prioridad_cliente[CLIENTES_ORDENADOS[i+1]]
);


% ----------------------------
% ESTRATEGIA DE BÚSQUEDA
% ----------------------------
% Primero asignar las plantas con restricciones de régimen alto
solve :: seq_search([
    float_search(
        [produccion[p,s,i] | p in PLANTAS where max_dias_consecutivos_regimen[p] > 0, s in CLIENTES, i in DIAS],
        0.01, most_constrained, indomain_max, complete
    ),
    float_search(
        [produccion[p,s,i] | p in PLANTAS where max_dias_consecutivos_regimen[p] = 0, s in CLIENTES, i in DIAS],
        0.01, input_order, indomain_min, complete
    )
]) maximize ganancia_neta;


% ----------------------------
% OUTPUT 
% ----------------------------
output [
  "Ganancia neta total: ", show(round(ganancia_neta * 100) / 100), "\n",
  "Ingresos totales: ", show(round(ingresos * 100) / 100), "\n",
  "Costos totales: ", show(round(costos_totales * 100) / 100), "\n\n",
  
  "Detalle por día:\n"
] ++
[ concat([
  "Dia ", show(i), ":\n",
  "  Produccion total: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i]) * 100) / 100), " MW\n",
  "  Ingresos: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i] * pagos[s]) * 100) / 100), "\n",
  "  Costos: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i] * costos[p]) * 100) / 100), "\n",
  "  Ganancia: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i] * (pagos[s] - costos[p])) * 100) / 100), "\n\n"
  ]) | i in DIAS ] ++
[ concat([
  "  Planta ", show(p), " dia ", show(i), ": ", 
  show(round(sum(s in CLIENTES)(produccion[p,s,i]) * 100) / 100), " MW\n"
  ]) | p in PLANTAS, i in DIAS ] ++
[ if fix(sum(s in CLIENTES)(produccion[p,s,i])) >= umbral_regimen_alto[p] then 
     concat(["  Planta ", show(p), " día ", show(i), " opero en REGIMEN ALTO\n"])
  else "" endif 
  | p in PLANTAS, i in DIAS ];