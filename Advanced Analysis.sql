/*==========================================================================
                             Advanced Analytics  
==========================================================================*/


-- 1. Find the average duration of movies and TV shows.

WITH AvgDuration AS (
    SELECT 
		type, 
        ROUND(AVG(CASE 
                     WHEN duration LIKE '%min' THEN CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER)
                     ELSE NULL 
                  END), 2) AS avg_movie_duration,
        ROUND(AVG(CASE 
                     WHEN duration LIKE '%Season%' THEN CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER)
                     ELSE NULL 
                  END), 2) AS avg_tvshow_seasons
    FROM netflix
    GROUP BY type
)
SELECT * FROM AvgDuration;

-- 2. Rank movies by their release year.

SELECT 
    title, 
    release_year, 
    DENSE_RANK() OVER(ORDER BY release_year ASC) AS year_rank
FROM netflix;

-- 3. Categorize movies into Old (before 2000), Mid (2000-2015), and Recent (2016+).

SELECT 
	title, 
	release_year,
    CASE 
		WHEN release_year < 2000 THEN 'Old'
        WHEN release_year BETWEEN 2000 AND 2015 THEN 'Mid'
        ELSE 'Recent'
    END AS era_category
FROM netflix;

-- 4. Find movies or shows with the same director.

SELECT 
    n1.title AS title1, 
    n2.title AS title2, 
    n1.director,
    n1.type AS content_type
FROM netflix n1
JOIN netflix n2
    ON n1.director = n2.director
    AND n1.show_id <> n2.show_id
    AND n1.type = n2.type  
WHERE n1.director IS NOT NULL
ORDER BY 
	n1.director, 
	n1.type, 
	n1.title;

-- 5. Find the year with the highest number of releases.

WITH YearlyCounts AS (
    SELECT 
		release_year, 
		COUNT(*) AS total_count
    FROM netflix
    GROUP BY release_year
)
SELECT 
	release_year
FROM YearlyCounts
ORDER BY total_count DESC
LIMIT 1;

-- 6. Calculate the standard deviation of movie durations.

SELECT 
	ROUND(STDDEV(CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER)), 2) AS stddev_duration
FROM netflix
WHERE duration LIKE '%min';

-- 7. Compute the rolling average of content added over 3 years.

WITH YearlyContent AS (
    SELECT 
        release_year, 
        COUNT(*) AS content_count
    FROM netflix
    GROUP BY release_year
)
SELECT 
    release_year,
    content_count,
    ROUND(AVG(content_count) OVER (ORDER BY release_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_avg_3_years
FROM YearlyContent;


-- 8. Identify the director with the most consistent output over years.

SELECT 
	director, 
	COUNT(DISTINCT release_year) AS years_active
FROM netflix
WHERE director IS NOT NULL
GROUP BY director
ORDER BY years_active DESC
LIMIT 1;

-- 9.  Is there a correlation between the release year and the number of cast members in a movie or TV show?

WITH Expanded AS (
    SELECT 
        release_year, 
        UNNEST(STRING_TO_ARRAY('casts', ', ')) AS actor
    FROM netflix
    WHERE 'casts' IS NOT NULL
)
SELECT 
    release_year, 
    COUNT(actor) AS movie_cast_count
FROM Expanded
GROUP BY release_year;

-- 10. How does the duration of movies evolve over the years?

WITH MovieDurations AS (
    SELECT release_year, 
           ROUND(AVG(CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER)), 2) AS avg_duration
    FROM netflix
    WHERE duration LIKE '%min%'
    GROUP BY release_year
)
SELECT 
	release_year, 
	avg_duration, 
    avg_duration - LAG(avg_duration) OVER (ORDER BY release_year) AS yearly_difference
FROM MovieDurations;

-- 11. Identify movies with extreme durations using Z-score analysis.

WITH DurationStats AS (
    SELECT 
        AVG(CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER)) AS mean_duration,
        STDDEV(CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER)) AS stddev_duration
    FROM netflix
    WHERE duration LIKE '%min%'
)
SELECT 
    n.title, 
    n.duration,
    (CAST(SPLIT_PART(n.duration, ' ', 1) AS INTEGER) - ds.mean_duration) / ds.stddev_duration AS z_score
FROM netflix n
CROSS JOIN DurationStats ds
WHERE n.duration LIKE '%min%' 
AND ABS((CAST(SPLIT_PART(n.duration, ' ', 1) AS INTEGER) - ds.mean_duration) / ds.stddev_duration) > 2;

-- 12. Find the average number of movies added per decade.

SELECT 
    (release_year / 10) * 10 AS decade, 
    ROUND(COUNT(*) / 10.0, 2) AS avg_movies_per_year
FROM netflix
WHERE type = 'Movie'
GROUP BY decade
ORDER BY decade;

-- 13. What is the percentage of content directed by the top 10% of directors?

WITH DirectorCounts AS (
    SELECT 
		director, 
		COUNT(*) AS movie_count
    FROM netflix
    WHERE director IS NOT NULL
    GROUP BY director
)
SELECT 
	ROUND(SUM(movie_count) * 100.0 / (SELECT COUNT(*) FROM netflix), 2) AS top_10_percent_contribution
FROM (SELECT * 
	  FROM DirectorCounts 
	  ORDER BY movie_count DESC 
	  LIMIT (SELECT COUNT(*) / 10 FROM DirectorCounts)) AS TopDirectors;

-- 14. Find the distribution of content by duration quartiles.

WITH Quartiles AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER)) AS Q1,
        PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER)) AS Q2,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER)) AS Q3
    FROM netflix
    WHERE duration LIKE '%min%'
)
SELECT 
	title, 
	duration,
	CASE 
		WHEN CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER) <= Q1 THEN 'Short'
	    WHEN CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER) <= Q2 THEN 'Medium'
	    WHEN CAST(SPLIT_PART(duration, ' ', 1) AS INTEGER) <= Q3 THEN 'Long'
	    ELSE 'Very Long'
	END AS duration_category
FROM netflix, Quartiles
WHERE duration LIKE '%min%';

-- 15. Identify directors who have a consistent increase in movies over time.

WITH DirectorTrends AS (
    SELECT 
        director, 
        release_year, 
        COUNT(*) AS movie_count
    FROM netflix
    WHERE director IS NOT NULL
    GROUP BY 
		director, 
		release_year
), 
RankedDirectors AS (
    SELECT 
        director, 
        release_year, 
        movie_count, 
        movie_count - LAG(movie_count) OVER (PARTITION BY director ORDER BY release_year) AS yearly_change
    FROM DirectorTrends
)
SELECT director
FROM RankedDirectors
GROUP BY director
HAVING COUNT(CASE WHEN yearly_change < 0 THEN 1 END) = 0  -- Exclude those with any decline
   AND COUNT(yearly_change) > 3;  -- Ensure at least 4 years of data

-- 16. Determine the probability distribution of content types (Movies vs. TV Shows).

SELECT type, COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflix) AS probability
FROM netflix
GROUP BY type;

-- 17. Compute the cumulative percentage of the top 20% most productive directors.

WITH DirectorCounts AS (
    SELECT 
        director, 
        COUNT(*) AS total_content
    FROM netflix
    WHERE director IS NOT NULL
    GROUP BY director
),
RankedDirectors AS (
    SELECT 
        director, 
        total_content, 
        RANK() OVER (ORDER BY total_content DESC) AS rank
    FROM DirectorCounts
)
SELECT 
	director, 
	total_content
FROM RankedDirectors
WHERE rank <= 20;

-- 18. Identify the longest gaps between releases for the same director.

WITH DirectorGaps AS (
    SELECT director, release_year,
           release_year - LAG(release_year) OVER (PARTITION BY director ORDER BY release_year) AS gap
    FROM netflix
    WHERE director IS NOT NULL
)
SELECT director, MAX(gap) AS longest_gap
FROM DirectorGaps
WHERE gap IS NOT NULL
GROUP BY director
ORDER BY longest_gap DESC
LIMIT 1;


