/* skapar databasen */

DROP DATABASE IF EXISTS tdl;
CREATE DATABASE tdl;

/* connectar till den skapade databasen */

\c tdl;
\set AUTOCOMMIT off

BEGIN;

/* skapar tabeller */

CREATE TABLE user_account (
    id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR NOT NULL,
    password VARCHAR NOT NULL,
    date_created TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT username_must_be_different UNIQUE (username)
);

CREATE TABLE note (
    id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES user_account(id),
    headline VARCHAR NOT NULL,
    additional_text VARCHAR,
    priority BIGINT NOT NULL,
    status BOOL DEFAULT FALSE NOT NULL,
    date_created TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL/*,
    CONSTRAINT note_priority_must_be_different UNIQUE (user_id, priority)*/
);

CREATE TABLE user_additional_info (
    user_id BIGINT PRIMARY KEY REFERENCES user_account(id),
    first_name VARCHAR,
    last_name VARCHAR
);

CREATE TABLE user_contact_info_phone (
    id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES user_account(id),
    phone VARCHAR
);

CREATE TABLE user_contact_info_email (
    id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES user_account(id),
    email VARCHAR
);

/*
TODO: constraints separat och inte i CREATE TABLE
Anledning: Skapa tabeller först, sedan länka ihop med contstraints/foreign keys
gör att tabeller kan skapas i vilken ordning som helst istället för som nu där
notes är beroende på att todo_user redan finns
*/

COMMIT;
