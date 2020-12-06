/*
Une bibliothèque est gérée à travers la base de données dont le schéma est ci-dessous. Elle dispose d'un bon nombre d'ouvrages caractérisés par un identifiant, un titre, une année de production, un thème, un nombre de likes et de dislikes obtenus à la suite de chaque prêt d'une copie de l'ouvrage.
À chaque ouvrage correspond un certain nombre de copies qui sont mises à disposition des étudiants pour le prêt. Une copie est caractérisée par un identifiant, un état ('P' pour prêté, 'D' pour disponible ou 'M' pour copie en maintenance) ainsi que l'identifiant de l'ouvrage auquel il est relié (IDO#).
La base gère aussi les étudiants. Chacun est caractérisé par un identifiant interne à l'école, un numéro de CIN unique, un nom et un cursus qu'il étudie (le parcours dans lequel il est inscrit).
Un prêt est fait par un étudiant (IDE#), pour une certaine copie (IDC#), à une date de prêt (DATEP). Le retour de la copie se fait à une certaine date (DATER), la saisie se fait par un bibliothécaire (IDB#) qui saisit par la même occasion l'avis de l'étudiant sur l'ouvrage (AVIS qui a la valeur LIKE ou DISLIKE).
Finalement les bibliothécaires sont gérés dans la table BIBLIO.
*/

-- OUVRAGE(IDO,TITRE,ANNEE,THEME,LIKES,DISLIKES)
-- COPIE(IDC,ETAT,IDO#)
-- ETUDIANT(IDE,CIN,NOM,CURSUS)
-- PRET(IDC#,IDE#,DATEP,DATER,AVIS,IDB#)
-- BIBLIO(IDB,NOM)
DROP USER BIBLIO CASCADE;
DROP USER TAREK;
DROP USER JIHED;
-- Création de l'utilisateur BIBLIO password sgbd tablespace USERS
CREATE USER BIBLIO IDENTIFIED BY sgbd
DEFAULT TABLESPACE USERS
QUOTA 10M ON USERS;
--Affecter à projet les privilèges qu'il faut pour se connecter, créer des tables, des vues, des indexes, des synonymes, des procédures, des séquences et des triggers.
GRANT CREATE SESSION, CREATE USER, CREATE TABLE, CREATE VIEW, CREATE SYNONYM, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER TO BIBLIO;
--Se connecter en tant que projet
CONNECT biblio/sgbd;
--création base
CREATE TABLE OUVRAGE(IDO VARCHAR2(10) PRIMARY KEY,TITRE VARCHAR2(100),ANNEE NUMBER,THEME VARCHAR2(30),LIKES NUMBER,DISLIKES NUMBER);
CREATE TABLE COPIE(IDC VARCHAR2(10) PRIMARY KEY,ETAT CHAR(1) CHECK (ETAT IN ('M','P','D')), IDO VARCHAR2(10) REFERENCES OUVRAGE(IDO));
CREATE TABLE ETUDIANT(IDE VARCHAR2(10) PRIMARY KEY,CIN VARCHAR2(8) UNIQUE, NOM VARCHAR2(30),CURSUS VARCHAR2(20));
CREATE TABLE BIBLIO(IDB VARCHAR2(10) PRIMARY KEY,NOM VARCHAR2(30));
CREATE TABLE PRET(IDC VARCHAR2(10) REFERENCES COPIE(IDC),IDE REFERENCES ETUDIANT(IDE),DATEP DATE,DATER DATE, AVIS VARCHAR2(7) CHECK (AVIS IN ('LIKE','DISLIKE')),IDB VARCHAR2(10) REFERENCES BIBLIO(IDB),PRIMARY KEY(IDC,IDE,DATEP));
--Création d'une séquence pour chacune des tables ouvrages, copie et etudiant
CREATE SEQUENCE ouv_pk MINVALUE 1 MAXVALUE 100
START WITH 1 INCREMENT BY 1 NOCYCLE;
CREATE SEQUENCE cop_pk MINVALUE 1 MAXVALUE 100
START WITH 1 INCREMENT BY 1 NOCYCLE;
CREATE SEQUENCE et_pk MINVALUE 1 MAXVALUE 100
START WITH 1 INCREMENT BY 1 NOCYCLE;
CREATE SEQUENCE bib_pk MINVALUE 1 MAXVALUE 100
START WITH 1 INCREMENT BY 1 NOCYCLE;
--Insertion de lignes échantillons
----Insertion de 10 ouvrages
DECLARE
  TYPE tab_titres IS VARRAY(10) OF VARCHAR2(100);
  titres tab_titres := tab_titres('Bases de données','Systèmes exploitation','Systèmes informations', 'Réseaux informatiques','Business Intelligence','A new IS architecture','Digital Marketing','A comparative study of customer behavior analysis methods','Comptabilité','Principes de gestion');
  TYPE tab_themes IS VARRAY(3) OF VARCHAR2(15);
  themes tab_themes := tab_themes('Informatique','Gestion');
BEGIN
  FOR i IN 1..6 LOOP
    INSERT INTO OUVRAGE VALUES('O'||ouv_pk.NEXTVAL, titres(i), ROUND(DBMS_RANDOM.VALUE(2000,2010)),'Informatique',0,0);
  END LOOP;
  FOR i IN 7..10 LOOP
    INSERT INTO OUVRAGE VALUES('O'||ouv_pk.NEXTVAL, titres(i), ROUND(DBMS_RANDOM.VALUE(2000,2010)),'Gestion',0,0);
  END LOOP;
END;
/
----Insertion de deux copies disponibles pour chaque ouvrage
BEGIN
	FOR rec_ouv IN (SELECT * FROM ouvrage) LOOP
		FOR i IN 1..5 LOOP
			INSERT INTO COPIE VALUES('C'||cop_pk.NEXTVAL,'D',rec_ouv.ido);
		END LOOP;
	END LOOP;
END;
/
----Insertion d'étudiants
DECLARE
	TYPE tab_noms IS VARRAY(10) OF VARCHAR2(10);
	noms tab_noms := tab_noms('ALI','MONIA','SAMI','KHADIJA','MOURAD','KARIMA','RAMI','SONIA','KHALIL','LINA');
	TYPE tab_cursus IS VARRAY(3) OF VARCHAR2(10);
	cursus tab_cursus := tab_cursus('DSSD','E-BUSINESS','VIC');
BEGIN
	FOR i IN 1..50 LOOP
		INSERT INTO ETUDIANT VALUES('E'||et_pk.NEXTVAL,
		TO_CHAR(ROUND(DBMS_RANDOM.VALUE(10000000,90000000))),
		noms(ROUND(DBMS_RANDOM.VALUE(1,10))),
		cursus(ROUND(DBMS_RANDOM.VALUE(1,3))));
	END LOOP;
END;
/

----Insertion de bibliothécaires
INSERT INTO BIBLIO VALUES('B'||bib_pk.NEXTVAL,'TAREK');
INSERT INTO BIBLIO VALUES('B'||bib_pk.NEXTVAL,'JIHED');
INSERT INTO BIBLIO VALUES('B'||bib_pk.NEXTVAL,'BIBLIO');

----Insertion de prêts
DECLARE
	TYPE tab_avis IS VARRAY(2) OF VARCHAR2(10);
	avis tab_avis := tab_avis('LIKE','DISLIKE');
	v_idc COPIE.IDC%TYPE;
	v_ide ETUDIANT.IDE%TYPE;
	v_idb BIBLIO.IDB%TYPE;
	v_datep DATE;
	v_dater DATE;
BEGIN
	FOR i IN 1..50 LOOP
		SELECT IDC INTO v_idc FROM (SELECT IDC FROM COPIE
			WHERE IDC NOT IN(SELECT IDC FROM PRET)
			ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM=1;
		SELECT IDE INTO v_ide FROM (SELECT IDE FROM ETUDIANT ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM=1;
		SELECT IDB INTO v_idb FROM (SELECT IDB FROM BIBLIO ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM=1;
		v_datep:= SYSDATE - ROUND(DBMS_RANDOM.VALUE(1,60));
		v_dater:= SYSDATE - ROUND(DBMS_RANDOM.VALUE(1,60));
		IF v_dater < v_datep THEN
			v_dater:=NULL;
		END IF;
		INSERT INTO PRET VALUES(v_idc,v_ide,v_datep,v_dater,avis(ROUND(DBMS_RANDOM.VALUE(1,2))),v_idb);
	END LOOP;
END;
/
COMMIT;

--Création des utilisateurs TAREK et JIHED avec le password sgbd
CREATE USER TAREK IDENTIFIED BY sgbd
DEFAULT TABLESPACE USERS
QUOTA 10M ON USERS;

CREATE USER JIHED IDENTIFIED BY sgbd
DEFAULT TABLESPACE USERS
QUOTA 10M ON USERS;
--0-Commentez le script de création de la BD et surtout les blocs PL/SQL qui ont servi à l'insertion de lignes.

--1-Créer une procédure P_AFF_INC qui affiche la liste des copies ayant l'état 'D' malgré qu'elles sont actuellement prêtées et non retournées (DATER est NULL). Afficher pour chacune des copies le titre du livre, le code de la copie concernée, son état, la date de prêt et la date de retour (qui est forcément NULL).

--2-Créer une procédure P_CORR_INC qui corrige cette situation incohérente en affectant l'état 'P' aux copies actuellement prêtées et non retournées.

--3-Créer une procédure P_AFF_PRETS qui affiche les prêts remis et non remis d'un étudiant dont on entre le CIN en paramètre. Afficher le code de l'étudiant, son CIN, le code de la copie, le titre de l'ouvrage, la date de prêt et la date de remise.

--4-Créer un trigger T_MAJ_P qui se déclenche avant l'insertion d'une ligne dans PRET. Ce trigger doit mettre à jour la colonne ETAT de la copie à prêter à 'P'. Il doit aussi lire le nom de l'utilisateur qui a lancé la requête INSERT, la chercher dans la table BIBLIO et affecter son identifiant au champ IDB de la ligne à insérer.

--5-Créer une procédure P_INSERT_PRET qui enregistre le prêt d'un ouvrage de code donné à un étudiant de CIN donné avec comme date de prêt la date système. La procédure doit trouver une copie disponible de cet ouvrage et ensuite insérer une ligne dans PRET en utilisant le code de la copie, le code de l'étudiant et la date système comme date de prêt. Les autres champs doivent être NULL. La procédure retourne dans un paramètre la valeur 1 si le prêt a été effectué, et -1 si la procédure n'a pas trouvé de copie disponible pour l'ouvrage en question.

--6-Créer un trigger T_MAJ_D qui se déclenche après la modification du champ 'DATER' de la table PRET si l'ancienne valeur est NULL et que la nouvelle n'est pas NULL (ici, nous sommes dans le cas d'une modification d'une date de retour de NULL à une valeur non nulle, et donc nous sommes dans le cas d'un retour de prêt). Le trigger doit mettre à jour la copie concernée par ce prêt en modifiant son état à 'D'.

--7-Créer une procédure P_UPDATE_RETOUR qui affecte à un prêt la date de retour, l'avis ('LIKE' ou 'DISLIKE') de l'étudiant par rapport à l'ouvrage emprunté, et le code du bibliothécaire qui effectue le retour de prêt (lire le nom d'utilisateur, et le chercher dans la table BIBLIO). Le prêt est identifié par le CIN de l'étudiant et le code de la copie prêtée.

--8-Créer une procédure P_MAJ_LIKES qui affecte aux champs LIKES et DISLIKES de la table ouvrage le nombre de LIKES et de DISLIKES reçus pour chaque ouvrage.

--9-Créer un trigger T_MAJ_AVIS qui à chaque UPDATE de la colonne AVIS de la table PRET d'incrémenter les colonnes LIKES ou DISLIKES de l'ouvrage concerné en l'incrémentant.

--10-Créer une fonction F_AVIS qui retourne une chaine de caractères renseignant le nombre de LIKES et de DISLIKES d'un ouvrage donné sous cette forme 'LIKES 12, DISLIKES 3'.

--11-Créer une vue V_CTO qui retourne pour chaque cursus, pour chaque theme, et pour chaque ouvrage, le nombre de prêts effectués. La vue est définie sur les colonnes CURSUS, THEME, OUVRAGE, NOMBRE.

--12-Afficher tous les objets BDs qui font partie du schéma de BIBLIO (tables, procédures, fonctions, vues, triggers et séquences) à partir du dictionnaire de données. Afficher aussi les utilisateurs.

--13-Donner à JIHED et TAREK les privilèges de connexion, d'exécution sur les procédures et fonctions créés, et d'accès à la vue V_CTO.

--14-Connectez vous sous JIHED et testez toutes les procédures et fonctions créées.

--15-Toujours sous JIHED, écrire une requête SQL qui affiche pour chaque cursus et chaque thème l'ouvrage ayant eu le plus grand nombre de prêts. utiliser la vue V_CTO.

--TRAVAIL À RENDRE--
/*
1. Projet implémenté à montrer dans uen soutenance technique
2. Imprimé du script en réponse aux 16 questions (de 0 à 15)
3. Le travail doit se faire en binôme (pas de monome et pas de trinomes ou autre).
*/