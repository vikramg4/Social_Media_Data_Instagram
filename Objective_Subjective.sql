-- -------------------------------------------------------------- SOCIAL MEDIA ANALYSIS (Objective) -----------------------------------------------------------------------------------

-- 1. Are there any tables with duplicate or missing null values? If so, how would you handle them?
	  
	-- Checking for duplicate valuses in all the table
	  SELECT username, COUNT(*) AS duplicate_count FROM users GROUP BY username HAVING duplicate_count > 1;
      SELECT image_url, COUNT(*) AS duplicate_count FROM photos GROUP BY image_url HAVING duplicate_count > 1;
      SELECT user_id, photo_id, COUNT(*) AS duplicate_count FROM comments GROUP BY user_id, photo_id HAVING duplicate_count > 1;	
      SELECT user_id, photo_id, COUNT(*) AS duplicate_count FROM likes GROUP BY user_id, photo_id HAVING duplicate_count > 1;
      SELECT follower_id, followee_id, COUNT(*) AS duplicate_count FROM follows GROUP BY follower_id, followee_id HAVING duplicate_count > 1;
	  SELECT tag_name, COUNT(*) AS duplicate_count FROM tags GROUP BY tag_name HAVING duplicate_count > 1;
	
	-- Checking for null valuses for crucial columns in each table
	  SELECT COUNT(*) AS users_null_count FROM users WHERE username IS NULL OR created_at IS NULL;
	  SELECT COUNT(*) AS photos_null_count FROM photos WHERE image_url IS NULL OR user_id IS NULL OR created_dat IS NULL;
      SELECT COUNT(*) AS comments_null_count FROM comments WHERE comment_text IS NULL OR user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;
      SELECT COUNT(*) AS likes_null_count FROM likes WHERE user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;
	  SELECT COUNT(*) AS follows_null_count FROM follows WHERE follower_id IS NULL OR followee_id IS NULL OR created_at IS NULL;
      SELECT COUNT(*) AS tags_null_count FROM tags WHERE tag_name IS NULL OR created_at IS NULL;
      SELECT COUNT(*) AS photo_tags_null_count FROM photo_tags WHERE photo_id IS NULL OR tag_id IS NULL;
        
     -- There's no duplicate and null values present in the data tables. 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?
	  
	-- Distribution of number of posts (photos) by each user
	  WITH Posts AS (SELECT user_id, COUNT(*) AS Post_count FROM photos GROUP BY user_id),
      
      -- Distribution of number of likes by each user
      Likes AS (SELECT user_id, COUNT(*) AS Likes_count FROM likes GROUP BY user_id),
      
      -- Distribution of number of comments by each user
      Comments AS (SELECT user_id, COUNT(*) AS Comments_count FROM Comments GROUP BY user_id)
      
      SELECT u.id, u.username, ifnull(p.Post_count, 0) AS Post_count, ifnull(l.Likes_count, 0) AS Likes_count, ifnull(c.Comments_count, 0) AS Comments_count
      FROM users u LEFT JOIN Posts p ON u.id = p.user_id
	  LEFT JOIN Comments c ON p.user_id = c.user_id
      LEFT JOIN Likes l ON c.user_id = l.user_id
      ORDER BY u.username;
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. Calculate the average number of tags per post (photo_tags and photos tables).
	  
      WITH tags_per_post AS (SELECT photo_id, COUNT(tag_id) AS tags
      FROM photo_tags
	  GROUP BY photo_id)
      
      SELECT ROUND(AVG(tags), 2) AS Avg_No_Of_Tags
      FROM tags_per_post;
      
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4. Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.
      
	WITH user_engagement AS (
    SELECT 
        p.id AS post_id, u.username,
        COUNT(DISTINCT l.user_id) AS total_likes, 
        COUNT(DISTINCT c.id) AS total_comments, 
        (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) AS engagement_rate
    FROM photos p JOIN likes l ON p.id = l.photo_id
    JOIN comments c ON p.id = c.photo_id
    JOIN users u ON p.user_id = u.id
    GROUP BY p.id)
    
-- Ranking the users based on total engagement
SELECT 
    post_id,
    username,
    total_likes,
    total_comments,
    engagement_rate,
    DENSE_RANK() OVER (ORDER BY engagement_rate DESC) AS engagement_rank
FROM user_engagement 
ORDER BY engagement_rank;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5. Which users have the highest number of followers and followings?
	
    -- Users with highest followers
    with cte as (SELECT followee_id AS user_id, COUNT(follower_id) AS followers_count
    FROM follows 
    GROUP BY followee_id
    ORDER BY followers_count DESC 
    ),
    
	-- Users with highest followings
	cte1 as (SELECT follower_id AS user_id, COUNT(followee_id) AS followings_count
	FROM follows
	GROUP BY follower_id
    ORDER BY followings_count DESC
	)
    
    SELECT c.user_id, u.username, c.followers_count, ct.followings_count
    FROM cte c JOIN cte1 ct ON C.user_id = ct.user_id
    JOIN users u ON u.id = c.user_id;
    
----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-- 6. Calculate the average engagement rate (likes, comments) per post for each user.
	
	WITH user_engagement AS (
    SELECT 
        p.id AS post_id, u.username,
        COUNT(DISTINCT l.user_id) AS total_likes, 
        COUNT(DISTINCT c.id) AS total_comments, 
        (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) AS total_engagement
    FROM photos p JOIN likes l ON p.id = l.photo_id
    JOIN comments c ON p.id = c.photo_id
    JOIN users u ON p.user_id = u.id
    GROUP BY p.id)
    
-- Ranking the users based on average engagement per post
	SELECT 
    post_id,
    username,
    ROUND(avg(total_engagement)) AS avg_engagement,
    DENSE_RANK() OVER (ORDER BY avg(total_engagement) DESC) AS engagement_rank
	FROM user_engagement 
	GROUP BY 1, 2
	ORDER BY engagement_rank;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 7. Get the list of users who have never liked any post (users and likes tables)

    SELECT u.id, u.username
	FROM users u
	LEFT JOIN likes l ON u.id = l.user_id
	WHERE l.user_id IS NULL;
	
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 8. How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?
    
    WITH user_hashtag_engagement AS (
    SELECT 
        u.id AS user_id, 
        pt.tag_id AS tag, 
        COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id) AS avg_engagement
    FROM users u
    JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY u.id, pt.tag_id
    HAVING avg_engagement > 0)
    
	SELECT 
    user_id, 
    tag_name as hashtag, 
	COUNT(tag) over(partition by tag_name order by user_id) as tag_count,
    avg_engagement
	FROM user_hashtag_engagement e JOIN tags t ON e.tag = t.id
	GROUP BY user_id, hashtag
	ORDER BY avg_engagement DESC
	;  
    
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 9. Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies?
    
	SELECT 
	DISTINCT t.tag_name,
	COUNT(pt.photo_id) AS post_count,
	COUNT(DISTINCT l.photo_id) AS total_likes,  
	COUNT(DISTINCT c.id) AS total_comments,
	ROUND(COUNT(pt.photo_id) / (COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id)), 2) AS avg_engagement_per_post
    FROM photos p JOIN likes l ON p.id = l.photo_id  
    JOIN comments c ON p.id = c.photo_id
    JOIN photo_tags pt ON p.id = pt.photo_id
    JOIN tags t ON pt.tag_id = t.id
    GROUP BY t.tag_name
    ORDER BY avg_engagement_per_post DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10. Calculate the total number of likes, comments, and photo tags for each user.

	SELECT u.id, u.username,
	COUNT(DISTINCT l.photo_id) AS total_likes, 
	COUNT(DISTINCT c.id) AS total_comments, 
	COUNT(DISTINCT t.tag_id) AS total_tags
	FROM users u LEFT JOIN photos p ON u.id = p.user_id
	LEFT JOIN likes l ON u.id = l.user_id
	LEFT JOIN comments c ON u.id = c.user_id
	LEFT JOIN photo_tags t ON p.id = t.photo_id
	GROUP BY u.id, u.username;
    

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 11. Rank users based on their total engagement (likes, comments, shares) over a month.
	
 -- Calculating user's monthly engagement
	WITH users_monthly_engagement AS 
    (SELECT P.user_id,  date_format(created_dat, '%Y-%m') as month,
    (COUNT(DISTINCT L.user_id) + COUNT(DISTINCT C.id)) AS total_engagement
    FROM photos P 
    LEFT JOIN likes L ON P.id = L.photo_id
    LEFT JOIN comments C ON P.id = C.photo_id 
    GROUP BY user_id, month
    ORDER BY total_engagement DESC)
    
 -- Ranking user based on total engagement over a month
	SELECT user_id, u.username, month, total_engagement,
    RANK() OVER(PARTITION BY month ORDER BY total_engagement DESC) AS engagement_rank
    FROM users_monthly_engagement u1
    JOIN users u ON u1.user_id = u.id;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 12. Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.
	
	WITH photo_likes AS (SELECT photo_id, COUNT(user_id) AS likes_count
    FROM likes
    group by 1),
    
    Hashtag_likes as (SELECT T.tag_id, ROUND(AVG(L.likes_count), 2) AS Avg_likes
    FROM photo_tags T JOIN photo_likes L 
    ON  T.photo_id = L.photo_id
    GROUP BY T.tag_id)
    
    SELECT t.id, t.tag_name AS Hashtags, Avg_likes
    FROM tags t JOIN Hashtag_likes h
    ON t.id = h.tag_id
    ORDER BY Avg_likes DESC 
    LIMIT 1;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 13. Retrieve the users who have started following someone after being followed by that person.
    
    SELECT f1.follower_id AS followed_back, f1.followee_id AS followed_by
	FROM follows f1 JOIN follows f2
    ON f1.follower_id = f2.followee_id  AND f1.followee_id = f2.follower_id
    WHERE f1.created_at > f2.created_at;
    
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------   


-- ---------------------------------------------------------- SOCIAL MEDIA ANALYSIS (Subjective) -----------------------------------------------------------------------------------

-- 1. Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?

	WITH post_per_user AS (
    SELECT user_id, count(id) AS total_post
    FROM photos 
    group by user_id),
    
    likes_per_user AS (
    SELECT user_id, COUNT(photo_id) AS total_likes
    FROM likes
    GROUP BY user_id), 
    
    comment_per_user AS (
    SELECT user_id, COUNT(id) AS total_comments
    FROM comments
    GROUP BY user_id)
    
	-- user activity & engagement and ranking user on loyalty
    SELECT u.id, u.username, SUM(total_post + total_likes + total_comments) AS user_activity_level,
    SUM(total_likes + total_comments) AS user_engagement_rate,
    DENSE_RANK() OVER(ORDER BY SUM(total_post + total_likes + total_comments) DESC, SUM(total_likes + total_comments)) AS user_loyalty_rank
    FROM users u JOIN post_per_user p
    ON u.id = p.user_id
    JOIN likes_per_user l ON u.id = l.user_id
    JOIN comment_per_user c ON u.id = c.user_id
	GROUP BY u.id;
    
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------	
-- 2. For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?

	SELECT u.id, u.username, (COUNT(DISTINCT p.id) + COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id)) AS engagement
    FROM users u LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON  u.id = l.user_id
    LEFT JOIN comments c ON u.id = c.user_id
    GROUP BY 1, 2
    HAVING engagement = 0;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?
    
    WITH likes_per_post AS (
    SELECT photo_id, count(user_id) AS total_likes
    FROM likes
    GROUP BY photo_id),
    
    comments_per_post AS (
    SELECT photo_id, COUNT(id) AS total_comments
    FROM comments
    GROUP BY photo_id)
    
    SELECT t.tag_name, SUM(l.total_likes + c.total_comments) AS post_engagement_rate,
    DENSE_RANK() OVER(ORDER BY SUM(l.total_likes + c.total_comments) DESC) AS tag_engagement_rank
    FROM tags t JOIN photo_tags pt
    ON t.id = pt.tag_id
    JOIN likes_per_post l ON pt.photo_id = l.photo_id
    JOIN comments_per_post c ON pt.photo_id = c.photo_id
    GROUP BY t.tag_name;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4. Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?
	
	WITH post_engagement AS (
		SELECT 
        p.id AS post_id,
        p.user_id,
        p.created_dat AS post_time,
        COUNT(l.user_id) AS total_likes,
        COUNT(c.id) AS total_comments,
        (COUNT(l.user_id) + COUNT(c.id)) AS total_engagement
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
	GROUP BY p.id),
    
-- Extracted hour and day of week from post_time and calculate average engagement for each
    engagement_by_time AS (
	SELECT 
    hour(post_time) AS post_hour,
    dayofweek(post_time) AS post_day,
    COUNT(post_id) AS total_post,
    ROUND(AVG(total_engagement)) AS avg_engagement_per_post
	FROM post_engagement
	GROUP BY post_hour, post_day
	ORDER BY avg_engagement_per_post DESC)

	SELECT 
    post_hour,
    post_day,
    total_post,
    avg_engagement_per_post
	FROM engagement_by_time;
    
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5. Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?
	
    WITH user_follower_count AS (
    SELECT followee_id AS user, COUNT(follower_id) AS followers_count
    FROM follows 
    GROUP BY followee_id),
    
    likes_per_user AS (
    SELECT user_id, COUNT(photo_id) AS total_likes
    FROM likes
    GROUP BY user_id), 
    
    comment_per_user AS (
    SELECT user_id, COUNT(id) AS total_comments
    FROM comments
    GROUP BY user_id)
    
-- ideal candidate for influencer marketing rank 

    SELECT u.username, followers_count, SUM( l.total_likes + c.total_comments) AS engagement_rate,
    DENSE_RANK() OVER(ORDER BY followers_count DESC, SUM( l.total_likes + c.total_comments) DESC) AS candidate_rank
    FROM users u JOIN user_follower_count uf
    ON u.id = uf.user
    JOIN likes_per_user l ON u.id = l.user_id
    JOIN comment_per_user c ON u.id = c.user_id
    GROUP BY 1, 2
    ORDER BY followers_count DESC, engagement_rate DESC;	
    
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 6. Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?

	WITH post_per_user AS (
    SELECT user_id, count(id) AS total_post
    FROM photos 
    group by user_id),
    
    likes_per_user AS (
    SELECT user_id, COUNT(photo_id) AS total_likes
    FROM likes
    GROUP BY user_id), 
    
    comment_per_user AS (
    SELECT user_id, COUNT(id) AS total_comments
    FROM comments
    GROUP BY user_id)

    SELECT u.id, u.username,
    (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) + COALESCE(p.total_post, 0)) AS total_engagement,
    CASE 
		WHEN (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) + COALESCE(p.total_post, 0)) >= 200 THEN 'High-Engagement'
		WHEN (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) + COALESCE(p.total_post, 0)) BETWEEN 100 AND 200 THEN 'Moderate-Engagement'
		ELSE 'Low-Engagement'
	END AS engagement_segment
	FROM users u LEFT JOIN post_per_user p
    ON u.id = p.user_id
    LEFT JOIN likes_per_user l ON u.id = l.user_id
    LEFT JOIN comment_per_user c ON u.id = c.user_id
    ORDER BY total_engagement DESC;
    
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 8. How can you use user activity data to identify potential brand ambassadors or advocates who could help promote Instagram's initiatives or events?

	WITH user_activity AS (
		SELECT 
			u.id AS user_id, u.username,
			COUNT(DISTINCT p.id) AS total_posts,
			COUNT(DISTINCT l.photo_id) AS total_likes_received,
			COUNT(DISTINCT c.id) AS total_comments_received,
			(SELECT COUNT(*) FROM follows f WHERE f.followee_id = u.id) AS total_followers
		FROM users u
		LEFT JOIN photos p ON u.id = p.user_id
		LEFT JOIN likes l ON p.id = l.photo_id
		LEFT JOIN comments c ON p.id = c.photo_id
		GROUP BY u.id),
	high_engagement_users AS (
		SELECT 
			user_id,
			username,
			total_posts,
			total_likes_received,
			total_comments_received,
			total_followers,
			(total_posts + total_likes_received + total_comments_received + total_followers) AS engagement_score
		FROM user_activity)
		SELECT 
			user_id, 
			username,
			engagement_score,
			RANK() OVER (ORDER BY engagement_score DESC) AS ambassador_rank
		FROM high_engagement_users
		ORDER BY engagement_score DESC
		LIMIT 10;  -- Select top 10 potential brand ambassadors

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10. Assuming there's a "User_Interactions" table tracking user engagements, how can you update the "Engagement_Type" column to change all instances of "Like" to "Heart" to align with Instagram's terminology?

	UPDATE User_Interactions
    SET Engagement_Type = "Heart"
    WHERE Engagement_Type = "Like";

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
