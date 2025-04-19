include "globals.mzn";

% ----------------------------
% PARÁMETROS DE ENTRADA (mejorado)
% ----------------------------
int: numero_plantas;
int: numero_clientes;
int: numero_dias;

set of int: PLANTAS = 1..numero_plantas;
set of int: CLIENTES = 1..numero_clientes;
set of int: DIAS = 1..numero_dias;

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
    forall(i in 1..numero_dias-1)(
        sum(k in 0..1)(
            bool2int(sum(s in CLIENTES)(produccion[p,s,i+k]) >= umbral_regimen_alto[p])
        ) <= 1 + bool2int(max_dias_consecutivos_regimen[p] > 1)
    )
);

constraint forall(p in PLANTAS, i in DIAS)(
    sum(s in CLIENTES)(produccion[p,s,i]) <= 0.99 * capacidades[p]
);
% ----------------------------
% RESTRICCIONES ADICIONALES
% ----------------------------

% Redundante: producción total no debe exceder capacidad total
constraint forall(p in PLANTAS)(
    sum(i in DIAS, c in CLIENTES)(produccion[p,c,i]) <= capacidades[p] * numero_dias
);


% Definir la prioridad dentro del modelo (ejemplo simple)
array[CLIENTES] of float: prioridad_cliente = [pagos[c] / sum(k in CLIENTES)(pagos[k]) | c in CLIENTES];

% Ordenar los clientes en función de la prioridad (de mayor a menor)
array[1..numero_clientes] of var CLIENTES: CLIENTES_ORDENADOS;
constraint forall(i in 1..numero_clientes-1)(
    prioridad_cliente[CLIENTES_ORDENADOS[i]] >= prioridad_cliente[CLIENTES_ORDENADOS[i+1]]
);

% Estrategia de búsqueda #6
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
  "Día ", show(i), ":\n",
  "  Producción total: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i]) * 100) / 100), " MW\n",
  "  Ingresos: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i] * pagos[s]) * 100) / 100), "\n",
  "  Costos: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i] * costos[p]) * 100) / 100), "\n",
  "  Ganancia: ", show(round(sum(p in PLANTAS, s in CLIENTES)(produccion[p,s,i] * (pagos[s] - costos[p])) * 100) / 100), "\n\n"
  ]) | i in DIAS ] ++
[ concat([
  "  Planta ", show(p), " día ", show(i), ": ", 
  show(round(sum(s in CLIENTES)(produccion[p,s,i]) * 100) / 100), " MW\n"
  ]) | p in PLANTAS, i in DIAS ] ++
[ if fix(sum(s in CLIENTES)(produccion[p,s,i])) >= umbral_regimen_alto[p] then 
     concat(["  Planta ", show(p), " día ", show(i), " operó en RÉGIMEN ALTO\n"])
  else "" endif 
  | p in PLANTAS, i in DIAS ];