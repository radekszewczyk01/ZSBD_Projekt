CREATE TABLE IF NOT EXISTS INPUT_ARTICLE (
    doi VARCHAR(255) PRIMARY KEY,
    coreId BIGINT,
    oai VARCHAR(255),
    title TEXT,
    authors TEXT,
    publisher TEXT,
    datePublished VARCHAR(20),
    year SMALLINT,
    topics TEXT,
    subject TEXT,
    downloadUrl TEXT,
    fullTextIdentifier TEXT,
    journals TEXT,
    contributors TEXT,
    pdfHashValue VARCHAR(255),
    language TEXT,
    relations TEXT
);

TRUNCATE TABLE INPUT_ARTICLE;

LOAD DATA LOCAL INFILE '/home/radek/Documents/DataBases/Etap1/input-data/core_dane_bazodanowe.csv'
INTO TABLE INPUT_ARTICLE
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(doi, coreId, oai, title, authors, publisher, datePublished, year, topics, subject, downloadUrl, fullTextIdentifier, journals, contributors, pdfHashValue, language, relations);