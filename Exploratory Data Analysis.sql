-- Create Netflix table

DROP TABLE IF EXISTS netflix;

CREATE TABLE netflix (
	show_id VARCHAR(8),
	type VARCHAR(10),
	title VARCHAR(150),
	director VARCHAR(250),
	Casts VARCHAR(1000),
	country VARCHAR(200),
	date_added VARCHAR(70),
	release_year INT,
	rating VARCHAR(15),
	duration VARCHAR(15),
	listed_in VARCHAR(100),
	description VARCHAR(300)
);

/*==========================================================================
                       Exploratory Data Analysis (EDA) 
==========================================================================*/

-- Retrieve all columns and rows from the Netflix dataset. 

SELECT * FROM netflix;

-- 1. Count the total number of movies and TV shows.

SELECT 
	type, 
	COUNT(*) AS total_count
FROM netflix
GROUP BY type;

-- 2. Find the top 5 most common ratings.

SELECT 
	rating,
	COUNT(*) AS count
FROM netflix
GROUP BY rating
ORDER BY count DESC
LIMIT 5;

-- 3. Find the top 5 directors with the most titles.

SELECT 
	director,
	COUNT(*) AS most_titles
FROM netflix
WHERE director IS NOT NULL
GROUP BY director
ORDER BY most_titles DESC
LIMIT 5;

-- 4. Find the top 5 countries producing the most content.

SELECT 
	country, 
	COUNT(*) AS total_count
FROM netflix
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_count DESC
LIMIT 5;

-- 5. Find the count of titles released per year.

SELECT 
	release_year, 
	COUNT(*) AS total_count
FROM netflix
GROUP BY release_year
ORDER BY release_year DESC;

-- 6. Find the most recent and oldest added shows.

SELECT 
	title, 
	date_added
FROM netflix
WHERE date_added IS NOT NULL
ORDER BY date_added DESC
LIMIT 1;

SELECT 
	title,
	date_added
FROM netflix
ORDER BY date_added ASC
LIMIT 1;

-- 7. Count the number of unique genres.

SELECT 
	COUNT(DISTINCT listed_in) AS unique_genres
FROM netflix;

-- 8. Find the longest duration movie.

SELECT 
	title,
	duration
FROM netflix
WHERE duration LIKE '%min'
ORDER BY CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER) DESC
LIMIT 1;

-- 9. Find the most common genre.

SELECT 
	listed_in, 
	COUNT(*) AS count
FROM netflix
GROUP BY listed_in
ORDER BY count DESC
LIMIT 1;

-- 10. Find the number of TV shows with more than 3 seasons.

SELECT 
	COUNT(*) AS tv_shows_with_3plus_seasons
FROM netflix
WHERE duration LIKE '%Season%'
AND CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER) > 3;

-- 11. Identify the proportion of each genre compared to the total content.

SELECT 
	listed_in, 
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflix), 2) AS percentage
FROM netflix
GROUP BY listed_in
ORDER BY percentage DESC;

-- 12. Identify the most popular combination of genres that appear together.

SELECT 
	listed_in, 
	COUNT(*) AS count
FROM netflix
GROUP BY listed_in
ORDER BY count DESC
LIMIT 5;

-- 13. Find the proportion of movies that belong to multiple genres.

SELECT 
	type,
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflix WHERE type='Movie'), 2) AS multiple_genre_percentage
FROM netflix
WHERE type='Movie' AND listed_in LIKE '%,%'
GROUP BY type;

-- 14. Determine the distribution of TV shows by number of seasons.

SELECT 
	duration, 
	COUNT(*) AS count
FROM netflix
WHERE duration LIKE '%Season%'
GROUP BY duration
ORDER BY CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER) DESC;

-- 15. Identify the most frequently occurring words in movie titles.

SELECT 
	word, 
	COUNT(*) AS frequency
FROM (
	SELECT 
		UNNEST(STRING_TO_ARRAY(title, ' ')) AS word 
    FROM netflix 
    WHERE type='Movie'
) AS words
GROUP BY word
ORDER BY frequency DESC
LIMIT 10;

-- 16. Find the average number of movies released per year.

SELECT 
	ROUND(AVG(movie_count), 2) AS avg_movies_per_year
FROM (
	SELECT 
		release_year, 
		COUNT(*) AS movie_count 
	FROM netflix 
	WHERE type='Movie' 
	GROUP BY release_year
) AS yearly_counts;

-- 17. Determine if there is a trend in the number of releases per year (increasing or decreasing).

WITH YearlyCounts AS (
    SELECT 
        release_year, 
        COUNT(*) AS total_count
    FROM netflix
    GROUP BY release_year
)
SELECT 
    release_year, 
    total_count,
    total_count - LAG(total_count) OVER (ORDER BY release_year) AS yearly_difference,
    CASE 
        WHEN total_count - LAG(total_count) OVER (ORDER BY release_year) > 0 THEN 'Increasing'
        WHEN total_count - LAG(total_count) OVER (ORDER BY release_year) < 0 THEN 'Decreasing'
        ELSE 'No Change'
    END AS Trend
FROM YearlyCounts;


-- 18. What percentage of Netflix’s content is international?

SELECT 
	ROUND(COUNT(*) FILTER (WHERE country NOT LIKE '%USA%') * 100.0 / COUNT(*), 2) AS international_percentage
FROM netflix;

-- 19. Find the top 3 countries producing the most unique genres.

SELECT 
	country,
	COUNT(DISTINCT listed_in) AS unique_genre_count
FROM netflix
WHERE country IS NOT NULL
GROUP BY country
ORDER BY unique_genre_count DESC
LIMIT 3;

-- 20. Identify the most diverse directors by genre.

SELECT 
	director, 
	COUNT(DISTINCT listed_in) AS genre_count
FROM netflix
WHERE director IS NOT NULL
GROUP BY director
ORDER BY genre_count DESC
LIMIT 5;

-- 21. Find the director with the most consistent production across all years.

SELECT 
	director, 
	COUNT(DISTINCT release_year) AS active_years
FROM netflix
WHERE director IS NOT NULL
GROUP BY director
ORDER BY active_years DESC
LIMIT 1;

