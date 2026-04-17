# 🗄️ Proyecto Lógica: Consultas SQL — Sakila Database

> ¿Cómo se aprende SQL de verdad? Consultando datos reales. Este proyecto recorre 64 ejercicios de complejidad progresiva sobre una base de datos relacional que simula una cadena de tiendas de alquiler de películas.

---

## 📖 Descripción del Proyecto

Este proyecto aplica los conocimientos adquiridos en el módulo de SQL trabajando con **Sakila**, una base de datos relacional que simula el sistema de gestión de una cadena de tiendas de alquiler de películas.

A lo largo del proyecto se han resuelto **64 consultas** de dificultad progresiva que cubren todos los requisitos del módulo:

| Requisito | Consultas |
|-----------|-----------|
| **Consultas sobre una sola tabla** | 2, 3, 5, 7, 8, 9, 10, 12, 13, 14, 15, 16, 18, 21, 22, 23, 25, 26, 35, 36, 37, 38, 39, 40, 41 |
| **Relaciones entre tablas (JOINs)** | 17, 19, 20, 29, 30, 31, 32, 33, 34, 42, 43, 44, 45, 49, 50, 61, 62, 63, 64 |
| **Subconsultas** | 4, 11, 24, 27, 28, 46, 47, 53, 54, 56, 57, 58, 59, 60 |
| **CTEs (`WITH`)** | 55 |
| **Vistas (`VIEW`)** | 48 |
| **Tablas temporales (`TEMP TABLE`)** | 51, 52 |

Todas las consultas han sido ejecutadas y verificadas contra la base de datos real en DBeaver.

**Enfoque:** configuración del entorno → exploración del esquema → resolución por bloques → verificación en BBDD real → informe de análisis.

---

## 🗂 Estructura del Proyecto

```
proyecto-sql-sakila/
│
├── README.md                  # Este archivo: pasos seguidos e informe de análisis
├── esquema_sakila.png         # Diagrama ER de la BBDD exportado desde DBeaver
└── consultas_sakila.sql       # Las 64 consultas resueltas con explicaciones paso a paso
```

---

## 🛠 Herramientas Utilizadas

- **PostgreSQL** — motor de base de datos relacional
- **DBeaver Community Edition** — herramienta visual para gestión y ejecución de consultas
- **GitHub** — control de versiones y entrega del proyecto
- **Base de datos:** Sakila (tienda de alquiler de películas ficticia)

---

## 🗺 Diagrama de la Base de Datos

![Diagrama ER Sakila](esquema_sakila.png)

> El diagrama fue generado automáticamente desde DBeaver (`clic derecho sobre public` → `View Diagram`) y exportado como imagen.

---

## ⚙️ Pasos Seguidos Durante el Proyecto

### 1. Instalación y configuración del entorno

Se instaló **PostgreSQL** como motor de base de datos relacional y **DBeaver Community Edition** como herramienta visual para la gestión y ejecución de consultas.

Para establecer la conexión en DBeaver:
1. Abrir DBeaver y verificar que aparece un **tick verde** en la conexión de PostgreSQL
2. Ir a `Window` → `Database Navigator` para abrir el panel de conexiones

---

### 2. Carga de la base de datos Sakila en DBeaver

**Crear la base de datos:**
1. En el panel izquierdo, clic derecho sobre **"Databases"** → **"Create New Database"**
2. Rellenar los campos: nombre `sakila`, encoding `UTF8`
3. Clic derecho sobre `sakila` → **"Set as default"**

> La base de datos activa aparece en **negrita** en el panel izquierdo.

**Ejecutar el script de la BBDD:**
1. `File` → `Open File` → seleccionar el archivo `.sql` proporcionado por el bootcamp
2. Verificar que la pestaña apunta a `sakila` y **NO pone `<none>`**

> ⚠️ **IMPORTANTE:** Si pone `<none>`, hacer clic sobre el nombre de la pestaña → icono de PostgreSQL → flecha → seleccionar `sakila`.

3. Seleccionar todo el código → `Command + A` → ejecutar con la **flecha de play (▶)**

**Verificar la instalación:**

Clic derecho sobre `sakila` → **"Refresh"** → desplegar `Schemas` → `public` → `Tables`. Deben aparecer las **15 tablas**:

`actor` · `address` · `category` · `city` · `country` · `customer` · `film` · `film_actor` · `film_category` · `inventory` · `language` · `payment` · `rental` · `staff` · `store`

---

### 3. Exploración y comprensión del esquema

Antes de escribir ninguna consulta se realizó un análisis exhaustivo del esquema:

- Se identificaron las **15 tablas** y su propósito dentro del modelo
- Se mapeó el flujo principal del negocio: `film → inventory → rental → payment`
- Se entendió que `film_actor` y `film_category` son **tablas intermedias** que resuelven relaciones N:M
- Se detectó que `original_language_id` en `film` es `NULL` en **todos** los registros (consulta 4: 0 resultados)
- Se confirmó que todos los actores tienen al menos una película asociada (consulta 46: 0 resultados)
- Se comprobó que los campos de texto están en **MAYÚSCULAS**, haciendo necesario el uso de `ILIKE`
- Se identificó que `payment` puede tener **múltiples registros por alquiler**, tenido en cuenta en la consulta 11 con `SUM()` + `GROUP BY`

---

### 4. Resolución de las 64 consultas

Las consultas se abordaron de menor a mayor complejidad en seis bloques:

| Bloque | Técnicas utilizadas |
|--------|---------------------|
| **Consultas sobre una sola tabla** | `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`, `HAVING`, `LIMIT`, `OFFSET`, funciones de agregación (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `VARIANCE`, `STDDEV`) |
| **Relaciones entre tablas** | `INNER JOIN`, `LEFT JOIN`, `FULL JOIN`, `CROSS JOIN` — criterio siempre basado en si se necesitan todos los registros independientemente de coincidencia |
| **Subconsultas** | Subconsultas escalares en `WHERE`. `NOT EXISTS` en lugar de `NOT IN` en consultas 46 y 56 por seguridad ante NULLs |
| **CTEs** | `WITH` en la consulta 55, la más compleja del proyecto, dividiendo el problema en dos pasos lógicos |
| **Vistas** | `CREATE OR REPLACE VIEW actor_num_peliculas` |
| **Tablas temporales** | `CREATE TEMP TABLE ... AS SELECT`, precedidas de `DROP TABLE IF EXISTS` |

---

### 5. Verificación de todas las consultas en DBeaver

Todas las consultas fueron ejecutadas individualmente contra la base de datos real. Hallazgos relevantes:

- **Consulta 4** → devuelve **0 filas**: `original_language_id` es NULL en todos los registros
- **Consulta 11** → `importe_total` es **0.00**: el alquiler tiene un pago registrado con importe cero, comportamiento coherente con los datos reales
- **Consulta 46** → devuelve **0 filas**: todos los actores tienen al menos una película asociada

---

## 📊 Informe de Análisis

### 💰 Rendimiento económico

> 💡 La empresa ha generado un **total de $67.416,51** en ingresos, con una media de **$4,20** por transacción y una desviación estándar de $2,37 — lo que indica precios de alquiler no uniformes.

- El **precio de alquiler** medio es de aproximadamente **$2,98**, con películas de `rental_rate` notablemente superior, lo que sugiere una estrategia de precios diferenciada.
- El **coste de reemplazo** varía entre $9,99 y $29,99, con varianza significativa que tiene implicaciones para la gestión del riesgo ante pérdidas o daños.
- Los **5 clientes con mayor gasto total** concentran una porción relevante de los ingresos — un programa de fidelización tendría impacto directo en la facturación.

---

### 🎬 Catálogo de películas

El catálogo contiene **1.000 películas** distribuidas en **5 clasificaciones por edades**:

| Clasificación | Descripción |
|---------------|-------------|
| **G** | Para todos los públicos |
| **PG** | Se sugiere guía parental |
| **PG-13** | No recomendado para menores de 13 años |
| **R** | Menores de 17 requieren acompañante adulto |
| **NC-17** | Solo para adultos |

- Duración mínima: **46 min** · Duración máxima: **185 min** · Media: ~**115 min**
- **Todas las películas fueron estrenadas en 2006**
- `original_language_id` es `NULL` en todos los registros: el modelo contempla la posibilidad de películas dobladas, pero ninguna está marcada como tal

---

### 🎭 Actores

- El elenco está compuesto por **200 actores**
- Algunos actores superan las **40 películas**, con una media de ~27 películas por actor
- La consulta 46 devuelve **0 resultados**: todos los actores registrados tienen al menos una película — buena integridad referencial de los datos

---

### 📅 Comportamiento de los alquileres

> 💡 Se han registrado **16.044 alquileres** en total, con una media real de **4,87 días** por alquiler calculada como diferencia entre `return_date` y `rental_date`.

- El análisis por **día** muestra picos claros de actividad, útil para planificar turnos de personal
- El análisis por **mes** revela estacionalidad: **los meses de verano concentran el mayor volumen de alquileres**
- Existen alquileres con `return_date IS NULL`: copias aún no devueltas — dato crítico para la gestión del inventario real
- La consulta 29 distingue copias disponibles de copias actualmente alquiladas usando `NOT EXISTS`, información mucho más valiosa que un simple conteo de inventario

---

### 🏷️ Categorías y géneros

- Las **16 categorías** presentan distribuciones de duración diferentes; las que superan los 110 min de promedio concentran las películas más largas
- La categoría **'Action'** destaca tanto en volumen de alquileres como en duración total acumulada
- Hay diferencia notable entre categorías con más películas y categorías con más alquileres: **más títulos no implica más demanda**

---

### 🏪 Operaciones y tiendas

- La cadena opera con **2 tiendas** y **2 empleados**; el `CROSS JOIN` genera exactamente **4 combinaciones** posibles
- Existe una **dependencia circular intencionada** entre `staff` y `store`: cada tienda referencia a un empleado como gerente y cada empleado está asignado a una tienda

---

### 🔍 Calidad e integridad de los datos

- Campos de texto en **MAYÚSCULAS**: imprescindible usar `ILIKE` para búsquedas robustas
- `original_language_id` sin poblar en todos los registros: verificado con 0 resultados en consulta 4
- `payment` puede tener **múltiples registros por `rental_id`**: gestionado con `SUM()` + `GROUP BY` en consulta 11
- La consulta 46 confirma integridad referencial completa: **0 actores sin película asociada**

---

## ✅ Buenas Prácticas Aplicadas

| Práctica | Descripción | Consultas |
|----------|-------------|-----------|
| **Alias descriptivos** | Todas las columnas calculadas tienen nombres claros y en español | Todas |
| **`ILIKE` en lugar de `LIKE`** | Búsquedas insensibles a mayúsculas, necesario en Sakila | 6, 17, 35, 53, 55, 59 |
| **`ORDER BY` determinista** | Siempre incluye criterio de desempate | Todas las que usan `ORDER BY` |
| **`::numeric` en `ROUND`** | Necesario en PostgreSQL para evitar errores de tipo | 13, 20, 21, 26 |
| **`NOT EXISTS` vs `NOT IN`** | Más seguro ante NULLs y más eficiente en PostgreSQL | 46, 56 |
| **`LEFT JOIN` consciente** | Usado solo cuando se necesitan registros sin coincidencia | 29, 30, 31, 32, 43, 47, 49, 51, 64 |
| **`actor_id` en `GROUP BY`** | Evita mezclar actores distintos con mismo nombre y apellido | 30, 47, 48, 49, 60, 64 |
| **`DROP TABLE IF EXISTS`** | Permite re-ejecutar el script sin errores | 51, 52 |
| **CTEs con `WITH`** | Divide lógica compleja en pasos legibles y mantenibles | 55 |
| **`SUM` + `GROUP BY` en pago** | Evita duplicar filas por múltiples pagos por alquiler | 11 |
| **`COALESCE` para NULLs** | Convierte NULL a 0 para películas sin inventario | 29 |
| **`rental_date::date`** | Cast nativo de PostgreSQL, más correcto que `DATE()` de MySQL | 23 |
| **Enunciado como comentario** | Facilita ejecución consulta a consulta en DBeaver | Todas |
| **Explicación paso a paso** | Cada línea de código tiene su porqué documentado | Todas |
| **Verificación en BBDD real** | Todas las consultas ejecutadas y comprobadas en DBeaver | Todas |

---

## 🔄 Próximos Pasos

- Explorar consultas con funciones de ventana (`WINDOW FUNCTIONS`: `ROW_NUMBER`, `RANK`, `LAG`, `LEAD`)
- Añadir índices y analizar su impacto en el rendimiento de las consultas más costosas
- Migrar el proyecto a otro motor (MySQL, SQLite) para identificar diferencias de sintaxis
- Incorporar visualización de los resultados conectando la BBDD a una herramienta de BI

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Si deseas proponer consultas alternativas o mejoras en las existentes, abre un pull request o una issue describiendo el cambio propuesto.

---

## ✒️ Autora

- **Carmen**
- Bootcamp de Análisis de Datos
- https://github.com/carmenperalgil-cyber

---

## 🧠 Conclusión Final

> 🎯 Este proyecto demuestra cómo trabajar con un modelo relacional de complejidad real cambia la forma de pensar en los datos. La elección del tipo de JOIN correcto, el uso de `NOT EXISTS` frente a `NOT IN`, o detalles como `::numeric` en `ROUND()` son los que distinguen un código que funciona en local de un código robusto que funciona con datos reales en producción. La verificación en base de datos real es imprescindible: algunos resultados solo son comprensibles cuando se ejecutan contra los datos y se entiende qué reflejan.
