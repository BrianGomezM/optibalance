include "globals.mzn";

% ----------------------------
% Parámetros de entrada
% ----------------------------
int: num_plantas;
int: num_clientes;
int: num_dias;

set of int: PLANTAS = 1..num_plantas;
set of int: CLIENTES = 1..num_clientes;
set of int: DIAS = 1..num_dias;

array[PLANTAS] of float: costos;
array[PLANTAS] of float: capacidades;
array[PLANTAS] of float: porcentaje_regimen_alto;
array[PLANTAS] of int: max_dias_consecutivos_regimen;

float: G; % porcentaje mínimo de demanda a satisfacer

array[CLIENTES, DIAS] of float: demanda;
array[CLIENTES] of float: pagos;

% ----------------------------
% Variables de decisión
% ----------------------------
array[PLANTAS, CLIENTES, DIAS] of var 0.0..1000.0: produccion;



% ----------------------------
% Cálculo de la ganancia
% ----------------------------
var float: ingresos = sum(p in PLANTAS, s in CLIENTES, i in DIAS)(
    produccion[p,s,i] * pagos[s]
);

var float: costos_totales = sum(p in PLANTAS, s in CLIENTES, i in DIAS)(
    produccion[p,s,i] * costos[p]
);

var float: ganancia_neta = ingresos - costos_totales;

% ----------------------------
% Restricciones
% ----------------------------

% 1. Validación de parámetros
constraint assert(G >= 0.0 /\ G <= 100.0, "G debe ser un porcentaje entre 0 y 100");
constraint forall(p in PLANTAS)(capacidades[p] >= 0.0);

% 2. Capacidad de planta por día
constraint forall(p in PLANTAS, i in DIAS)(
    sum(s in CLIENTES)(produccion[p,s,i]) <= capacidades[p]
);

% 3. Satisfacer al menos G% de la demanda de cada cliente por día
constraint forall(s in CLIENTES, i in DIAS)(
    sum(p in PLANTAS)(produccion[p,s,i]) >= (G / 100.0) * demanda[s,i]
);

% 4. No exceder la demanda (opcional pero puede ayudar)
constraint forall(s in CLIENTES, i in DIAS)(
    sum(p in PLANTAS)(produccion[p,s,i]) <= demanda[s,i]
);

% 5. Restricciones de régimen alto
constraint forall(p in PLANTAS where porcentaje_regimen_alto[p] > 0)(
    forall(i in 1..num_dias - max_dias_consecutivos_regimen[p]) (
        sum(j in i..i+max_dias_consecutivos_regimen[p]) (
            bool2int(sum(s in CLIENTES)(produccion[p,s,j]) >=
                     (porcentaje_regimen_alto[p]/100.0) * capacidades[p])
        ) <= max_dias_consecutivos_regimen[p]
    )
);

% ----------------------------
% Restricciones Redundantes / Simetría
% ----------------------------

% Redundante: producción total por planta no puede exceder su capacidad diaria acumulada
constraint forall(p in PLANTAS)(
    sum(i in DIAS, s in CLIENTES)(produccion[p,s,i]) <= capacidades[p] * num_dias
);

% Ruptura de simetría: priorizar plantas más baratas
% Justificación: Las plantas con menor costo deben usarse primero para maximizar ganancia
constraint forall(p1, p2 in PLANTAS where p1 < p2 /\ costos[p1] < costos[p2])(
    sum(i in DIAS, s in CLIENTES)(produccion[p1,s,i]) >= 
    sum(i in DIAS, s in CLIENTES)(produccion[p2,s,i])
);

% ----------------------------
% Estrategias de búsqueda
% ----------------------------

% Estrategia 1: Búsqueda estándar
solve :: float_search(
    [produccion[p,s,i] | p in PLANTAS, s in CLIENTES, i in DIAS],
    0.001,               % Precisión para flotantes
    input_order,         % Orden de búsqueda
    indomain_min,        % Elegir el menor valor posible
    complete             % Búsqueda completa
) maximize ganancia_neta;

% Estrategia 2: Búsqueda alternativa (comentada para alternar)
% solve :: seq_search([
%     float_search([produccion[p,s,i] | p in PLANTAS, s in CLIENTES, i in DIAS], 
%                  smallest, indomain_min, complete),
%     float_search([ganancia_neta], most_constrained, indomain_max, complete)
% ]) maximize ganancia_neta;


%solve :: int_search(
%  [round(produccion[p,s,i]) | p in PLANTAS, s in CLIENTES, i in DIAS],
%  input_order, indomain_min, complete
%) maximize ganancia_neta;

% ----------------------------
% Output
% ----------------------------
output [
  "Ganancia neta: ", show(ganancia_neta), "\n\n",
  "Producción por planta-cliente-día:\n",
  concat([
    "Planta " ++ show(p) ++ ", Cliente " ++ show(s) ++ ", Día " ++ show(i) ++ " -> " ++
    show(produccion[p,s,i]) ++ " MW\n"
    | p in PLANTAS, s in CLIENTES, i in DIAS
  ])
];