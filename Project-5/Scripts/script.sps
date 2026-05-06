* Encoding: UTF-8.
COMPUTE stress_score=2*(DASS1 + DASS6 + DASS8 + DASS11 + DASS12 + DASS14 + DASS18). 
COMPUTE anxiety_score=2*(DASS2 + DASS4 + DASS7 + DASS9 + DASS15 + DASS19 + DASS20). 
COMPUTE depression_score=2*(DASS3 + DASS5 + DASS10 + DASS13 + DASS16 + DASS17 + DASS21).
EXECUTE.

RECODE stress_score (Lowest thru 14=1) (14 thru 18=2) (18 thru 25=3) (25 thru 33=4) (33 thru 
    Highest=5) INTO stress_level.
EXECUTE.
