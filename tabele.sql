DROP TABLE IF EXISTS zdravnik CASCADE;
DROP TABLE IF EXISTS oseba CASCADE;
DROP TABLE IF EXISTS pregled CASCADE;
DROP TABLE IF EXISTS test CASCADE;
DROP TABLE IF EXISTS specializacija CASCADE;
DROP TABLE IF EXISTS diagnoza CASCADE;
DROP TABLE IF EXISTS bolezen CASCADE;
DROP TABLE IF EXISTS zdravilo CASCADE;

CREATE TABLE bolezen (
	bolezenID INTEGER PRIMARY KEY,
	ime TEXT UNIQUE NOT NULL
);

CREATE TABLE zdravilo (
	zdraviloID INTEGER PRIMARY KEY,
	ime TEXT UNIQUE NOT NULL
);

CREATE TABLE test (
	testID INTEGER PRIMARY KEY,
	ime TEXT UNIQUE NOT NULL
);

CREATE TABLE zdravnik (
	zdravnikID SERIAL PRIMARY KEY,
	ime TEXT NOT NULL,
	priimek TEXT NOT NULL,
	rojstvo DATE NOT NULL
);

CREATE TABLE oseba (
	osebaID SERIAL PRIMARY KEY,
	ime TEXT NOT NULL,
	priimek TEXT NOT NULL,
	rojstvo DATE NOT NULL,
	kri TEXT NOT NULL,
	teza DECIMAL NOT NULL,
	visina DECIMAL NOT NULL,
	osebniZdravnik INTEGER NOT NULL REFERENCES zdravnik(zdravnikID),
	CONSTRAINT sam_svoj_zdravnik CHECK (/* TODO*/),
	CONSTRAINT napoved_rojstva CHECK (rojstvo <= now()),
	CONSTRAINT nepozitivna_teza CHECK (teza > 0),
	CONSTRAINT nepozitivna_visina CHECK (visina > 0)
);

CREATE TABLE specializacija (
    zdravnik INTEGER NOT NULL REFERENCES zdravnik(zdravnikID) ON DELETE CASCADE,
    test INTEGER NOT NULL REFERENCES test(testID) ON DELETE CASCADE,
    PRIMARY KEY (zdravnik, test)
);

CREATE TABLE diagnoza (
	diagnozaID SERIAL PRIMARY KEY,
	bolezen INTEGER NOT NULL REFERENCES bolezen(bolezenID),
	zdravilo INTEGER NOT NULL REFERENCES zdravilo(zdraviloID),
	zdravnik INTEGER NOT NULL REFERENCES zdravnik(zdravnikID)
);

CREATE TABLE pregled (
    pregledID SERIAL PRIMARY KEY,
	oseba INTEGER NOT NULL REFERENCES oseba(osebaID),
	zdravnik INTEGER NOT NULL REFERENCES zdravnik(zdravnikID),
	testZdaj INTEGER NOT NULL REFERENCES test(testID),
	testNaprej INTEGER REFERENCES test(testID) DEFAULT NULL,
	diagnoza INTEGER REFERENCES diagnoza(diagnozaID) DEFAULT NULL,
	izvid TEXT,
	datum DATE DEFAULT now(), 
	CONSTRAINT napoved_pregleda CHECK (datum <= now()),
	CONSTRAINT brez_diagnoze_in_napotnice CHECK (testNaprej IS NOT NULL OR diagnoza IS NOT NULL)
);

/* ne deluje */
CREATE TRIGGER posodobitev AFTER INSERT ON pregled
FOR EACH ROW
WHEN (last(diagnoza) <> NULL)
EXECUTE PROCEDURE UPDATE pregled
   SET pregled(diagnoza) = last(pregled(diagnoza))
   WHERE pregled(oseba) = last(pregled(oseba)) AND pregled(diagnoza) = NULL;
   
/* alternativno - tudi ne deluje */
CREATE TRIGGER posodobitev
ON pregled
AFTER INSERT
AS
BEGIN
  UPDATE pregled 
     SET pregled(diagnoza) = last(pregled(diagnoza))
     WHERE pregled(oseba) = last(pregled(oseba)) AND pregled(diagnoza) = NULL;
END