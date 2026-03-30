
/* =========================================================
   DataProject SQL - Consultas (PostgreSQL)
   BBDD: Tienda de películas (esquema tipo Sakila/Pagila)
   Herramienta: DBeaver
   Formato: Cada consulta identificada con su número y enunciado.
   ========================================================= */

/* ============================================================
   CONSULTA 1: Crea el esquema de la BBDD
   ============================================================ */

-- PASO 1: Listamos todas las tablas del esquema público
-- para tener una visión general de la estructura de la BBDD
SELECT table_name AS tablas_en_sakila
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- PASO 2: Mostramos columnas, tipos de dato y si admiten NULL
-- de cada tabla principal consultando information_schema.columns
SELECT
    table_name      AS tabla,
    column_name     AS columna,
    data_type       AS tipo_de_dato,
    is_nullable     AS admite_nulos,
    column_default  AS valor_por_defecto
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
      'actor', 'film', 'film_actor', 'category', 'film_category',
      'language', 'inventory', 'rental', 'payment',
      'customer', 'address', 'city', 'country', 'staff', 'store'
  )
ORDER BY table_name, ordinal_position;

-- PASO 3: Mostramos las claves primarias (PRIMARY KEY) de cada tabla
-- para entender qué columna identifica de forma única cada registro
SELECT
    tc.table_name   AS tabla,
    kcu.column_name AS clave_primaria
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema    = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND tc.table_schema    = 'public'
ORDER BY tc.table_name;

-- PASO 4: Mostramos las claves foráneas (FOREIGN KEY) de cada tabla
-- para ver cómo se relacionan las tablas entre sí
SELECT
    tc.table_name            AS tabla_origen,
    kcu.column_name          AS columna_fk,
    ccu.table_name           AS tabla_referenciada,
    ccu.column_name          AS columna_referenciada
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema    = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
   AND ccu.table_schema    = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema    = 'public'
ORDER BY tc.table_name;

/* ============================================================
   CONSULTA 2: Muestra los nombres de todas las películas
               con una clasificación por edades de 'R'
   ============================================================ */
-- Seleccionamos el título de la tabla film
-- Filtramos con WHERE para quedarnos solo con las películas
-- cuya columna rating sea exactamente 'R'
SELECT title
FROM film
WHERE rating = 'R';

/* ============================================================
   CONSULTA 3: Encuentra los nombres de los actores que tengan
               un "actor_id" entre 30 y 40
   ============================================================ */
-- Seleccionamos nombre y apellido de la tabla actor
-- BETWEEN filtra los actor_id en ese rango (30 y 40 inclusive)
SELECT first_name, last_name
FROM actor
WHERE actor_id BETWEEN 30 AND 40;

/* ============================================================
   CONSULTA 4: Obtén las películas cuyo idioma coincide
               con el idioma original
   ============================================================ */
-- Seleccionamos film_id, título e IDs de idioma para poder
-- verificar visualmente qué valores se están comparando
-- WHERE compara directamente las dos columnas de idioma
-- IMPORTANTE: en Sakila la columna original_language_id es NULL
-- en todas las filas, por lo que esta consulta devuelve 0 resultados.
-- Esto es correcto: NULL = NULL no es TRUE en SQL, sino NULL.
-- La consulta está bien escrita; el resultado vacío refleja los datos reales.
SELECT film_id, title, language_id, original_language_id
FROM film
WHERE language_id = original_language_id;

/* ============================================================
   CONSULTA 5: Ordena las películas por duración de forma ascendente
   ============================================================ */
-- Incluimos film_id para identificar cada película de forma única
-- ORDER BY length ASC ordena de menor a mayor duración
SELECT film_id, title, length
FROM film
ORDER BY length ASC;

 /* ============================================================
   CONSULTA 6: Encuentra el nombre y apellido de los actores
               que tengan 'Allen' en su apellido
   ============================================================ */
-- ILIKE es la versión insensible a mayúsculas/minúsculas de LIKE en PostgreSQL
-- Más robusto que LIKE porque los datos en Sakila están almacenados en mayúsculas
-- El patrón '%Allen%' busca cualquier texto antes y después de 'Allen'
SELECT first_name, last_name
FROM actor
WHERE last_name ILIKE '%Allen%';

/* ============================================================
   CONSULTA 7: Encuentra la cantidad total de películas en cada
               clasificación de la tabla "film" y muestra la
               clasificación junto con el recuento
   ============================================================ */
-- GROUP BY rating agrupa todas las filas por clasificación
-- COUNT(*) cuenta el número de películas dentro de cada grupo
-- Ordenamos por recuento DESC y rating como desempate alfabético
SELECT rating, COUNT(*) AS total_peliculas
FROM film
GROUP BY rating
ORDER BY total_peliculas DESC, rating;

/* ============================================================
   CONSULTA 8: Encuentra el título de todas las películas que son
               'PG-13' o tienen una duración mayor a 3 horas
   ============================================================ */
-- OR combina dos condiciones: clasificación 'PG-13' O duración > 180 min
-- Una película solo necesita cumplir una de las dos condiciones
-- ORDER BY title ordena el resultado alfabéticamente
SELECT title, rating, length
FROM film
WHERE rating = 'PG-13' OR length > 180
ORDER BY title;

/* ============================================================
   CONSULTA 9: Encuentra la variabilidad de lo que costaría
               reemplazar las películas
   ============================================================ */
-- VARIANCE() mide cuánto se dispersan los valores respecto a la media
-- STDDEV() es la raíz cuadrada de la varianza, más fácil de interpretar
-- Incluir ambas métricas da una visión más completa de la dispersión
SELECT
    VARIANCE(replacement_cost) AS var_replacement_cost,
    STDDEV(replacement_cost)   AS std_replacement_cost
FROM film;

/* ============================================================
   CONSULTA 10: Encuentra la mayor y menor duración de una
                película de nuestra BBDD
   ============================================================ */
-- MIN() devuelve la duración más corta de todas las películas
-- MAX() devuelve la duración más larga
-- Ambas se calculan en la misma consulta para mayor eficiencia
SELECT
    MIN(length) AS duracion_min,
    MAX(length) AS duracion_max
FROM film;

/* ============================================================
   CONSULTA 11: Encuentra lo que costó el antepenúltimo alquiler
                ordenado por día
   ============================================================ */
-- Usamos una subconsulta para obtener el rental_id del antepenúltimo alquiler
-- ordenando por fecha descendente y usando OFFSET 2 LIMIT 1
-- SUM(p.amount) agrupa todos los pagos asociados a ese alquiler en uno solo,
-- evitando devolver múltiples filas si un alquiler tiene más de un pago
-- GROUP BY agrupa por los campos del alquiler para consolidar el importe total
-- En este caso, el resultado del importe_total es de 0.00, lo cual se debe a que el alquiler seleccionado tiene un registro en la tabla payment, pero con importe igual a 0. Esto es coherente con los datos de la base de datos, aunque no sea lo habitual en un escenario real. 
SELECT
    r.rental_id,
    r.rental_date,
    SUM(p.amount) AS importe_total
FROM payment p
JOIN rental r ON r.rental_id = p.rental_id
WHERE p.rental_id = (
    SELECT rental_id
    FROM rental
    ORDER BY rental_date DESC
    OFFSET 2
    LIMIT 1
)
GROUP BY r.rental_id, r.rental_date;


/* ============================================================
   CONSULTA 12: Encuentra el título de las películas en la tabla
                "film" que no sean ni 'NC-17' ni 'G' en cuanto
                a su clasificación
   ============================================================ */
-- NOT IN excluye múltiples valores en una sola condición
-- Equivale a: rating != 'NC-17' AND rating != 'G'
-- ORDER BY title ordena el resultado alfabéticamente
SELECT title, rating
FROM film
WHERE rating NOT IN ('NC-17', 'G')
ORDER BY title;

/* ============================================================
   CONSULTA 13: Encuentra el promedio de duración de las películas
                para cada clasificación de la tabla film y muestra
                la clasificación junto con el promedio de duración
   ============================================================ */
-- GROUP BY rating agrupa las filas por clasificación
-- AVG(length) calcula la media de duración dentro de cada grupo
-- ::numeric es necesario en PostgreSQL para que ROUND funcione correctamente
-- ROUND(..., 2) redondea a 2 decimales para mayor legibilidad
SELECT rating, ROUND(AVG(length)::numeric, 2) AS promedio_duracion
FROM film
GROUP BY rating
ORDER BY promedio_duracion DESC;

/* ============================================================
   CONSULTA 14: Encuentra el título de todas las películas que
                tengan una duración mayor a 180 minutos
   ============================================================ */
-- WHERE length > 180 filtra las películas más largas que 3 horas
-- Ordenamos por duración DESC y title como desempate alfabético
SELECT title, length
FROM film
WHERE length > 180
ORDER BY length DESC, title;

/* ============================================================
   CONSULTA 15: ¿Cuánto dinero ha generado en total la empresa?
   ============================================================ */
-- SUM(amount) suma todos los importes registrados en la tabla payment
-- Esta tabla recoge todos los pagos realizados por los clientes
SELECT SUM(amount) AS total_generado
FROM payment;

/* ============================================================
   CONSULTA 16: Muestra los 10 clientes con mayor valor de id
   ============================================================ */
-- ORDER BY customer_id DESC ordena de mayor a menor ID
-- LIMIT 10 restringe el resultado a las 10 primeras filas
SELECT customer_id, first_name, last_name
FROM customer
ORDER BY customer_id DESC
LIMIT 10;

/* ============================================================
   CONSULTA 17: Encuentra el nombre y apellido de los actores
                que aparecen en la película con título 'Egg Igby'
   ============================================================ */
-- Encadenamos film → film_actor → actor para llegar a los actores
-- DISTINCT evita duplicados si un actor aparece varias veces
-- ILIKE hace la búsqueda insensible a mayúsculas/minúsculas
-- ORDER BY ordena el resultado alfabéticamente
SELECT DISTINCT a.first_name, a.last_name
FROM film f
JOIN film_actor fa ON fa.film_id = f.film_id
JOIN actor a       ON a.actor_id = fa.actor_id
WHERE f.title ILIKE 'Egg Igby'
ORDER BY a.last_name, a.first_name;

/* ============================================================
   CONSULTA 18: Selecciona todos los nombres de las películas únicos
   ============================================================ */
-- DISTINCT elimina títulos duplicados del resultado
-- ORDER BY title ordena alfabéticamente
SELECT DISTINCT title
FROM film
ORDER BY title;

/* ============================================================
   CONSULTA 19: Encuentra el título de las películas que son
                comedias y tienen una duración mayor a 180 minutos
                en la tabla "film"
   ============================================================ */
-- Unimos film → film_category → category para acceder al género
-- WHERE filtra por categoría 'Comedy' AND duración > 180 min
-- Ambas condiciones deben cumplirse a la vez (AND)
-- Añadimos film_id para identificar cada película de forma única
SELECT f.film_id, f.title, f.length
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c       ON c.category_id = fc.category_id
WHERE c.name = 'Comedy' AND f.length > 180
ORDER BY f.title;

/* ============================================================
   CONSULTA 20: Encuentra las categorías de películas que tienen
                un promedio de duración superior a 110 minutos y
                muestra el nombre de la categoría junto con el
                promedio de duración
   ============================================================ */
-- Unimos category → film_category → film para calcular duración por categoría
-- HAVING filtra grupos tras la agregación (como WHERE pero para GROUP BY)
-- ::numeric necesario en PostgreSQL para que ROUND funcione correctamente
SELECT c.name AS categoria, ROUND(AVG(f.length)::numeric, 2) AS promedio_duracion
FROM category c
JOIN film_category fc ON fc.category_id = c.category_id
JOIN film f           ON f.film_id = fc.film_id
GROUP BY c.name
HAVING AVG(f.length) > 110
ORDER BY promedio_duracion DESC;

/* ============================================================
   CONSULTA 21: ¿Cuál es la media de duración del alquiler
                de las películas?
   ============================================================ */
-- Calculamos la diferencia real entre return_date y rental_date
-- EXTRACT(EPOCH ...) convierte el intervalo a segundos totales
-- Dividimos entre 86400 (segundos en un día) para obtener días
-- WHERE return_date IS NOT NULL excluye alquileres aún activos
-- ::numeric necesario para que ROUND funcione correctamente en PostgreSQL
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (return_date - rental_date)) / 86400)::numeric, 2) AS media_dias_alquiler
FROM rental
WHERE return_date IS NOT NULL;

/* ============================================================
   CONSULTA 22: Crea una columna con el nombre y apellidos
                de todos los actores y actrices
   ============================================================ */
-- El operador || concatena cadenas de texto en PostgreSQL
-- Incluimos actor_id para identificar cada actor de forma única
-- ORDER BY actor_id mantiene el orden natural de la tabla
SELECT actor_id, (first_name || ' ' || last_name) AS nombre_completo
FROM actor
ORDER BY actor_id;

/* ============================================================
   CONSULTA 23: Números de alquiler por día, ordenados por
                cantidad de alquiler de forma descendente
   ============================================================ */
-- rental_date::date es el cast nativo de PostgreSQL para extraer solo la fecha
-- Es más correcto que DATE() que es una función de MySQL
-- COUNT(*) cuenta los alquileres de cada día
-- Ordenamos por num_alquileres DESC y dia DESC como desempate
SELECT rental_date::date AS dia, COUNT(*) AS num_alquileres
FROM rental
GROUP BY rental_date::date
ORDER BY num_alquileres DESC, dia DESC;

/* ============================================================
   CONSULTA 24: Encuentra las películas con una duración
                superior al promedio
   ============================================================ */
-- La subconsulta escalar calcula el promedio global de duración
-- La consulta principal filtra las películas que superan ese valor
-- Incluimos film_id para identificar cada película de forma única
-- Ordenamos por length DESC y title como desempate alfabético
SELECT film_id, title, length
FROM film
WHERE length > (SELECT AVG(length) FROM film)
ORDER BY length DESC, title;

/* ============================================================
   CONSULTA 25: Averigua el número de alquileres registrados
                por mes
   ============================================================ */
-- DATE_TRUNC('month', ...) trunca la fecha al primer día del mes
-- ::date convierte el resultado a tipo date para mejor legibilidad
-- Agrupa correctamente todos los alquileres del mismo mes y año
-- ORDER BY mes muestra la evolución cronológica
SELECT DATE_TRUNC('month', rental_date)::date AS mes, COUNT(*) AS num_alquileres
FROM rental
GROUP BY DATE_TRUNC('month', rental_date)::date
ORDER BY mes;

/* ============================================================
   CONSULTA 26: Encuentra el promedio, la desviación estándar
                y varianza del total pagado
   ============================================================ */
-- AVG()      → media aritmética de los importes
-- STDDEV()   → mide la dispersión de los pagos respecto a la media
-- VARIANCE() → cuadrado de la desviación estándar
-- Usamos 4 decimales para std y varianza por mayor precisión estadística
SELECT
    ROUND(AVG(amount)::numeric, 2)      AS promedio,
    ROUND(STDDEV(amount)::numeric, 4)   AS desviacion_std,
    ROUND(VARIANCE(amount)::numeric, 4) AS varianza
FROM payment;

/* ============================================================
   CONSULTA 27: ¿Qué películas se alquilan por encima del
                precio medio?
   ============================================================ */
-- La subconsulta calcula el rental_rate medio de todas las películas
-- La consulta principal filtra las que superan esa media
-- Incluimos film_id para identificar cada película de forma única
-- Ordenamos por rental_rate DESC y title como desempate
SELECT film_id, title, rental_rate
FROM film
WHERE rental_rate > (SELECT AVG(rental_rate) FROM film)
ORDER BY rental_rate DESC, title;

/* ============================================================
   CONSULTA 28: Muestra el id de los actores que hayan participado
                en más de 40 películas
   ============================================================ */
-- Agrupamos film_actor por actor_id para contar sus películas
-- HAVING COUNT(*) > 40 filtra solo los actores más prolíficos
-- actor_id como desempate garantiza un resultado determinista
SELECT fa.actor_id, COUNT(*) AS num_peliculas
FROM film_actor fa
GROUP BY fa.actor_id
HAVING COUNT(*) > 40
ORDER BY num_peliculas DESC, fa.actor_id;

/* ============================================================
   CONSULTA 29: Obtener todas las películas y, si están
                disponibles en el inventario, mostrar la cantidad
                disponible
   ============================================================ */
-- LEFT JOIN incluye todas las películas aunque no tengan inventario
-- "Disponible" significa: copia en inventario SIN alquiler activo
-- Un alquiler está activo cuando return_date IS NULL (no devuelta aún)
-- NOT EXISTS comprueba que esa copia concreta no esté actualmente alquilada
-- CASE WHEN ... THEN 1 ELSE 0 suma 1 solo por las copias realmente libres
-- COALESCE convierte NULL a 0 para películas sin ninguna copia en inventario
SELECT
    f.film_id,
    f.title,
    COALESCE(SUM(
        CASE
            WHEN i.inventory_id IS NOT NULL
             AND NOT EXISTS (
                 SELECT 1
                 FROM rental r
                 WHERE r.inventory_id = i.inventory_id
                   AND r.return_date IS NULL
             )
            THEN 1 ELSE 0
        END
    ), 0) AS copias_disponibles
FROM film f
LEFT JOIN inventory i ON i.film_id = f.film_id
GROUP BY f.film_id, f.title
ORDER BY f.title;

/* ============================================================
   CONSULTA 30: Obtener los actores y el número de películas
                en las que ha actuado
   ============================================================ */
-- LEFT JOIN incluye actores que no han actuado en ninguna película
-- COUNT(fa.film_id) cuenta solo filas no NULL (devuelve 0 si no hay películas)
-- Agrupamos por actor_id para evitar mezclar actores con mismo nombre
-- Ordenamos por num_peliculas DESC y apellido+nombre como desempate
SELECT a.actor_id, a.first_name, a.last_name, COUNT(fa.film_id) AS num_peliculas
FROM actor a
LEFT JOIN film_actor fa ON fa.actor_id = a.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY num_peliculas DESC, a.last_name, a.first_name;

/* ============================================================
   CONSULTA 31: Obtener todas las películas y mostrar los actores
                que han actuado en ellas, incluso si algunas
                películas no tienen actores asociados
   ============================================================ */
-- Partimos de film como tabla base para incluir TODAS las películas
-- LEFT JOIN con film_actor: incluye películas sin entradas en film_actor
-- LEFT JOIN con actor: muestra NULL en nombre si no hay actor asociado
-- Incluimos IDs para identificar cada fila de forma inequívoca
SELECT f.film_id, f.title, a.actor_id, a.first_name, a.last_name
FROM film f
LEFT JOIN film_actor fa ON fa.film_id = f.film_id
LEFT JOIN actor a       ON a.actor_id = fa.actor_id
ORDER BY f.title, a.last_name, a.first_name;

/* ============================================================
   CONSULTA 32: Obtener todos los actores y mostrar las películas
                en las que han actuado, incluso si algunos actores
                no han actuado en ninguna película
   ============================================================ */
-- Ahora la tabla base es actor: queremos TODOS los actores
-- LEFT JOIN con film_actor y film: actores sin películas tienen NULL en title
-- Incluimos IDs para identificar cada fila de forma inequívoca
SELECT a.actor_id, a.first_name, a.last_name, f.film_id, f.title
FROM actor a
LEFT JOIN film_actor fa ON fa.actor_id = a.actor_id
LEFT JOIN film f        ON f.film_id = fa.film_id
ORDER BY a.last_name, a.first_name, f.title;

/* ============================================================
   CONSULTA 33: Obtener todas las películas que tenemos y todos
                los registros de alquiler
   ============================================================ */
-- FULL JOIN combina LEFT y RIGHT JOIN:
-- incluye películas sin alquileres Y alquileres sin película asociada
-- Pasamos por inventory como tabla intermedia obligatoria entre film y rental
-- NULLS LAST coloca los NULL al final para mejor legibilidad del resultado
SELECT
    f.film_id,
    f.title,
    r.rental_id,
    r.rental_date,
    r.return_date
FROM film f
FULL JOIN inventory i ON i.film_id = f.film_id
FULL JOIN rental r    ON r.inventory_id = i.inventory_id
ORDER BY r.rental_date NULLS LAST, f.title NULLS LAST;

/* ============================================================
   CONSULTA 34: Encuentra los 5 clientes que más dinero se hayan
                gastado con nosotros
   ============================================================ */
-- JOIN entre customer y payment para acceder a los importes pagados
-- SUM(p.amount) suma el total gastado por cada cliente
-- ORDER BY total_gastado DESC + LIMIT 5 devuelve solo el top 5
SELECT c.customer_id, c.first_name, c.last_name, SUM(p.amount) AS total_gastado
FROM customer c
JOIN payment p ON p.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_gastado DESC
LIMIT 5;

/* ============================================================
   CONSULTA 35: Selecciona todos los actores cuyo primer nombre
                es 'Johnny'
   ============================================================ */
-- Usamos ILIKE para que la búsqueda sea insensible a mayúsculas/minúsculas
-- ya que los nombres en Sakila están almacenados en mayúsculas ('JOHNNY')
-- ORDER BY last_name, first_name ordena el resultado alfabéticamente
SELECT actor_id, first_name, last_name
FROM actor
WHERE first_name ILIKE 'Johnny'
ORDER BY last_name, first_name;

/* ============================================================
   CONSULTA 36: Renombra la columna "first_name" como Nombre
                y "last_name" como Apellido
   ============================================================ */
-- AS asigna un alias a cada columna en el resultado
-- Incluimos actor_id para mantener la referencia única del registro
-- Comillas dobles preservan tildes y mayúsculas en el alias
SELECT actor_id, first_name AS "Nombre", last_name AS "Apellido"
FROM actor
ORDER BY actor_id;

/* ============================================================
   CONSULTA 37: Encuentra el ID del actor más bajo y más alto
                en la tabla actor
   ============================================================ */
-- MIN() devuelve el actor_id menor (primer registro insertado)
-- MAX() devuelve el actor_id mayor (último registro insertado)
-- Ambos se calculan en una sola consulta para mayor eficiencia
SELECT MIN(actor_id) AS actor_id_min, MAX(actor_id) AS actor_id_max
FROM actor;

/* ============================================================
   CONSULTA 38: Cuenta cuántos actores hay en la tabla "actor"
   ============================================================ */
-- COUNT(*) cuenta todas las filas de la tabla sin importar NULLs
-- Es la forma más directa de obtener el total de registros
SELECT COUNT(*) AS total_actores
FROM actor;

/* ============================================================
   CONSULTA 39: Selecciona todos los actores y ordénalos por
                apellido en orden ascendente
   ============================================================ */
-- ORDER BY last_name ASC ordena alfabéticamente de la A a la Z
-- first_name ASC como segundo criterio desempata actores con mismo apellido
SELECT actor_id, first_name, last_name
FROM actor
ORDER BY last_name ASC, first_name ASC;

/* ============================================================
   CONSULTA 40: Selecciona las primeras 5 películas de la tabla "film"
   ============================================================ */
-- ORDER BY film_id garantiza un orden determinista y reproducible
-- Sin ORDER BY el resultado podría variar entre ejecuciones
-- LIMIT 5 restringe el resultado a las 5 primeras filas
SELECT film_id, title
FROM film
ORDER BY film_id
LIMIT 5;

/* ============================================================
   CONSULTA 41: Agrupa los actores por su nombre y cuenta cuántos
                actores tienen el mismo nombre.
                ¿Cuál es el nombre más repetido?
   ============================================================ */
-- GROUP BY first_name agrupa actores que comparten el mismo nombre
-- COUNT(*) cuenta cuántos actores hay en cada grupo
-- ORDER BY repeticiones DESC + LIMIT 1 devuelve solo el más frecuente
-- first_name como segundo criterio garantiza resultado determinista
SELECT first_name, COUNT(*) AS repeticiones
FROM actor
GROUP BY first_name
ORDER BY repeticiones DESC, first_name
LIMIT 1;

/* ============================================================
   CONSULTA 42: Encuentra todos los alquileres y los nombres
                de los clientes que los realizaron
   ============================================================ */
-- JOIN entre rental y customer usando customer_id como clave de unión
-- Solo aparecen alquileres con cliente asociado (INNER JOIN)
-- Incluimos customer_id para identificar al cliente de forma inequívoca
-- Ordenamos por rental_date DESC para ver los más recientes primero
SELECT r.rental_id, r.rental_date, c.customer_id, c.first_name, c.last_name
FROM rental r
JOIN customer c ON c.customer_id = r.customer_id
ORDER BY r.rental_date DESC;

/* ============================================================
   CONSULTA 43: Muestra todos los clientes y sus alquileres si
                existen, incluyendo aquellos que no tienen alquileres
   ============================================================ */
-- LEFT JOIN desde customer: todos los clientes aparecen siempre
-- Si un cliente no tiene alquileres, rental_id y fechas serán NULL
-- Incluimos return_date para ver el estado de cada alquiler
-- Ordenamos por customer_id y rental_date para agrupar el historial por cliente
SELECT c.customer_id, c.first_name, c.last_name, r.rental_id, r.rental_date, r.return_date
FROM customer c
LEFT JOIN rental r ON r.customer_id = c.customer_id
ORDER BY c.customer_id, r.rental_date;

/* ============================================================
   CONSULTA 44: Realiza un CROSS JOIN entre las tablas film y category.
                ¿Aporta valor esta consulta? ¿Por qué?
   ============================================================ */
-- CROSS JOIN genera el producto cartesiano: cada película con cada categoría
-- Si hay 1000 films y 16 categorías el resultado tendrá 16.000 filas
-- No usa clave de unión: combina TODAS las filas de ambas tablas
-- Incluimos IDs para identificar cada combinación
-- ORDER BY para resultado determinista
SELECT f.film_id, f.title, c.category_id, c.name AS category_name
FROM film f
CROSS JOIN category c
ORDER BY f.film_id, c.category_id;

/*
   ¿Aporta valor esta consulta?
   No aporta valor analítico real en este contexto.
   El CROSS JOIN combina cada película con TODAS las categorías posibles,
   ignorando la relación real almacenada en film_category. El resultado
   mezcla películas con categorías a las que no pertenecen, generando
   combinaciones sin sentido. Solo sería útil para casos muy específicos
   como generar plantillas vacías o auditar cobertura de categorías.
   Para trabajar con las relaciones reales siempre debe usarse
   film_category con INNER JOIN.
*/

/* ============================================================
   CONSULTA 45: Encuentra los actores que han participado en
                películas de la categoría 'Action'
   ============================================================ */
-- Encadenamos actor → film_actor → film_category → category
-- No necesitamos pasar por film porque film_category ya tiene film_id
-- DISTINCT evita que el mismo actor aparezca varias veces
-- (un actor puede tener múltiples películas de acción)
-- Incluimos actor_id para identificar cada actor de forma inequívoca
SELECT DISTINCT a.actor_id, a.first_name, a.last_name
FROM actor a
JOIN film_actor fa    ON fa.actor_id = a.actor_id
JOIN film_category fc ON fc.film_id = fa.film_id
JOIN category c       ON c.category_id = fc.category_id
WHERE c.name = 'Action'
ORDER BY a.last_name, a.first_name;

/* ============================================================
   CONSULTA 46: Encuentra todos los actores que no han participado
                en películas
   ============================================================ */
-- NOT EXISTS es más eficiente y seguro que LEFT JOIN ... IS NULL
-- La subconsulta busca cualquier entrada en film_actor para ese actor
-- El resultado es vacío (0 filas), lo cual indica que todos los actores de la base de datos han participado en al menos una película. 
SELECT a.actor_id, a.first_name, a.last_name
FROM actor a
WHERE NOT EXISTS (
    SELECT 1
    FROM film_actor fa
    WHERE fa.actor_id = a.actor_id
)
ORDER BY a.last_name, a.first_name;

/* ============================================================
   CONSULTA 47: Selecciona el nombre de los actores y la cantidad
                de películas en las que han participado
   ============================================================ */
-- Concatenamos nombre y apellido en una sola columna descriptiva
-- LEFT JOIN incluye actores con 0 películas
-- COUNT(fa.film_id) devuelve 0 para actores sin películas (no cuenta NULLs)
-- Agrupamos por actor_id para evitar mezclar actores con mismo nombre y apellido
-- Usamos actor_id como desempate final en lugar del alias de texto,
-- ya que dos actores podrían tener el mismo nombre completo
SELECT a.actor_id, (a.first_name || ' ' || a.last_name) AS actor, COUNT(fa.film_id) AS num_peliculas
FROM actor a
LEFT JOIN film_actor fa ON fa.actor_id = a.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY num_peliculas DESC, a.last_name, a.first_name, a.actor_id;

/* ============================================================
   CONSULTA 48: Crea una vista llamada "actor_num_peliculas" que
                muestre los nombres de los actores y el número de
                películas en las que han participado
   ============================================================ */
-- CREATE OR REPLACE VIEW define una consulta guardada reutilizable
-- Se comporta como una tabla virtual: se consulta con SELECT normal
-- OR REPLACE permite actualizar la vista si ya existía sin generar error
-- Incluimos actor_id como identificador único en la vista
CREATE OR REPLACE VIEW actor_num_peliculas AS
SELECT
    a.actor_id,
    a.first_name,
    a.last_name,
    COUNT(fa.film_id) AS num_peliculas
FROM actor a
LEFT JOIN film_actor fa ON fa.actor_id = a.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name;

-- Consultamos la vista como si fuera una tabla normal
SELECT * FROM actor_num_peliculas
ORDER BY num_peliculas DESC;

/* ============================================================
   CONSULTA 49: Calcula el número total de alquileres realizados
                por cada cliente
   ============================================================ */
-- LEFT JOIN incluye clientes con 0 alquileres
-- COUNT(r.rental_id) cuenta solo filas no NULL (0 si no hay alquileres)
-- customer_id como desempate garantiza un orden determinista
SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS total_alquileres
FROM customer c
LEFT JOIN rental r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_alquileres DESC, c.customer_id;

/* ============================================================
   CONSULTA 50: Calcula la duración total de las películas en
                la categoría 'Action'
   ============================================================ */
-- Unimos film → film_category → category para filtrar por 'Action'
-- SUM(f.length) suma los minutos de todas las películas de esa categoría
SELECT SUM(f.length) AS duracion_total_minutos
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c       ON c.category_id = fc.category_id
WHERE c.name = 'Action';

/* ============================================================
   CONSULTA 51: Crea una tabla temporal llamada
                "cliente_rentas_temporal" para almacenar el total
                de alquileres por cliente
   ============================================================ */
-- DROP TABLE IF EXISTS evita error si la tabla ya existía de ejecución anterior
-- CREATE TEMP TABLE crea una tabla que solo existe en la sesión actual
-- Se elimina automáticamente al cerrar la conexión con la BBDD
-- LEFT JOIN incluye clientes con 0 alquileres
-- Patrón CTAS (Create Table As Select): creamos y rellenamos en un solo paso
DROP TABLE IF EXISTS cliente_rentas_temporal;
CREATE TEMP TABLE cliente_rentas_temporal AS
SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS total_alquileres
FROM customer c
LEFT JOIN rental r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

-- Consultamos la tabla temporal para verificar los datos cargados
SELECT * FROM cliente_rentas_temporal ORDER BY total_alquileres DESC;

/* ============================================================
   CONSULTA 52: Crea una tabla temporal llamada "peliculas_alquiladas"
                que almacene las películas que han sido alquiladas
                al menos 10 veces
   ============================================================ */
-- DROP TABLE IF EXISTS evita error si ya existe de ejecución anterior
-- Encadenamos film → inventory → rental para contar alquileres por película
-- HAVING COUNT >= 10 filtra solo las películas con suficiente demanda
-- Guardamos el resultado en tabla temporal para posible reutilización
DROP TABLE IF EXISTS peliculas_alquiladas;
CREATE TEMP TABLE peliculas_alquiladas AS
SELECT f.film_id, f.title, COUNT(r.rental_id) AS veces_alquilada
FROM film f
JOIN inventory i ON i.film_id = f.film_id
JOIN rental r    ON r.inventory_id = i.inventory_id
GROUP BY f.film_id, f.title
HAVING COUNT(r.rental_id) >= 10;

-- Consultamos la tabla temporal para verificar los datos cargados
SELECT * FROM peliculas_alquiladas ORDER BY veces_alquilada DESC, title;

/* ============================================================
   CONSULTA 53: Encuentra el título de las películas que han sido
                alquiladas por el cliente con el nombre 'Tammy Sanders'
                y que aún no se han devuelto. Ordena los resultados
                alfabéticamente por título de película
   ============================================================ */
-- Encadenamos customer → rental → inventory → film
-- Los nombres en Sakila están almacenados en mayúsculas ('TAMMY', 'SANDERS')
-- return_date IS NULL indica que la película aún no ha sido devuelta
-- DISTINCT evita duplicados si hay varias copias de la misma película alquiladas
SELECT DISTINCT f.title
FROM customer c
JOIN rental r    ON r.customer_id = c.customer_id
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film f      ON f.film_id = i.film_id
WHERE c.first_name = 'TAMMY' AND c.last_name = 'SANDERS'
  AND r.return_date IS NULL
ORDER BY f.title;

/* ============================================================
   CONSULTA 54: Encuentra los nombres de los actores que han
                actuado en al menos una película que pertenece a
                la categoría 'Sci-Fi'. Ordena los resultados
                alfabéticamente por apellido
   ============================================================ */
-- Encadenamos actor → film_actor → film_category → category
-- DISTINCT evita repetir actores con varias películas de Sci-Fi
-- Ordenamos por apellido y nombre alfabéticamente
SELECT DISTINCT a.first_name, a.last_name
FROM actor a
JOIN film_actor fa    ON fa.actor_id = a.actor_id
JOIN film_category fc ON fc.film_id = fa.film_id
JOIN category c       ON c.category_id = fc.category_id
WHERE c.name = 'Sci-Fi'
ORDER BY a.last_name, a.first_name;

/* ============================================================
   CONSULTA 55: Encuentra el nombre y apellido de los actores que
                han actuado en películas que se alquilaron después
                de que la película 'Spartacus Cheaper' se alquilara
                por primera vez. Ordena alfabéticamente por apellido
   ============================================================ */
-- CTE 1: obtiene la fecha mínima de alquiler de 'Spartacus Cheaper'
-- CTE 2: obtiene los film_id distintos alquilados DESPUÉS de esa fecha
--        excluimos 'Spartacus Cheaper' para no incluir sus propios alquileres
--        posteriores al primero, ya que el enunciado busca OTRAS películas
--        alquiladas después de ese momento de referencia
-- Consulta final: une esos film_id con film_actor y actor
-- ILIKE para búsqueda insensible a mayúsculas/minúsculas
WITH spartacus_primera_fecha AS (
    SELECT MIN(r.rental_date) AS primera_renta
    FROM film f
    JOIN inventory i ON i.film_id = f.film_id
    JOIN rental r    ON r.inventory_id = i.inventory_id
    WHERE f.title ILIKE 'Spartacus Cheaper'
),
peliculas_rentadas_despues AS (
    SELECT DISTINCT i.film_id
    FROM rental r
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film f      ON f.film_id = i.film_id
    WHERE r.rental_date > (SELECT primera_renta FROM spartacus_primera_fecha)
      AND f.title NOT ILIKE 'Spartacus Cheaper'
)
SELECT DISTINCT a.first_name, a.last_name
FROM peliculas_rentadas_despues prd
JOIN film_actor fa ON fa.film_id = prd.film_id
JOIN actor a       ON a.actor_id = fa.actor_id
ORDER BY a.last_name, a.first_name;

/* ============================================================
   CONSULTA 56: Encuentra el nombre y apellido de los actores que
                no han actuado en ninguna película de la categoría
                'Music'
   ============================================================ */
-- NOT EXISTS es más seguro que NOT IN ante posibles NULLs en actor_id
-- La subconsulta comprueba si ese actor tiene alguna película de 'Music'
-- Si no existe ninguna coincidencia, el actor se incluye en el resultado
SELECT a.first_name, a.last_name
FROM actor a
WHERE NOT EXISTS (
    SELECT 1
    FROM film_actor fa
    JOIN film_category fc ON fc.film_id = fa.film_id
    JOIN category c       ON c.category_id = fc.category_id
    WHERE fa.actor_id = a.actor_id
      AND c.name = 'Music'
)
ORDER BY a.last_name, a.first_name;

/* ============================================================
   CONSULTA 57: Encuentra el título de todas las películas que
                fueron alquiladas por más de 8 días
   ============================================================ */
-- Restamos rental_date a return_date para obtener la duración real
-- INTERVAL '8 days' es más preciso que comparar números enteros con timestamps
-- return_date IS NOT NULL excluye alquileres aún activos (no devueltos)
-- DISTINCT evita duplicados si la misma película se alquiló varias veces
SELECT DISTINCT f.title
FROM rental r
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film f      ON f.film_id = i.film_id
WHERE r.return_date IS NOT NULL
  AND (r.return_date - r.rental_date) > INTERVAL '8 days'
ORDER BY f.title;

/* ============================================================
   CONSULTA 58: Encuentra el título de todas las películas que son
                de la misma categoría que 'Animation'
   ============================================================ */
-- JOIN directo entre film, film_category y category
-- WHERE filtra directamente por el nombre de la categoría 'Animation'
-- En Sakila cada película pertenece a exactamente una categoría,
-- por lo que este enfoque devuelve correctamente todas las películas
-- de dicha categoría sin duplicados
SELECT f.title
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c       ON c.category_id = fc.category_id
WHERE c.name = 'Animation'
ORDER BY f.title;

/* ============================================================
   CONSULTA 59: Encuentra los nombres de las películas que tienen
                la misma duración que la película con el título
                'Dancing Fever'. Ordena los resultados
                alfabéticamente por título de película
   ============================================================ */
-- La subconsulta obtiene la duración exacta de 'Dancing Fever'
-- ILIKE hace la búsqueda insensible a mayúsculas/minúsculas
-- LIMIT 1 en la subconsulta evita error si hubiera títulos duplicados
-- Excluimos 'Dancing Fever' del resultado con NOT ILIKE para no incluirla
SELECT title, length
FROM film
WHERE length = (
    SELECT length
    FROM film
    WHERE title ILIKE 'Dancing Fever'
    LIMIT 1
)
  AND title NOT ILIKE 'Dancing Fever'
ORDER BY title;

/* ============================================================
   CONSULTA 60: Encuentra los nombres de los clientes que han
                alquilado al menos 7 películas distintas. Ordena
                los resultados alfabéticamente por apellido
   ============================================================ */
-- Unimos customer → rental → inventory para obtener el film_id de cada alquiler
-- COUNT(DISTINCT i.film_id) cuenta películas únicas, no copias repetidas
-- HAVING >= 7 filtra solo los clientes con suficiente variedad de alquileres
-- Nota: en Sakila prácticamente todos los clientes activos superan este umbral
-- dado el alto volumen de alquileres registrados, por lo que el resultado
-- incluirá la mayoría de los clientes de la BBDD
-- Ordenamos por apellido y nombre como desempate alfabético
SELECT c.customer_id, c.first_name, c.last_name, COUNT(DISTINCT i.film_id) AS peliculas_distintas
FROM customer c
JOIN rental r    ON r.customer_id = c.customer_id
JOIN inventory i ON i.inventory_id = r.inventory_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT i.film_id) >= 7
ORDER BY c.last_name, c.first_name;

/* ============================================================
   CONSULTA 61: Encuentra la cantidad total de películas alquiladas
                por categoría y muestra el nombre de la categoría
                junto con el recuento de alquileres
   ============================================================ */
-- Partimos de rental como tabla base (más eficiente para contar alquileres)
-- inventory tiene film_id, así que podemos ir directamente a film_category
-- sin necesidad de pasar por la tabla film, reduciendo un JOIN innecesario
-- COUNT(*) cuenta directamente los registros de alquiler por categoría
-- c.name como desempate garantiza orden determinista
SELECT c.name AS categoria, COUNT(*) AS total_alquileres
FROM rental r
JOIN inventory i      ON i.inventory_id = r.inventory_id
JOIN film_category fc ON fc.film_id = i.film_id
JOIN category c       ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY total_alquileres DESC, c.name;

/* ============================================================
   CONSULTA 62: Encuentra el número de películas por categoría
                estrenadas en 2006
   ============================================================ */
-- Unimos film → film_category → category
-- WHERE release_year = 2006 filtra solo las películas de ese año
-- COUNT(*) cuenta las películas por categoría
-- c.name como desempate garantiza orden determinista
SELECT c.name AS categoria, COUNT(*) AS num_peliculas_2006
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c       ON c.category_id = fc.category_id
WHERE f.release_year = 2006
GROUP BY c.name
ORDER BY num_peliculas_2006 DESC, c.name;

/* ============================================================
   CONSULTA 63: Obtén todas las combinaciones posibles de
                trabajadores con las tiendas que tenemos
   ============================================================ */
-- CROSS JOIN entre staff y store genera todas las combinaciones posibles
-- Incluimos staff_id para identificar cada trabajador de forma única
-- Concatenamos nombre y apellido para mayor legibilidad del resultado
-- Ordenamos por staff_id y store_id para resultado determinista
SELECT
    s.staff_id,
    (s.first_name || ' ' || s.last_name) AS trabajador,
    st.store_id
FROM staff s
CROSS JOIN store st
ORDER BY s.staff_id, st.store_id;

/* ============================================================
   CONSULTA 64: Encuentra la cantidad total de películas alquiladas
                por cada cliente y muestra el ID del cliente, su
                nombre y apellido junto con la cantidad de películas
                alquiladas
   ============================================================ */
-- LEFT JOIN incluye todos los clientes aunque no tengan alquileres
-- COUNT(r.rental_id) devuelve 0 para clientes sin ningún alquiler
-- Alias peliculas_alquiladas es más preciso semánticamente
-- customer_id como desempate garantiza orden determinista
SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS peliculas_alquiladas
FROM customer c
LEFT JOIN rental r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY peliculas_alquiladas DESC, c.customer_id;


