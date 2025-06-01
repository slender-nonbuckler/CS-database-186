-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE "% %"
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear,AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear,AVG(height), COUNT(*)
    FROM people
    GROUP BY birthyear
    HAVING AVG(height) > 70
    ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT p.nameFirst, p.nameLast, p.playerID, h.yearid
  FROM people p INNER JOIN halloffame h ON p.playerID = h.playerID
  WHERE h.inducted = 'Y'
  ORDER BY h.yearid DESC, h.playerID
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, cp.schoolid, h.yearid
  FROM people p
  INNER JOIN halloffame h ON p.playerID = h.playerID
  INNER JOIN collegeplaying cp ON p.playerID = cp.playerID
  INNER JOIN schools s ON cp.schoolID = s.schoolID
  WHERE h.inducted = 'Y'
    AND s.schoolState = 'CA'
  ORDER BY h.yearid DESC, cp.schoolid ASC,h.playerid ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, cp.schoolid
  FROM people p
  INNER JOIN halloffame h ON p.playerID = h.playerID
  LEFT JOIN collegeplaying cp ON p.playerID = cp.playerID
  WHERE h.inducted = 'Y'
  ORDER BY p.playerid DESC, cp.schoolid ASC

;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT b.playerid, b.namefirst, b.namelast, b.yearid
    CAST((b.H - b.H2B - b.H3B- b.HR+ 2 * b.H2B + 3 * b.H3B + 4* b.HR) AS FLOAT) /b.AB as slg
   FROM batting b
   INNER JOIN PEOPLE p ON b.playerID = p.playerID
   WHERE b.AB > 50
   ORDER BY slg DESC, b.yearid ASC, b.playerid ASC
   LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT b.playerid, b.namefirst, b.namelast, b.yearid,
      CAST((SUM(b.H - b.H2B - b.H3B- b.HR)+ 2 * SUM(b.H2B) + 3 * SUM(b.H3B) + 4* SUM(b.HR)) AS FLOAT) /b.AB as slg
  FROM batting b
  INNER JOIN PEOPLE p ON b.playerID = p.playerID
  GROUP BY b.playerID
  HAVING SUM(b.AB) > 50
  ORDER BY slg DESC, b.yearid ASC, b.playerid ASC
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
WITH lifetime_slg AS (
  SELECT b.playerid, b.namefirst, b.namelast, b.yearid,
    CAST((SUM(b.H - b.H2B - b.H3B- b.HR)+ 2 * SUM(b.H2B) + 3 * SUM(b.H3B) + 4* SUM(b.HR)) AS FLOAT) /b.AB as lslg
  FROM batting b
  INNER JOIN PEOPLE p ON b.playerID = p.playerID
  GROUP BY b.playerID
  HAVING SUM(b.AB) > 50
),


mays_slg AS (
    SELECT lslg
    FROM lifetime_slg
    WHERE playerID = 'mayswi01'
)
SELECT namefirst,namelast, lslg
FROM lifetime_slg
WHERE lslg > (
    SELECT lslg FROM mays_slg
)
ORDER BY slg DESC, b.yearid ASC, b.playerid ASC

;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT
    yearID,
    MIN(salary) AS min,
    MAX(salary) AS max,
    AVG(salary) AS avg
  FROM salaries
  GROUP BY yearID
  ORDER BY yearID

;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
WITH
   stats AS (
    SELECT
        MIN(salary) AS min_s,
        MAX(salary) AS max_s,
        ((max_s - min_s) / 10.0) AS bin_width
    FROM salaries
    WHERE yearID = 2016
    ),
    salary_bins AS (

    SELECT
      salary,
      CASE
        WHEN salary = (SELECT max_s FROM stats) THEN 9
        ELSE CAST((salary - (SELECT min_s FROM stats)) /
            (SELECT bin_width FROM stats) AS INTEGER)
      END AS binid
    FROM salaries
    WHERE yearID = 2016
    )

  SELECT
    b.binid,
    ROUND(s.min_s + b.binid * s.bin_width, 2) AS low,
    ROUND(s.min_s + (b.binid + 1) * s.bin_width, 2) AS high,
    COUNT(sb.binid) AS count
  FROM binids b CROSS JOIN stats s
  LEFT JOIN salary_bins sb ON b.binid = sb.binid
  GROUP BY b.binid
  ORDER BY b.binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
WITH yearly_stats AS (
    SELECT
        yearID,
        MIN(salary) AS min_s
        MAX(salary) AS max_s,
        AVG(salary) AS avg_s
    FROM salaries
    GROUP BY yearID
    )

  SELECT
    cur.yearID,
    cur.min_s - pre.min_s AS mindiff,
    cur.max_s - pre.max_s AS maxdiff,
    cur.avg_s - pre.avg_s AS avgdiff
    FROM yearly_stats cur JOIN yearly_stats pre ON cur.yearID = prev.yearID + 1
    ORDER BY cur.yearID
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
WITH max_salary AS (
    SELECT yearID, MAX(salary) AS max_s
    FROM salaries
    WHERE yearID IN (2000, 2001)
    GROUP BY yearID
    )
  SELECT
  s.playerID,
  p.nameFirst,
  p.nameLast,
  s.salry,
  s.yearID
  FROM salaries s JOIN people p ON s.playerID = p.playerID
  JOIN max_salaries ms ON s.yearID = ms.yearID AND s.salary = ms.max_s
  ORDER BY s.yearID, s.playerID
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT
    a.teamID,
    MAX(s.salary) - MIN(s.salary) AS diffAvg
  FROM AllStarFull a JOIN salaries s ON a.playerID = s.playerID AND a.yearID = s.yearID
  GROUP BY a.teamID
  ORDER BY a.teamID

;

