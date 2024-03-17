ALTER THE UNKNOWN COLUMN NAME 

ALTER TABLE gameanalysis.player_details
CHANGE COLUMN MyUnknownColumn Serial_NO INT

SELECT *
FROM gameanalysis.player_details


SELECT *
FROM gameanalysis.level_details2

1. Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.

SELECT 
ld.P_ID,ld.Dev_ID,pd.PName,ld.Difficulty
FROM gameanalysis.player_details as pd
INNER JOIN gameanalysis.level_details2 as ld
ON pd.P_ID=ld.P_ID
WHERE Level =0 

2. Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed.

SELECT 
pd.L1_code,
AVG(ld.Kill_Count) as avg_killcount
FROM gameanalysis.player_details as pd
JOIN gameanalysis.level_details2 as ld
ON  pd.P_ID=ld.P_ID
WHERE ld.Lives_Earned=2 and ld.Stages_crossed>=3
GROUP BY pd.L1_code
ORDER BY pd.L1_code

3. Find the total number of stages crossed at each difficulty level for Level 2 with players using `zm_series` devices. Arrange the result in decreasing order of the total number of stages crossed.

SELECT 
Difficulty,
COUNT(Stages_crossed) as total_stages_crossed
FROM gameanalysis.level_details2 
WHERE Level=2 AND Dev_ID like "zm_%"
GROUP BY Difficulty 
ORDER BY total_stages_crossed DESC

4. Extract `P_ID` and the total number of unique dates for those players who have played games on multiple days.

SELECT 
P_ID,
COUNT(DISTINCT TimeStamp) AS total_dates
FROM gameanalysis.level_details2
GROUP BY P_ID
HAVING COUNT(DISTINCT TimeStamp) >1
ORDER BY total_dates DESC

5. Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the average kill count for Medium difficulty.

SELECT 
P_ID,
Level,
SUM(Kill_Count) AS total_killcount
FROM gameanalysis.level_details2
GROUP BY Level,P_ID
HAVING SUM(Kill_Count)>
(SELECT 
AVG(Kill_Count) AS avg_killcount
FROM gameanalysis.level_details2
WHERE Difficulty='Medium')
ORDER BY Level DESC

6. Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 0. Arrange in ascending order of level.

SELECT
ld.Level,pd.L1_Code,pd.L2_Code ,
SUM(ld.Lives_Earned) AS Total_lives_Earned
FROM gameanalysis.player_details AS pd
JOIN gameanalysis.level_details2 AS ld
ON pd.P_ID=ld.P_ID
WHERE ld.Level!=0
GROUP BY ld.Level,pd.L1_Code,pd.L2_Code 
ORDER BY ld.Level

7. Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using `Row_Number`. Display the difficulty as well.

WITH CTE AS 
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY Dev_ID ORDER BY Score ) AS RNK
FROM gameanalysis.level_details2
)
SELECT 
Dev_ID,
Difficulty,
Score,
RNK
FROM CTE 
WHERE RNK<=3
ORDER BY Dev_ID,RNK

8. Find the `first_login` datetime for each device ID.

SELECT 
Dev_ID,
MIN(TimeStamp) AS First_login
FROM gameanalysis.level_details2
GROUP BY Dev_ID

9.Find the top 5 scores based on each difficulty level and rank them in increasing order using `Rank`. Display `Dev_ID` as well.
WITH Ranks AS 
(
SELECT
Dev_ID,
Difficulty,
Score,
RANK() OVER (PARTITION BY Difficulty ORDER BY Score DESC ) AS Ranking
FROM gameanalysis.level_details2
)
SELECT 
Dev_ID,
Difficulty,
Score,
Ranking
FROM Ranks
WHERE Ranking<=5

10. Find the device ID that is first logged in (based on `start_datetime`) for each player (`P_ID`). Output should contain player ID, device ID, and first login datetime.

WITH 
LoginDetails AS
(
SELECT 
P_ID,Dev_ID,
TimeStamp,
ROW_NUMBER() OVER(PARTITION BY P_ID ORDER BY TimeStamp ) AS Ranking
FROM gameanalysis.level_details2
)
SELECT 
P_ID,Dev_ID,
TimeStamp AS first_login_datetime
FROM LoginDetails 
WHERE Ranking=1

11. For each player and date, determine how many `kill_counts` were played by the player so far.
a) Using window functions
b) Without window functions

a)
SELECT 
DISTINCT P_ID,
DATE(TimeStamp) AS Date,
SUM(Kill_Count) OVER(PARTITION BY P_ID , DATE(TimeStamp)  ORDER BY DATE(TimeStamp) ) AS Total_kill_counts
FROM gameanalysis.level_details2
ORDER BY P_ID,Date

b)
SELECT
P_ID,
DATE(TimeStamp) AS Dates,
SUM(Kill_Count) AS Total_Kill_counts
FROM gameanalysis.level_details2
GROUP BY P_ID,DATE(TimeStamp)
ORDER BY P_ID,Dates


12. Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, excluding the most recent `start_datetime`.

WITH STAGES AS 
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY P_ID ORDER BY TimeStamp DESC) AS Rnk
FROM gameanalysis.level_details2
)
SELECT 
P_ID,
TimeStamp AS Start_Datetime,
SUM(Stages_crossed) OVER(PARTITION BY P_ID ORDER BY TimeStamp ) AS Cumulative_sum
FROM STAGES
WHERE Rnk!=1

13. Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

WITH Scores AS
(
SELECT 
P_ID,
Dev_ID,
SUM(Score) AS Total_Score,
RANK() OVER(PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS Rnk
FROM gameanalysis.level_details2
GROUP BY P_ID,Dev_ID
)
SELECT 
P_ID,
Dev_ID,
Total_Score
FROM Scores
WHERE Rnk<=3

14. Find players who scored more than 50% of the average score, scored by the sum of scores for each `P_ID`.

SELECT 
P_ID,
SUM(Score) AS Sum_Scores
FROM gameanalysis.level_details2
GROUP BY P_ID
HAVING SUM(Score) > 0.5 *(SELECT AVG(Score)
FROM gameanalysis.level_details2) 

15. Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID` and rank them in increasing order using `Row_Number`. Display the difficulty as well.

DELIMITER //

CREATE PROCEDURE top_headshots (IN n INT)
BEGIN
    WITH Topheadshots  AS (
        SELECT 
            ld.*, 
            ROW_NUMBER() OVER (PARTITION BY ld.Dev_ID ORDER BY ld.Headshots_Count DESC) AS rnk
        FROM 
            gameanalysis.level_details2 ld
    )
    SELECT 
        Dev_ID, 
        Headshots_Count,
        Difficulty,
        rnk
    FROM 
        Topheadshots 
    WHERE 
        rnk <= n;
END//

DELIMITER ;

CALL top_headshots(6);