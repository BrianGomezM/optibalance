# OptiBalance

> **Taller 1: Modelamiento e Implementación de CSPs**  
> Programación por Restricciones - MiniZinc  
> Universidad del Valle  
> Abril de 2025  

---

## 📄 Información General

**OptiBalance** es un modelo de optimización basado en programación por restricciones (CSP), desarrollado en MiniZinc. Este taller tiene como objetivo formular, modelar e implementar un problema de asignación balanceada, en donde se busca distribuir equitativamente actividades o cargas de trabajo entre diferentes entidades.

El desarrollo incluye tanto el modelado matemático como su implementación computacional, además de pruebas experimentales y análisis de resultados.

---

## 👨‍💻 Autores

- Brayan Gómez Muñoz – 2310016  
- Juan José Moreno Jaramillo – 2310038  

**Profesor:** Robinson Andrey Duque Agudelo  
**Curso:** Programación por Restricciones  
**Escuela:** Ingeniería de Sistemas y Computación  
**Universidad del Valle**

---

## 📁 Estructura del Proyecto

```plaintext
optibalance/
├── models/
│   ├── model.mzn            # Modelo principal en MiniZinc
│   └── data.dzn             # Archivo base con datos de ejemplo
├── solutions/
│   └── solution.txt         # Resultados de ejecución guardados
├── tests/
│   ├── test1.dzn            # Casos de prueba adicionales
│   ├── test2.dzn
│   └── ...
├── reports/
│   ├── informe_optibalance.pdf   # Informe en PDF con portada y desarrollo
│   └── portada.tex               # (Opcional) Portada en LaTeX
├── Imagenes/
│   └── univalle.jpg         # Logo de la Universidad del Valle
└── README.md                # Este archivo



## Solver
PS B:\Universidad\Restricciones\optibalance\modelo> minizinc --solver Gecode --time-limit 5000 .\planta_energia.mzn ..\pruebas\datos_prueba_2.dzn

