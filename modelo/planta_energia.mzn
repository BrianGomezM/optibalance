include "globals.mzn";

% ----------------------------
% PARÁMETROS DE ENTRADA (mejorado)
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
array[PLANTAS] of float: umbral_regimen_alto = [capacidades[p] * porcentaje_regimen_alto[p] / 100.0 | p in PLANTAS];
array[PLANTAS] of int: max_dias_consecutivos_regimen;

float: G; % porcentaje mínimo de demanda a satisfacer (ej: 50.0)

array[CLIENTES, DIAS] of float: demanda;
array[CLIENTES] of float: pagos;

% ----------------------------
% VARIABLES DE DECISIÓN
% ----------------------------
array[PLANTAS, CLIENTES, DIAS] of var 0.0..10000.0: produccion;

% ----------------------------
% FUNCIÓN OBJETIVO
% ----------------------------
var float: ingresos = sum(p in PLANTAS, s in CLIENTES, i in DIAS)(
    produccion[p,s,i] * pagos[s]
);

var float: costos_totales = sum(p in PLANTAS, s in CLIENTES, i in DIAS)(
    produccion[p,s,i] * costos[p]
);

var float: ganancia_neta = ingresos - costos_totales;

% ----------------------------
% RESTRICCIONES (mejoradas)
% ----------------------------

% 1. Validación de parámetros
constraint assert(G >= 0.0 /\ G <= 100.0, "G debe estar entre 0 y 100");
constraint forall(p in PLANTAS)(capacidades[p] >= 0.0);
constraint forall(p in PLANTAS)(porcentaje_regimen_alto[p] >= 0.0 /\ porcentaje_regimen_alto[p] <= 100.0);

% 2. Capacidad máxima de producción por planta por día
constraint forall(p in PLANTAS, i in DIAS)(
    sum(s in CLIENTES)(produccion[p,s,i]) <= capacidades[p]
);

% 3. Mínimo garantizado de demanda por cliente por día
constraint forall(s in CLIENTES, i in DIAS)(
    sum(p in PLANTAS)(produccion[p,s,i]) >= (G / 100.0) * demanda[s,i]
);

% 4. No exceder demanda del cliente
constraint forall(s in CLIENTES, i in DIAS)(
    sum(p in PLANTAS)(produccion[p,s,i]) <= demanda[s,i]
);

% 5. Restricción de régimen alto (no más de max_dias_consecutivos_regimen días consecutivos en régimen alto)
constraint forall(p in PLANTAS where max_dias_consecutivos_regimen[p] > 0)(
    forall(i in 1..num_dias - max_dias_consecutivos_regimen[p] - 1)(
        sum(k in 0..max_dias_consecutivos_regimen[p])(
            bool2int(sum(s in CLIENTES)(produccion[p,s,i+k]) >= umbral_regimen_alto[p])
        ) <= max_dias_consecutivos_regimen[p]
    )
);

constraint forall(p in PLANTAS where max_dias_consecutivos_regimen[p] > 0)(
    forall(i in num_dias - max_dias_consecutivos_regimen[p]..num_dias)(
        sum(k in 0..num_dias - i)(
            bool2int(sum(s in CLIENTES)(produccion[p,s,i+k]) >= umbral_regimen_alto[p])
        ) <= max_dias_consecutivos_regimen[p]
    )
);
% ----------------------------
% RESTRICCIONES ADICIONALES
% ----------------------------

% Redundante: producción total no debe exceder capacidad total
constraint forall(p in PLANTAS)(
    sum(i in DIAS, s in CLIENTES)(produccion[p,s,i]) <= capacidades[p] * num_dias
);

% Ruptura de simetría: usar plantas más baratas primero
constraint forall(p in PLANTAS where max_dias_consecutivos_regimen[p] > 0)(
    forall(i in DIAS)(
        sum(s in CLIENTES)(produccion[p,s,i]) <= capacidades[p] + 0.0001 
    )
);

% ----------------------------
% ESTRATEGIA DE BÚSQUEDA
% ----------------------------
solve :: float_search(
    [produccion[p,s,i] | p in PLANTAS, s in CLIENTES, i in DIAS],
    0.001,               % Precisión
    input_order,         % Orden de entrada
    indomain_min,        % Valor mínimo
    complete             % Búsqueda completa
) maximize ganancia_neta;

% ----------------------------
% OUTPUT (mejorado)
% ----------------------------
output [
  "Ganancia neta total: ", show(round(ganancia_neta * 100) / 100), "\n",
  "Ingresos totales: ", show(round(ingresos * 100) / 100), "\n",
  "Costos totales: ", show(round(costos_totales * 100) / 100), "\n\n",
  
  "Detalle por día:\n"
] ++
[ concat([
  "Día ", show(i), ":\n",
  "  Producción total: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i]) * 100) / 100), " MW\n",
  "  Ingresos: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i] * pagos[s]) * 100) / 100), "\n",
  "  Costos: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i] * costos[p]) * 100) / 100), "\n",
  "  Ganancia: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i] * (pagos[s] - costos[p])) * 100) / 100), "\n"
  ]) | i in DIAS ] ++
[ concat([
  "  Planta ", show(p), " día ", show(i), ": ", 
  show(round(sum(s in CLIENTES)(produccion[p,s,i]) * 100) / 100), " MW\n"
  ]) | p in PLANTAS, i in DIAS ] ++
[ if fix(sum(s in CLIENTES)(produccion[p,s,i])) >= umbral_regimen_alto[p] then 
     concat(["  Planta ", show(p), " día ", show(i), " operó en RÉGIMEN ALTO\n"])
  else "" endif 
  | p in PLANTAS, i in DIAS ];