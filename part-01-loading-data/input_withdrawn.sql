CREATE TABLE IF NOT EXISTS INPUT_WITHDRAWN (
    RecordID INT PRIMARY KEY,
    Title TEXT,
    Subject TEXT,
    Institution TEXT,
    Journal TEXT,
    Publisher TEXT,
    Country TEXT,
    Author TEXT,
    URLS TEXT,
    ArticleType VARCHAR(255),
    RetractionDate VARCHAR(50),
    RetractionDOI VARCHAR(255),
    RetractionPubMedID BIGINT,
    OriginalPaperDate VARCHAR(50),
    OriginalPaperDOI VARCHAR(255),
    OriginalPaperPubMedID BIGINT,
    RetractionNature VARCHAR(255),
    Reason TEXT,
    Paywalled VARCHAR(10),
    Notes TEXT
);

TRUNCATE TABLE INPUT_WITHDRAWN;

LOAD DATA LOCAL INFILE '/home/radek/Documents/DataBases/Etap1/input-data/retraction_watch.csv'
INTO TABLE INPUT_WITHDRAWN
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(RecordID, Title, Subject, Institution, Journal, Publisher, Country, Author, URLS, ArticleType, RetractionDate, RetractionDOI, RetractionPubMedID, OriginalPaperDate, OriginalPaperDOI, OriginalPaperPubMedID, RetractionNature, Reason, Paywalled, Notes);