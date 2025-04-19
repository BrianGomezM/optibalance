# OptiBalance

> **Taller 1: Modelamiento e Implementación de CSPs**  
> Programación por Restricciones - MiniZinc  
> Universidad del Valle  
> Abril de 2025  

---

## 📄 Información General

**OptiBalance** Modelo de optimización basado en programación por restricciones (CSP). Este taller tiene como objetivo formular, modelar e implementar un problema de asignación balanceada, en donde se busca distribuir equitativamente actividades o cargas de trabajo entre diferentes entidades.

## 👨‍💻 Autores

- Brayan Gómez Muñoz – 2310016  
- Juan José Moreno Jaramillo – 2310038  

**Profesor:** Robinson Andrey Duque Agudelo  
**Curso:** Programación por Restricciones  
**Escuela:** Ingeniería de Sistemas y Computación  
**Universidad del Valle**


## 📁 Estructura del Proyecto
optibalance/
├───estrategias_busqueda/
│   └── estrategiasBusqueda.txt
├───informe/
│   └── InformeTaller2.pdf
├───modelo/
│   └── planta_energia.mzn
├───pruebas/
│   ├── pruebas_prueba_1.dzn
│   ├── pruebas_prueba_2.dzn
│   ├── pruebas_prueba_3.dzn
│   ├── pruebas_prueba_4.dzn
│   ├── pruebas_prueba_5.dzn
│   ├── pruebas_prueba_6.dzn
│   ├── pruebas_prueba_7.dzn
│   ├── pruebas_prueba_8.dzn
│   ├── pruebas_prueba_9_Error.dzn
│   ├── pruebas_prueba_10_Error.dzn
│   └── pruebas_prueba_11_Error.dzn
├───solucion/
│   ├── solucion_prueba_1.txt
│   ├── solucion_prueba_2.txt
│   ├── solucion_prueba_3.txt
│   ├── solucion_prueba_4.txt
│   ├── solucion_prueba_5.txt
│   ├── solucion_prueba_6.txt
│   ├── solucion_prueba_7.txt
│   ├── solucion_prueba_8.txt
│   ├── solucion_prueba_9.txt
│   ├── solucion_prueba_10.txt
│   └── solucion_prueba_11.txt
├───taller/
│   └── Taller 2.pdf
└───README.md


## Solver
minizinc --solver gecode --time-limit 5000 --statistics .\planta_energia.mzn ..\pruebas\pruebas_prueba_1.dzn
minizinc --solver coin-bc --time-limit 60000 --statistics .\planta_energia.mzn ..\pruebas\pruebas_prueba_1.dzn
minizinc --solver highs --time-limit 60000 --statistics .\planta_energia.mzn ..\pruebas\pruebas_prueba_1.dzn
minizinc --solver scip --time-limit 5000 --statistics .\planta_energia.mzn ..\pruebas\pruebas_prueba_1.dzn

