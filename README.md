# Cero

Aplicación iOS de finanzas personales enfocada en un solo objetivo: **quedar libre de deudas**.

Cero no es una hoja de cálculo. Al abrirla responde cinco preguntas:

1. ¿Cuánto debo?
2. ¿Cuánto puedo gastar esta semana?
3. ¿Qué debo pagar ahora?
4. ¿Cuándo quedaré libre de deudas?
5. ¿Qué está retrasando mi progreso?

> El nombre del repositorio es provisional y se cambiará más adelante.

## Stack

- SwiftUI (iOS 18+), Swift
- SwiftData para persistencia local, sin backend ni login
- XcodeGen: el proyecto se genera desde `project.yml`

## Cómo correrlo

```bash
make open     # genera Cero.xcodeproj y lo abre en Xcode
make build    # compila para el simulador
make test     # corre las pruebas del motor de planificación
```

`Cero.xcodeproj` no se versiona: se regenera con `xcodegen generate`.

## Arquitectura

Cuatro capas, con dependencias siempre hacia abajo. Cada capa se comunica con la
siguiente mediante protocolos, y cada archivo tiene una sola responsabilidad.

```
Sources/
  App/         Punto de entrada, composición de dependencias, navegación raíz
  Features/    Una carpeta por pantalla: vista + view model + subvistas
  Core/
    Design/    Sistema de diseño: paleta, tipografía, componentes reutilizables
    Store/     SwiftData: entidades, repositorios y ensamblado del snapshot
    Engine/    Motor de planificación (puro, sin UI ni persistencia)
    Domain/    Tipos de valor puros, sin dependencias
```

### El motor

`Domain` y `Engine` no importan SwiftUI ni SwiftData: son Swift puro y por eso se
pueden probar sin simulador. El motor toma un `FinancialSnapshot` (retrato
inmutable de las finanzas del usuario) y produce un `FinancialPlan`.

Cada paso del cálculo es un objeto pequeño detrás de un protocolo:

| Protocolo | Responsabilidad |
|---|---|
| `CashFlowCalculating` | Ingresos menos compromisos obligatorios: cuánto queda realmente |
| `EmergencyFundAdvising` | Fondo de emergencia recomendado y aporte mensual |
| `LifestyleBudgeting` | Presupuestos por categoría, respetando pisos realistas |
| `SurplusAllocating` | Reparto del excedente entre deuda, imprevistos, metas y margen |
| `DebtPrioritizing` | Orden de ataque: avalancha, bola de nieve o personalizado |
| `DebtProjecting` | Simulación mes por mes: fecha libre de deuda e intereses |
| `PlanBuilding` | Compone lo anterior en un plan completo |
| `PlanSetBuilding` | Construye los tres planes comparables |
| `TargetDateSolving` | ¿Es posible tu fecha objetivo? ¿A qué costo? |
| `ImpactEvaluating` | Cuántos días mueve tu fecha una decisión concreta |
| `ScenarioApplying` | Aplica una decisión hipotética al snapshot sin tocar datos reales |
| `WeeklyBudgetSplitting` | Reparte el presupuesto mensual en semanas exactas |
| `GroceryBudgetSplitting` | Divide el supermercado en compra principal y reposiciones |

Añadir una estrategia de pago o una velocidad de plan nueva significa añadir un
tipo, no editar los existentes.

### Las tres velocidades

`Suelto`, `Balanceado` (recomendado) y `Agresivo` son un mismo algoritmo con
distintos parámetros (`PlanTuning`): cuánto se recorta el estilo de vida, cuánto
del excedente va a deuda, qué tan grande es el colchón y si las metas
secundarias siguen avanzando. Los nombres son editables.

Ninguna velocidad puede recomendar un presupuesto imposible: cada categoría tiene
un piso proporcional a lo que el usuario declaró, y las esenciales (supermercado,
transporte) se recortan mucho menos que las flexibles.
